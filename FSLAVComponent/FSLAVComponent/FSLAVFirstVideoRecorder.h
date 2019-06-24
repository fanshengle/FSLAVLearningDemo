//
//  VideoFirstRecorder.h
//  AudioVideoSDK
//
//  Created by tutu on 2019/6/14.
//  Copyright © 2019 tutu. All rights reserved.
//

#import "FSLAVRecordVideoCoreBase.h"

NS_ASSUME_NONNULL_BEGIN
/**
 视频第一选择录制器
 */
@interface FSLAVFirstVideoRecorder : FSLAVRecordVideoCoreBase


@property (nonatomic, assign) FSLAVVideoRecordPosition recordPosition;
@property (nonatomic, assign) FSLAVFSLAVVideoRecordVoiceType recordVoiceType;
@property (nonatomic, assign) FSLAVVideoRecordOutputType recordOutputType;


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

NS_ASSUME_NONNULL_END
