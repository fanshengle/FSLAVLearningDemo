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


/**
 代理
 */
@property (nonatomic, weak) id<FSLAVAudioRecorderDelegate> delegate;



@end

NS_ASSUME_NONNULL_END
