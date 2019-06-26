//
//  FSLAVRecordCoreBaseInterface.h
//  FSLAVComponent
//
//  Created by tutu on 2019/6/26.
//  Copyright © 2019 tutu. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol FSLAVRecordCoreBaseInterface;

@protocol FSLAVRecordCoreBaseDelegate <NSObject>

@optional

/**
 在录制音视频是添加定时器，定时事件回调

 @param recordTimeLength 录制的时间
 */
- (void)didChangeRecordTime:(NSTimeInterval)recordTimeLength;

@end

@protocol FSLAVRecordCoreBaseInterface <NSObject>

@optional

//添加定时器
- (void)addRecordTimer;

//移除定时器
- (void)removeRecordTimer;

@end

NS_ASSUME_NONNULL_END
