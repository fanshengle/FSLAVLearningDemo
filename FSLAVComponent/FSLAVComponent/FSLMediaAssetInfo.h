//
//  FSLMediaAssetInfo.h
//  FSLAVComponent
//
//  Created by tutu on 2019/7/15.
//  Copyright © 2019 tutu. All rights reserved.
//

#import "FSLAVMediaInfo.h"
#import "FSLAVAudioInfo.h"
#import "FSLAVVideoInfo.h"

NS_ASSUME_NONNULL_BEGIN
/**
 媒体素材中的音视频信息
 */
typedef void(^lsqMovieInfoLoadCompletionHandler)(void);

@interface FSLMediaAssetInfo : FSLAVMediaInfo

/**
 根据 AVAsset 初始化 FSLMediaAssetInfo
 
 @param asset 资产信息
 @return FSLMediaAssetInfo
 */
- (instancetype)initWithAsset:(AVAsset *)asset;

/**
 视频轨道信息
 */
@property (nonatomic,readonly)AVAsset *asset;

/**
 视频轨道信息
 */
@property (nonatomic,readonly)FSLAVVideoInfo *videoInfo;

/**
 音频轨道信息
 */
@property (nonatomic,readonly)FSLAVAudioInfo *audioInfo;

/**
 异步加载视频信息
 
 @param asset AVAsset
 */
- (void)loadSynchronouslyForAssetInfo:(AVAsset *)asset;


@end

NS_ASSUME_NONNULL_END
