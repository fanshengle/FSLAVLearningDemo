//
//  FSLAVCoreBase.h
//  FSLAVComponent
//
//  Created by tutu on 2019/7/21.
//  Copyright © 2019 tutu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>
#import "FSLAVLog.h"

NS_ASSUME_NONNULL_BEGIN

@interface FSLAVCoreBase : NSObject

/**
 GCD:8种常用场景:『主线程』中，『不同队列』+『不同任务』
 并发队列 的并发功能只有在异步（dispatch_async）方法下才有效。
 */
// 同步执行+主队列:『主线程』 中调用 『主队列』+『同步执行』 会导致死锁问题。
void FSLRunSynchronouslyOnMainQueue(void (^block)(void));
// 异步执行+主队列:没有开启新线程，串行执行任务
void FSLRunAsynchronouslyOnMainQueue(void (^block)(void));
// 同步执行+串行队列:没有开启新线程，串行执行任务;『同步执行+串行队列』嵌套『同步执行+同一个串行队列』
void FSLRunSynchronouslyOnSerialQueue(void (^block)(void));
// 异步执行+串行队列:有开启新线程（1条），串行执行任务;『异步执行+串行队列』嵌套『同一个串行队列』会导致死锁问题
void FSLRunAsynchronouslyOnSerialQueue(void (^block)(void));
// 同步执行+并行队列:没有开启新线程，串行执行任务
void FSLRunSynchronouslyOnConcurrentQueue(void (^block)(void));
// 异步执行+并行队列:有开启新线程(多条)，并发执行任务
void FSLRunAsynchronouslyOnConcurrentQueue(void (^block)(void));
// 同步执行+全局并行队列:没有开启新线程，串行执行任务
void FSLRunSynchronouslyOnGlobalConcurrentQueue(void (^block)(void));
// 异步执行+全局并行队列:有开启新线程，并发执行任务
void FSLRunAsynchronouslyOnGlobalConcurrentQueue(void (^block)(void));

// 一次性代码（只执行一次）dispatch_once（这里面默认是线程安全的）
void FSLRunOnce(void (^block)(void));

/**
 设置默认参数配置
 */
- (void)setConfig;

/**
 销毁对象，释放对象
 */
- (void)destory;

@end

NS_ASSUME_NONNULL_END
