//
//  NSForwardProxy.h
//  FSLAVComponent
//
//  Created by tutu on 2019/6/29.
//  Copyright © 2019 tutu. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 以下是三种处理方式，专门用来打破循环引用的
 step1:
 给self添加中间件proxy
 引入一个对象proxy，proxy弱引用 self，然后 proxy 传入NSTimer。即self 强引用NSTimer，NSTimer强引用 proxy，proxy 弱引用 self，这样通过弱引用来解决了相互引用，此时不会形成循环。
 */
@interface FSLProxy : NSObject

+ (instancetype)proxyWithTarget:(id)target;

@end

/**
 step2:
 消息转发类，专门用来处理循环强引用的工具类
 如：ControllerB->NSTimer->ControllerB的循环强引用，导致内存泄露，timer一直执行定时事件，走不了dealloc，得不到销毁释放
 同理还有：block块中，delegate的传参中都会存在这样的问题
 */
@interface FSLForwordProxy : NSProxy

+ (instancetype)proxyWithTarget:(id)target;

@end


/**
 step3:
 自定义category用block解决，封装一个NSTimer的category，提供block形式的接口
 只能用来处理定时器的循环引用
 */
@interface NSTimer(TimerBlock)

/**
 分类解决NSTimer在使用时造成的循环引用的问题
 @param interval 间隔时间
 @param block    回调
 @param repeats  用于设置定时器是否重复触发
 @return 返回NSTimer实体
 */
+ (NSTimer *)block_TimerWithTimeInterval:(NSTimeInterval)interval block:(void (^)(void))block repeats:(BOOL)repeats;

@end



NS_ASSUME_NONNULL_END
