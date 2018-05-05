//
//  JQDownloadRequestLoader.h
//  JQRequestKit
//
//  Created by jinquan on 2017/8/9.
//  Copyright © 2017年 jqoo. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "JQDownloadRequest.h"

@interface JQDownloadRequestLoader : NSObject

@property (nonatomic, copy) void (^didFinishEventsForBackgroundURLSession)(NSURLSession *session);

- (void)scheduleRequest:(JQDownloadRequest *)request;
- (void)cancelRequest:(JQDownloadRequest *)request;
- (void)cancelAllRequests;

- (void)clearDefaultResumeCache;

+ (instancetype)sharedInstance;
+ (instancetype)loaderWithConfiguration:(NSURLSessionConfiguration *)cfg;

@end
