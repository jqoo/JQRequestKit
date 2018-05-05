//
//  JQDownloadRequestLoader.m
//  JQRequestKit
//
//  Created by jinquan on 2017/8/9.
//  Copyright © 2017年 Real Cloud. All rights reserved.
//

#import "JQDownloadRequestLoader.h"
#import <CommonCrypto/CommonDigest.h>
#import "JQRequest.h"

@interface JQDownloadInfoPrivate : NSObject
{
@public
    JQDownloadRequest *request;
    NSURL *locationURL;
    NSURLSessionDownloadTask *task;
}

@end

@implementation JQDownloadInfoPrivate

@end

@interface JQDownloadRequestLoader () <NSURLSessionDownloadDelegate>
{
    NSMutableDictionary *_InfoMap;
    NSURLSession* _session;
}

@end

static NSString *MD5ForString(NSString *str) {
    if(str == nil || [str length] == 0)
        return nil;
    
    const char *value = [str UTF8String];
    
    unsigned char outputBuffer[CC_MD5_DIGEST_LENGTH];
    CC_MD5(value, (CC_LONG)str.length, outputBuffer);
    
    NSMutableString *outputString = [[NSMutableString alloc] initWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for(NSInteger count = 0; count < CC_MD5_DIGEST_LENGTH; count++){
        [outputString appendFormat:@"%02x",outputBuffer[count]];
    }
    
    return outputString;
}


@implementation JQDownloadRequestLoader

+ (instancetype)loaderWithConfiguration:(NSURLSessionConfiguration *)cfg {
    return [[self alloc] initWithConfiguration:cfg];
}

- (instancetype)initWithConfiguration:(NSURLSessionConfiguration *)cfg {
    self = [super init];
    if (self) {
        _session = [NSURLSession sessionWithConfiguration:cfg delegate:self delegateQueue:[NSOperationQueue mainQueue]];
        
        _InfoMap = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (instancetype)init {
    return [self initWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
}

- (NSURL *)resumeDataHome {
    NSString *cachePath = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject;
    NSString *path = [cachePath stringByAppendingPathComponent:@"JQDownloadCache"];
    return [NSURL fileURLWithPath:path];
}

- (NSURL *)resumBackupPath:(JQDownloadRequest *)request {
    NSURL *home = [self resumeDataHome];
    NSString *folderName = nil;
    if ([request.tracer respondsToSelector:@selector(resumeDataHomeOfRequest:targetPath:resumeInfoName:)]) {
        NSURL *url = [request.tracer resumeDataHomeOfRequest:request targetPath:home resumeInfoName:&folderName];
        if (url) {
            home = url;
        }
    }
    if (!folderName) {
        folderName = MD5ForString([request.urlRequest.URL absoluteString]);
    }
    return [home URLByAppendingPathComponent:folderName];
}

- (void)scheduleRequest:(JQDownloadRequest *)request {
    if (!request.urlRequest) {
        return;
    }
    NSURLSessionDownloadTask* task = nil;
    if (request.resumable) {
        NSURL *resumeBackupPath = [self resumBackupPath:request];
        NSURL *resumDataPath = [resumeBackupPath URLByAppendingPathComponent:@"resume.data"];
        NSData *resumeData = [NSData dataWithContentsOfURL:resumDataPath];
        if (resumeData) {
            NSPropertyListFormat format = 0;
            NSError *error = nil;
            NSDictionary *resumeInfo = [NSPropertyListSerialization propertyListWithData:resumeData
                                                                                 options:NSPropertyListImmutable
                                                                                  format:&format
                                                                                   error:&error];
            NSString *downloadUrl = resumeInfo[@"NSURLSessionDownloadURL"];
            if ([[request.urlRequest.URL absoluteString] isEqualToString:downloadUrl]) {
                NSURL *tmpFilePath = [self tempFileURL:resumeInfo];
                if (tmpFilePath) {
                    [[NSFileManager defaultManager] moveItemAtURL:tmpFilePath toURL:[resumeBackupPath URLByAppendingPathComponent:[tmpFilePath lastPathComponent]] error:&error];
                    [[NSFileManager defaultManager] moveItemAtURL:[resumeBackupPath URLByAppendingPathComponent:[tmpFilePath lastPathComponent]] toURL:tmpFilePath error:&error];
                    [[NSFileManager defaultManager] removeItemAtURL:resumDataPath error:&error];
                    task = [_session downloadTaskWithResumeData:resumeData];
                }
            }
            else {
                [[NSFileManager defaultManager] removeItemAtURL:resumeBackupPath error:nil];
            }
        }
    }
    if (!task) {
        task = [_session downloadTaskWithRequest:request.urlRequest];
    }
    
    JQDownloadInfoPrivate *info = [[JQDownloadInfoPrivate alloc] init];
    info->request = request;
    info->task = task;
    NSLog(@"download tast : %lld, url : %@", (long long)task.taskIdentifier, request.urlRequest.URL);
    [_InfoMap setObject:info forKey:@(task.taskIdentifier)];
    
    [task resume];
}

- (void)cancelRequest:(JQDownloadRequest *)request {
    __block JQDownloadInfoPrivate *info = nil;
    [_InfoMap.allValues enumerateObjectsUsingBlock:^(JQDownloadInfoPrivate *obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj->request == request) {
            info = obj;
            *stop = YES;
        }
    }];
    if (!info) {
        return;
    }
    if (request.resumable) {
        [info->task cancelByProducingResumeData:^(NSData *resumeData) {
            // save in completion callback
        }];
    }
    else {
        [info->task cancel];
    }
}

- (NSURL *)tempFileURL:(NSDictionary *)resumeInfo {
    NSString *tempFileName = resumeInfo[@"NSURLSessionResumeInfoTempFileName"];
    NSString *path = nil;
    if (tempFileName) {
        NSString *tmp = NSTemporaryDirectory();
        path = [tmp stringByAppendingPathComponent:tempFileName];
    }
    else {
        // ios8上用的是路径
        path = resumeInfo[@"NSURLSessionResumeInfoLocalPath"];
    }
    return path ? [NSURL fileURLWithPath:path] : nil;
}

- (void)saveResumeData:(NSData *)resumeData request:(JQDownloadRequest *)request {
    if (resumeData) {
        NSURL *resumeBackupPath = [self resumBackupPath:request];
        [[NSFileManager defaultManager] createDirectoryAtURL:resumeBackupPath withIntermediateDirectories:YES attributes:nil error:nil];
        
        NSPropertyListFormat format = 0;
        NSError *error = nil;
        NSDictionary *resumeInfo = [NSPropertyListSerialization propertyListWithData:resumeData
                                                                             options:NSPropertyListImmutable
                                                                              format:&format
                                                                               error:&error];
        NSURL *tmpFilePath = [self tempFileURL:resumeInfo];
        if (tmpFilePath) {
            [[NSFileManager defaultManager] moveItemAtURL:tmpFilePath toURL:[resumeBackupPath URLByAppendingPathComponent:[tmpFilePath lastPathComponent]] error:&error];
            [resumeData writeToURL:[resumeBackupPath URLByAppendingPathComponent:@"resume.data"] atomically:YES];
        }
    }
}

- (void)cancelAllRequests {
    NSArray *infos = [_InfoMap allValues];
    for (JQDownloadInfoPrivate *info in infos) {
        [self cancelRequest:info->request];
    }
}

- (void)clearResumeCache:(JQDownloadRequest *)request task:(NSURLSessionTask *)downloadTask {
    NSURL *resumeBackupPath = [self resumBackupPath:request];
    [[NSFileManager defaultManager] removeItemAtURL:resumeBackupPath error:nil];
}

+ (instancetype)sharedInstance {
    static JQDownloadRequestLoader *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[JQDownloadRequestLoader alloc] init];
    });
    return instance;
}

