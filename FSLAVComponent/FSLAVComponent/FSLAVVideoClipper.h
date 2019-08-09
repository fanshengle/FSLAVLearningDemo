//
//  FSLAVVideoClipper.h
//  FSLAVComponent
//
//  Created by tutu on 2019/8/1.
//  Copyright © 2019 tutu. All rights reserved.
//

#import "FSLAVCoreBase.h"
#import "FSLAVAudioClipperOptions.h"
#import "FSLAVVideoClipperOptions.h"

NS_ASSUME_NONNULL_BEGIN
@protocol FSLAVVideoClipperDelegate;

/**
 视频裁剪器
 
 1、移除一个视频中的某个时间段的内容
 2、移除一个视频中的多个时间段的内容
 3、消除一个视频的音轨
 
 */
@interface FSLAVVideoClipper : FSLAVCoreBase

// 代理
@property (nonatomic, weak) id<FSLAVVideoClipperDelegate> clipDelegate;

// 主视频素材
@property (nonatomic, strong) FSLAVVideoClipperOptions *clipVideo;

// 要删除的时间段数组
@property (nonatomic, strong) NSArray<FSLAVTimeRange *> * dropTimeRangeArr;

/**
 初始化音视频混合器，用init初始化也可以，mainVideo都得自行配置
 
 @param mainVideo 主视频轨
 @return FSLAVvideoClipper
 */
- (instancetype)initWithClipperVideoOptions:(FSLAVVideoClipperOptions *)clipVideo;

/**
 开始混合音视频轨，该方法的混合音视频轨结果没有block回调过程，结果可通过协议拿到
 */
- (void)startClippingVideo;

/**
 开始混合音视频轨，该方法的混合音视频轨结果有block回调，同时也可通过协议拿到
 */
- (void)startClippingVideoWithCompletion:(void (^ _Nullable)(NSString *filePath, FSLAVClipStatus status))handler;

/**
 取消混合操作
 */
- (void)cancelClipping;

@end

#pragma mark - protocol FSLAVvideoClipperDelegate

/**
 音视频混合代理
 */
@protocol FSLAVVideoClipperDelegate <NSObject>

@optional

/**
 状态通知代理
 
 @param status 一个/多个片段切片时间合成状态
 @param videoClipper 视频剪辑器
 */- (void)didClippingVideoStatusChanged:(FSLAVClipStatus)status onVideoClip:(FSLAVVideoClipper *)videoClipper;


/**
 所有的合成结果通知代理
 
 @param result 合成结果（如：包括地址输出）
 @param videoClipper 视频剪辑器
 */- (void)didClippedVideoResult:(FSLAVVideoClipperOptions *)result onVideoClip:(FSLAVVideoClipper *)videoClipper;

/**
 合成完成:结果回调
 @param filePath 合成结果文件路径
 @param videoClipper 视频剪辑器对象
 */
- (void)didCompletedMixVideoOutputFilePath:(NSString *)filePath onVideoClip:(FSLAVVideoClipper *)videoClipper;

/**
 视频片段时间合成才会有进度通知代理
 
 @param progress 合成进度
 @param videoClipper 视频剪辑器
 */
- (void)didClippingVideoProgressChanged:(CGFloat)progress onVideoClip:(FSLAVVideoClipper *)videoClipper;

/**
 合成完成：合成的媒体总时间回调
 @param mediaTotalTime 音视频的总时长
 @param videoClipper 视频剪辑器对象
 */
- (void)didCompletedCompositionMediaTotalTime:(NSTimeInterval)mediaTotalTime onVideoClip:(FSLAVvideoClipper *)videoClipper;

@end

NS_ASSUME_NONNULL_END
