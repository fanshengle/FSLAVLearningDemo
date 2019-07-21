//
//  FSLAVMediaTimelineSliceComposition.h
//  FSLAVComponent
//
//  Created by tutu on 2019/7/21.
//  Copyright © 2019 tutu. All rights reserved.
//

#import "FSLAVCoreBase.h"
#import "FSLAVAssetExportSession.h"
#import "FSLAVMediaTimelineSliceOptions.h"
#import "FSLAVMeidaTimelineSlice.h"

NS_ASSUME_NONNULL_BEGIN

@protocol FSLAVMediaTimelineSliceCompositionDelegate;

/**
 媒体资源音视频分段时间线（包括快慢速）编辑工具
 功能
 1、将一个视频的一个或多个多个片段进行（包括快慢速）编辑
 2、移除视频中的一个或多个片段
 
 */
@interface FSLAVMediaTimelineSliceComposition : FSLAVCoreBase

// 代理
@property (nonatomic, weak) id<FSLAVMediaTimelineSliceCompositionDelegate> compositionDelegate;
/**
 时间片段编辑的配置项
 */
@property (nonatomic, strong) FSLAVMediaTimelineSliceOptions *timeSliceOptions;

// 媒体资源音视频的时间段数组  注：数组中应包含所有音视频段，而不是只截取某段音视频
@property (nonatomic, strong) NSArray<FSLAVMeidaTimelineSlice *> *meidaFragmentArr;

/**
 初始化媒体音视频分段时间片编辑器，用init初始化也可以，timeSliceOptions都得自行配置
 
 @param timeSliceOptions 分段时间片编辑配置项
 @return FSLAVMediaTimelineSliceComposition
 */
- (instancetype)initWithTimeSliceCompositionOptions:(FSLAVMediaTimelineSliceOptions *)timeSliceOptions;

#pragma mark -- 可以处理视频或音频(使用该方法需要设置_timeSliceOptions.meidaType)
/**
 * 开始音视频分段时间切片（包括录制变速处理）合成
 */
- (void)startMediaComposition;

/**
 * 开始音视频分段时间切片（包括录制变速处理）合成 block回调
 *
 * @param handler 完成回调处理
 */

- (void)startMediaCompositionWithCompletionHandler:(void (^ _Nullable)(NSString *outputFilePath, FSLAVMediaTimelineSliceCompositionStatus status))handler;

/**
 * 取消操作
 */
- (void)cancelMediaComposition;

#pragma mark --  处理视频（包含音频和视频）
/**
 * 开始变速合成
 */
- (void)startVideoComposition;

/**
 * 开始变速合成视频 block回调
 *
 * @param handler 完成回调处理
 */

- (void)startVideoCompositionWithCompletionHandler:(void (^ _Nullable)(NSString *outputFilePath, FSLAVMediaTimelineSliceCompositionStatus status))handler;

#pragma mark --  处理音频（只有音频）

/**
 * 开始变速合成
 */
- (void)startAudioComposition;

/**
 * 开始裁剪音频
 */
- (void)startAudioCompositionWithCompletionHandler:(void (^ _Nullable)(NSString *outputFilePath, FSLAVMediaTimelineSliceCompositionStatus status))handler;

@end


#pragma mark - protocol FSLAVMediaTimelineSliceCompositionDelegate

/**
 多音频混合代理
 */
@protocol FSLAVMediaTimelineSliceCompositionDelegate <NSObject>

@optional

// 状态通知代理
- (void)didCompositionMediaStatusChanged:(FSLAVMediaTimelineSliceCompositionStatus)status composition:(FSLAVMediaTimelineSliceComposition *)composition;

// 结果通知代理
- (void)didCompositionMediaResult:(FSLAVMediaTimelineSliceOptions *)result composition:(FSLAVMediaTimelineSliceComposition *)composition;

// 进度通知代理
- (void)didCompositionMediaProgressChanged:(CGFloat)progress composition:(FSLAVMediaTimelineSliceComposition *)composition;

@end

NS_ASSUME_NONNULL_END
