//
//  JQRequestLoader.m
//  LoochaCampusMain
//
//  Created by zhang jinquan on 1/14/16.
//  Copyright © 2016 Real Cloud. All rights reserved.
//

#import "JQRequestLoader.h"
#import "AFNetworking.h"
#import "JQRequest.h"
#import "AFNetworking.h"

#import <objc/runtime.h>

@interface JQHTTPSessionManagerPrivate : AFHTTPSessionManager

@end

@implementation JQHTTPSessionManagerPrivate

- (BOOL)respondsToSelector:(SEL)aSelector {
    if (aSelector == @selector(URLSession:didReceiveChallenge:completionHandler:)) {
        return NO;
    }
    return [super respondsToSelector:aSelector];
}

@end

@interface JQFakeSessionManagerPrivate : NSProxy

@property (nonatomic, weak) AFURLSessionManager *realManager;
@property (nonatomic, strong, nullable) dispatch_queue_t completionQueue;
@property (nonatomic, strong, nullable) dispatch_group_t completionGroup;
@property (nonatomic, strong) AFHTTPResponseSerializer <AFURLResponseSerialization> * responseSerializer;
@property (nonatomic, strong) JQRequest *request;
@property (nonatomic, strong) NSURLSessionDataTask *task;
@property (nonatomic, strong) NSString *domain;

@end

@implementation JQFakeSessionManagerPrivate

+ (instancetype)fakeManager:(AFURLSessionManager *)manager {
    JQFakeSessionManagerPrivate *fake = [JQFakeSessionManagerPrivate alloc];
    fake.realManager = manager;
    return fake;
}

- (void)forwardInvocation:(NSInvocation *)anInvocation {
    if (self.realManager) {
        [anInvocation invokeWithTarget:self.realManager];
    }
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector {
    if (self.realManager) {
        return [(NSObject *)self.realManager methodSignatureForSelector:aSelector];
    }
    return [super methodSignatureForSelector:aSelector];
}

@end

@interface JQMultipartComposer ()

- (instancetype)initWithFormData:(id<AFMultipartFormData>)formData;

@end

@interface AFSecurityPolicy (JQSecurityPolicy) <JQSecurityPolicy>

@end

@interface JQRequestLoader ()
{
    AFHTTPSessionManager *_manager;
    NSMutableDictionary *_requestSerializerCache;
    NSMutableDictionary *_responseSerializerCache;
    NSMutableDictionary *_infoDict;
    NSMutableSet *_requestSet;
}

@end

@implementation JQRequestLoader

@synthesize manager = _manager;

- (void)dealloc {
    [self cancelAllRequests];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        NSURLSessionConfiguration *cfg = [NSURLSessionConfiguration defaultSessionConfiguration];
        _manager = [[JQHTTPSessionManagerPrivate alloc] initWithSessionConfiguration:cfg];
        
        _infoDict = [[NSMutableDictionary alloc] init];
        _requestSet = [[NSMutableSet alloc] init];
        
        __weak typeof(self) weakSelf = self;
        [_manager setTaskWillPerformHTTPRedirectionBlock:^NSURLRequest *(NSURLSession *session, NSURLSessionTask *task, NSURLResponse *response, NSURLRequest *request) {
            JQRequest *req = [weakSelf requestForTask:task];
            return req.traceRedirect && response ? nil : request;
        }];
        [_manager setDataTaskWillCacheResponseBlock:^NSCachedURLResponse *(NSURLSession *session, NSURLSessionDataTask *dataTask, NSCachedURLResponse *proposedResponse) {
            return weakSelf.shouldCacheResponse ? proposedResponse : nil;
        }];
        [_manager setTaskDidSendBodyDataBlock:^(NSURLSession *session, NSURLSessionTask *task, int64_t bytesSent, int64_t totalBytesSent, int64_t totalBytesExpectedToSend) {
            JQRequest *req = [weakSelf requestForTask:task];
            if (req.traceUploadProgress && [req.requestTracer respondsToSelector:@selector(didUploadWithRequest:bytesWritten:totalBytesWritten:totalBytesExpectedToWrite:)]) {
                [req.requestTracer didUploadWithRequest:req bytesWritten:bytesSent totalBytesWritten:bytesSent totalBytesExpectedToWrite:totalBytesExpectedToSend];
            }
        }];
        [_manager setTaskDidReceiveAuthenticationChallengeBlock:^NSURLSessionAuthChallengeDisposition(NSURLSession *session, NSURLSessionTask *task, NSURLAuthenticationChallenge *challenge, NSURLCredential * __autoreleasing *outCredential) {
            NSURLSessionAuthChallengeDisposition disposition = NSURLSessionAuthChallengePerformDefaultHandling;
            NSURLCredential *credential = nil;
            JQRequestLoader *strongSelf = weakSelf;
            if (strongSelf) {
                if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
                    JQFakeSessionManagerPrivate *fakeManager = strongSelf->_infoDict[@(task.taskIdentifier)];
                    if ([weakSelf.manager.securityPolicy evaluateServerTrust:challenge.protectionSpace.serverTrust forDomain:fakeManager.domain]) {
                        credential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
                        if (credential) {
                            disposition = NSURLSessionAuthChallengeUseCredential;
                        } else {
                            disposition = NSURLSessionAuthChallengePerformDefaultHandling;
                        }
                    } else {
                        disposition = NSURLSessionAuthChallengeCancelAuthenticationChallenge;
                    }
                } else {
                    disposition = NSURLSessionAuthChallengePerformDefaultHandling;
                }
            }
            if (outCredential) {
                *outCredential = credential;
            }
            return disposition;
        }];
    }
    return self;
}

