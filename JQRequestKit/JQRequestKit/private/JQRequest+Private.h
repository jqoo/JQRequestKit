//
//  JQRequest+Private.h
//  LoochaCampusMain
//
//  Created by zhang jinquan on 5/9/16.
//  Copyright © 2016 jqoo. All rights reserved.
//

#import "JQRequest.h"

@class JQRequestLoader;

@interface JQRequest (Private)

@property (nonatomic, weak) JQRequestLoader *requestLoader;

@end
