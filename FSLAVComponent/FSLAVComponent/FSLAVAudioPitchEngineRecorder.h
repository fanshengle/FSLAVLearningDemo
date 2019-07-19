//
//  FSLAVAudioPitchEngineRecorder.h
//  FSLAVComponent
//
//  Created by tutu on 2019/7/18.
//  Copyright © 2019 tutu. All rights reserved.
//

#import "FSLAVRecordAudioCoreBase.h"
#import "FSLAVAudioPitchEngine.h"

NS_ASSUME_NONNULL_BEGIN

/**
 音频录制
 支持变声及快慢速调节
 */
@interface FSLAVAudioPitchEngineRecorder : FSLAVRecordAudioCoreBase

/**
 * 改变音频音调 [速度设置将失效]
 * pitch 0 > pitch [大于1时声音升调，小于1时为降调]
 * pitchType 与 pitch不能同时设置；因为pitchType就是设置固定值pitch得到的
 */
@property (nonatomic) FSLAVSoundPitchType pitchType;

/**
 * 改变音频音调 [速度设置将失效]
 * pitch 0 > pitch [大于1时声音升调，小于1时为降调]
 * pitchType 与 pitch不能同时设置；因为pitchType就是设置固定值pitch得到的
 */
@property (nonatomic) float pitch;

/**
 * 改变音频播放速度 [变速不变调, 音调设置将失效]
 * speed 0 > speed
 */
@property (nonatomic) float speed;


@end

NS_ASSUME_NONNULL_END