- (NSString *)methodOfType:(JQRequestMethod)methodType {
    switch (methodType) {
        case JQRequestMethod_GET:
            return @"GET";
            
        case JQRequestMethod_POST:
            return @"POST";
            
        case JQRequestMethod_PUT:
            return @"PUT";
            
        case JQRequestMethod_DELETE:
            return @"DELETE";
            
        case JQRequestMethod_HEAD:
            return @"HEAD";
            
        default:
            break;
    }
    return nil;
}

- (AFHTTPRequestSerializer <AFURLRequestSerialization> *)requestSerializerOfType:(JQRequestSerializerType)serializerType defaultValue:(AFHTTPRequestSerializer <AFURLRequestSerialization> *)defaultSerializer {
    AFHTTPRequestSerializer <AFURLRequestSerialization> *serializer =  _requestSerializerCache[@(serializerType)];
    if (serializer == nil) {
        switch (serializerType) {
            case JQRequestSerializerType_HTTP:
                serializer = [AFHTTPRequestSerializer serializer];
                break;
                
            case JQRequestSerializerType_PROTOBUF:
                serializer = [AFHTTPRequestSerializer serializer];
                [serializer setValue:@"application/x-protobuf" forHTTPHeaderField:@"Content-Type"];
                break;
                
            case JQRequestSerializerType_JSON:
                serializer = [AFJSONRequestSerializer serializer];
                break;
                
            case JQRequestSerializerType_PLIST:
                serializer = [AFPropertyListRequestSerializer serializer];
                break;
                
            default:
                return defaultSerializer;
        }
        if (_requestSerializerCache == nil) {
            _requestSerializerCache = [[NSMutableDictionary alloc] init];
        }
        _requestSerializerCache[@(serializerType)] = serializer;
    }
    return serializer;
}

- (AFHTTPResponseSerializer <AFURLResponseSerialization> *)responseSerializerOfType:(JQResponseSerializerType)serializerType defaultValue:(AFHTTPResponseSerializer <AFURLResponseSerialization> *)defaultSerializer {
    AFHTTPResponseSerializer <AFURLResponseSerialization> *serializer = _responseSerializerCache[@(serializerType)];
    if (serializer == nil) {
        switch (serializerType) {
            case JQResponseSerializerType_HTTP:
                serializer = [AFHTTPResponseSerializer serializer];
                break;
                
            case JQResponseSerializerType_PROTOBUF:
                serializer = [AFHTTPResponseSerializer serializer];
                break;
                
            case JQResponseSerializerType_JSON:
                serializer = [AFJSONResponseSerializer serializer];
                break;
                
            case JQResponseSerializerType_PLIST:
                serializer = [AFPropertyListResponseSerializer serializer];
                break;
                
            case JQResponseSerializerType_RAW:
                serializer = [AFHTTPResponseSerializer serializer];
                break;

                
            default:
                return defaultSerializer;
        }
        if (serializerType == JQResponseSerializerType_RAW) {
            serializer.acceptableContentTypes = nil;
        }
        else {
            serializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json", @"text/json", @"text/javascript", @"text/plain",  @"text/html", nil];
        }
        if (_responseSerializerCache == nil) {
            _responseSerializerCache = [[NSMutableDictionary alloc] init];
        }
        _responseSerializerCache[@(serializerType)] = serializer;
    }
    return serializer;
}

