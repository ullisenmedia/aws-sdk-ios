//
//  AWSLambda.m
//  AWSiOSSDKv2
//
//  Created by Earl Ferguson on 1/24/15.
//  Copyright (c) 2015 Amazon Web Services. All rights reserved.
//

#import "AWSLambda.h"

#import "AWSNetworking.h"
#import "AWSSignature.h"
#import "AWSService.h"
#import "AWSCategory.h"
#import "AWSNetworking.h"
#import "AWSURLRequestSerialization.h"
#import "AWSURLResponseSerialization.h"
#import "AWSURLRequestRetryHandler.h"

NSString *const AWSLambdaDefinitionFileName = @"dynamodb-2012-08-10";

@interface AWSLambdaResponseSerializer : AWSJSONResponseSerializer

@property (nonatomic, assign) Class outputClass;

+ (instancetype)serializerWithOutputClass:(Class)outputClass
                                 resource:(NSString *)resource
                               actionName:(NSString *)actionName;

@end

@implementation AWSLambdaResponseSerializer

#pragma mark - Service errors

static NSDictionary *errorCodeDictionary = nil;
+ (void)initialize {
    errorCodeDictionary = @{
                            @"AccessDeniedException" : @(AWSLambdaErrorAccessDenied),
                            @"UnrecognizedClientException" : @(AWSLambdaErrorUnrecognizedClient),
                            @"IncompleteSignature" : @(AWSLambdaErrorIncompleteSignature),
                            @"InvalidClientTokenId" : @(AWSLambdaErrorInvalidClientTokenId),
                            @"MissingAuthenticationToken" : @(AWSLambdaErrorMissingAuthenticationToken),
                            @"ConditionalCheckFailedException" : @(AWSLambdaErrorConditionalCheckFailed),
                            @"InternalServerError" : @(AWSLambdaErrorInternalServer),
                            @"InvalidRequestContent" : @(AWSLambdaErrorInvalidRequestContentException),
                            @"LimitExceededException" : @(AWSLambdaErrorResourceNotFoundException),
                            @"ServiceException" : @(AWSLambdaErrorServiceException),
                            @"ResourceNotFoundException" : @(AWSLambdaErrorResourceNotFoundException),
                            };
}

#pragma mark -

+ (instancetype)serializerWithOutputClass:(Class)outputClass resource:(NSString *)resource actionName:(NSString *)actionName
{
    AWSLambdaResponseSerializer *serializer = [AWSLambdaResponseSerializer serializerWithResource:resource actionName:actionName];
    
    serializer.outputClass = outputClass;
    
    return serializer;
}

- (id)responseObjectForResponse:(NSHTTPURLResponse *)response
                originalRequest:(NSURLRequest *)originalRequest
                 currentRequest:(NSURLRequest *)currentRequest
                           data:(id)data
                          error:(NSError *__autoreleasing *)error {
    id responseObject = [super responseObjectForResponse:response
                                         originalRequest:originalRequest
                                          currentRequest:currentRequest
                                                    data:data
                                                   error:error];
    if (!*error && [responseObject isKindOfClass:[NSDictionary class]]) {
        if ([errorCodeDictionary objectForKey:[[[responseObject objectForKey:@"__type"] componentsSeparatedByString:@"#"] lastObject]]) {
            if (error) {
                *error = [NSError errorWithDomain:AWSLambdaErrorDomain
                                             code:[[errorCodeDictionary objectForKey:[[[responseObject objectForKey:@"__type"] componentsSeparatedByString:@"#"] lastObject]] integerValue]
                                         userInfo:responseObject];
            }
            return responseObject;
        } else if ([[[responseObject objectForKey:@"__type"] componentsSeparatedByString:@"#"] lastObject]) {
            if (error) {
                *error = [NSError errorWithDomain:AWSLambdaErrorDomain
                                             code:AWSLambdaErrorUnknown
                                         userInfo:responseObject];
            }
            return responseObject;
        }
        
        if (self.outputClass) {
            responseObject = [MTLJSONAdapter modelOfClass:self.outputClass
                                       fromJSONDictionary:responseObject
                                                    error:error];
        }
    }
    
    return responseObject;
}

@end

@interface AWSLambdaRequestRetryHandler : AWSURLRequestRetryHandler

@end

@implementation AWSLambdaRequestRetryHandler

