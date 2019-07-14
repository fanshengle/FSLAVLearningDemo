//
//  FSLAVAudioInfo.h
//  FSLAVComponent
//
//  Created by tutu on 2019/7/12.
//  Copyright © 2019 tutu. All rights reserved.
//

#import "FSLAVMixerOptions.h"


NS_ASSUME_NONNULL_BEGIN

/**
 音频数据配置项
 */
@interface FSLAVMixerAudioOptions : FSLAVMixerOptions


// 音轨是否可循环添加 默认 NO 不循环
@property (nonatomic, assign) BOOL enableCycleAdd;


@end

NS_ASSUME_NONNULL_END
