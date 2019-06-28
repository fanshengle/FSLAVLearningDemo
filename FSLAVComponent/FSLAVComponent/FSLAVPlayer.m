//
//  AudioVideoPlayer.m
//  AudioVideoSDK
//
//  Created by tutu on 2019/6/11.
//  Copyright © 2019 tutu. All rights reserved.
//

#import "FSLAVPlayer.h"

@interface FSLAVPlayer ()


/** player 播放过程中的时间监听 */
@property (nonatomic,strong) id playerTimeObserver;

@end

@implementation FSLAVPlayer

- (instancetype)init
{
    self = [super init];
    if (self) {
        
        [self initPlayer];
    }
    return self;
}

- (instancetype)initWithURL:(NSString *)url{
    self = [super initWithURL:url];

    [self initPlayer];
    [self addPlayerItemObserver];
    return self;
}

/**
 切换播放资源
 */
- (void)switchPlayURL:(NSString *)url{
    
    _currentURL = [self retrieveURL:url];
    
    _playerItem = [AVPlayerItem playerItemWithURL:_currentURL];
    if (@available(iOS 9.0, *)) {
        _playerItem.canUseNetworkResourcesForLiveStreamingWhilePaused = YES;
    }
    //更换播放的资源
    [_player replaceCurrentItemWithPlayerItem:_playerItem];
    
    //添加观察者
    [self addPlayerItemObserver];
}

#pragma mark -- 初始化音视频播放器player
- (void)initPlayer{
    
    _isBuffering = YES;
    _volume = 1.0;
    _isAutomaticPlay = YES;
    _playerItem = [AVPlayerItem playerItemWithURL:_currentURL];
    _player = [AVPlayer playerWithPlayerItem:_playerItem];
    _player.volume = _volume;
    
    _playerLayer = [AVPlayerLayer playerLayerWithPlayer:_player];
    //玩家应该保持视频的长宽比，并在层的边界内匹配视频。
    _playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
    
    [self addNotification];
}

#pragma mark -- 添加通知
- (void)addNotification{
    
    //监听耳机的插拔状态
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(checkHeaderPhone) name:AVAudioSessionRouteChangeNotification object:nil];
    // app退到后台
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidEnterBackground) name:NSExtensionHostWillResignActiveNotification object:nil];
    // app进入前台
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidEnterPlayGround) name:NSExtensionHostDidBecomeActiveNotification object:nil];
}

#pragma mark -- 删除通知
- (void)removeNotification{
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVAudioSessionRouteChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSExtensionHostWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSExtensionHostDidBecomeActiveNotification object:nil];
}

#pragma mark -- 添加观察者
- (void)addPlayerItemObserver{
    
    if (!_playerItem) return;
    
    //监听播放状态
    [_playerItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
    //监听播放进度loadedTimeRanges
    [_playerItem addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:nil];
    // Will warn you when your buffer is empty
    [_playerItem addObserver:self forKeyPath:@"playbackBufferEmpty" options:NSKeyValueObservingOptionNew context:nil];
    // Will warn you when your buffer is good to go again.
    [_playerItem addObserver:self forKeyPath:@"playbackLikelyToKeepUp" options:NSKeyValueObservingOptionNew context:nil];
    
    // AVPlayer播放完成通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(moviePlayDidEnd:) name:AVPlayerItemDidPlayToEndTimeNotification object:_playerItem];
}

#pragma mark -- 移除观察者
- (void)removePlayerItemObserver{
    
    if (!_playerItem) return;
    
    [_playerItem removeObserver:self forKeyPath:@"status"];
    [_playerItem removeObserver:self forKeyPath:@"loadedTimeRanges"];
    [_playerItem removeObserver:self forKeyPath:@"playbackBufferEmpty"];
    [_playerItem removeObserver:self forKeyPath:@"playbackLikelyToKeepUp"];
    
    //移除播放完成通知
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:_playerItem];
    
    _playerItem = nil;
    
    // 将AudioSession设置为不活跃，恢复其他音频
    [[AVAudioSession sharedInstance] setActive:NO withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:nil];
}

