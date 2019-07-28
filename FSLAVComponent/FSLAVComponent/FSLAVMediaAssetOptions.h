//
//  FSLAVAudioOptions.h
//  FSLAVComponent
//
//  Created by tutu on 2019/7/14.
//  Copyright © 2019 tutu. All rights reserved.
//

#import "FSLAVOptions.h"
#import "FSLAVTimeRange.h"
#import "FSLAVLog.h"

NS_ASSUME_NONNULL_BEGIN

/**
 媒体资源音视频处理（剪辑、编辑、分离、合成等）的核心配置
 */
@interface FSLAVMediaAssetOptions : FSLAVOptions
{
    FSLAVTimeRange *_mediaTimeRange;
}

// 输入的媒体（音视频）路径
@property (nonatomic, strong) NSString *mediaPath;

// 输入的本地音频地址
@property (nonatomic, strong) NSURL *mediaURL;

// 媒体素材 mediaAsset
@property (nonatomic, strong) AVAsset *mediaAsset;

// 媒体音轨、视频轨
@property (nonatomic, strong) AVAssetTrack *mediaTrack;

// 媒体片段所在时间（剪辑的实际有效时间范围）, 默认 整个媒体资源的时间范围
@property (nonatomic, strong) FSLAVTimeRange *atTimeRange;

// 媒体资源的整个媒体资源时间范围
@property (nonatomic, strong, readonly) FSLAVTimeRange *mediaTimeRange;

// 开始合成的时间节点（设置该时间可以控制在什么时间点进行合成。注意：一定要在主（视频轨、音轨）的时间范围内。
@property (nonatomic, assign) CMTime atNodeTime;

// 音量设置
@property (nonatomic, assign) CGFloat audioVolume;

// 是否保留视频原音，默认 YES，保留视频原音
@property (nonatomic, assign) BOOL enableVideoSound;

// 媒体音视频素材的总时长
@property (nonatomic, assign,getter=mediaDuration) NSTimeInterval mediaDuration;


#pragma mark - init
/**
 初始化音频信息媒体
 
 @param mediaPath 音频资源地址
 @return 音频信息媒体
 */
- (instancetype)initWithMediaPath:(NSString *)mediaPath;

/**
 初始化音频信息媒体
 
 @param mediaURL 音频资源地址
 @return 音频信息媒体
 */
- (instancetype)initWithMediaURL:(NSURL *)mediaURL;

/**
 初始化音频信息媒体
 
 @param mediaAsset 音频资源素材
 @return 音频信息媒体
 */
- (instancetype)initWithMediaAsset:(AVURLAsset *)mediaAsset;

/**
 初始化音频信息媒体
 
 @param mediaTrack 音频资源音轨
 @return 音频信息媒体
 */
- (instancetype)initWithMediaTrack:(AVAssetTrack *)mediaTrack;

@end

NS_ASSUME_NONNULL_END
