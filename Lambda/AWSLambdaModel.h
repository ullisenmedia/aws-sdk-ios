//
//  AWSLambdaModel.h
//  AWSiOSSDKv2
//
//  Created by Earl Ferguson on 1/24/15.
//  Copyright (c) 2015 Amazon Web Services. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AWSNetworking.h"
#import "AWSModel.h"

FOUNDATION_EXPORT NSString *const AWSLambdaErrorDomain;

typedef NS_ENUM(NSInteger, AWSLambdaErrorType) {
    AWSLambdaErrorUnknown,
    AWSLambdaErrorAccessDenied,
    AWSLambdaErrorUnrecognizedClient,
    AWSLambdaErrorIncompleteSignature,
    AWSLambdaErrorInvalidClientTokenId,
    AWSLambdaErrorMissingAuthenticationToken,
    AWSLambdaErrorConditionalCheckFailed,
    AWSLambdaErrorInternalServer,
    AWSLambdaErrorInvalidRequestContentException,
    AWSLambdaErrorResourceNotFoundException,
    AWSLambdaErrorServiceException
};


@interface AWSLambdaInvokeAsyncRequest : AWSRequest

@property (nonatomic, strong) NSString *functionName;

@end