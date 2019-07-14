//
//  FSLAVAudioOptions.h
//  FSLAVComponent
//
//  Created by TuSDK on 2019/7/14.
//  Copyright © 2019 tutu. All rights reserved.
//

#import "FSLAVOptions.h"
#import "FSLAVTimeRange.h"
#import "FSLAVLog.h"

NS_ASSUME_NONNULL_BEGIN

/**
 音频媒体资源核心配置项
 */
@interface FSLAVAudioOptions : FSLAVOptions
{
    FSLAVTimeRange *_audioTimeRange;
}

// 本地音频地址
@property (nonatomic, strong) NSURL *audioURL;
// 素材 audioSsset
@property (nonatomic, strong) AVAsset *audioAsset;
// 音轨
@property (nonatomic, strong) AVAssetTrack *audioTrack;
// 音频片段所在时间, 默认 整个音频的时间范围
@property (nonatomic, strong) FSLAVTimeRange *atTimeRange;
// 整个音频的时间范围
@property (nonatomic, strong, readonly) FSLAVTimeRange *audioTimeRange;
// 音量设置
@property (nonatomic, assign) CGFloat audioVolume;

#pragma mark - init

/**
 初始化音频信息媒体
 
 @param audioURL 音频资源地址
 @return 音频信息媒体
 */
- (instancetype)initWithAudioURL:(NSURL *)audioURL;

/**
 初始化音频信息媒体
 
 @param audioAsset 音频资源素材
 @return 音频信息媒体
 */
- (instancetype)initWithAudioAsset:(AVURLAsset *)audioAsset;

/**
 初始化音频信息媒体
 
 @param audioTrack 音频资源音轨
 @return 音频信息媒体
 */
- (instancetype)initWithAudioTrack:(AVAssetTrack *)audioTrack;

/**
 重置默认参数配置
 */
- (void)resetConfig;
@end

NS_ASSUME_NONNULL_END
