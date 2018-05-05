//
//  JQResponseResult.h
//  LoochaCampusMain
//
//  Created by zhang jinquan on 5/9/16.
//  Copyright © 2016 jqoo. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface JQResponseResult : NSObject

@property (nonatomic, readonly) id responseObject;
@property (nonatomic, readonly) NSError *error;
@property (nonatomic, readonly) NSURLResponse *urlResponse;

- (instancetype)initWithResponseObject:(id)responseObject urlResponse:(NSURLResponse *)urlResponse error:(NSError *)error;

- (NSInteger)httpCode;

+ (instancetype)resultWithResponseObject:(id)responseObject urlResponse:(NSURLResponse *)urlResponse error:(NSError *)error;

@end
