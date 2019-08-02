//
//  FSLAVAudioCliper.h
//  FSLAVComponent
//
//  Created by tutu on 2019/7/14.
//  Copyright © 2019 tutu. All rights reserved.
//

#import "FSLAVCoreBase.h"
#import "FSLAVClipperOptions.h"

NS_ASSUME_NONNULL_BEGIN

@protocol FSLAVAudioClipperDelegate;

/**
 音频剪辑器
 */
@interface FSLAVAudioClipper : FSLAVCoreBase

// 代理
@property (nonatomic, weak) id<FSLAVAudioClipperDelegate> clipDelegate;

// 需要剪辑的音频素材
@property (nonatomic, strong) FSLAVClipperOptions *clipAudio;

/**
 初始化音频剪辑器，用init初始化也可以，clipAudio都得自行配置
 
 @param clipAudio 需要裁剪的音轨
 @return FSLAVAudioCliper
 */
- (instancetype)initWithCliperAudioOptions:(FSLAVClipperOptions *)clipAudio;

/**
 开始剪辑音轨，该方法的剪辑音轨结果没有block回调过程，结果可通过协议拿到
 */
- (void)startClippingAudio;

/**
 开始剪辑音轨，该方法的剪辑音轨结果有block回调，同时也可通过协议拿到
 */
- (void)startClippingAudioWithCompletion:(void (^ _Nullable)(NSString*, FSLAVClipStatus))handler;

/**
 取消剪辑操作
 */
- (void)cancelClipping;


@end

#pragma mark - protocol FSLAVAudioClipperDelegate

/**
 音频剪辑代理
 */
@protocol FSLAVAudioClipperDelegate <NSObject>

@optional

// 状态通知代理
- (void)didClippingAudioStatusChanged:(FSLAVClipStatus)audioStatus onAudioClip:(FSLAVAudioClipper *)audioClipper;

// 结果通知代理
- (void)didClipedAudioResult:(FSLAVClipperOptions *)result onAudioClip:(FSLAVAudioClipper *)audioClipper;

// 剪辑完成路径通知代理
- (void)didCompletedClipAudioOutputPath:(NSString *)outputPath onAudioClip:(FSLAVAudioClipper *)audioMixer;
@end
NS_ASSUME_NONNULL_END
