//
//  JQRequestFamily.m
//  LoochaCampusMain
//
//  Created by zhang jinquan on 5/9/16.
//  Copyright © 2016 Real Cloud. All rights reserved.
//

#import "JQRequestFamily.h"

@interface JQRequestFamily ()

@property (nonatomic, readonly) NSHashTable *requestTable;

@end

@implementation JQRequestFamily

@synthesize requestTable = _requestTable;

- (void)dealloc {
    [self cancelAllRequests];
}

- (NSHashTable *)requestTable {
    if (_requestTable == nil) {
        _requestTable = [NSHashTable weakObjectsHashTable];
    }
    return _requestTable;
}

- (void)cancelAllRequests {
    if (_requestTable) {
        NSEnumerator<JQRequest *> *e = [_requestTable objectEnumerator];
        JQRequest *request = [e nextObject];
        while (request) {
            [request cancel];
            request = [e nextObject];
        }
    }
}

//- (JQRequest *)requestWithUrl:(NSString *)url method:(JQRequestMethod)method {
//    JQRequest *request = [[JQRequest alloc] init];
//    [self.requestTable addObject:request];
//    request.requestUrl = url;
//    request.requestMethod = method;
//    return request;
//}

@end

@interface JQRequest (xxx)

- (void)start;

@end

@implementation JQRequest (JQRequestFamily)

- (void)startInFamily:(JQRequestFamily *)family {
    [family.requestTable addObject:self];
    [self start];
}

@end
