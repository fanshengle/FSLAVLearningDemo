//
//  FSLAVRecordVideoCoreBase.h
//  FSLAVComponent
//
//  Created by tutu on 2019/6/21.
//  Copyright © 2019 tutu. All rights reserved.
//

#import "FSLAVRecordCoreBase.h"

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

//录制状态
typedef NS_ENUM(NSInteger, FSLAVVideoRecordState) {
    FSLAVVideoRecordStateInit = 0,
    FSLAVVideoRecordStateRecording,
    FSLAVVideoRecordStatePause,
    FSLAVVideoRecordStateFinish,
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
 视频录制的基础类
 */
@interface FSLAVRecordVideoCoreBase : FSLAVRecordCoreBase

@end

NS_ASSUME_NONNULL_END
