//
//  FSLAVVideoClipper.m
//  FSLAVComponent
//
//  Created by tutu on 2019/8/1.
//  Copyright © 2019 tutu. All rights reserved.
//

#import "FSLAVVideoClipper.h"
#import "FSLAVAssetExportSession.h"

@interface FSLAVVideoClipper ()
{
    // 混合的composition
    AVMutableComposition    *_mixComposition;
    // 输出的 session
    FSLAVAssetExportSession *_exporter;
    // 视频 size
    CGSize _renderSize;
    
    // 回调
    void (^_handler)(NSString *filePath, FSLAVClipStatus status);
    // 是否需要手动调用start
    BOOL _needStartCompressing;
}


// 音频是否可循环 默认 NO 不循环
@property (nonatomic, assign) BOOL enableCycleAdd;
// 是否保留视频原音，默认 YES，保留视频原音
@property (nonatomic, assign) BOOL enableVideoSound;
// 校验视频时间范围
@property (nonatomic, strong) FSLAVTimeRange *videoTimeRange;
// 开始合成的时间节点（设置该时间可以控制在什么时间点进行合成。注意：一定要在主（视频轨、音轨）的时间范围内。
@property (nonatomic, assign) CMTime videoAtNodeTime;
// 媒体素材 mediaAsset
@property (nonatomic, strong) AVAsset *videoAsset;
// 保存到本地FSLAVSandboxDirType下的音视频文件Str路径
@property (nonatomic, strong) NSString *outputFilePath;

@end

@implementation FSLAVVideoClipper

/**
 初始化音视频混合器，用init初始化也可以，mainVideo都得自行配置
 
 @param clipVideo 主视频轨
 @return FSLAVvideoClipper
 */
- (instancetype)initWithClipperVideoOptions:(FSLAVVideoClipperOptions *)clipVideo;
{
    if (self = [super init]) {
        _clipVideo = clipVideo;
        
    }
    return self;
}


#pragma mark -- setter getter

- (void)setClipVideo:(FSLAVVideoClipperOptions *)clipVideo{
    _clipVideo = clipVideo;
    
    //将主视频配置好的内容取出来，方便使用
    _enableCycleAdd = _mainVideo.enableCycleAdd;
    _enableVideoSound = _mainVideo.enableVideoSound;
    _videoTimeRange = _mainVideo.atTimeRange;
    _videoAtNodeTime = _mainVideo.atNodeTime;
    _videoAsset = _mainVideo.mediaAsset;
    _outputFilePath = _mainVideo.outputFilePath;
    
}
#pragma mark -- public methods

/**
 开始混合音视频轨，该方法的混合音视频轨结果没有block回调过程，结果可通过协议拿到
 */
- (void)startClippingVideo;
{
    [self startClippingVideoWithCompletion:nil];
}

/**
 开始混合音视频轨，该方法的混合音视频轨结果有block回调，同时也可通过协议拿到
 */
- (void)startClippingVideoWithCompletion:(void (^ _Nullable)(NSString *filePath, FSLAVClipStatus status))handler;
{
    _needStartCompressing = NO;
    if (_mainVideo.mixStatus == FSLAVClipStatusClipping) {
        [self cancelClipping];
        _handler = handler;
        _needStartCompressing = YES;
        return;
    }
    
    
}

/**
 取消混合操作
 */
- (void)cancelClipping;
{
    
}

#pragma mark -- private methods



@end
