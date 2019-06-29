//
//  FSLAVSingleAudioPlayer.h
//  FSLAVComponent
//
//  Created by TuSDK on 2019/6/29.
//  Copyright © 2019 tutu. All rights reserved.
//

#import "FSLAVPlayCoreBase.h"

NS_ASSUME_NONNULL_BEGIN
@class FSLAVSingleAudioPlayer;
@protocol FSLAVSingleAudioPlayerDelegate <NSObject,FSLAVPlayCoreBaseDelegate>

/**
 播放器状态变化
 @param state 状态
 @param player 播放器
 */
- (void)didChangedAudioPlayState:(FSLAVPlayerState)state player:(FSLAVSingleAudioPlayer *)player;

@end
@interface FSLAVSingleAudioPlayer : FSLAVPlayCoreBase

@property (nonatomic,weak) id<FSLAVSingleAudioPlayerDelegate> delegate;

/**单例类的定时器只能自行销毁*/
+ (instancetype)player;

//播放音效
- (void)playSound;

//摧毁音效
- (void)disposeSound;

@end

NS_ASSUME_NONNULL_END
