//
//  JQDownloadRequest.m
//  JQRequestKit
//
//  Created by jinquan on 2017/8/9.
//  Copyright © 2017年 jqoo. All rights reserved.
//

#import "JQDownloadRequest.h"
#import "JQDownloadRequestLoader.h"

@implementation JQDownloadRequestTracer

+ (instancetype)tracerWithDestination:(NSURL * (^)(JQDownloadRequest *request, NSURL *targetPath, NSURLResponse *response))destination
                    completionHandler:(void (^)(JQDownloadRequest *request, NSURLResponse *response, NSURL *filePath, NSError *error))completionHandler
                      progressHandler:(void (^)(JQDownloadRequest *request, long long completedSize, long long totalSize))progressHandler {
    JQDownloadRequestTracer *tracer = [[self alloc] init];
    tracer.destination = destination;
    tracer.completionHandler = completionHandler;
    tracer.progressHandler = progressHandler;
    return tracer;
}

+ (instancetype)tracerWithDestination:(NSURL * (^)(JQDownloadRequest *request, NSURL *targetPath, NSURLResponse *response))destination
                       resumeDataHome:(NSURL * (^)(JQDownloadRequest *request, NSURL *targetPath, NSString **resumeInfoName))resumeDataHome
                    completionHandler:(void (^)(JQDownloadRequest *request, NSURLResponse *response, NSURL *filePath, NSError *error))completionHandler
                      progressHandler:(void (^)(JQDownloadRequest *request, long long completedSize, long long totalSize))progressHandler {
    JQDownloadRequestTracer *tracer = [[self alloc] init];
    tracer.destination = destination;
    tracer.resumeDataHome = resumeDataHome;
    tracer.completionHandler = completionHandler;
    tracer.progressHandler = progressHandler;
    return tracer;
}

- (NSURL *)destinationOfRequest:(JQDownloadRequest *)request targetPath:(NSURL *)targetPath response:(NSURLResponse *)response {
    NSURL *url = nil;
    if (_destination) {
        url = _destination(request, targetPath, response);
    }
    if (!url) {
        url = targetPath;
    }
    return url;
}

- (void)didReceiveDataWithRequest:(JQDownloadRequest *)request completedSize:(long long)completedSize totalSize:(long long)totalSize {
    if (_progressHandler) {
        _progressHandler(request, completedSize, totalSize);
    }
}

- (void)didCompleteWithRequest:(JQDownloadRequest *)request response:(NSURLResponse *)response filePath:(NSURL *)filePath error:(NSError *)error {
    if (_completionHandler) {
        _completionHandler(request, response, filePath, error);
    }
}

- (NSURL *)resumeDataHomeOfRequest:(JQDownloadRequest *)request targetPath:(NSURL *)targetPath resumeInfoName:(NSString **)resumeInfoName {
    NSURL *url = nil;
    if (_resumeDataHome) {
        url = _resumeDataHome(request, targetPath, resumeInfoName);
    }
    if (!url) {
        url = targetPath;
    }
    return url;
}

@end

@interface JQDownloadRequest ()
{
    __weak JQDownloadRequestLoader *_loader;
}

@property (nonatomic, strong) NSURLRequest *urlRequest;
@property (nonatomic, assign) BOOL resumable;

@end

@implementation JQDownloadRequest

+ (instancetype)requestWithURLRequest:(NSURLRequest *)urlRequest resumable:(BOOL)resumable {
    return [[self alloc] initWithURLRequest:urlRequest resumable:resumable];
}

- (instancetype)initWithURLRequest:(NSURLRequest *)urlRequest resumable:(BOOL)resumable {
    self = [super init];
    if (self) {
        self.urlRequest = urlRequest;
        self.resumable = resumable;
    }
    return self;
}

- (void)startOnLoader:(JQDownloadRequestLoader *)loader {
    _loader = loader;
    [loader scheduleRequest:self];
}

- (void)start {
    [self startOnLoader:[JQDownloadRequestLoader sharedInstance]];
}

- (void)cancel {
    [_loader cancelRequest:self];
}

@end
