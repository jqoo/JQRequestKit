//
//  JQMultipartComposer.h
//  LoochaCampusMain
//
//  Created by zhang jinquan on 1/15/16.
//  Copyright © 2016 Real Cloud. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface JQMultipartComposer : NSObject

- (void)addFileWithURL:(NSURL *)fileURL forPartName:(NSString *)partName mimeType:(NSString *)mimeType;
- (void)addFileWithURL:(NSURL *)fileURL forPartName:(NSString *)partName;

- (void)addData:(NSData *)data forPartName:(NSString *)partName mimeType:(NSString *)mimeType;
- (void)addData:(NSData *)data forPartName:(NSString *)partName;

@end
