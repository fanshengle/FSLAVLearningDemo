//
//  FSLAVAudioMixerOptions.h
//  FSLAVComponent
//
//  Created by tutu on 2019/8/2.
//  Copyright © 2019 tutu. All rights reserved.
//

#import "FSLAVMixerOptions.h"
#import "FSLAVEncodeAudioSetting.h"

NS_ASSUME_NONNULL_BEGIN

@interface FSLAVAudioMixerOptions : FSLAVMixerOptions

/** 音频编码设置*/
@property (nonatomic,strong) FSLAVEncodeAudioSetting *audioSetting;

@end

NS_ASSUME_NONNULL_END
