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
 音频录制器：通过AVAudioRecorder形式录制
 */
@interface FSLAVFirstAudioRecorder : FSLAVRecordAudioCoreBase<FSLAVAudioRecorderInterface>

/**
 音频配置项
 */
@property (nonatomic, strong) FSLAVAudioRecoderOptions *options;

/**
 代理
 */
@property (nonatomic, weak) id<FSLAVAudioRecorderDelegate> delegate;



@end

NS_ASSUME_NONNULL_END
