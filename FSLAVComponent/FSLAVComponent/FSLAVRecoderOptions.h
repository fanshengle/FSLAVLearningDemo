//
//  FSLAVRecodeOptions.h
//  FSLAVComponent
//
//  Created by tutu on 2019/7/12.
//  Copyright © 2019 tutu. All rights reserved.
//

#import "FSLAVOptions.h"

NS_ASSUME_NONNULL_BEGIN

//录制状态
typedef NS_ENUM(NSInteger, FSLAVRecordState) {
    FSLAVRecordStateReadyToRecord = 0, //开始录制
    FSLAVRecordStateRecording,         //正在录制
    FSLAVRecordStateLessMinRecordTime, //小于最小录制时间
    FSLAVRecordStateMoreMaxRecorTime,  //大于等于最大录制时间
    FSLAVRecordStatePause,             //暂停录制
    FSLAVRecordStateFinish,            //结束录制
    FSLAVRecordStateFailed,            //录制失败
    FSLAVRecordStateUnKnow             //录制时，发生未知原因
};

/**
 音视频录制的基础配置类
 */
@interface FSLAVRecoderOptions : FSLAVOptions
{
    BOOL _isAutomaticStop;
    NSUInteger _maxRecordDelay;
    NSTimeInterval _recordTimeLength;
}

/**
 是否开启自动停止录制,默认是no
 */
@property (nonatomic, assign) BOOL isAutomaticStop;

/**
 自动停止录制的最小录制时间，默认3s,
 */
@property (nonatomic, assign) NSUInteger minRecordDelay;

/**
 自动停止录制的最大录制时间，默认0s,可以一直录制
 */
@property (nonatomic, assign) NSUInteger maxRecordDelay;

/**
 当前的录制音视频的总时长
 */
@property (nonatomic, assign) NSTimeInterval recordTimeLength;

/**
 是否开启音频声波定时器,默认开启
 */
@property (nonatomic, assign) BOOL isAcousticTimer;

@end

NS_ASSUME_NONNULL_END
