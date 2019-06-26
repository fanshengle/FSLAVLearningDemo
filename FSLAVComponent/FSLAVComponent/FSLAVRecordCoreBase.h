//
//  FSLAVCoreBase.h
//  FSLAVComponent
//
//  Created by tutu on 2019/6/21.
//  Copyright © 2019 tutu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>
#import "FSLAVRecordCoreBaseInterface.h"

NS_ASSUME_NONNULL_BEGIN

/**
 音视频录制的基础类
 */
@interface FSLAVRecordCoreBase : NSObject<FSLAVRecordCoreBaseInterface>
{
    
    NSTimer *_recordTimer;//录制定时器
    NSTimeInterval _recordTime;//录制时长
}

@property (nonatomic, strong, readonly) NSTimer *recordTimer;//录制定时器

@property (nonatomic, assign, readonly) NSTimeInterval recordTime;//录制时长

/**
 代理
 */
@property (nonatomic, weak) id<FSLAVRecordCoreBaseDelegate> delegate;


@end

NS_ASSUME_NONNULL_END
