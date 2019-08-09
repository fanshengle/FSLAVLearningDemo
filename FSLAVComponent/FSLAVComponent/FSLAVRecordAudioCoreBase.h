//
//  FSLAVRecordAudioCoreBase.h
//  FSLAVComponent
//
//  Created by tutu on 2019/6/21.
//  Copyright © 2019 tutu. All rights reserved.
//

#import "FSLAVRecordCoreBase.h"

NS_ASSUME_NONNULL_BEGIN
/**
 音频录制的基础类
 */
@interface FSLAVRecordAudioCoreBase : FSLAVRecordCoreBase<FSLAVAudioRecorderInterface>
{
    FSLAVAudioRecorderOptions *_options;
}

/**
 音频配置项
 */
@property (nonatomic, strong) FSLAVAudioRecorderOptions *options;

/**
 audioSession的处理来电、锁屏、启动其他音频app等类别
 */
@property (nonatomic, assign) AVAudioSessionCategory sessionCategory;

/**
 代理
 */
@property (nonatomic, weak) id<FSLAVAudioRecorderDelegate> delegate;


#pragma mark -- 激活Session控制当前的使用场景
/**
 *  初始化音频检查
 */
- (void)setAudioSession;

/**
 重置音频会话分类
 */
- (void)resetAudioSessionCategory;


@end

NS_ASSUME_NONNULL_END