- (NSURLSessionDataTask *)taskForRequest:(NSMutableURLRequest *)request {
//    request.timeoutInterval = kTimeOutInterval;
    __weak typeof(self) weakSelf = self;
    __block NSURLSessionDataTask *dataTask = nil;
    dataTask = [_manager dataTaskWithRequest:request
                       completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
                           [weakSelf didFinishTask:dataTask response:response responseObject:responseObject error:error];
                       }];
    return dataTask;
}

- (JQRequest *)requestForTask:(NSURLSessionTask *)task {
    JQFakeSessionManagerPrivate *fakeManager = _infoDict[@(task.taskIdentifier)];
    return fakeManager.request;
}

- (void)willBeginTask:(NSURLSessionDataTask *)task request:(JQRequest *)request domain:(NSString *)domain {
    // AFN内部使用taskDescription用于控制系统indicator的条件，将其篡改，以便我们自己控制
    task.taskDescription = [NSString stringWithFormat:@"%@:%@", task.currentRequest.HTTPMethod, task.currentRequest.URL];
    
    JQFakeSessionManagerPrivate *fakeManager = [JQFakeSessionManagerPrivate fakeManager:_manager];
    fakeManager.request = request;
    fakeManager.task = task;
    fakeManager.domain = domain;
    fakeManager.responseSerializer = [self responseSerializerOfType:request.responseSerializerType
                                                       defaultValue:_manager.responseSerializer];
    fakeManager.completionGroup = _manager.completionGroup;
    fakeManager.completionQueue = _manager.completionQueue;
    if ([request.requestTracer respondsToSelector:@selector(completionGroup)]
        && request.requestTracer.completionGroup) {
        fakeManager.completionGroup = request.requestTracer.completionGroup;
    }
    if ([request.requestTracer respondsToSelector:@selector(completionQueue)]
        && request.requestTracer.completionQueue) {
        fakeManager.completionQueue = request.requestTracer.completionQueue;
    }

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    if ([_manager respondsToSelector:@selector(delegateForTask:)]) {
        id taskDelegate = [_manager performSelector:@selector(delegateForTask:) withObject:task];
        if ([taskDelegate respondsToSelector:@selector(setManager:)]) {
            [taskDelegate performSelector:@selector(setManager:) withObject:fakeManager];
        }
    }
#pragma clang diagnostic pop
    
    _infoDict[@(task.taskIdentifier)] = fakeManager;
}

- (void)didFinishTask:(NSURLSessionDataTask *)task response:(NSURLResponse *)response responseObject:(id)responseObject error:(NSError *)error {
    JQFakeSessionManagerPrivate *fakeManager = _infoDict[@(task.taskIdentifier)];
    JQRequest *request = fakeManager.request;
    
    [_infoDict removeObjectForKey:@(task.taskIdentifier)];
    [_requestSet removeObject:request];
    
    if (task.error && error.code == NSURLErrorCancelled && !request.traceCancel) {
        NSLog(@"canceled request : %@", request);
        return;
    }
    else {
        NSError *resultError = nil;
        if (task.error) {
            resultError = task.error;
        }
        else {
            long httpCode = [(NSHTTPURLResponse *)response statusCode];
            if (httpCode >= 400) {
                resultError = [NSError errorWithDomain:@"JQRequestKitError" code:httpCode userInfo:nil];
            }
//            else if (error) {
//                resultError = error;
//            }
        }
        if (resultError) {
            responseObject = nil;
        }
        [request.requestTracer didCompleteWithRequest:request response:response responseObject:responseObject error:resultError];
    }
}

