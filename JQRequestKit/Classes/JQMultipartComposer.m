//
//  JQMultipartComposer.m
//  LoochaCampusMain
//
//  Created by zhang jinquan on 1/15/16.
//  Copyright © 2016 jqoo. All rights reserved.
//

#import "JQMultipartComposer.h"

#import "AFURLRequestSerialization.h"

@interface JQMultipartComposer ()

- (instancetype)initWithFormData:(id<AFMultipartFormData>)formData;

@end

@implementation JQMultipartComposer
{
    id<AFMultipartFormData> _formData;
}

- (instancetype)initWithFormData:(id<AFMultipartFormData>)formData {
    self = [super init];
    if (self) {
        _formData = formData;
    }
    return self;
}

- (NSDictionary *)headerWithName:(NSString *)name mimeType:(NSString *)mimeType
{
    NSMutableDictionary *mutableHeaders = [[NSMutableDictionary alloc] initWithCapacity:2];
    [mutableHeaders setValue:[NSString stringWithFormat:@"form-data; name=\"%@\"; ", name] forKey:@"Content-Disposition"];
    [mutableHeaders setValue:mimeType forKey:@"Content-Type"];
    return mutableHeaders;
}

- (void)addFileWithURL:(NSURL *)fileURL forPartName:(NSString *)partName mimeType:(NSString *)mimeType {
    [_formData appendPartWithFileURL:fileURL
                                name:partName
                            fileName:[fileURL lastPathComponent]
                            mimeType:mimeType
                               error:NULL];
}

- (void)addFileWithURL:(NSURL *)fileURL forPartName:(NSString *)partName {
    [_formData appendPartWithFileURL:fileURL
                                name:partName
                               error:NULL];
}

- (void)addData:(NSData *)data forPartName:(NSString *)partName mimeType:(NSString *)mimeType {
    [_formData appendPartWithHeaders:[self headerWithName:partName mimeType:mimeType]
                                body:data];
}

- (void)addData:(NSData *)data forPartName:(NSString *)partName {
    [_formData appendPartWithFormData:data
                                 name:partName];
}

@end
