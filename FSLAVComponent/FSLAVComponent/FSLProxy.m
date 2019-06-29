//
//  NSForwardProxy.m
//  FSLAVComponent
//
//  Created by TuSDK on 2019/6/29.
//  Copyright © 2019 tutu. All rights reserved.
//

#import "FSLProxy.h"

@interface FSLProxy()

@property (nonatomic ,weak)id target;//循环引用的对象

@end

@implementation FSLProxy



+(instancetype)proxyWithTarget:(id)target
{
    FSLProxy *proxy = [[FSLProxy alloc] init];
    proxy.target = target;
    return proxy;
}

/**
 仅仅添加了weak类型的属性还不够，为了保证中间件能够响应外部self的事件，需要通过消息转发机制，让实际的响应target还是外部self，这一步至关重要，主要涉及到runtime的消息机制。

 @param aSelector 弱引用之后的循环对象
 @return 未识别的消息定向到的对象。
 */
-(id)forwardingTargetForSelector:(SEL)aSelector
{
    return self.target;
}

@end

@interface FSLForwordProxy()

@property (nonatomic ,weak)id target;//循环引用的对象

@end

@implementation FSLForwordProxy

+ (instancetype)proxyWithTarget:(id)target {
    //NSProxy实例方法为alloc
    FSLForwordProxy *proxy = [FSLForwordProxy alloc];
    proxy.target = target;
    return proxy;
}

/**
 这个函数让重载方有机会抛出一个函数的签名，再由后面的forwardInvocation:去执行
 为给定消息提供参数类型信息
 */
- (NSMethodSignature *)methodSignatureForSelector:(SEL)sel {
    
    return [self.target methodSignatureForSelector:sel];
}

/**
 *  NSInvocation封装了NSMethodSignature，通过invokeWithTarget方法将消息转发给其他对象。这里转发给控制器执行。
 */
- (void)forwardInvocation:(NSInvocation *)invocation {
    [invocation invokeWithTarget:self.target];
}


@end

@implementation NSTimer(TimerBlock)

+ (NSTimer *)block_TimerWithTimeInterval:(NSTimeInterval)interval block:(void (^)(void))block repeats:(BOOL)reqeats;
{
    return [self scheduledTimerWithTimeInterval:interval target:self selector:@selector(blockSelector:) userInfo:block repeats:reqeats];
}

+ (void)blockSelector:(NSTimer *)timer;
{
    void (^block)(void) = timer.userInfo;
    if (block) {
        block();
    }
}

@end
