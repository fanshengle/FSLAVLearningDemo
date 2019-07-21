//
//  FSLAVAudioOptions.m
//  FSLAVComponent
//
//  Created by tutu on 2019/7/14.
//  Copyright © 2019 tutu. All rights reserved.
//

#import "FSLAVAudioOptions.h"

@implementation FSLAVAudioOptions

#pragma mark - init

/**
 初始化音频信息媒体
 
 @param audioURL 音频资源地址
 @return 音频信息媒体
 */
- (instancetype)initWithAudioURL:(NSURL *)audioURL;
{
    if (self = [super init]) {
        self.audioURL = audioURL;
    }
    return self;
}

/**
 初始化音频信息媒体
 
 @param audioAsset 音频资源素材
 @return 音频信息媒体
 */
- (instancetype)initWithAudioAsset:(AVURLAsset *)audioAsset;
{
    if (self = [super init]) {
        self.audioAsset = audioAsset;
    }
    return self;
}


/**
 初始化音频信息媒体
 
 @param audioTrack 音频资源音轨
 @return 音频信息媒体
 */
- (instancetype)initWithAudioTrack:(AVAssetTrack *)audioTrack;
{
    if (self = [super init]) {
        self.audioTrack = audioTrack;
    }
    return self;
}

/**
 设置默认参数配置
 */
- (void)setConfig;
{
    [super setConfig];
    
    _enableCreateFilePath = NO;
    _audioVolume = 1.0;
}

#pragma mark - setter getter

/**
 设置音频url地址
 
 @param audioURL url地址
 */
- (void)setAudioURL:(NSURL *)audioURL{
    if(_audioURL == audioURL) return;
    _audioURL = audioURL;
    self.audioAsset = [AVURLAsset URLAssetWithURL:_audioURL options:nil];
    self.audioTrack = [[_audioAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0];
}


/**
 设置音频素材
 
 @param audioAsset 音频素材
 */
- (void)setAudioAsset:(AVAsset *)audioAsset{
    if(_audioAsset == audioAsset) return;
    _audioAsset = audioAsset;
    self.audioTrack = [[_audioAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0];
}

/**
 设置音频音轨
 
 @param audioTrack 音轨
 */
- (void)setAudioTrack:(AVAssetTrack *)audioTrack{
    if(_audioTrack == audioTrack) return;
    _audioTrack = audioTrack;
    if (audioTrack) {
        _audioTimeRange = [FSLAVTimeRange timeRangeWithStartTime:kCMTimeZero endTime:audioTrack.timeRange.duration];
        _atTimeRange = _audioTimeRange;
    }
}

/**
 设置音效播放区间
 
 @param atTimeRange 音效播放区间
 */
- (void)setAtTimeRange:(FSLAVTimeRange *)atTimeRange;
{
    if(_atTimeRange == atTimeRange) return;
    _atTimeRange = atTimeRange;
    
    //判断设置的持续时间是否大于素材本身的持续时间
    if (CMTIME_COMPARE_INLINE(_atTimeRange.duration, >, _audioTimeRange.duration)) {
        fslLWarn(@"_atTimeRange.duration > _audioTimeRange.duration : %f > %f",_atTimeRange.durationSeconds,_audioTimeRange.durationSeconds);
        
        _atTimeRange.duration = _audioTimeRange.duration;
    }
    //判断开始时间是否大于素材本身的持续时间
    if (CMTIME_COMPARE_INLINE(_atTimeRange.start, >, _audioTimeRange.end)) {
        fslLWarn(@"_atTimeRange.start > _audioTimeRange.end : %f > %f",_atTimeRange.startSeconds,_audioTimeRange.endSeconds);
        
        _atTimeRange.start = _audioTimeRange.duration;
        _atTimeRange.duration = _audioTimeRange.start;
    }
}

/**
 音量设置
 
 @param audioVolume 音量调节值
 */
- (void)setAudioVolume:(CGFloat)audioVolume;
{
    _audioVolume = audioVolume > 1.0 ? 1.0 : (audioVolume < 0.0 ? 0.0 : audioVolume);
}
@end
