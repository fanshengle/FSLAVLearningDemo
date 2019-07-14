//
//  FSLAVLog.m
//  FSLAVComponent
//
//  Created by tutu on 2019/7/13.
//  Copyright © 2019 tutu. All rights reserved.
//

#import "FSLAVLog.h"

#pragma mark - NSObjectExceptionExtend
/**
 *  异常管理
 */
@implementation NSObject(NSObjectExceptionExtend)
/**
 *  是否为相同或继承关系的类对象
 *
 *  @param clazz 类对象
 *
 *  @return 是否为相同或继承关系的类对象
 */
+ (BOOL)fsl_isKindOfClass:(Class)clazz;
{
    return self == clazz || [self isSubclassOfClass:clazz];
}

/**
 *  抛出异常
 *
 *  @param reason 异常信息
 */
- (void)fslThrowWithReason:(NSString *)reason;
{
    NSDictionary *userInfo = nil;
    [self fslThrowWithReason:reason userInfo:userInfo];
}

/**
 *  抛出异常
 *
 *  @param reason   原因
 *  @param userInfo 详细信息
 */
- (void)fslThrowWithReason:(NSString *)reason userInfo:(NSDictionary *)userInfo;
{
    NSException *exception = [NSException exceptionWithName:[NSString stringWithFormat:@"%@Exception", [self class]]
                                                     reason:reason userInfo:userInfo];
    @throw exception;
}

/**
 *  执行主线程方法
 *
 *  @param aSelector 方法签名
 *  @param arg1      参数1
 *  @param arg2      参数2
 *  @param wait      是否等待执行完毕
 */
- (void)fslPerformSelectorOnMainThread:(SEL)aSelector withObject:(id)arg1  withObject:(id)arg2 waitUntilDone:(BOOL)wait;
{
    NSMethodSignature *sig = [self methodSignatureForSelector:aSelector];
    if (!sig) return;
    
    NSInvocation* invo = [NSInvocation invocationWithMethodSignature:sig];
    [invo setTarget:self];
    [invo setSelector:aSelector];
    [invo setArgument:&arg1 atIndex:2];
    [invo setArgument:&arg2 atIndex:3];
    [invo retainArguments];
    [invo performSelectorOnMainThread:@selector(invoke) withObject:nil waitUntilDone:wait];
}
@end

#pragma mark - FSLAVLog
/**
 *  日志处理类
 */
@implementation FSLAVLog

/**
 *  日志处理类
 */
+ (FSLAVLog *)sharedLog;
{
    static dispatch_once_t pred = 0;
    static FSLAVLog *object = nil;
    dispatch_once(&pred, ^{
        object = [[self alloc]init];
    });
    return object;
}

/**
 *  输出日志
 *
 *  @param format  信息
 *  @param argList 参数
 */
+ (void)log:(NSString *)format arguments:(va_list)argList;
{
    if ([self sharedLog].outputLevel == FSLAVLogLevelFATAL)return;
    NSLogv([@"FSLAVComponent -> " stringByAppendingString:format], argList);
}

/**
 *  输出日志
 *
 *  @param format 日志信息
 */
+ (void)log:(NSString *)format, ...;
{
    va_list argList;
    va_start(argList,format);
    [self log:[@"[ALL]:\n" stringByAppendingString:format] arguments:argList];
    va_end(argList);
}

/**
 *  仅输出错误信息
 *
 *  @param format 日志信息
 */
+ (void)error:(NSString *)format, ...;
{
    if ([self sharedLog].outputLevel < FSLAVLogLevelERROR)return;
    va_list argList;
    va_start(argList,format);
    [self log:[@"[ERROR]:\n" stringByAppendingString:format] arguments:argList];
    va_end(argList);
}

/**
 *  仅输出错误，警告信息
 *
 *  @param format 日志信息
 */
+ (void)warn:(NSString *)format, ...;
{
    if ([self sharedLog].outputLevel < FSLAVLogLevelWARN)return;
    va_list argList;
    va_start(argList,format);
    [self log:[@"[WARN]:\n" stringByAppendingString:format] arguments:argList];
    va_end(argList);
}

/**
 *  仅输出INFO，错误，警告信息
 *
 *  @param format 日志信息
 */
+ (void)info:(NSString *)format, ...;
{
    if ([self sharedLog].outputLevel < FSLAVLogLevelINFO)return;
    va_list argList;
    va_start(argList,format);
    [self log:[@"[INFO]:\n" stringByAppendingString:format] arguments:argList];
    va_end(argList);
}

/**
 *  输出所有信息
 *
 *  @param format 日志信息
 */
+ (void)debug:(NSString *)format, ...;
{
    if ([self sharedLog].outputLevel < FSLAVLogLevelDEBUG)return;
    va_list argList;
    va_start(argList,format);
    [self log:[@"[DEBUG]:\n" stringByAppendingString:format] arguments:argList];
    va_end(argList);
}

@end

