//
//  AudioVideoPlayer.h
//  AudioVideoSDK
//
//  Created by tutu on 2019/6/11.
//  Copyright © 2019 tutu. All rights reserved.
//

#import "FSLAVPlayCoreBase.h"
#import "FSLAVPlayerInterface.h"

NS_ASSUME_NONNULL_BEGIN

@interface FSLAVPlayer : FSLAVPlayCoreBase<FSLAVPlayerInterface>
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

/** 播放 */
- (void)play;
/** 暂停 */
- (void)pause;
/** 停止 */
- (void)stop;


@end

NS_ASSUME_NONNULL_END
