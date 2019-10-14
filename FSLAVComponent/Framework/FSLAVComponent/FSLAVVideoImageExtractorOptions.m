//
//  FSLAVVideoImageExtractorOptions.m
//  FSLAVComponent
//
//  Created by tutu on 2019/8/22.
//  Copyright © 2019 tutu. All rights reserved.
//

#import "FSLAVVideoImageExtractorOptions.h"

@implementation FSLAVVideoImageExtractorOptions

- (instancetype)init
{
    self = [super init];
    if (self) {
        _extractFrameCount = 15;
        _isAccurate = NO;
    }
    return self;
}

#pragma mark - init
/**
 初始化视频信息
 
 @param videoPath 视频资源地址
 @return 视频信息
 */
- (instancetype)initWithVideoPath:(NSString *)videoPath;
{
    if (self = [self init]) {
        self.videoPath = videoPath;
    }
    return self;
}

/**
 初始化视频信息
 
 @param videoURL 视频资源地址
 @return 视频信息
 */
- (instancetype)initWithVideoURL:(NSURL *)videoURL;
{
    if (self = [self init]) {
        self.videoURL = videoURL;
    }
    return self;
}

/**
 初始化视频信息
 
 @param videoAsset 视频资源素材
 @return 视频信息
 */
- (instancetype)initWithVideoAsset:(AVURLAsset *)videoAsset;
{
    if (self = [self init]) {
        self.videoAsset = videoAsset;
    }
    return self;
}

/**
 初始化视频信息：多视频统一配置
 
 @param videoAssets 视频资源素材数组
 @return 视频信息
 */
- (instancetype)initWithVideoAssets:(NSArray <AVURLAsset *> *)videoAssets;
{
    if (self = [self init]) {
        self.videoAssets = videoAssets;
    }
    return self;
}

#pragma mark -- setter getter

/**
 设置媒体资源Asset

 @param videoAsset 媒体资源Asset
 */
- (void)setVideoAsset:(AVAsset *)videoAsset{
    if (_videoAsset == videoAsset) return;
    _videoAsset = videoAsset;
    
    self.videoAssets = @[videoAsset];
}

/**
 设置媒体url路径

 @param videoPath url路径
 */
- (void)setVideoPath:(NSString *)videoPath{
    if(_videoPath == videoPath) return;
    _videoPath = videoPath;
    
    self.videoURL = [self retrieveURL:videoPath];
}

/**
 设置媒体url地址
 
 @param videoURL url地址
 */
- (void)setVideoURL:(NSURL *)videoURL{
    if(_videoURL == videoURL) return;
    _videoURL = videoURL;
    
    self.videoAsset = [AVURLAsset URLAssetWithURL:_videoURL options:nil];
}

/**
 设置图片提取的数量

 @param extractFrameCount 提取的数量
 */
- (void)setExtractFrameCount:(NSUInteger)extractFrameCount{
    
    _extractFrameCount = extractFrameCount;
    _extractFrameTimeInterval = self.videoDuration / _extractFrameCount * 1.0;
}


/**
 设置图片提取的时间间隔
 
 @param extractFrameTimeInterval 提取的时间间隔
 */
- (void)setExtractFrameTimeInterval:(CGFloat)extractFrameTimeInterval{
    
    if (_extractFrameCount == 0) {//同时设置优先使用_extractFrameCount
        
        _extractFrameTimeInterval = extractFrameTimeInterval;
        _extractFrameCount = self.videoDuration / _extractFrameTimeInterval * 1.0;
    }
}


/**
 所有媒体的视频总时长

 @return 视频总时长
 */
- (NSTimeInterval)videoDuration{
    if (!_videoDuration) {
        
        if (self.videoAssets.count > 0) {
            
            for (AVAsset *videoAsset in _videoAssets) {
                
                _videoDuration += CMTimeGetSeconds(videoAsset.duration);
            }
        }else{
            
            _videoDuration = CMTimeGetSeconds(self.videoAsset.duration);
        }
    }
    return _videoDuration;
}

#pragma mark -- private methods
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

@end
