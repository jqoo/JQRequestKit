//
//  JQRequest.m
//  LoochaCampusMain
//
//  Created by zhang jinquan on 1/14/16.
//  Copyright © 2016 Real Cloud. All rights reserved.
//

#import "JQRequest.h"
#import "JQRequestLoader.h"
#import "JQRequest+Private.h"

@implementation JQRequestBodyPart

@end

@interface JQRequest ()
{
    NSMutableDictionary<NSString *, NSString *> *_allHTTPHeaderFields;
    NSMutableArray<JQRequestBodyPart *> *_bodyParts;
}

@property (nonatomic, weak) JQRequestLoader *requestLoader;

@end

@implementation JQRequest

+ (instancetype)requestWithUrl:(NSString *)url method:(JQRequestMethod)method {
    return [self requestWithUrl:url method:method tracer:nil];
}

+ (instancetype)requestWithUrl:(NSString *)url method:(JQRequestMethod)method tracer:(id<JQRequestTracer>)tracer {
    JQRequest *request = [[self alloc] init];
    request.requestUrl = url;//URL.absoluteString;
    request.requestMethod = method;
    request.requestTracer = tracer;
    return request;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.timeoutInterval = 30;
    }
    return self;
}

- (void)setValue:(NSString *)value forHTTPHeaderField:(NSString *)field {
    if (value == nil || field == nil) {
        return;
    }
    if (!_allHTTPHeaderFields) {
        _allHTTPHeaderFields = [[NSMutableDictionary alloc] init];
    }
    [_allHTTPHeaderFields setObject:value forKey:field];
}

- (NSArray<JQRequestBodyPart *> *)allBodyParts {
    return _bodyParts;
}

- (void)clearAllBodyParts {
    _bodyParts = nil;
}

- (void)addBodyPart:(JQRequestBodyPart *)bodyPart {
    if (_bodyParts == nil) {
        _bodyParts = [[NSMutableArray<JQRequestBodyPart *> alloc] init];
    }
    [_bodyParts addObject:bodyPart];
}

- (void)addBodyPartWithContent:(id)content partName:(NSString *)partName mimeType:(NSString *)mimeType {
    JQRequestBodyPart *part = [[JQRequestBodyPart alloc] init];
    part.content = content;
    part.partName = partName;
    part.mimeType = mimeType;
    [self addBodyPart:part];
}

- (void)addBodyPartWithContent:(id)content partName:(NSString *)partName mimeType:(NSString *)mimeType fileName:(NSString *)fileName {
    JQRequestBodyPart *part = [[JQRequestBodyPart alloc] init];
    part.content = content;
    part.partName = partName;
    part.mimeType = mimeType;
    part.fileName = fileName;
    [self addBodyPart:part];
}

- (void)addBodyPartWithJsonData:(NSData*)jsonData
{
    [self addBodyPartWithContent:jsonData partName:@"json" mimeType:@"application/json"];
}

- (JQRequestLoader *)realRequestLoader {
    JQRequestLoader *requestLoader = self.requestLoader;
    if (requestLoader == nil) {
        requestLoader = [JQRequestLoader sharedInstance];
    }
    return requestLoader;
}

- (void)start {
    [[self realRequestLoader] scheduleRequest:self];
}

- (void)cancel {
    [[self realRequestLoader] cancelRequest:self];
}

- (NSString *)description {
    return [[super description] stringByAppendingString:[[self dictionaryWithValuesForKeys:@[@"requestUrl", @"requestMethod"]] description]];
}

@end

@implementation JQRequest (Private)

@end
