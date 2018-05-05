//
//  JQDNSResolver.m
//  JQRequestKit
//
//  Created by jinquan on 2017/9/8.
//  Copyright © 2017年 Real Cloud. All rights reserved.
//

#import "JQDNSResolver.h"

@interface JQDNSResolverHolder ()

@property (nonatomic, strong) id<JQDNSResolver> resolver;

@end

@implementation JQDNSResolverHolder

+ (instancetype)globalResolver {
    static dispatch_once_t onceToken;
    static JQDNSResolverHolder *instance;
    dispatch_once(&onceToken, ^{
        instance = [[JQDNSResolverHolder alloc] init];
    });
    return instance;
}

- (BOOL)shouldResolveDomain:(NSString *)domain {
    return [_resolver shouldResolveDomain:domain];
}

- (NSString *)queryDomain:(NSString *)domain {
    return [_resolver queryDomain:domain];
}

- (void)accessFailedForIP:(NSString *)ip domain:(NSString *)domain error:(NSError *)error {
    [_resolver accessFailedForIP:ip domain:domain error:error];
}

+ (void)registerResolver:(id<JQDNSResolver>)resolver {
    [JQDNSResolverHolder globalResolver].resolver = resolver;
}

@end