- (AWSNetworkingRetryType)shouldRetry:(uint32_t)currentRetryCount
                             response:(NSHTTPURLResponse *)response
                                 data:(NSData *)data
                                error:(NSError *)error {
    AWSNetworkingRetryType retryType = [super shouldRetry:currentRetryCount
                                                 response:response
                                                     data:data
                                                    error:error];
    if(retryType == AWSNetworkingRetryTypeShouldNotRetry
       && [error.domain isEqualToString:AWSNetworkingErrorDomain]
       && currentRetryCount < self.maxRetryCount) {
        switch (error.code) {
            case AWSLambdaErrorAccessDenied:
            case AWSLambdaErrorUnrecognizedClient:
            case AWSLambdaErrorIncompleteSignature:
            case AWSLambdaErrorInvalidClientTokenId:
            case AWSLambdaErrorMissingAuthenticationToken:
                retryType = AWSNetworkingRetryTypeShouldRefreshCredentialsAndRetry;
                break;
                
            default:
                break;
        }
    }
    
    return retryType;
}

@end

@interface AWSRequest()

@property (nonatomic, strong) AWSNetworkingRequest *internalRequest;

@end

@interface AWSServiceConfiguration()

@property (nonatomic, strong) AWSEndpoint *endpoint;

@end

@interface AWSLambda()

@property (nonatomic, strong) AWSNetworking *networking;
@property (nonatomic, strong) AWSServiceConfiguration *configuration;

@end

@implementation AWSLambda

+ (instancetype)defaultLambda {
    if (![AWSServiceManager defaultServiceManager].defaultServiceConfiguration) {
        return nil;
    }
    
    static AWSLambda *_defaultLambda = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _defaultLambda = [[AWSLambda alloc] initWithConfiguration:[AWSServiceManager defaultServiceManager].defaultServiceConfiguration];
    });
    
    return _defaultLambda;
}

- (instancetype)initWithConfiguration:(AWSServiceConfiguration *)configuration {
    if (self = [super init]) {
        _configuration = [configuration copy];
        
        _configuration.endpoint = [AWSEndpoint endpointWithRegion:_configuration.regionType
                                                          service:AWSServiceDynamoDB];
        
        AWSSignatureV4Signer *signer = [AWSSignatureV4Signer signerWithCredentialsProvider:_configuration.credentialsProvider
                                                                                  endpoint:_configuration.endpoint];
        
        _configuration.baseURL = _configuration.endpoint.URL;
        _configuration.requestSerializer = [AWSJSONRequestSerializer new];
        _configuration.requestInterceptors = @[[AWSNetworkingRequestInterceptor new], signer];
        _configuration.retryHandler = [[AWSLambdaRequestRetryHandler alloc] initWithMaximumRetryCount:_configuration.maxRetryCount];
        _configuration.headers = @{@"Host" : _configuration.endpoint.hostName,
                                   @"Content-Type" : @"application/x-amz-json-1.0",
                                   @"Accept-Encoding" : @""};
        
        _networking = [AWSNetworking networking:_configuration];
    }
    
    return self;
}

- (BFTask *)invokeRequest:(AWSRequest *)request
               HTTPMethod:(AWSHTTPMethod)HTTPMethod
                URLString:(NSString *) URLString
             targetPrefix:(NSString *)targetPrefix
            operationName:(NSString *)operationName
              outputClass:(Class)outputClass {
    if (!request) {
        request = [AWSRequest new];
    }
    
    AWSNetworkingRequest *networkingRequest = request.internalRequest;
    if (request) {
        networkingRequest.parameters = [[MTLJSONAdapter JSONDictionaryFromModel:request] aws_removeNullValues];
    } else {
        networkingRequest.parameters = @{};
    }
    NSMutableDictionary *headers = [NSMutableDictionary new];
    headers[@"X-Amz-Target"] = [NSString stringWithFormat:@"%@.%@", targetPrefix, operationName];
    networkingRequest.headers = headers;
    networkingRequest.HTTPMethod = HTTPMethod;
    networkingRequest.responseSerializer = [AWSLambdaResponseSerializer serializerWithOutputClass:outputClass resource:AWSLambdaDefinitionFileName actionName:operationName];
    networkingRequest.requestSerializer = [AWSJSONRequestSerializer serializerWithResource:AWSLambdaDefinitionFileName actionName:operationName];
    
    return [self.networking sendRequest:networkingRequest];
}

#pragma mark - Service method

- (BFTask *)invokeAsync:(AWSLambdaInvokeAsyncRequest *)request {
    
    return [self invokeRequest:request
                    HTTPMethod:AWSHTTPMethodPOST
                     URLString:@"/function/{FunctionName}/invoke-async"
                  targetPrefix:@""
                 operationName:@"InvokeAsync"
                   outputClass:nil];
}

@end
