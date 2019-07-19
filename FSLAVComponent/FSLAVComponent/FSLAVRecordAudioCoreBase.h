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
    FSLAVAudioRecoderOptions *_options;
    AVAssetWriter *_audioWriter;
    AVAssetWriterInput *_audioWriterInput;
}

/**
 音频配置项
 */
@property (nonatomic, strong) FSLAVAudioRecoderOptions *options;

/**
 媒体数据写入器：用于将媒体数据写入指定的视听容器类型的新文件的对象。
 */
@property (nonatomic, strong) AVAssetWriter *audioWriter;

/**
 媒体数据写入器：输入参数。媒体用于将媒体数据配置参数附加到资产写入器输出文件的单个跟踪中
 */
@property (nonatomic, strong) AVAssetWriterInput *audioWriterInput;


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

#pragma mark -- 媒体写入
/**
 媒体写入器audioWriter开始写入
 */
- (void)startWriting;

/**
 媒体写入器audioWriter取消写入
 */
- (void)cancelWriting;

/**
 设置回调通知，并委托协议
 
 @param recoderOptions 回调的录制结果
 */
- (void)notifyRecordResult:(FSLAVAudioRecoderOptions *)recoderOptions;


@end

NS_ASSUME_NONNULL_END
