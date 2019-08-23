//
//  FSLAVAudioPlayer.h
//  ZYAudioPlaying
//
//  Created by 王志盼 on 15/10/12.
//  Copyright © 2015年 王志盼. All rights reserved.
//

#import "FSLAVPlayCoreBase.h"

/**
 子类继承父类的协议，要想有效果并想消除警告，以下
 1、协议的声明必须写在最上面按以下的方式写，
 2、在@implementation FSLAVAudioPlayer
 写@dynamic delegate;//解决子类协议继承父类协议的delegate命名警告
 
 */
@class FSLAVAudioPlayer;
@protocol FSLAVAudioPlayerDelegate <NSObject,FSLAVPlayCoreBaseDelegate>

/**
 播放器状态变化
 @param state 状态
 @param player 播放器
 */
- (void)didChangedAudioPlayState:(FSLAVPlayerState)state player:(FSLAVAudioPlayer *)player;

@end

/**
 音频播放器，只能用来播放本地音频，不能播放在线音频，在线播放->FSAAVPlayer
 */
@interface FSLAVAudioPlayer : FSLAVPlayCoreBase

@property (nonatomic,weak) id<FSLAVAudioPlayerDelegate> delegate;

/**
 methods0：AVAuidoPlayer：详见FSLAVAudioPlayer
 这种方式适用于音乐时间比较长，或者对播放的控制性要求比较高的场景。
 优点： 抒写效率更高，基本上支持所有的音频格式，对播放的控制，如循环播放，声音大小，暂停等比较方便。
 缺点: 相比上一种，对内存的消耗会多些。不支持流式，即无法播放在线音乐
 */

/**
 method1：播放音效（适用于播放简单音频）
 对于比较短促的声音，比如系统的推送声音和短信声音，官方要求不要超过30s。
 优点：C语言的底层写法，节省内存。
 缺点：支持的格式有限，音量无法通过音量键控制，而且播放方式单一
 */

//播放音效
- (void)playSound;

//摧毁音效
- (void)disposeSound;

/**
 methods0：AVPlayer，详见FSAAVPlayer
 支持本地资源播放，支持流播放，即可以播放在线的音乐。
 优点：音视频类APP基本都是使用该方式，实现音视频播放功能的，定制能力极强，最优，最屌
 */

@end
