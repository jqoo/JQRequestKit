//
//  JQRequest.h
//  LoochaCampusMain
//
//  Created by zhang jinquan on 1/14/16.
//  Copyright © 2016 Real Cloud. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "JQMultipartComposer.h"
#import "JQRequestTracer.h"

typedef NS_ENUM(int, JQRequestSerializerType) {
    JQRequestSerializerType_Default, // 在requestLoader发起请求时，使用requestLoader配置的serializer
    JQRequestSerializerType_HTTP,
    JQRequestSerializerType_JSON,
    JQRequestSerializerType_PLIST,
    JQRequestSerializerType_PROTOBUF
};

typedef NS_ENUM(int, JQResponseSerializerType) {
    JQResponseSerializerType_Default, // 在requestLoader发起请求时，使用requestLoader配置的serializer
    JQResponseSerializerType_HTTP,
    JQResponseSerializerType_JSON,
    JQResponseSerializerType_PLIST,
    JQResponseSerializerType_PROTOBUF,
    JQResponseSerializerType_RAW
};

typedef NS_ENUM(int, JQRequestMethod) {
    JQRequestMethod_GET,
    JQRequestMethod_POST,
    JQRequestMethod_PUT,
    JQRequestMethod_DELETE,
    JQRequestMethod_HEAD,
};

@interface JQRequestBodyPart : NSObject

@property (nonatomic, strong) id content;
@property (nonatomic, strong) NSString *partName;
@property (nonatomic, strong) NSString *mimeType;
@property (nonatomic, strong) NSString *fileName;

@end

@protocol JQSecurityPolicy <NSObject>

- (BOOL)evaluateServerTrust:(SecTrustRef)serverTrust forDomain:(NSString *)domain;

@end

@interface JQRequest : NSObject

@property (nonatomic, assign) JQRequestMethod requestMethod;
@property (nonatomic, assign) JQRequestSerializerType requestSerializerType;
@property (nonatomic, assign) JQResponseSerializerType responseSerializerType;
@property (nonatomic, strong) NSString *requestUrl;

@property (nonatomic, assign) Class responseObjectClass;

/**
 *  安静模式请求，不会引起状态栏indicator变化
 */
@property (nonatomic, assign) BOOL quietly;

@property (nonatomic, strong) id bodyParam;
@property (nonatomic, strong) id userInfo;

//@property (nonatomic, copy) JQBodyComposingBlock bodyComposingBlock;
@property (nonatomic, assign) BOOL traceCancel; // YES:取消操作将回调failure，NO:取消后不接收任何回调
@property (nonatomic, assign) BOOL traceUploadProgress; // default:NO
@property (nonatomic, assign) BOOL traceRedirect; // default:NO
@property (nonatomic, assign) NSTimeInterval timeoutInterval; // default 30
//@property (nonatomic, assign) BOOL traceDownloadProgress;
@property (nonatomic, strong) id<JQRequestTracer> requestTracer;

@property (nonatomic, readonly) NSDictionary<NSString *, NSString *> *allHTTPHeaderFields;

+ (instancetype)requestWithUrl:(NSString *)url method:(JQRequestMethod)method;
+ (instancetype)requestWithUrl:(NSString *)url method:(JQRequestMethod)method tracer:(id<JQRequestTracer>)tracer;

- (void)setValue:(NSString *)value forHTTPHeaderField:(NSString *)field;

- (NSArray<JQRequestBodyPart *> *)allBodyParts;
- (void)clearAllBodyParts;
- (void)addBodyPart:(JQRequestBodyPart *)bodyPart;
- (void)addBodyPartWithContent:(id)content partName:(NSString *)partName mimeType:(NSString *)mimeType fileName:(NSString *)fileName;
- (void)addBodyPartWithContent:(id)content partName:(NSString *)partName mimeType:(NSString *)mimeType;
- (void)addBodyPartWithJsonData:(NSData*)jsonData;
//- (void)start;
- (void)cancel;



@end
