//
//  AWSLambdaModel.m
//  AWSiOSSDKv2
//
//  Created by Earl Ferguson on 1/24/15.
//  Copyright (c) 2015 Amazon Web Services. All rights reserved.
//

#import "AWSLambdaModel.h"

NSString *const AWSLambdaErrorDomain = @"com.amazonaws.AWSLambdaErrorDomain";

@implementation AWSLambdaInvokeAsyncRequest

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
    return @{
             @"functionName" : @"FunctionName"
             };
}

@end

