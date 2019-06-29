//
//  AudioVideoPlayer.h
//  AudioVideoSDK
//
//  Created by tutu on 2019/6/11.
//  Copyright © 2019 tutu. All rights reserved.
//

#import "FSLAVPlayCoreBase.h"

NS_ASSUME_NONNULL_BEGIN

@class FSLAVPlayer;
@protocol FSLAVPlayerDelegate <NSObject,FSLAVPlayCoreBaseDelegate>

@optional
/**
 播放器状态变化
 @param state 状态
 @param player 播放器
 */
- (void)didChangedPlayState:(FSLAVPlayerState)state player:(FSLAVPlayer *)player;

/**
 视频源开始加载后调用 ，返回视频的时间长度
 @param time 长度（秒）
 @param player 播放器
 */
- (void)didChangedPlayTotalTime:(CGFloat)time player:(FSLAVPlayer *)player;

/**
 视频源加载时调用 ，返回视频的（下载）缓冲长度
 @param time 长度（秒）
 @param player 播放器
 */
- (void)didChangedPlayLoadTime:(CGFloat)time player:(FSLAVPlayer *)player;
/**
 播放时调用，返回当前时间
 @param time 播放到当前的时间（秒）
 @param player 播放器
 */
- (void)didChangedPlayCurrentTime:(CGFloat)time player:(FSLAVPlayer *)player;

@end
@interface FSLAVPlayer : FSLAVPlayCoreBase
{
    AVPlayer *_player;
    AVPlayerItem *_playerItem;
    AVPlayerLayer *_playerLayer;
}
//音视频播放器
@property (nonatomic,strong,readonly) AVPlayer *player;

//音频播放器：只能播放本地音频资源

//音视频播放器的资源管理类
@property (nonatomic,strong,readonly) AVPlayerItem *playerItem;

//视频预览层
@property (nonatomic,strong,readonly) AVPlayerLayer *playerLayer;

/** 播放器预览层的背景色 */
@property (nonatomic,strong) UIColor *playerLayerBackColor;

/** 代理 */
@property (nonatomic,weak) id <FSLAVPlayerDelegate> delegate;

@end


NS_ASSUME_NONNULL_END
