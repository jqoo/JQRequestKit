//
//  JQDNSResolver.h
//  JQRequestKit
//
//  Created by jinquan on 2017/9/8.
//  Copyright © 2017年 Real Cloud. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol JQDNSResolver <NSObject>

- (BOOL)shouldResolveDomain:(NSString *)domain;

- (NSString *)queryDomain:(NSString *)domain;

- (void)accessFailedForIP:(NSString *)ip domain:(NSString *)domain error:(NSError *)error;

@end

@interface JQDNSResolverHolder : NSObject <JQDNSResolver>

+ (instancetype)globalResolver;

+ (void)registerResolver:(id<JQDNSResolver>)resolver;

@end
