//
//  FSLAVSecondAudioRecorder.h
//  FSLAVComponent
//
//  Created by tutu on 2019/7/3.
//  Copyright © 2019 tutu. All rights reserved.
//

#import "FSLAVRecordAudioCoreBase.h"

NS_ASSUME_NONNULL_BEGIN

/**
 音频录制器：通过音频捕捉会话AVCaptureSession形式获取的音频数据CMSampleBufferRef格式
 */
@interface FSLAVSecondAudioRecorder : FSLAVRecordAudioCoreBase<FSLAVAudioRecorderInterface>


/**
 音频配置项
 */
@property (nonatomic, strong) FSLAVAudioRecorderConfiguration *configuration;

@property (nonatomic, weak) id<FSLAVAudioRecorderDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
