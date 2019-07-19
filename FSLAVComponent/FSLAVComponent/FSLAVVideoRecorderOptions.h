//
//  FSLAVVideoRecorderoptions.h
//  FSLAVComponent
//
//  Created by tutu on 2019/6/25.
//  Copyright © 2019 tutu. All rights reserved.
//

#import "FSLAVRecoderOptions.h"

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
    
    FSLAVCaptureSessionPreset_Low = 0,
    
    FSLAVCaptureSessionPreset_Medium = 1,
    
    FSLAVCaptureSessionPreset_High = 2,
    
    FSLAVCaptureSessionPreset_Default =  FSLAVCaptureSessionPreset_High
};


/**
 视频录制的参数配置项
 */
@interface FSLAVVideoRecorderOptions : FSLAVRecoderOptions

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
 
 @return FSLAVVideoRecorderOptions
 */
+ (instancetype)defaultOptions;

/**
 视频配置(分辨率)
 
 @param sessionPreset 视频分辨率
 @return FSLAVVideoRecorderOptions
 */
+ (instancetype)defaultOptionsForSessionPreset:(FSLAVCaptureSessionPreset)sessionPreset;

/**
 视频配置(分辨率&摄像机位置设置)
 
 @param sessionPreset 视频分辨率
 @param videoRecordPosition 摄像机位置
 @return FSLAVVideoRecorderOptions
 */
+ (instancetype)defaultOptionsForSessionPreset:(FSLAVCaptureSessionPreset)sessionPreset videoRecordPosition:(FSLAVVideoRecordPosition)videoRecordPosition;

@end

NS_ASSUME_NONNULL_END
