//
//  JQResponseResult.m
//  LoochaCampusMain
//
//  Created by zhang jinquan on 5/9/16.
//  Copyright © 2016 Real Cloud. All rights reserved.
//

#import "JQResponseResult.h"

@interface JQResponseResult ()

@property (nonatomic, strong) id responseObject;
@property (nonatomic, strong) NSError *error;
@property (nonatomic, strong) NSURLResponse *urlResponse;

@end

@implementation JQResponseResult

- (instancetype)initWithResponseObject:(id)responseObject urlResponse:(NSURLResponse *)urlResponse error:(NSError *)error {
    self = [super init];
    if (self) {
        self.urlResponse = urlResponse;
        self.responseObject = responseObject;
        self.error = error;
    }
    return self;
}

- (NSInteger)httpCode {
    if ([self.urlResponse isKindOfClass:[NSHTTPURLResponse class]]) {
        return [(NSHTTPURLResponse *)self.urlResponse statusCode];
    }
    if (self.error) {
        return self.error.code;
    }
    return 200;
}

+ (instancetype)resultWithResponseObject:(id)responseObject urlResponse:(NSURLResponse *)urlResponse error:(NSError *)error {
    return [[[self class] alloc] initWithResponseObject:responseObject urlResponse:urlResponse error:error];
}

@end
