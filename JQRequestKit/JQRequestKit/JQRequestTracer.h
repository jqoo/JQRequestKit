//
//  JQRequestTracer.h
//  LoochaCampusMain
//
//  Created by zhang jinquan on 2/18/16.
//  Copyright © 2016 Real Cloud. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "JQResponseResult.h"

@class JQRequest;

@protocol JQRequestTracer <NSObject>

@optional

@property (nonatomic, strong) dispatch_queue_t completionQueue;
@property (nonatomic, strong) dispatch_group_t completionGroup;

/**
 *  数据发送进度反馈
 *  被回调至主线程执行
 *
 *  @param request
 *  @param bytesWritten              本次发送数据字节数
 *  @param totalBytesWritten         总共已发送的字节数
 *  @param totalBytesExpectedToWrite 该请求需要发送的总大小
 */
- (void)didUploadWithRequest:(JQRequest *)request bytesWritten:(NSInteger)bytesWritten totalBytesWritten:(NSInteger)totalBytesWritten totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite;

@required

- (void)didCompleteWithRequest:(JQRequest *)request response:(NSURLResponse *)response responseObject:(id)responseObject error:(NSError *)error;

@end

typedef void (^JQRequestUploadProgressBlock)(JQRequest *request, NSUInteger bytes, long long totalBytes, long long totalBytesExpected);
//typedef void (^JQRequestCompletionBlock)(JQRequest *request, NSURLResponse *response, id responseObject, NSError *error);

@interface JQRequestTracer : NSObject <JQRequestTracer>

@property (nonatomic, copy) void (^completionBlock)(JQResponseResult *responseResult);
@property (nonatomic, copy) JQRequestUploadProgressBlock uploadProgressBlock;

@property (nonatomic, strong) dispatch_queue_t completionQueue;
@property (nonatomic, strong) dispatch_group_t completionGroup;

+ (instancetype)tracerWithCompletionBlock:(void (^)(JQResponseResult *responseResult))completionBlock;

- (void)didReceiveResponseResult:(JQResponseResult *)responseResult request:(JQRequest *)request;

@end

@interface JQRequestTracerWeakify : NSProxy <JQRequestTracer>

@property (nonatomic, weak) id<JQRequestTracer> weakTracer;

+ (instancetype)tracerWithWeakTracer:(id<JQRequestTracer>)weakTracer;

@end
