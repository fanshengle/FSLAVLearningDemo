//
//  FSLAVAudioMixer.h
//  FSLAVComponent
//
//  Created by tutu on 2019/7/12.
//  Copyright © 2019 tutu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FSLAVMixerAudioOptions.h"

NS_ASSUME_NONNULL_BEGIN

@protocol FSLAVAudioMixerDelegate;

/**
 多音频混合
 
 功能：
 1、将一个音频(可设定时间范围)，与一个音频(可设定时间范围)混合
 2、将一个音频(可设定时间范围)，与多个音频(可设定时间范围)混合
 3、导出一个视频中的音轨
 
 */
@interface FSLAVAudioMixer : NSObject

// 代理
@property (nonatomic, weak) id<FSLAVAudioMixerDelegate> mixDelegate;

// 主音频，即背景音频，在混合过程中，主音频不变
@property (nonatomic, strong) FSLAVMixerAudioOptions *mainAudio;

// 混合音频，即要添加在主音频上混合音频
@property (nonatomic, strong) NSArray<FSLAVMixerAudioOptions *> *mixAudios;

/**
 初始化音频混合器，用init初始化也可以，mainAudio都得自行配置
 
 @param mainAudio 主音轨
 @return FSLAVAudioMixer
 */
- (instancetype)initWithMixerAudioOptions:(FSLAVMixerAudioOptions *)mainAudio;

/**
 开始混合音轨，该方法的混合音轨结果没有block回调过程，结果可通过协议拿到
 */
- (void)startMixingAudio;

/**
 开始混合音轨，该方法的混合音轨结果有block回调，同时也可通过协议拿到
 */
- (void)startMixingAudioWithCompletion:(void (^)(NSURL*, FSLAVMixStatus))handler;

// 取消混合操作
- (void)cancelMixing;

@end

#pragma mark - protocol FSLAVAudioMixerDelegate

/**
 多音频混合代理
 */
@protocol FSLAVAudioMixerDelegate <NSObject>

@optional

// 状态通知代理
- (void)didMixedAudioStatusChanged:(FSLAVMixStatus)audioStatus onAudioMix:(FSLAVAudioMixer *)audioMixer;

// 结果通知代理
- (void)didMixedAudioResult:(FSLAVMixerAudioOptions *)result onAudioMix:(FSLAVAudioMixer *)audioMixer;

@end


NS_ASSUME_NONNULL_END
