//
//  FSLAVLog.h
//  FSLAVComponent
//
//  Created by tutu on 2019/7/13.
//  Copyright © 2019 tutu. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - NSObjectExceptionExtend
/**
 *  异常管理
 */
@interface NSObject(NSObjectExceptionExtend)
/**
 *  是否为相同或继承关系的类对象
 *
 *  @param clazz 类对象
 *
 *  @return 是否为相同或继承关系的类对象
 */
+ (BOOL)fsl_isKindOfClass:(Class)clazz;

/**
 *  抛出异常
 *
 *  @param reason 异常信息
 */
- (void)fslThrowWithReason:(NSString *)reason;

/**
 *  抛出异常
 *
 *  @param reason   原因
 *  @param userInfo 详细信息
 */
- (void)fslThrowWithReason:(NSString *)reason userInfo:(NSDictionary *)userInfo;

/**
 *  执行主线程方法
 *
 *  @param aSelector 方法签名
 *  @param arg1      参数1
 *  @param arg2      参数2
 *  @param wait      是否等待执行完毕
 */
- (void)fslPerformSelectorOnMainThread:(SEL)aSelector withObject:(id)arg1  withObject:(id)arg2 waitUntilDone:(BOOL)wait;
@end

#pragma mark - FSLAVLog
/**
 *  日志输出级别
 */
typedef NS_ENUM(NSInteger, FSLAVLogLevel)
{
    /**
     *  不输出
     */
    FSLAVLogLevelFATAL = 0,
    /**
     *  仅输出错误信息
     */
    FSLAVLogLevelERROR = 3,
    /**
     *  仅输出错误，警告信息
     */
    FSLAVLogLevelWARN = 4,
    /**
     *  仅输出INFO，错误，警告信息
     */
    FSLAVLogLevelINFO = 6,
    /**
     *  输出所有信息
     */
    FSLAVLogLevelDEBUG = 7,
};

/**
 *  日志处理类
 */
@interface FSLAVLog : NSObject
/**
 *  日志输出级别 (默认：FSLAVLogLevelFATAL 不输出)
 */
@property (nonatomic) FSLAVLogLevel outputLevel;

/**
 *  日志处理类
 */
+ (FSLAVLog *)sharedLog;

/**
 *  输出日志
 *
 *  @param format 日志信息
 */
+ (void)log:(NSString *)format, ...;

/**
 *  仅输出错误信息
 *
 *  @param format 日志信息
 */
+ (void)error:(NSString *)format, ...;

/**
 *  仅输出错误，警告信息
 *
 *  @param format 日志信息
 */
+ (void)warn:(NSString *)format, ...;

/**
 *  仅输出INFO，错误，警告信息
 *
 *  @param format 日志信息
 */
+ (void)info:(NSString *)format, ...;

/**
 *  输出所有信息
 *
 *  @param format 日志信息
 */
+ (void)debug:(NSString *)format, ...;

@end

#ifndef FSLAVLogDefine
#define FSLAVLogDefine

/**
 *  输出所有日志
 */
#define fslL(...) [FSLAVLog log:__VA_ARGS__]

/**
 *  仅输出错误信息
 */
#define fslLError(...) [FSLAVLog error:__VA_ARGS__]

/**
 *  仅输出错误，警告信息
 */
#define fslLWarn(...) [FSLAVLog warn:__VA_ARGS__]

/**
 *  仅输出INFO，错误，警告信息
 */
#define fslLInfo(...) [FSLAVLog info:__VA_ARGS__]

/**
 *  仅输出INFO，错误，警告信息
 */
#define fslLDebug(...) [FSLAVLog debug:__VA_ARGS__]

#endif


NS_ASSUME_NONNULL_END