- (void)scheduleRequest:(JQRequest *)request {
    NSString *method = [self methodOfType:request.requestMethod];
    if (request == nil || method == nil) {
        return;
    }
    [_requestSet addObject:request];
    
    AFHTTPRequestSerializer <AFURLRequestSerialization> * requestSerializer = [self requestSerializerOfType:request.requestSerializerType
                                                                                               defaultValue:_manager.requestSerializer];
    __block NSMutableURLRequest *urlRequest = nil;
    NSArray<JQRequestBodyPart *> *allBodyParts = [request allBodyParts];
    if ([allBodyParts count]) {
        urlRequest = [requestSerializer multipartFormRequestWithMethod:method
                                                             URLString:request.requestUrl
                                                            parameters:nil
                                             constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
                                                 for (JQRequestBodyPart *part in allBodyParts) {
                                                     JQMultipartComposer *composer = [[JQMultipartComposer alloc] initWithFormData:formData];
                                                     if ([part.content isKindOfClass:[NSURL class]]) {
                                                         [composer addFileWithURL:part.content forPartName:part.partName mimeType:part.mimeType];
                                                     }
                                                     else if ([part.content isKindOfClass:[NSData class]]) {
                                                         [composer addData:part.content forPartName:part.partName mimeType:part.mimeType];
                                                     }
                                                 }
                                                 [request clearAllBodyParts];
                                             } error:NULL];
    }
    else {
        if ([request.bodyParam isKindOfClass:[NSDictionary class]]) {
            urlRequest = [requestSerializer requestWithMethod:method
                                                    URLString:request.requestUrl
                                                   parameters:request.bodyParam error:NULL];
        }
        else {
            urlRequest = [requestSerializer requestWithMethod:method
                                                    URLString:request.requestUrl
                                                   parameters:nil error:NULL];
            NSData *data = nil;
            if ([request.bodyParam isKindOfClass:[NSData class]]) {
                data = request.bodyParam;
            }
            if ([request.bodyParam isKindOfClass:[NSString class]]) {
                data = [(NSString *)request.bodyParam dataUsingEncoding:NSUTF8StringEncoding];
            }
            if (data) {
                urlRequest.HTTPBody = data;
            }
        }
    }
    [request.allHTTPHeaderFields enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull obj, BOOL * _Nonnull stop) {
        [urlRequest setValue:obj forHTTPHeaderField:key];
    }];
    urlRequest.timeoutInterval = request.timeoutInterval;
    
    NSString *domain = urlRequest.URL.host;
    if ([[JQDNSResolverHolder globalResolver] shouldResolveDomain:domain]) {
        [self.manager.operationQueue addOperationWithBlock:^{
            NSString *ip = [[JQDNSResolverHolder globalResolver] queryDomain:domain];
            dispatch_async(dispatch_get_main_queue(), ^{
                if ([ip length] > 0) {
                    NSURLComponents *comps = [[NSURLComponents alloc] initWithURL:urlRequest.URL resolvingAgainstBaseURL:YES];
                    comps.host = ip;
                    urlRequest.URL = comps.URL;
                }
                [self scheduleRequest:request urlRequest:urlRequest domain:domain];
            });
        }];
    }
    else {
        [self scheduleRequest:request urlRequest:urlRequest domain:domain];
    }
}

- (void)scheduleRequest:(JQRequest *)request urlRequest:(NSMutableURLRequest *)urlRequest domain:(NSString *)domain {
    // DNS查询回来可能已经被取消了
    if (![_requestSet containsObject:request]) {
        return;
    }
    NSURLSessionDataTask *task = [self taskForRequest:urlRequest];
    [self scheduleTask:task request:request domain:domain];
}

- (void)scheduleTask:(NSURLSessionDataTask *)task request:(JQRequest *)request domain:(NSString *)domain {
    [self willBeginTask:task request:request domain:domain];
    [task resume];
    
    if (!request.quietly) {
        [[NSNotificationCenter defaultCenter] postNotificationName:AFNetworkingTaskDidResumeNotification object:task];
    }
}

- (void)cancelRequest:(JQRequest *)request {
    if (![_requestSet containsObject:request]) {
        return;
    }
    [_requestSet removeObject:request];
    
    __block NSURLSessionTask *task = nil;
    [[_infoDict allValues] enumerateObjectsUsingBlock:^(JQFakeSessionManagerPrivate *fakeManager, NSUInteger idx, BOOL * _Nonnull stop) {
        if (fakeManager.request == request) {
            task = fakeManager.task;
            *stop = YES;
        }
    }];
    [task cancel];
}

- (void)cancelAllRequests {
    [[_infoDict allValues] enumerateObjectsUsingBlock:^(JQFakeSessionManagerPrivate *fakeManager, NSUInteger idx, BOOL * _Nonnull stop) {
        [fakeManager.task cancel];
    }];
}

+ (instancetype)sharedInstance {
    static JQRequestLoader *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[JQRequestLoader alloc] init];
    });
    return instance;
}

@end