#pragma mark -- 移除监听播放器播放过程中时间的观察者
- (void)removeTimeObserver {
    if (_playerTimeObserver) {
        @try {
            [_player removeTimeObserver:_playerTimeObserver];
        }@catch (id e) {
            
        }@finally {
            _playerTimeObserver = nil;
        }
    }
}

#pragma mark -- Public Set
- (void)setPlayerLayerBackColor:(UIColor *)playerLayerBackColor{
    
    _playerLayerBackColor = playerLayerBackColor;
    self.playerLayer.backgroundColor = _playerLayerBackColor.CGColor;
}

#pragma mark -- private methods

//设置播放进度和时间
-(void)setTheProgressOfPlayTime {
    
    //音视频的总时长
    _timeInterval   = CMTimeGetSeconds(_playerItem.asset.duration);
    NSLog(@"正在播放...，音视频总长度:%.2f", CMTimeGetSeconds(_playerItem.duration));
    if (self.delegate && [self.delegate respondsToSelector:@selector(FSLAVPlayerTotalTime:player:)]) {
        [self.delegate FSLAVPlayerTotalTime:self.timeInterval player:self];
    }
    
    //监听播放进度
    __weak typeof(self) weakSelf = self;
    _playerTimeObserver = [_player addPeriodicTimeObserverForInterval:CMTimeMake(1.0, 10) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
        if (weakSelf.isPlaying) {
            CGFloat currentTime = CMTimeGetSeconds(time);
            NSLog(@"当前已经播放%.2fs.", currentTime);
            if (weakSelf.delegate && [weakSelf.delegate respondsToSelector:@selector(FSLAVPlayerCurrentTime:player:)]) {
                [weakSelf.delegate FSLAVPlayerCurrentTime:currentTime player:weakSelf];
            }
        }
    }];
}

/**
 播放器资源管理器播放状态
 
 @param status 几种播放状态
 */
- (void)playerItemStateChange:(AVPlayerItemStatus)status
{
    switch (status) {
        case AVPlayerItemStatusReadyToPlay: {
            NSLog(@"准备播放");
            
            // 开始播放
            _isPlaying = YES;
            [_player play];
            [self setTheProgressOfPlayTime];
            if (self.delegate && [self.delegate respondsToSelector:@selector(FSLAVPlayerStateChange:player:)]) {
                [self.delegate FSLAVPlayerStateChange:FSLAVPlayerStateReadyToPlay player:self];
            }
            
        } break;
            
        case AVPlayerItemStatusFailed: {
            NSLog(@"音频加载失败");
            
            _isPlaying = NO;
            if (self.delegate && [self.delegate respondsToSelector:@selector(FSLAVPlayerStateChange:player:)]) {
                [self.delegate FSLAVPlayerStateChange:FSLAVPlayerStateFailed player:self];
            }
            [self stop];
        }
            break;
            
        case AVPlayerItemStatusUnknown: {
            NSLog(@"未知资源");
            _isPlaying = NO;
            if (self.delegate && [self.delegate respondsToSelector:@selector(FSLAVPlayerStateChange:player:)]) {
                [self.delegate FSLAVPlayerStateChange:FSLAVPlayerStateUnKnow player:self];
            }
        }
            break;
            
        default:
            break;
            
    }
}

#pragma mark -- public methods

/**
 播放音视频
 */
- (void)play{
    
    if (_isPlaying) return;
    if (!_playerItem) {
        
        [self switchPlayURL:_currentURLStr];
    }
    
    _isPlaying = YES;
    [_player play];
    if (self.delegate && [self.delegate respondsToSelector:@selector(FSLAVPlayerStateChange:player:)]) {
        [self.delegate FSLAVPlayerStateChange:FSLAVPlayerStatePlaying player:self];
    }
}

/**
 暂停
 */
- (void)pause {
    
    if (!_isPlaying) return;
    _isPlaying = NO;
    [_player pause];
    if (self.delegate && [self.delegate respondsToSelector:@selector(FSLAVPlayerStateChange:player:)]) {
        [self.delegate FSLAVPlayerStateChange:FSLAVPlayerStatePause player:self];
    }
}


