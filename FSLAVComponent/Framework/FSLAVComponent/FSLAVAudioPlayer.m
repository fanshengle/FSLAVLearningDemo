//
//  FSLAVAudioPlayer.m
//  ZYAudioPlaying
//
//  Created by 王志盼 on 15/10/12.
//  Copyright © 2015年 王志盼. All rights reserved.
//

#import "FSLAVAudioPlayer.h"

@interface FSLAVAudioPlayer ()<AVAudioPlayerDelegate>
{
    AVAudioPlayer *_audioPlayer;
}
@property (nonatomic, strong) AVAudioPlayer *audioPlayer;
@property (nonatomic, strong) NSMutableDictionary *musicPlayers;
@property (nonatomic, strong) NSMutableDictionary *soundIDs;
@end

@implementation FSLAVAudioPlayer

static FSLAVAudioPlayer *player = nil;
@dynamic delegate;//解决子类协议继承父类协议的delegate命名警告

#pragma mark --  两种初始化方式，step1：init
- (instancetype)init
{
    self = [super init];
    if (self) {
        _musicPlayers = [NSMutableDictionary dictionary];
        _soundIDs = [NSMutableDictionary dictionary];
    }
    return self;
}

#pragma mark --  三种初始化方式，step2：initWithURL:(NSString *)url
- (instancetype)initWithURL:(NSString *)url{
    if (self = [super initWithURL:url]) {
    }
    return self;
}

#pragma mark -- 懒加载创建
- (AVAudioPlayer *)audioPlayer{
    if (!_audioPlayer) {
        NSError *error;
        _audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:_currentURL error:&error];
        
        if (error) {
            NSAssert(YES, @"音频播放器创建失败");
        }
    }
    return _audioPlayer;
}

#pragma mark -- private methods
- (void)playTimeAction{
    /**多种方式尝试播放功能*/
    /**
     step1,缓存播放器,
     */
    AVAudioPlayer *player = _musicPlayers[_currentURLStr];
    
    /**
     step2,重复将播放器置为nil，重复创建播放器，缺点：创建对象，都是耗内存的，优点：代码量少
     */
    //AVAudioPlayer *player = self.audioPlayer;
    
    _currentTimeLength = player.currentTime;
    _totalTimeLength = player.duration;
    _progressScale = _currentTimeLength / _totalTimeLength;
    
    NSLog(@"------>>>%f",_currentTimeLength);
    NSLog(@"======>>>%f",_totalTimeLength);
    NSLog(@"++++++>>>%f",_progressScale);
    
    [super playTimeAction];
}

#pragma mark -- public methods
/**
 播放
 */
- (void)play{
    
    if(_isPlaying) return;
    _isPlaying = YES;
    /**多种方式尝试播放功能*/
    /**
     step1,缓存播放器,
     */
    AVAudioPlayer *player = _musicPlayers[_currentURLStr];
    if (!player) {//将播放器进行缓存
        player = [[AVAudioPlayer alloc] initWithContentsOfURL:_currentURL  error:nil];
        player.delegate = self;
        //将创建好的播放器，缓存起来
        _musicPlayers[_currentURLStr] = player;
    }
    [player prepareToPlay];
    [player play];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(didChangedAudioPlayState:player:)]) {
        [self.delegate didChangedAudioPlayState:FSLAVPlayerStatePlaying player:self];
    }
    
    /**
     step2,重复将播放器置为nil，重复创建播放器，缺点：创建对象，都是耗内存的，优点：代码量少
     */
    //[self.audioPlayer prepareToPlay];
    //[self.audioPlayer play];
    
    [self removePlayTimer];
    [self addPlayTimer];
}

/**
 暂停
 */
- (void)pause{
    
    if(!_isPlaying) return;
    _isPlaying = NO;
    
    /**
     step1,缓存播放器,
     */
    AVAudioPlayer *player = _musicPlayers[_currentURLStr];
    [player pause];
    
    /**
     step2,重复将播放器置为nil，重复创建播放器，缺点：创建对象，都是耗内存的，优点：代码量少
     */
    //[self.audioPlayer pause];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(didChangedAudioPlayState:player:)]) {
        [self.delegate didChangedAudioPlayState:FSLAVPlayerStatePause player:self];
    }
    
    [self removePlayTimer];
}

/**
 停止
 */
- (void)stop{
    
    if(!_isPlaying) return;
    _isPlaying = NO;
    
    AVAudioPlayer *player = _musicPlayers[_currentURLStr];
    [player stop];
    //移除播放器
    [_musicPlayers removeObjectForKey:_currentURLStr];
    
    /**
     step2,重复将播放器置为nil，重复创建播放器，缺点：创建对象，都是耗内存的，优点：代码量少
     */
    //[self.audioPlayer stop];
    //self.audioPlayer = nil;
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(didChangedAudioPlayState:player:)]) {
        [self.delegate didChangedAudioPlayState:FSLAVPlayerStateStop player:self];
    }
    
    [self removePlayTimer];
}


//播放音效
- (void)playSound
{
    if(_isPlaying) return;
    _isPlaying = YES;
    
    //取出对应的音效ID
    SystemSoundID soundID = (int)[_soundIDs[_currentURLStr] unsignedLongValue];
    if (!soundID) {
        //创建音效播放对象
        AudioServicesCreateSystemSoundID((__bridge CFURLRef)(_currentURL), &soundID);
        //将创建好的音效播放对象，缓存起来
        self.soundIDs[_currentURLStr] = @(soundID);
    }
    // 播放
    AudioServicesPlaySystemSound(soundID);
}

//摧毁音效
- (void)disposeSound
{
    if(_isPlaying) return;
    _isPlaying = YES;
    SystemSoundID soundID = (int)[_soundIDs[_currentURLStr] unsignedLongValue];
    if (soundID) {
        //摧毁音效播放对象
        AudioServicesDisposeSystemSoundID(soundID);
        //音效被摧毁，那么对应的对象应该从缓存中移除
        [self.soundIDs removeObjectForKey:_currentURLStr];
    }
}

#pragma mark -- <AVAudioPlayerDelegate>
- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag{
    
    NSLog(@"播放完成");
    if (flag) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(didChangedAudioPlayState:player:)]) {
            [self.delegate didChangedAudioPlayState:FSLAVPlayerStateFinish player:self];
        }
    }else{
        if (self.delegate && [self.delegate respondsToSelector:@selector(didChangedAudioPlayState:player:)]) {
            [self.delegate didChangedAudioPlayState:FSLAVPlayerStateFailed player:self];
        }
    }
    NSLog(@"------>>>%f",player.duration);
    NSLog(@"======>>>%f",player.currentTime);
    NSLog(@"++++++>>>%f",_progressScale);
    
    [self removePlayTimer];
}

- (void)audioPlayerDecodeErrorDidOccur:(AVAudioPlayer *)player error:(NSError * __nullable)error{
    
    if(!error) return;
    if (self.delegate && [self.delegate respondsToSelector:@selector(didChangedAudioPlayState:player:)]) {
        [self.delegate didChangedAudioPlayState:FSLAVPlayerStateFailed player:self];
    }
}


@end
