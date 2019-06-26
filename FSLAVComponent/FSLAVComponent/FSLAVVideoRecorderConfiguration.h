//
//  FSLAVVideoRecorderConfiguration.h
//  FSLAVComponent
//
//  Created by tutu on 2019/6/25.
//  Copyright © 2019 tutu. All rights reserved.
//

#import "FSLAVConfiguraction.h"
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

//录制视频的长宽比
typedef NS_ENUM(NSInteger, FSLAVVideoRecordViewType) {
    Type1X1 = 0,
    Type4X3,
    TypeFullScreen
};

//闪光灯状态
typedef NS_ENUM(NSInteger, FSLAVVideoRecordFlashState) {
    FSLAVVideoRecordFlashClose = 0,
    FSLAVVideoRecordFlashOpen,
    FSLAVVideoRecordFlashAuto,
};

//摄像头位置
typedef NS_ENUM(NSInteger, FSLAVVideoRecordPosition) {
    FSLAVVideoRecordPositionFront = 0,
    FSLAVVideoRecordPositionBack,
    FSLAVVideoRecordPositionUnspecified,
};

//控制录制的视频是否有声音
typedef NS_ENUM(NSInteger, FSLAVFSLAVVideoRecordVoiceType) {
    FSLAVVideoRecordVoiceTypeSoundType = 0,
    FSLAVVideoRecordVoiceTypeNoSoundType,
};


//录制视频的输出类型
typedef NS_ENUM(NSInteger,FSLAVVideoRecordOutputType) {
    FSLAVVideoRecordMovieFileOutput = 0,
    FSLAVVideoRecordVideoDataOutput,
};

/**
 视频分辨率
 */
typedef NS_ENUM (NSUInteger, FSLAVCaptureSessionPreset)
{
    
    FSLAVCaptureSessionPresetLow = 0,
    
    FSLAVCaptureSessionPresetMedium = 1,
    
    FSLAVCaptureSessionPresetHigh = 2,
    
    FSLAVCaptureSessionPresetDefault =  FSLAVCaptureSessionPresetHigh
};

@interface FSLAVVideoRecorderConfiguration : FSLAVConfiguraction

/**
 视频录制的画面比例
 */
@property (nonatomic, assign) FSLAVVideoRecordViewType recordViewType;

/**
 录制的状态
 */
@property (nonatomic, assign) FSLAVRecordState recordState;

/**
 摄像头位置
 */
@property (nonatomic, assign) FSLAVVideoRecordPosition recordPosition;

/**
 是否有声音
 */
@property (nonatomic, assign) FSLAVFSLAVVideoRecordVoiceType recordVoiceType;

/**
 录制视频的输出类型
 */
@property (nonatomic, assign) FSLAVVideoRecordOutputType recordOutputType;

/**
 录制视频的分辨率
 */
@property (nonatomic, assign) FSLAVCaptureSessionPreset sessionPreset;

/**
 采集分辨率
 */
@property (nonatomic, copy) NSString *avSessionPreset;

/**
 摄像头位置
 */
@property (nonatomic, assign) AVCaptureDevicePosition devicePosition;


/**
 录制结束是否跳出预览视图
 */
@property (nonatomic, assign) BOOL isOutPreview;

/**
 默认视频配置
 
 @return FSLAVVideoRecorderConfiguration
 */
+ (instancetype)defaultConfiguration;

/**
 视频配置(质量)
 
 @param sessionPreset 视频分辨率
 @return FSLAVVideoRecorderConfiguration
 */
+ (instancetype)defaultConfigurationForSessionPreset:(FSLAVCaptureSessionPreset)sessionPreset;

/**
 视频配置(质量&是否是横屏)
 
 @param sessionPreset 视频分辨率
 @param videoRecordPosition 摄像机位置
 @return FSLAVVideoRecorderConfiguration
 */
+ (instancetype)defaultConfigurationForSessionPreset:(FSLAVCaptureSessionPreset)sessionPreset videoRecordPosition:(FSLAVVideoRecordPosition)videoRecordPosition;

@end

NS_ASSUME_NONNULL_END
