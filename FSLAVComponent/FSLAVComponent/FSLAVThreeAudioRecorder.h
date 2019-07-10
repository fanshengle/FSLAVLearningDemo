//
//  FSLAVThreeAudioRecorder.h
//  FSLAVComponent
//
//  Created by tutu on 2019/7/8.
//  Copyright © 2019 tutu. All rights reserved.
//

#import "FSLAVRecordAudioCoreBase.h"

NS_ASSUME_NONNULL_BEGIN



/**
 音频录制器：通过组件示例AudioComponentInstance形式获取的音频数据Data格式
 */
@interface FSLAVThreeAudioRecorder : FSLAVRecordAudioCoreBase<FSLAVAudioRecorderInterface>

/**
 音频配置项
 */
@property (nonatomic, strong) FSLAVAudioRecorderConfiguration *configuration;

@property (nonatomic, weak) id<FSLAVAudioRecorderDelegate> delegate;

/**
 *  开启音频采集
 */
@property (nonatomic, assign) BOOL enableAudioCapture;

/**
 *  是否静音(默认不开启静音）
 */
@property (nonatomic, assign) BOOL muted;

@end

NS_ASSUME_NONNULL_END
