//
//  JQRequestTracer.m
//  LoochaCampusMain
//
//  Created by zhang jinquan on 2/18/16.
//  Copyright © 2016 Real Cloud. All rights reserved.
//

#import "JQRequestTracer.h"
#import "JQRequest.h"

@implementation JQRequestTracer

+ (instancetype)tracerWithCompletionBlock:(void (^)(JQResponseResult *responseResult))completionBlock {
    JQRequestTracer *tracer = [[[self class] alloc] init];
    tracer.completionBlock = completionBlock;
    return tracer;
}

- (void)didCompleteWithRequest:(JQRequest *)request response:(NSURLResponse *)response responseObject:(id)responseObject error:(NSError *)error {
    if (self.completionBlock) {
        [self didReceiveResponseResult:[JQResponseResult resultWithResponseObject:responseObject urlResponse:response error:error] request:request];
    }
}

- (void)didUploadWithRequest:(JQRequest *)request bytesWritten:(NSInteger)bytesWritten totalBytesWritten:(NSInteger)totalBytesWritten totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite {
    if (self.uploadProgressBlock) {
        self.uploadProgressBlock(request, bytesWritten, totalBytesWritten, totalBytesExpectedToWrite);
    }
}

- (void)didReceiveResponseResult:(JQResponseResult *)responseResult request:(JQRequest *)request {
    NSLog(@"request url : %@, error : %@, responseObject : %@", request.requestUrl, responseResult.error, [responseResult.responseObject isKindOfClass:[NSData class]] ? @"<NSData>":responseResult.responseObject);
    if (self.completionBlock) {
        self.completionBlock(responseResult);
    }
}

@end

@implementation JQRequestTracerWeakify

- (instancetype)initWithWeakTracer:(id<JQRequestTracer>)weakTracer {
    self.weakTracer = weakTracer;
    return self;
}

- (void)forwardInvocation:(NSInvocation *)anInvocation {
    if (self.weakTracer) {
        [anInvocation invokeWithTarget:self.weakTracer];
    }
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector {
    if (self.weakTracer) {
        return [(NSObject *)self.weakTracer methodSignatureForSelector:aSelector];
    }
    return [super methodSignatureForSelector:aSelector];
}


+ (instancetype)tracerWithWeakTracer:(id<JQRequestTracer>)weakTracer {
    return [[JQRequestTracerWeakify alloc] initWithWeakTracer:weakTracer];
}

@end
