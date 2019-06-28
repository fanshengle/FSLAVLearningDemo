//
//  FSLAVRecordCoreBaseInterface.h
//  FSLAVComponent
//
//  Created by tutu on 2019/6/26.
//  Copyright © 2019 tutu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FSLAVVideoRecorderConfiguration.h"
#import "FSLAVAudioRecorderConfiguration.h"

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


@protocol FSLAVVideoRecorderInterface;

@protocol FSLAVVideoRecorderDelegate <NSObject,FSLAVRecordCoreBaseDelegate>

@optional
/**
 播放器状态变化
 @param state 状态
 @param videoRecorder 录制器
 */
- (void)didChangedRecordState:(FSLAVRecordState)state fromVideoRecorder:(id<FSLAVVideoRecorderInterface>)videoRecorder outputFileAtURL:(NSURL *)fileURL;

/**
 通知委托已写入新的视频帧。
 
 @param sampleBuffer 视频帧
 @param videoRecorder 录制器
 */
- (void)didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromVideoRecorder:(id<FSLAVVideoRecorderInterface>)videoRecorder;

@end

@protocol FSLAVVideoRecorderInterface <NSObject,FSLAVRecordCoreBaseInterface>

@optional

/**
 初始化配置
 
 @param configuration 配置
 @return configuration
 */
- ( instancetype)initWithVideoRecordConfiguration:(FSLAVVideoRecorderConfiguration *)configuration;

/**
 设置代理
 
 @param delegate 代理
 */
//- (void)setDelegate:(id<FSLAVVideoRecorderDelegate>)delegate;

/**
 将设备捕捉到的画面呈现到某个view上
 
 @param view 显示具体捕捉画面的视图
 */
- (void)showCaptureSessionOnView:(UIView *)view;

/**
 告诉接收器开始运行。
 */
- (void)startRunning;

/**
 告诉接收器停止运行。
 */
- (void)stopRunning;


//切换设备的摄像机位置
- (void)switchCameraDevicePosition;

/**
 保存视频数据到添加的路径下,录制视频
 */
- (void)startVideoRecording;
/**
 保存视频数据输，结束录制
 */
- (void)stopVideoRecoding;

@end


@protocol FSLAVAudioRecorderInterface;

@protocol FSLAVAudioRecorderDelegate <NSObject,FSLAVRecordCoreBaseDelegate>

@optional
/**
 播放器状态变化
 @param state 状态
 @param videoRecorder 录制器
 */
- (void)didChangedRecordState:(FSLAVRecordState)state fromAudioRecorder:(id<FSLAVAudioRecorderInterface>)audioRecorder outputFileAtURL:(NSURL *)fileURL;

@end

@protocol FSLAVAudioRecorderInterface <NSObject,FSLAVRecordCoreBaseInterface>

@optional

/**
 初始化配置
 
 @param configuration 配置
 @return configuration
 */
- ( instancetype)initWithAudioRecordConfiguration:(FSLAVAudioRecorderConfiguration *)configuration;


@end

NS_ASSUME_NONNULL_END
