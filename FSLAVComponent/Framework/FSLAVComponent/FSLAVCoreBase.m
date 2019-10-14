//
//  FSLAVCoreBase.m
//  FSLAVComponent
//
//  Created by tutu on 2019/7/21.
//  Copyright © 2019 tutu. All rights reserved.
//

#import "FSLAVCoreBase.h"

@implementation FSLAVCoreBase

- (instancetype)init
{
    self = [super init];
    if (self) {
        
        [self setConfig];
    }
    return self;
}

/**
 GCD:8种常用场景:『主线程』中，『不同队列』+『不同任务』
 并发队列 的并发功能只有在异步（dispatch_async）方法下才有效。
 */
// 同步执行+主队列:没有开启新线程，串行执行任务;『主线程』 中调用 『主队列』+『同步执行』 会导致死锁问题。
void FSLRunSynchronouslyOnMainQueue(void (^block)(void))
{
    // 这里屏蔽掉『主线程』 中调用 『主队列』+『同步执行』，屏蔽死锁的问题
    if ([NSThread isMainThread])
    {
        block();
    }
    else
    {
        dispatch_sync(dispatch_get_main_queue(), block);
    }
}

// 异步执行+主队列:没有开启新线程，串行执行任务
void FSLRunAsynchronouslyOnMainQueue(void (^block)(void))
{
    if ([NSThread isMainThread])
    {
        block();
    }
    else
    {
        dispatch_async(dispatch_get_main_queue(), block);
    }
}

// 同步执行+串行队列:没有开启新线程，串行执行任务
void FSLRunSynchronouslyOnSerialQueue(void (^block)(void))
{
    dispatch_queue_t serialQueue = dispatch_queue_create("com.FSLAVComponent.SerialQueue", DISPATCH_QUEUE_SERIAL);
    // iOS 6.0就被弃用了：返回与预期不一致的结果；误用可能导致线程死锁
    //if (dispatch_get_current_queu() = serialQueue)
    static const void * const SpecificKey = (const void*)&SpecificKey;
    if (dispatch_get_specific(SpecificKey) == (__bridge void *)(serialQueue))
    {
        block();
    }else
    {
        dispatch_sync(serialQueue, block);
    }
}

// 同步执行+串行队列:没有开启新线程，串行执行任务;『同步执行+串行队列』嵌套『同一个串行队列』
void FSLRunAsynchronouslyOnSerialQueue(void (^block)(void))
{
    dispatch_queue_t serialQueue = dispatch_queue_create("com.FSLAVComponent.SerialQueue", DISPATCH_QUEUE_SERIAL);
    // iOS 6.0就被弃用了：返回与预期不一致的结果；误用可能导致线程死锁
    //if (dispatch_get_current_queu() = serialQueue)
    static const void * const SpecificKey = (const void*)&SpecificKey;
    if (dispatch_get_specific(SpecificKey) == (__bridge void *)(serialQueue))
    {
        block();
    }else
    {
        dispatch_async(serialQueue, block);
    }
}

// 同步执行+并行队列:没有开启新线程，串行执行任务
void FSLRunSynchronouslyOnConcurrentQueue(void (^block)(void))
{
    dispatch_queue_t concurrentQueue = dispatch_queue_create("com.FSLAVComponent.ConcurrentQueue", DISPATCH_QUEUE_CONCURRENT);
    // iOS 6.0就被弃用了：返回与预期不一致的结果；误用可能导致线程死锁
    //if (dispatch_get_current_queu() = serialQueue)
    static const void * const SpecificKey = (const void*)&SpecificKey;
    if (dispatch_get_specific(SpecificKey) == (__bridge void *)(concurrentQueue))
    {
        block();
    }else
    {
        dispatch_sync(concurrentQueue, block);
    }
}

// 异步执行+并行队列:有开启新线程，并发执行任务
void FSLRunAsynchronouslyOnConcurrentQueue(void (^block)(void))
{
    dispatch_queue_t concurrentQueue = dispatch_queue_create("com.FSLAVComponent.ConcurrentQueue", DISPATCH_QUEUE_CONCURRENT);
    // iOS 6.0就被弃用了：返回与预期不一致的结果；误用可能导致线程死锁
    //if (dispatch_get_current_queu() = serialQueue)
    static const void * const SpecificKey = (const void*)&SpecificKey;
    if (dispatch_get_specific(SpecificKey) == (__bridge void *)(concurrentQueue))
    {
        block();
    }else
    {
        dispatch_async(concurrentQueue, block);
    }
}

// 同步执行+全局并行队列:没有开启新线程，串行执行任务
void FSLRunSynchronouslyOnGlobalConcurrentQueue(void (^block)(void))
{
    dispatch_queue_t globalConcurrentQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    // iOS 6.0就被弃用了：返回与预期不一致的结果；误用可能导致线程死锁
    //if (dispatch_get_current_queu() = serialQueue)
    static const void * const SpecificKey = (const void*)&SpecificKey;
    if (dispatch_get_specific(SpecificKey) == (__bridge void *)(globalConcurrentQueue))
    {
        block();
    }else
    {
        dispatch_sync(globalConcurrentQueue, block);
    }
}

// 异步执行+全局并行队列:有开启新线程，并发执行任务
void FSLRunAsynchronouslyOnGlobalConcurrentQueue(void (^block)(void))
{
    
    dispatch_queue_t globalConcurrentQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    // iOS 6.0就被弃用了：返回与预期不一致的结果；误用可能导致线程死锁
    //if (dispatch_get_current_queu() = serialQueue)
    static const void * const SpecificKey = (const void*)&SpecificKey;
    if (dispatch_get_specific(SpecificKey) == (__bridge void *)(globalConcurrentQueue))
    {
        block();
    }else
    {
        dispatch_async(globalConcurrentQueue, block);
    }
}

// 一次性代码（只执行一次）dispatch_once（这里面默认是线程安全的）
void FSLRunOnce(void (^block)(void)){
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, block);
}

/**
 设置默认参数配置
 */
- (void)setConfig;
{
    
}

/**
 销毁对象，释放对象
 */
- (void)destory;
{
    
}

- (void)dealloc{
    [self destory];
}
@end
