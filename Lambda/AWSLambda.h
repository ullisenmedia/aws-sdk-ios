//
//  AWSLambda.h
//  AWSiOSSDKv2
//
//  Created by Earl Ferguson on 1/24/15.
//  Copyright (c) 2015 Amazon Web Services. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AWSService.h"
#import "AWSLambdaModel.h"

@interface AWSLambda : AWSService

@property (nonatomic, strong, readonly) AWSServiceConfiguration *configurations;

+(instancetype)defaultLambda;

- (instancetype)initWithConfiguration:(AWSServiceConfiguration *)configuration;


@end
