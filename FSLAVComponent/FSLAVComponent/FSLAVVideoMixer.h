//
//  FSLAVVideoMixer.h
//  FSLAVComponent
//
//  Created by tutu on 2019/7/28.
//  Copyright © 2019 tutu. All rights reserved.
//

#import "FSLAVCoreBase.h"
#import "FSLAVMixerOptions.h"

NS_ASSUME_NONNULL_BEGIN

@protocol FSLAVVideoMixerDelegate;
/*
 音视频混合器
 
 功能：
 1、将一个视频(可设定时间范围)，与一个音频(可设定时间范围)混合
 2、将一个视频(可设定时间范围)，与多个音频(可设定时间范围)混合
 3、消除一个视频的音轨
 4、将一个无音轨的视频，与一个(或多个)音频混合
 
 */
@interface FSLAVVideoMixer : FSLAVCoreBase

// 代理
@property (nonatomic, weak) id<FSLAVVideoMixerDelegate> mixDelegate;

// 主视频素材
@property (nonatomic, strong) FSLAVMixerOptions *mainVideo;

// 混合的音频数组
@property (nonatomic, strong) NSArray<FSLAVMixerOptions *> *mixAudios;


/**
 初始化音视频混合器，用init初始化也可以，mainVideo都得自行配置
 
 @param mainVideo 主视频轨
 @return FSLAVvideoMixer
 */
- (instancetype)initWithMixerVideoOptions:(FSLAVMixerOptions *)mainVideo;

/**
 开始混合音视频轨，该方法的混合音视频轨结果没有block回调过程，结果可通过协议拿到
 */
- (void)startMixingVideo;

/**
 开始混合音视频轨，该方法的混合音视频轨结果有block回调，同时也可通过协议拿到
 */
- (void)startMixingVideoWithCompletion:(void (^ _Nullable)(NSString *filePath, FSLAVMixStatus status))handler;

/**
 取消混合操作
 */
- (void)cancelMixing;

@end

#pragma mark - protocol FSLAVVideoMixerDelegate

/**
 音视频混合代理
 */
@protocol FSLAVVideoMixerDelegate <NSObject>

@optional

/**
 状态通知代理
 
 @param status 一个/多个片段切片时间合成状态
 @param videoMixer 合成器
 */- (void)didMixingVideoStatusChanged:(FSLAVMixStatus)status onVideoMix:(FSLAVVideoMixer *)videoMixer;


/**
 所有的合成结果通知代理
 
 @param result 合成结果（如：包括地址输出）
 @param videoMixer 合成器
 */- (void)didMixedVideoResult:(FSLAVMixerOptions *)result onVideoMix:(FSLAVVideoMixer *)videoMixer;

/**
 合成完成:结果回调
 @param filePath 合成结果文件路径
 @param videoMixer 合成器对象
 */
- (void)didCompletedMixVideoOutputFilePath:(NSString *)filePath onVideoMix:(FSLAVVideoMixer *)videoMixer;

/**
 视频片段时间合成才会有进度通知代理
 
 @param progress 合成进度
 @param videoMixer 合成器
 */
- (void)didMixingVideoProgressChanged:(CGFloat)progress onVideoMix:(FSLAVVideoMixer *)videoMixer;

/**
 合成完成：合成的媒体总时间回调
 @param mediaTotalTime 音视频的总时长
 @param videoMixer 合成器对象
 */
- (void)didCompletedCompositionMediaTotalTime:(NSTimeInterval)mediaTotalTime onVideoMix:(FSLAVVideoMixer *)videoMixer;

@end

NS_ASSUME_NONNULL_END
