//
//  JQRequestLoader.h
//  LoochaCampusMain
//
//  Created by zhang jinquan on 1/14/16.
//  Copyright © 2016 jqoo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JQRequest.h"
#import "JQDNSResolver.h"
#import <AFNetworking/AFNetworking.h>
//#import "AFNetworking.h"

@interface JQRequestLoader : NSObject

@property (nonatomic, readonly) AFHTTPSessionManager *manager;
@property (nonatomic, assign) BOOL shouldCacheResponse;

- (void)scheduleRequest:(JQRequest *)request;
- (void)cancelRequest:(JQRequest *)request;
- (void)cancelAllRequests;

+ (instancetype)sharedInstance;

@end
