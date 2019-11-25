//
//  JQDownloadRequest.h
//  JQRequestKit
//
//  Created by jinquan on 2017/8/9.
//  Copyright © 2017年 jqoo. All rights reserved.
//

#import <Foundation/Foundation.h>

@class JQDownloadRequest;
@class JQDownloadRequestLoader;

@protocol JQDownloadRequestTracer <NSObject>

@optional

- (NSURL *)destinationOfRequest:(JQDownloadRequest *)request targetPath:(NSURL *)targetPath response:(NSURLResponse *)response;

- (NSURL *)resumeDataHomeOfRequest:(JQDownloadRequest *)request targetPath:(NSURL *)targetPath resumeInfoName:(NSString **)resumeInfoName;

- (void)didReceiveDataWithRequest:(JQDownloadRequest *)request completedSize:(long long)completedSize totalSize:(long long)totalSize;

- (void)didCompleteWithRequest:(JQDownloadRequest *)request response:(NSURLResponse *)response filePath:(NSURL *)filePath error:(NSError *)error;

@end

@interface JQDownloadRequestTracer : NSObject <JQDownloadRequestTracer>

@property (nonatomic, copy) NSURL * (^destination)(JQDownloadRequest *request, NSURL *targetPath, NSURLResponse *response);
@property (nonatomic, copy) NSURL * (^resumeDataHome)(JQDownloadRequest *request, NSURL *resumeDataPath, NSString **resumeInfoName);
@property (nonatomic, copy) void (^completionHandler)(JQDownloadRequest *request, NSURLResponse *response, NSURL *filePath, NSError *error);
@property (nonatomic, copy) void (^progressHandler)(JQDownloadRequest *request, long long completedSize, long long totalSize);

+ (instancetype)tracerWithDestination:(NSURL * (^)(JQDownloadRequest *request, NSURL *targetPath, NSURLResponse *response))destination
                    completionHandler:(void (^)(JQDownloadRequest *request, NSURLResponse *response, NSURL *filePath, NSError *error))completionHandler
                      progressHandler:(void (^)(JQDownloadRequest *request, long long completedSize, long long totalSize))progressHandler;

+ (instancetype)tracerWithDestination:(NSURL * (^)(JQDownloadRequest *request, NSURL *targetPath, NSURLResponse *response))destination
                       resumeDataHome:(NSURL * (^)(JQDownloadRequest *request, NSURL *targetPath, NSString **resumeInfoName))resumeDataHome
                    completionHandler:(void (^)(JQDownloadRequest *request, NSURLResponse *response, NSURL *filePath, NSError *error))completionHandler
                      progressHandler:(void (^)(JQDownloadRequest *request, long long completedSize, long long totalSize))progressHandler;

@end

@interface JQDownloadRequest : NSObject

@property (nonatomic, strong) id<JQDownloadRequestTracer> tracer;
@property (nonatomic, readonly) NSURLRequest *urlRequest;
@property (nonatomic, readonly) BOOL resumable;
@property (nonatomic, assign) BOOL traceCancel;

+ (instancetype)requestWithURLRequest:(NSURLRequest *)urlRequest resumable:(BOOL)resumable;

- (instancetype)initWithURLRequest:(NSURLRequest *)urlRequest resumable:(BOOL)resumable;

- (void)startOnLoader:(JQDownloadRequestLoader *)loader;

- (void)start;
- (void)cancel;

@end
