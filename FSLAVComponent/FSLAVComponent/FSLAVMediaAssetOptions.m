//
//  FSLAVAudioOptions.m
//  FSLAVComponent
//
//  Created by tutu on 2019/7/14.
//  Copyright © 2019 tutu. All rights reserved.
//

#import "FSLAVMediaAssetOptions.h"

@implementation FSLAVMediaAssetOptions

#pragma mark - init
/**
 初始化音频信息媒体
 
 @param mediaPath 音频资源地址
 @return 音频信息媒体
 */
- (instancetype)initWithMediaPath:(NSString *)mediaPath;
{
    if (self = [super init]) {
        self.mediaPath = mediaPath;
    }
    return self;
}
/**
 初始化音频信息媒体
 
 @param mediaURL 音频资源地址
 @return 音频信息媒体
 */
- (instancetype)initWithMediaURL:(NSURL *)mediaURL;
{
    if (self = [super init]) {
        self.mediaURL = mediaURL;
    }
    return self;
}

/**
 初始化音频信息媒体
 
 @param mediaAsset 音频资源素材
 @return 音频信息媒体
 */
- (instancetype)initWithMediaAsset:(AVURLAsset *)mediaAsset;
{
    if (self = [super init]) {
        self.mediaAsset = mediaAsset;
    }
    return self;
}


/**
 初始化音频信息媒体
 
 @param mediaTrack 音频资源音轨
 @return 音频信息媒体
 */
- (instancetype)initWithMediaTrack:(AVAssetTrack *)mediaTrack;
{
    if (self = [super init]) {
        self.mediaTrack = mediaTrack;
    }
    return self;
}

/**
 设置默认参数配置(可以重置父类的默认参数，不设置的话，父类的默认参数会无效)
 */
- (void)setConfig;
{
    [super setConfig];
    
    _enableCreateFilePath = NO;
    _audioVolume = 1.0;
    _atNodeTime = kCMTimeZero;
    _enableVideoSound = YES;
}

/**
 检索url是网络、本地哪一种
 
 @param url urlStr
 @return 返回相应的url
 */
- (NSURL *)retrieveURL:(NSString *)url{
    
    NSURL *videoUrl;
    if ([url containsString:@"http"] || [url containsString:@"https"]) {//网络url
        videoUrl = [self translateIllegalCharacterWtihUrlStr:url];
        //videoUrl = [NSURL URLWithString:url];
    }else {//本地url
        
        videoUrl = [NSURL fileURLWithPath:url];
    }
    return videoUrl;
}

//如果链接中存在中文或某些特殊字符，需要通过以下代码转译
- (NSURL *)translateIllegalCharacterWtihUrlStr:(NSString *)yourUrl{
    
    yourUrl = [yourUrl stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    //NSString *encodedString = [yourUrl stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSString *encodedString = [yourUrl stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    
    return [NSURL URLWithString:encodedString];
}

#pragma mark - setter getter
- (void)setMediaPath:(NSString *)mediaPath{
    if(_mediaPath == mediaPath) return;
    _mediaPath = mediaPath;
    self.mediaURL = [self retrieveURL:mediaPath];
}

/**
 设置音频url地址
 
 @param mediaURL url地址
 */
- (void)setMediaURL:(NSURL *)mediaURL{
    if(_mediaURL == mediaURL) return;
    _mediaURL = mediaURL;
    self.mediaAsset = [AVURLAsset URLAssetWithURL:_mediaURL options:nil];
}


/**
 设置音频素材
 
 @param mediaAsset 音频素材
 */
- (void)setMediaAsset:(AVAsset *)mediaAsset{
    if(_mediaAsset == mediaAsset) return;
    _mediaAsset = mediaAsset;
    self.mediaTrack = [[_mediaAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0];
}

/**
 设置音频音轨
 
 @param mediaTrack 音轨
 */
- (void)setMediaTrack:(AVAssetTrack *)mediaTrack{
    if(_mediaTrack == mediaTrack) return;
    _mediaTrack = mediaTrack;
    if (mediaTrack) {
        _mediaTimeRange = [FSLAVTimeRange timeRangeWithStartTime:kCMTimeZero endTime:mediaTrack.timeRange.duration];
        _atTimeRange = _mediaTimeRange;
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
    
    //判断开始时间是否大于结束时间
    if (CMTIME_COMPARE_INLINE(_atTimeRange.start, >, _atTimeRange.end)) {
        fslLWarn(@"_atTimeRange.start > _atTimeRange.end : %f > %f",_atTimeRange.startSeconds,_atTimeRange.endSeconds);
        
        CMTime start = _atTimeRange.start;
        CMTime end = _atTimeRange.end;
        _atTimeRange.start = end;
        _atTimeRange.end = start;
        _atTimeRange.duration = CMTimeSubtract(_atTimeRange.end, _atTimeRange.start);
    }
    
    //判断设置的持续时间是否大于素材本身的持续时间
    if (CMTIME_COMPARE_INLINE(_atTimeRange.duration, >, _mediaTimeRange.duration)) {
        fslLWarn(@"_atTimeRange.duration > _mediaTimeRange.duration : %f > %f",_atTimeRange.durationSeconds,_mediaTimeRange.durationSeconds);
        
        _atTimeRange.duration = _mediaTimeRange.duration;
    }
    
    //判断开始时间是否大于素材本身的持续时间
    if (CMTIME_COMPARE_INLINE(_atTimeRange.start, >, _mediaTimeRange.end)) {
            fslLWarn(@"_atTimeRange.start > _mediaTimeRange.end : %f > %f",_atTimeRange.startSeconds,_mediaTimeRange.endSeconds);
            
            _atTimeRange.start = _mediaTimeRange.duration;
            _atTimeRange.duration = _mediaTimeRange.start;
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
