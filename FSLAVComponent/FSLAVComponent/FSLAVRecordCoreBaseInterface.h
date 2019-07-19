//
//  FSLAVRecordCoreBaseInterface.h
//  FSLAVComponent
//
//  Created by tutu on 2019/6/26.
//  Copyright © 2019 tutu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FSLAVVideoRecorderOptions.h"
#import "FSLAVAudioRecoderOptions.h"

NS_ASSUME_NONNULL_BEGIN

@protocol FSLAVRecordCoreBaseInterface;

@protocol FSLAVRecordCoreBaseDelegate <NSObject>

@optional

/**
 在录制音视频是添加定时器，定时事件回调

 @param recordTimeLength 录制的时间
 */
- (void)didChangedRecordCurrentTotalTimeLength:(NSTimeInterval)recordTimeLength;

@end

@protocol FSLAVRecordCoreBaseInterface <NSObject>

@optional

//添加录制定时器
- (void)addRecordTimer;

//录制定时事件
- (void)recordTimerAction;

//移除定时器
- (void)removeRecordTimer;


/**
 录制时间是否超过最大录制时间
 */
- (BOOL)isMoreRecordTime;

/**
 录制时间是否小于最小录制时间
 */
- (BOOL)isLessRecordTime;

/**
 开始录制
 */
- (void)startRecord;

/**
 暂停录制
 */
- (void)pauaseRecord;

/**
 结束录制
 */
- (void)stopRecord;

/**
 重新录制
 */
- (void)reRecording;

@end


@protocol FSLAVVideoRecorderInterface;

@protocol FSLAVVideoRecorderDelegate <NSObject,FSLAVRecordCoreBaseDelegate>

@optional
/**
 播放器状态变化
 @param state 状态
 @param videoRecorder 录制器
 */
- (void)didChangedVideoRecordState:(FSLAVRecordState)state fromVideoRecorder:(id<FSLAVVideoRecorderInterface>)videoRecorder outputFileAtURL:(NSURL *)fileURL;

/**
 视频录制：通知委托已写入新的视频帧。
 
 @param sampleBuffer 视频帧
 @param videoRecorder 录制器
 */
- (void)didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromVideoRecorder:(id<FSLAVVideoRecorderInterface>)videoRecorder;

@end

@protocol FSLAVVideoRecorderInterface <NSObject,FSLAVRecordCoreBaseInterface>

@optional

/**
 初始化配置
 
 @param options 配置
 @return options
 */
- ( instancetype)initWithVideoRecordOptions:(FSLAVVideoRecorderOptions *)options;

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

@end


@protocol FSLAVAudioRecorderInterface;

@protocol FSLAVAudioRecorderDelegate <NSObject,FSLAVRecordCoreBaseDelegate>

@optional

/**
 音频录制状态变化
 @param state 状态
 @param audioRecorder 音频录制器
 */
- (void)didChangedAudioRecordState:(FSLAVRecordState)state fromAudioRecorder:(id<FSLAVAudioRecorderInterface>)audioRecorder outputFileAtURL:(NSURL *)fileURL;

/**
 
 FSLAVFirstAudioRecorder的委托
 音频的声波监控，录制时，声波波动值，可以根据该值进行声波UI刷新

 @param progress 声波波动值
 */
- (void)didChangedAudioRecordingPowerProgress:(CGFloat)progress;

/**
 FSLAVSecondAudioRecorder的委托
 音频录制：通知委托已写入新的视频帧。
 
 @param sampleBuffer 视频帧
 @param audioRecorder 录制器
 */
- (void)didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromAudioRecorder:(id<FSLAVAudioRecorderInterface>)audioRecorder;

/**
 FSLAVThreeAudioRecorder的委托
 编码器编码过程回调
 
 @param data 录制的音频数据
 @param recorder FSLAVThreeAudioRecorder
 */
- (void)didRecordingAudioData:(NSData *)data recorder:(id<FSLAVAudioRecorderInterface>)recorder;

@end

@protocol FSLAVAudioRecorderInterface <NSObject,FSLAVRecordCoreBaseInterface>

@optional

/**
 初始化配置
 
 @param options 配置
 @return options
 */
- ( instancetype)initWithAudioRecordOptions:(FSLAVAudioRecoderOptions *)options;


@end

NS_ASSUME_NONNULL_END
