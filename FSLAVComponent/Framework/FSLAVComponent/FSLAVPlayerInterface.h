//
//  FSLAVPlayerInterface.h
//  FSLAVComponent
//
//  Created by tutu on 2019/6/27.
//  Copyright © 2019 tutu. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol FSLAVPlayerInterface;

@protocol FSLAVPlayerDelegate <NSObject>
@optional
/**
 播放器状态变化
 @param state 状态
 @param player 播放器
 */
- (void)FSLAVPlayerStateChange:(FSLAVPlayerState)state player:(id<FSLAVPlayerInterface>)player;

/**
 视频源开始加载后调用 ，返回视频的长度
 @param time 长度（秒）
 @param player 播放器
 */
- (void)FSLAVPlayerTotalTime:(CGFloat)time player:(id<FSLAVPlayerInterface>)player;

/**
 视频源加载时调用 ，返回视频的缓冲长度
 @param time 长度（秒）
 @param player 播放器
 */
- (void)FSLAVPlayerLoadTime:(CGFloat)time player:(id <FSLAVPlayerInterface>)player;

/**
 播放时调用，返回当前时间
 @param time 播放到当前的时间（秒）
 @param player 播放器
 */
- (void)FSLAVPlayerCurrentTime:(CGFloat)time player:(id <FSLAVPlayerInterface>)player;

@end

@protocol FSLAVPlayerInterface <NSObject>

@optional

/**
 音视频总时间长度
 */
@property (nonatomic, assign) NSTimeInterval timeInterval;


@end

NS_ASSUME_NONNULL_END
