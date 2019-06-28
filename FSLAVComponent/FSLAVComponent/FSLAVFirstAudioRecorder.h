//
//  AudioFirstVoiceRecorder.h
//  AudioVideoSDK
//
//  Created by tutu on 2019/6/6.
//  Copyright © 2019 tutu. All rights reserved.
//

#import "FSLAVRecordAudioCoreBase.h"

NS_ASSUME_NONNULL_BEGIN
/**
 音频第一选择录制器
 */
@interface FSLAVFirstAudioRecorder : FSLAVRecordAudioCoreBase<FSLAVAudioRecorderInterface>

/**
 音频配置项
 */
@property (nonatomic, strong , readonly) FSLAVAudioRecorderConfiguration *configuration;


@property (nonatomic, assign) BOOL isRecording; //正在录制中

/**
 是否开启音频声波定时器,默认开启
 */
@property (nonatomic, assign) BOOL isAcousticTimer;

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

NS_ASSUME_NONNULL_END
