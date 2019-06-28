//
//  FSLAVPlayCoreBase.h
//  FSLAVComponent
//
//  Created by tutu on 2019/6/21.
//  Copyright © 2019 tutu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, FSLAVPlayerState) {
    FSLAVPlayerStateReadyToPlay, // 播放器准备完毕
    FSLAVPlayerStatePlaying, // 正在播放
    FSLAVPlayerStatePause, // 暂停
    FSLAVPlayerStateStop, // 播放完毕
    FSLAVPlayerStateBufferEmpty, // 缓冲中
    FSLAVPlayerStateKeepUp, // 缓冲完成
    FSLAVPlayerStateFailed, // 播放器准备失败、网络原因，格式原因
    FSLAVPlayerStateUnKnow // 播放器准备失败，发生未知原因
};

/**
 音视频播放的基础类
 */
@interface FSLAVPlayCoreBase : NSObject
{
    BOOL _isBuffering;
    BOOL _isAutomaticPlay;
    BOOL _isPlaying;
    float _volume;
    NSURL *_currentURL;
    NSString *_currentURLStr;
    NSTimeInterval _timeInterval;
}
/**
 是否在缓冲
 */
@property (nonatomic, assign) BOOL isBuffering;

/**
 是否开启自动播放,默认是YES
 */
@property (nonatomic, assign) BOOL isAutomaticPlay;

/**
 是否正在播放
 */
@property (nonatomic, assign, readonly) BOOL isPlaying;


/**
 当前播放器正在播放的url
 */
@property (nonatomic, strong) NSURL *currentURL;

/**
 当前播放器正在播放的urlstr
 */
@property (nonatomic, copy) NSString *currentURLStr;

/**
 播放声音的音量
 */
@property (nonatomic, assign) float volume;
/**
 音视频总时间长度
 */
@property (nonatomic, assign, readonly) NSTimeInterval timeInterval;


@property (nonatomic, assign) AVAudioSessionCategory sessionCategory;

#pragma mark -- 激活Session控制当前的使用场景
- (void)setAudioSession;

/**
 初始化播放源url的播放起
 
 @param url 播放源
 @return 播放器
 */
- (instancetype)initWithURL:(NSString *)url;

/**
 检索url是网络、本地哪一种
 
 @param url url
 @return 返回相应的url
 */
- (NSURL *)retrieveURL:(NSString *)url;

@end

NS_ASSUME_NONNULL_END
