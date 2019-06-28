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
    BOOL _isRecording;// 是否正在录制中
}

/**
 代理
 */
@property (nonatomic, weak) id<FSLAVRecordCoreBaseDelegate> delegate;


/**
 是否正在录制中
 */
@property (readonly, getter=isRecording) BOOL isRecording;


@end

NS_ASSUME_NONNULL_END
