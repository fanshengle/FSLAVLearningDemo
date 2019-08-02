//
//  FSLAVAudioPitchEngineRecorder.h
//  FSLAVComponent
//
//  Created by tutu on 2019/7/18.
//  Copyright © 2019 tutu. All rights reserved.
//

#import "FSLAVRecordAudioCoreBase.h"
#import "FSLAVMediaTimelineSliceComposition.h"
#import "FSLAVAudioPitchEngineRecorderOptions.h"

NS_ASSUME_NONNULL_BEGIN

/**
 音频录制
 支持变声及快慢速调节
 */
@interface FSLAVAudioPitchEngineRecorder : FSLAVRecordAudioCoreBase

/**
 音频变掉录制器配置项
 */
@property (nonatomic, strong) FSLAVAudioPitchEngineRecorderOptions *pitchOptions;

/**
 删除最后一个音频片段
 */
- (void)deleteLastAudioFragment;

- (instancetype)initWithAudioPitchEngineRecordOptions:(FSLAVAudioPitchEngineRecorderOptions *)options;

@end

NS_ASSUME_NONNULL_END