- (JQDownloadInfoPrivate *)infoOfTask:(NSURLSessionTask *)downloadTask {
    return _InfoMap[@(downloadTask.taskIdentifier)];;
}

#pragma mark - NSURLSessionDownloadDelegate

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location {
    NSLog(@"download tast : %lld, didFinishDownloadingToURL: %@", (long long)downloadTask.taskIdentifier, location);
    
    JQDownloadInfoPrivate *info = [self infoOfTask:downloadTask];
    if (!info) {
        return;
    }
    NSInteger statusCode = [(NSHTTPURLResponse *)downloadTask.response statusCode];
    if (statusCode >= 200 && statusCode < 400) {
        if ([info->request.tracer respondsToSelector:@selector(destinationOfRequest:targetPath:response:)]) {
            NSURL *dist = [info->request.tracer destinationOfRequest:info->request targetPath:location response:downloadTask.response];
            if (dist) {
                NSError *error = nil;
                [[NSFileManager defaultManager] moveItemAtURL:location toURL:dist error:&error];
                if (error) {
                    NSLog(@"error : %@", error);
                }
                location = dist;
            }
        }
        info->locationURL = location;
    }
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask
      didWriteData:(int64_t)bytesWritten
 totalBytesWritten:(int64_t)totalBytesWritten
totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
    JQDownloadInfoPrivate *info = [self infoOfTask:downloadTask];
    if (!info) {
        return;
    }
    if ([info->request.tracer respondsToSelector:@selector(didReceiveDataWithRequest:completedSize:totalSize:)]) {
        [info->request.tracer didReceiveDataWithRequest:info->request completedSize:totalBytesWritten totalSize:totalBytesExpectedToWrite];
    }
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)downloadTask didCompleteWithError:(NSError *)error {
    NSLog(@"download tast : %lld, didCompleteWithError: %@", (long long)downloadTask.taskIdentifier, error);
    
    JQDownloadInfoPrivate *info = [self infoOfTask:downloadTask];
    if (!info) {
        return;
    }
    [self clearTask:downloadTask];
    
    BOOL hasResumeData = NO;
    if (!error) {
        NSHTTPURLResponse *response = (NSHTTPURLResponse *)downloadTask.response;
        if (response && (response.statusCode < 200 || response.statusCode >= 400)) {
            error = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorBadServerResponse userInfo:nil];
        }
    }
    else if (info->request.resumable) {
        NSData *resumeData = [error.userInfo objectForKey:NSURLSessionDownloadTaskResumeData];
        if (resumeData) {
            hasResumeData = YES;
            [self saveResumeData:resumeData request:info->request];
        }
    }
    
    BOOL isCanceled = error && [error code] == NSURLErrorCancelled;
    
    // 如果是服务器错误，或请求错误，则清理
    if (info->request.resumable && downloadTask.response && !hasResumeData) {
        [self clearResumeCache:info->request task:downloadTask];
    }
    if (isCanceled && !info->request.traceCancel) {
        return;
    }
    if ([info->request.tracer respondsToSelector:@selector(didCompleteWithRequest:response:filePath:error:)]) {
        [info->request.tracer didCompleteWithRequest:info->request response:downloadTask.response filePath:info->locationURL error:error];
    }
}

- (void)clearTask:(NSURLSessionTask *)downloadTask {
    [_InfoMap removeObjectForKey:@(downloadTask.taskIdentifier)];
}

- (void)clearDefaultResumeCache {
    [[NSFileManager defaultManager] removeItemAtURL:[self resumeDataHome] error:nil];
}

- (void)URLSessionDidFinishEventsForBackgroundURLSession:(NSURLSession *)session {
    if (self.didFinishEventsForBackgroundURLSession) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.didFinishEventsForBackgroundURLSession(session);
        });
    }
}

@end
