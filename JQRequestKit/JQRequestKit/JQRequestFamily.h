//
//  JQRequestFamily.h
//  LoochaCampusMain
//
//  Created by zhang jinquan on 5/9/16.
//  Copyright © 2016 Real Cloud. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JQRequest.h"

@interface JQRequestFamily : NSObject

- (void)cancelAllRequests;

//- (JQRequest *)requestWithUrl:(NSString *)url method:(JQRequestMethod)method;

@end

@interface JQRequest (JQRequestFamily)

- (void)startInFamily:(JQRequestFamily *)family;

@end
