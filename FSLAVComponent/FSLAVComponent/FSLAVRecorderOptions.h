//
//  FSLAVRecodeOptions.h
//  FSLAVComponent
//
//  Created by tutu on 2019/7/12.
//  Copyright © 2019 tutu. All rights reserved.
//

#import "FSLAVOptions.h"

NS_ASSUME_NONNULL_BEGIN

/**
 录制状态
 */
typedef NS_ENUM(NSInteger, FSLAVRecordState) {
    
    FSLAVRecordStateReadyToRecord = 0, //开始录制
    FSLAVRecordStateRecording,         //正在录制
    FSLAVRecordStatePause,             //暂停录制
    FSLAVRecordStateResume,            //继续录制
    FSLAVRecordStateCompleted,            //结束录制
    FSLAVRecordStateCanceled,          //取消录制
    FSLAVRecordStateFailed,            //录制失败
    
    FSLAVRecordStateLessMinRecordTime, //小于最小录制时间
    FSLAVRecordStateMoreMaxRecordTime,  //大于等于最大录制时间
    
    FSLAVRecordStateSaving,            //正在保存
    FSLAVRecordStateSavingCompleted,   //保存完成
    FSLAVRecordStateUnKnow             //录制时，发生未知原因
};

/**
 录制模式
 */
typedef NS_ENUM(NSInteger,FSLAVRecordMode)
{
    /** 正常模式 */
    FSLAVRecordModeNormal,
    
    /** 续拍模式 */
    FSLAVRecordModeKeep,
};


/**
 录制速度模式
 */
typedef NS_ENUM(NSInteger,FSLAVRecordSpeedMode)
{
    /** 标准模式 速度大小1.0 */
    FSLAVRecordSpeedMode_Normal,
    
    /** 快速模式 速度大小1.5 */
    FSLAVRecordSpeedMode_Fast1,
    
    /** 极快模式 速度大小2.0 */
    FSLAVRecordSpeedMode_Fast2,
    
    /** 慢速模式 速度大小0.7 */
    FSLAVRecordSpeedMode_Slow1,
    
    /** 极慢模式  速度大小0.5 */
    FSLAVRecordSpeedMode_Slow2,
};

/**
 音视频录制的基础配置类
 */
@interface FSLAVRecorderOptions : FSLAVOptions
{
    NSUInteger _maxRecordDelay;
}

/**
 是否开启自动停止录制,默认是no
 */
@property (nonatomic, assign) BOOL isAutomaticStop;

/**
 是否开启音频声波定时器,默认NO
 */
@property (nonatomic, assign) BOOL isAcousticTimer;

/**
 最小录制时间，默认3s,
 */
@property (nonatomic, assign) NSUInteger minRecordDelay;

/**
 最大录制时长， 默认: -1 不限制录制时长 单位: 秒
 */
@property (nonatomic, assign) NSUInteger maxRecordDelay;

/**
 已录制的总时长
 */
@property (nonatomic, assign,getter=outputDuration) NSTimeInterval outputDuration;


@end

NS_ASSUME_NONNULL_END