/**
 停止
 */
- (void)stop {
    
    if(!_isPlaying) return;
    _isPlaying = NO;
    [_player pause];
    
    // 移除之前的时间监听
    [self removeTimeObserver];
    //移除播放器一系列的播放监听
    [self removePlayerItemObserver];
    
    [_player replaceCurrentItemWithPlayerItem:_playerItem];
    if (self.delegate && [self.delegate respondsToSelector:@selector(FSLAVPlayerStateChange:player:)]) {
        [self.delegate FSLAVPlayerStateChange:FSLAVPlayerStateStop player:self];
    }
}

#pragma mark -- Notification
//改变播放模式
- (void)checkHeaderPhone{
    
    AVAudioSession *session = [AVAudioSession sharedInstance];
    for (AVAudioSessionPortDescription *dp in session.currentRoute.outputs) {
        if ([dp.portType isEqualToString:AVAudioSessionPortHeadphones]) {
            [session overrideOutputAudioPort:AVAudioSessionPortOverrideNone error:nil];
            break;
        } else {
            //设置为公放模式
            [session overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker error:nil];
            break;
        }
    }
}

// 应用退到后台
- (void)appDidEnterBackground {
    [self pause];
}
// 应用进入前台
- (void)appDidEnterPlayGround {
    
}

/**
 播放器播放完成的通知

 @param noti 通知携带的消息
 */
- (void)moviePlayDidEnd:(NSNotification *)noti {
    //将当前播放时间设置为指定的时间,恢复初始状态。
    [_player seekToTime:kCMTimeZero];
    _isPlaying = NO;
    if (self.delegate && [self.delegate respondsToSelector:@selector(FSLAVPlayerStateChange:player:)]) {
        [self.delegate FSLAVPlayerStateChange:FSLAVPlayerStateStop player:self];
    }
}


#pragma mark -- delegate

#pragma mark - 视频输出代理
- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didStartRecordingToOutputFileAtURL:(NSURL *)fileURL fromConnections:(NSArray *)connections
{
    NSLog(@"开始录制...");
}

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray *)connections error:(NSError *)error
{
    NSLog(@"视频录制完成.");
}


#pragma mark - KVO
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    
    if (object == _playerItem) {
        
        if ([keyPath isEqualToString:@"status"]) {
            
            AVPlayerItemStatus status = (AVPlayerItemStatus)[[change objectForKey:@"new"] integerValue];
            [self playerItemStateChange:status];
            
        } else if ([keyPath isEqualToString:@"loadedTimeRanges"]) {
            
            CMTimeRange range = [_playerItem.loadedTimeRanges.firstObject CMTimeRangeValue];
            CGFloat loadSeconds = CMTimeGetSeconds(range.start) + CMTimeGetSeconds(range.duration);
            NSLog(@"共缓冲：%.2f", loadSeconds);
            if (self.delegate && [self.delegate respondsToSelector:@selector(FSLAVPlayerLoadTime:player:)]) {
                [self.delegate FSLAVPlayerLoadTime:loadSeconds player:self];
            }
        }else if ([keyPath isEqualToString:@"playbackBufferEmpty"]) {
            
            // 当缓冲是空的时候
        }else if ([keyPath isEqualToString:@"playbackLikelyToKeepUp"]) {
            
            //一个布尔值，指示项目是否可能在不停顿的情况下完成。
            if (!_playerItem.playbackLikelyToKeepUp) {
                
                _isBuffering = YES;
            }else {
                _isBuffering = NO;
            }
            if (self.delegate && [self.delegate respondsToSelector:@selector(FSLAVPlayerStateChange:player:)]) {
                [self.delegate FSLAVPlayerStateChange:_isBuffering?FSLAVPlayerStateBufferEmpty:FSLAVPlayerStateKeepUp player:self];
            }
        }
    }
}


#pragma mark - dealloc

- (void)dealloc{
    
    [self removeNotification];
    [self removePlayerItemObserver];
}

@end
