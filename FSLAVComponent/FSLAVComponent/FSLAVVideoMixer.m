//
//  FSLAVVideoMixer.m
//  FSLAVComponent
//
//  Created by tutu on 2019/7/28.
//  Copyright © 2019 tutu. All rights reserved.
//

#import "FSLAVVideoMixer.h"
#import "FSLAVAssetExportSession.h"
#import "FSLAVAudioMixer.h"

@interface FSLAVVideoMixer ()<FSLAVAssetExportSessionDelegate>
{
    // 混合的composition
    AVMutableComposition    *_mixComposition;
    // 输出的 session
    FSLAVAssetExportSession *_exporter;
    // 视频 size
    CGSize _renderSize;
    
    // 回调
    void (^_handler)(NSString *filePath, FSLAVMixStatus status);
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

@end

@implementation FSLAVVideoMixer

#pragma mark - setter getter
- (void)setMixAudios:(NSArray<FSLAVAudioMixerOptions *> *)mixAudios;
{
    _mixAudios = mixAudios;
}

- (void)setMainVideo:(FSLAVVideoMixerOptions *)mainVideo{
    if(_mainVideo == mainVideo) return;
    _mainVideo = mainVideo;
    
    //将主视频配置好的内容取出来，方便使用
    _enableCycleAdd = _mainVideo.enableCycleAdd;
    _enableVideoSound = _mainVideo.enableVideoSound;
    _videoTimeRange = _mainVideo.atTimeRange;
    _videoAtNodeTime = _mainVideo.atNodeTime;
    _videoAsset = _mainVideo.mediaAsset;
}

#pragma mark -- mixing methods
/**
 初始化音视频混合器，用init初始化也可以，mainVideo都得自行配置
 
 @param mainVideo 主视频轨
 @return FSLAVAudioMixer
 */
- (instancetype)initWithMixerVideoOptions:(FSLAVVideoMixerOptions *)mainVideo;
{
    if (self = [super init]) {
        
        self.mainVideo = mainVideo;
    }
    return self;
}

/**
 开始混合音视频轨，该方法的混合音视频轨结果没有block回调过程，结果可通过协议拿到
 */
- (void)startMixingVideo;
{
    [self startMixingVideoWithCompletion:nil];
}

/**
 开始混合音视频轨，该方法的混合音视频轨结果有block回调，同时也可通过协议拿到
 */
- (void)startMixingVideoWithCompletion:(void (^ _Nullable)(NSString* , FSLAVMixStatus))handler;
{
    _needStartCompressing = NO;
    if (_mainVideo.mixStatus == FSLAVMixStatusMixing) {
        [self cancelMixing];
        _handler = handler;
        _needStartCompressing = YES;
        return;
    }
    
    if (!_mainVideo) {
        fslLError(@"have not set a valid main track");
        [self notifyStatus:FSLAVMixStatusCancelled];
        return;
    }
    
    if(!_mixComposition){
        
        //编辑素材环境，创建新组合的可变对象。保证该对象是唯一的
        _mixComposition = [[AVMutableComposition alloc]init];
    }

    // 1.优先处理视频音轨与多音频进行混合，最后返回合成音频的地址
    [self processVideoOfAudioMixWithCompletion:^(NSString *mixAudioFilePath) {
        
        //2. 导出音视频合成视频：通过视频轨编辑环境
        [self exportVideoWithMixAudioPath:mixAudioFilePath CompletionHandler:handler];
    }];
}

/**
 取消混合操作
 */
- (void)cancelMixing;
{
    [self notifyStatus:FSLAVMixStatusCancelled];
    [self resetMixOperation];
    [_mainVideo clearOutputFilePath];
}

/**
 设置默认参数配置
 */
- (void)setConfig;
{
    [super setConfig];
}

/**
 销毁对象，释放对象
 */
- (void)destory{
    [super destory];
    
    [self cancelMixing];
}

#pragma mark -- private methods

/**
 优先处理视频音轨与多音频进行混合，最后返回合成音频的地址

 @param handler 地址回调
 */
- (void)processVideoOfAudioMixWithCompletion:(void (^ _Nullable)(NSString *mixAudioFilePath))handler;
{
    //优先处理视频的音轨与音轨合成
    if (_mixAudios && _mixAudios.count > 0) {// 保留视频原音
        
        // 添加背景音乐 且 保留视频原音
        if (_mainVideo.enableVideoSound) {//保留视频原音
            //分离视频的音频轨
            NSArray *audioTracks = [_videoAsset tracksWithMediaType:AVMediaTypeAudio];
            FSLAVAudioMixerOptions *mainAudio;
            if (audioTracks.count > 0) {
                
                AVAssetTrack *mainAudioTrack = [audioTracks firstObject];
                mainAudio = [[FSLAVAudioMixerOptions alloc] init];
                mainAudio.audioTrack = mainAudioTrack;
                //是否循环添加音频
                mainAudio.enableCycleAdd = _enableCycleAdd;
                //将视频轨设置的参数赋给视频的音轨
                mainAudio.atTimeRange = _videoTimeRange;
                mainAudio.atNodeTime = _videoAtNodeTime;
            }else{
                
                fslLWarn(@"This video has no audio tracks.");
                mainAudio = [[FSLAVAudioMixerOptions alloc]init];
                mainAudio.enableCycleAdd = NO;
                mainAudio.atTimeRange = _videoTimeRange;
                mainAudio.audioVolume = 0;
            }
            
            //开始视频原音与多音频进行混合
            [self mixAudioWithMainTrack:mainAudio completionHandler:^(NSString *filePath) {
                if (handler) {
                    handler(filePath);
                }
            }];
        }else{// 不保留视频原音

            FSLAVAudioMixerOptions *mainAudio = [[FSLAVAudioMixerOptions alloc]init];
            mainAudio.enableCycleAdd = NO;
            mainAudio.atTimeRange = _videoTimeRange;
            mainAudio.audioVolume = 0;
            
            //开始视频原音与多音频进行混合
            [self mixAudioWithMainTrack:mainAudio completionHandler:^(NSString *filePath) {
                if (handler) {
                    handler(filePath);
                }
            }];
        }
    }else{//没有多音频数据
        
        // 不添加背景音乐，使用视频原声
        if (_mainVideo.enableVideoSound) {
            NSArray *audioTracks = [_videoAsset tracksWithMediaType:AVMediaTypeAudio];
            if (audioTracks.count > 0) {
                
                AVAssetTrack *mainAudioTrack = [audioTracks firstObject];
                FSLAVAudioMixerOptions *mainAudio = [[FSLAVAudioMixerOptions alloc] init];
                //是否循环添加音频
                mainAudio.enableCycleAdd = _enableCycleAdd;
                mainAudio.audioTrack = mainAudioTrack;
                //将视频轨设置的参数赋给视频的音轨
                mainAudio.atTimeRange = _videoTimeRange;
                mainAudio.atNodeTime = _videoAtNodeTime;
                
                [self mixAudioWithMainTrack:mainAudio completionHandler:^(NSString *filePath) {
                    if (handler) {
                        handler(filePath);
                    }
                }];
            }else{
                // 无音轨 输出
                if (handler) {
                    handler(nil);
                }
            }
        }else{
            // 无音轨 输出
            if (handler) {
                handler(nil);
            }
        }
    }
}


/**
 多银牌合成：保留原音时，添加背景音乐，首先 音频与音频 混合

 @param mainAudio 主音频
 @param handler 合成结果回调
 */
- (void)mixAudioWithMainTrack:(FSLAVAudioMixerOptions *)mainAudio completionHandler:(void (^)(NSString *filePath))handler;
{
    FSLAVAudioMixer *audioMix = [[FSLAVAudioMixer alloc]init];
    audioMix.mainAudio = mainAudio;
    audioMix.mixAudios = _mixAudios;
    
    [audioMix startMixingAudioWithCompletion:^(NSString *filePath, FSLAVMixStatus status) {
        if (status == FSLAVMixStatusCompleted) {
            if (handler) {
                handler(filePath);
            }
        }else if(status == FSLAVMixStatusFailed){
            
            fslLError(@"Audio mixing failure");
            [self notifyStatus:FSLAVMixStatusFailed];
        }
    }];
    
}

/**
 导出音视频合成视频：通过视频轨编辑环境
 
 @param mixAudioPath 多音频合成的导出地址
 @param handler 回调
 */
- (void)exportVideoWithMixAudioPath:(NSString *)mixAudioPath CompletionHandler:(void (^)(NSString* outputFilePath, FSLAVMixStatus status))handler;
{
    
    AVMutableAudioMix *audioMix = nil;
    if (mixAudioPath) {
        
        //1-1.创建音轨接收器。
        AVMutableCompositionTrack *compositionAudioTrack = [_mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
        AVURLAsset *audioAsset = [[AVURLAsset alloc]initWithURL:[NSURL fileURLWithPath:mixAudioPath] options:nil];
        //2-1.分离音轨
        AVAssetTrack *assetAudioTrack = [[audioAsset tracksWithMediaType:AVMediaTypeAudio] firstObject];
        NSError *error = nil;
        //3-1.在视频的合成时间节点插入该合成音频时间范围的音频轨
        [compositionAudioTrack insertTimeRange:_videoTimeRange.CMTimeRange ofTrack:assetAudioTrack atTime:_videoAtNodeTime error:&error];
        if (error) {
            fslLError(@"compositionAudioTrack insert error : %@",error);
        }
        
        //4-1.将音频轨道添加到混合时使用的参数,如：音量控制。
        AVMutableAudioMixInputParameters *mixInput = [AVMutableAudioMixInputParameters audioMixInputParametersWithTrack:compositionAudioTrack];
        //设置音轨音量
        [mixInput setVolume:_mainVideo.audioVolume atTime:_videoAtNodeTime];
        
        //5-1.创建一个可变的音频混合对象,将音频音量设置加到audioMix
        audioMix = [AVMutableAudioMix audioMix];
        audioMix.inputParameters = @[mixInput];
    }
    
    //1-2.分离视频轨
    AVAssetTrack *assetVideoTrack = [[_videoAsset tracksWithMediaType:AVMediaTypeVideo] firstObject];
    // 注：视频 音频 的duration会存在不一致的情况，所以整体时间应以 视频的时间 为准
    NSUInteger videoBitRate = (NSUInteger)[assetVideoTrack estimatedDataRate];
    CGSize videoSize = assetVideoTrack.naturalSize;
    
    //2-2.创建视频轨接收器。输出前需要调整方向 和 构建 videoComposition;
    AVMutableCompositionTrack *compositionVideoTrack = [_mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    
    //3-2.在合成时间节点插入该视频时间范围的视频轨
    NSError *error = nil;
    [compositionVideoTrack insertTimeRange:_videoTimeRange.CMTimeRange ofTrack:assetVideoTrack atTime:_videoAtNodeTime error:&error];
    if (error) {
        fslLError(@"_compositionVideoTrack insert error : %@",error);
    }
    
    //4.注意：视频方向不对会引起导出问题；调整视频方向;一个对象，用于修改应用于可变组合中给定轨道的变换、裁剪和不透明度坡道。
    AVMutableVideoCompositionLayerInstruction *layerInstruction = [self adjustVideoOrientationWith:compositionVideoTrack assetTrack:assetVideoTrack videoSize:videoSize atTime:_videoAtNodeTime];
    // 创建最终视频输出方向使用的 VideoComposition
    AVMutableVideoCompositionInstruction *mainInstruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    //指令生效的时间范围。
    mainInstruction.timeRange = _videoTimeRange.CMTimeRange;
    //指示视频帧应该如何分层和组合
    mainInstruction.layerInstructions = [NSArray arrayWithObject:layerInstruction];
    
    //5.表示可变视频合成的对象。
    AVMutableVideoComposition *mainComposition = [AVMutableVideoComposition videoComposition];
    mainComposition.instructions = [NSMutableArray arrayWithObject:mainInstruction];
    //帧率间隔：视频合成应该呈现合成视频帧的时间间隔。如：每秒显示30帧：30fps
    mainComposition.frameDuration = CMTimeMake(1, assetVideoTrack.nominalFrameRate);
    //视频合成应该呈现的大小。
    mainComposition.renderSize = _renderSize;
    //视频合成应该呈现的比例。
    mainComposition.renderScale = 1.0;
    
    //6.初始化导出素材对象导出器
    if (!_exporter) {
        
        _exporter = [[FSLAVAssetExportSession alloc] initWithAsset:_mixComposition];
        _exporter.delegate = self;
    }
    //导出视频地址
    _exporter.outputURL = _mainVideo.outputFileURL;
    //导出视频类型
    _exporter.outputFileType = _mainVideo.appOutputFileType;
    //指示是否启用视频合成导出，并提供视频合成说明。
    _exporter.videoComposition = mainComposition;
    //设置混音
    _exporter.audioMix = audioMix;
    //导出视频的时间范围
    _exporter.timeRange = CMTimeRangeMake(kCMTimeZero, _videoTimeRange.duration);
    //指示是否应优化电影以供网络使用。
    _exporter.shouldOptimizeForNetworkUse = YES;

    // 输出视频格式设置
    if (@available(iOS 11.0, *)) {
        _exporter.videoSettings = @{
                                    AVVideoCodecKey:AVVideoCodecTypeH264,
                                    AVVideoWidthKey:[NSNumber numberWithInt:_renderSize.width],
                                    AVVideoHeightKey:[NSNumber numberWithInt:_renderSize.height],
                                    AVVideoCompressionPropertiesKey:@{
                                            AVVideoAverageBitRateKey:[NSNumber numberWithInteger: (videoBitRate <= 0 ? 1000000 : videoBitRate)],
                                            AVVideoProfileLevelKey:AVVideoProfileLevelH264HighAutoLevel,
                                            },
                                    };
    } else {
        // Fallback on earlier versions
        _exporter.videoSettings = @{
                                    AVVideoCodecKey:AVVideoCodecH264,
                                    AVVideoWidthKey:[NSNumber numberWithInt:_renderSize.width],
                                    AVVideoHeightKey:[NSNumber numberWithInt:_renderSize.height],
                                    AVVideoCompressionPropertiesKey:@{
                                            AVVideoAverageBitRateKey:[NSNumber numberWithInteger: (videoBitRate <= 0 ? 1000000 : videoBitRate)],
                                            AVVideoProfileLevelKey:AVVideoProfileLevelH264HighAutoLevel,
                                            },
                                    };
    }
    // 输出音频格式设置
    _exporter.audioSettings =  @{
                                 AVFormatIDKey: @(kAudioFormatMPEG4AAC),
                                 AVNumberOfChannelsKey: @2,
                                 AVSampleRateKey: @44100,
                                 AVEncoderBitRateKey: @128000,
                                 };
    //正在合成通知回调
    [self notifyStatus:FSLAVMixStatusMixing];
    
    //7.导出视频素材
    [_exporter exportAsynchronouslyWithCompletionHandler:^{
        
        if (self->_exporter.error)
            fslLError(@"exporter error :  %@",self->_exporter.error);
        
        FSLAVMixStatus exportStatus = FSLAVMixStatusUnknown;
        switch (self->_exporter.status)
        {
            case AVAssetExportSessionStatusUnknown:
                exportStatus = FSLAVMixStatusUnknown;
                break;
            case AVAssetExportSessionStatusExporting:
                exportStatus = FSLAVMixStatusMixing;
                break;
            case AVAssetExportSessionStatusCompleted:
                exportStatus = FSLAVMixStatusCompleted;
                break;
            case AVAssetExportSessionStatusFailed:
                exportStatus = FSLAVMixStatusFailed;
                break;
            case AVAssetExportSessionStatusCancelled:
                exportStatus = FSLAVMixStatusCancelled;
                break;
            default:
                exportStatus = FSLAVMixStatusFailed;
                break;
        }
        
        //合成状态通知回调
        [self notifyStatus:exportStatus];
        //视频进度通知回调
        if (handler) {
            
            handler(self.mainVideo.outputFilePath,exportStatus);
        }
        
        //重置合成状态
        [self resetMixOperation];
    }];
}

/**
 调整视频方向
 
 @param videoTrack 加入到 composition 的合成轨道
 @param assetVideoTrack 要添加的视频轨道
 @return 视频合成的转换layer
 */
- (AVMutableVideoCompositionLayerInstruction *)adjustVideoOrientationWith:(AVMutableCompositionTrack *)videoTrack assetTrack:(AVAssetTrack *)assetVideoTrack videoSize:(CGSize)videoSize atTime:(CMTime)time;
{
    UIImageOrientation videoOrientation = UIImageOrientationUp;
    BOOL isAssetPortrait = NO;
    CGAffineTransform transform = assetVideoTrack.preferredTransform;
    
    CGFloat translationX = 0;
    CGFloat translationY = 0;
    CGFloat radio = 0;
    CGFloat videoWidth = videoSize.width;
    CGFloat videoHeight = videoSize.height;
    if (transform.a == 0 && transform.b == 1.0 && transform.c == -1.0 && transform.d == 0) {
        videoOrientation = UIImageOrientationRight;
        isAssetPortrait = YES;
        translationX = videoWidth * (videoHeight/videoWidth);
        translationY = 0;
        radio = M_PI_2;
    }else if (transform.a == 0 && transform.b == -1.0 && transform.c == 1.0 && transform.d == 0){
        videoOrientation = UIImageOrientationLeft;
        isAssetPortrait = YES;
        translationX = 0;
        translationY = videoHeight * (videoWidth/videoHeight);
        radio = M_PI_2*3;
    }else if (transform.a == -1.0 && transform.b == 0 && transform.c == 0 && transform.d == -1.0){
        videoOrientation = UIImageOrientationDown;
        translationX = videoWidth;
        translationY = videoHeight;
        radio = M_PI;
    }else{
        videoOrientation = UIImageOrientationUp;
        translationX = 0;
        translationY = 0;
        radio = 0;
    }
    
    CGAffineTransform rotation = CGAffineTransformMakeRotation(radio);
    CGAffineTransform translateToCenter = CGAffineTransformMakeTranslation(translationX, translationY);
    CGAffineTransform mixedTransform = CGAffineTransformConcat(rotation, translateToCenter);
    
    if (isAssetPortrait ) {
        //交换宽高
        CGSize tempSize = videoSize;
        videoSize = CGSizeMake(tempSize.height, tempSize.width);
    }
    if (CGSizeEqualToSize(_renderSize, CGSizeZero)) {
        _renderSize = videoSize;
    }
    // 调整视频方向
    AVMutableVideoCompositionLayerInstruction * layerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoTrack];
    [layerInstruction setTransform:mixedTransform atTime:time];
    
    return layerInstruction;
}


// 重置混合状态
- (void)resetMixOperation;
{
    if (_exporter.status == AVAssetExportSessionStatusExporting || _exporter.status == AVAssetExportSessionStatusWaiting) {
        if (_exporter) {
            [_exporter cancelExport];
        }
    }else{
        if (_exporter) {
            [_exporter cancelExport];
        }
        if (_mixComposition) {
            [[_mixComposition tracks] enumerateObjectsUsingBlock:^(AVMutableCompositionTrack * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                [self->_mixComposition removeTrack:obj];
            }];
        }
        
        _exporter = nil;
        _mixComposition = nil;
    }
}

/**
 设置回调通知，并委托协议
 
 @param status 回调的混合状态
 */
- (void)notifyStatus:(FSLAVMixStatus)status;
{
    if (self.mainVideo.mixStatus == status) return;
    self.mainVideo.mixStatus = status;

    dispatch_sync(dispatch_get_main_queue(), ^{
        
        //合成的状态
        if ([self.mixDelegate respondsToSelector:@selector(didMixingVideoStatusChanged:onVideoMix:)]) {
            [self.mixDelegate didMixingVideoStatusChanged:status onVideoMix:self];
        }
        if (status == FSLAVMixStatusCompleted) {
            
            //合成的所有结果返回
            if ([self.mixDelegate respondsToSelector:@selector(didMixedVideoResult:onVideoMix:)]) {
                [self.mixDelegate didMixedVideoResult:self.mainVideo onVideoMix:self];
            }
            //合成视频的输出地址返回
            if ([self.mixDelegate respondsToSelector:@selector(didCompletedMixVideoOutputFilePath:onVideoMix:)]) {
                [self.mixDelegate didCompletedMixVideoOutputFilePath:self.mainVideo.outputFilePath onVideoMix:self];
            }
            //合成视频的输出总时长返回
            if ([self.mixDelegate respondsToSelector:@selector(didCompletedMixVideoTotalTime:onVideoMix:)]) {
                [self.mixDelegate didCompletedMixVideoTotalTime:CMTimeGetSeconds(self.videoTimeRange.duration) onVideoMix:self];
            }
        }
    });
}


/**
 通知音视频合成进度
 
 @param progress 当前进度
 */
- (void)notifyProgress:(CGFloat)progress{

    dispatch_sync(dispatch_get_main_queue(), ^{
    
        if ([self.mixDelegate respondsToSelector:@selector(didMixingVideoProgressChanged:onVideoMix:)]) {
            [self.mixDelegate didMixingVideoProgressChanged:progress onVideoMix:self];
        }
    });
}

#pragma mark - FSLAVAssetExportSessionDelegate
- (void)exportSession:(FSLAVAssetExportSession *)exportSession notifyStatus:(AVAssetExportSessionStatus)status;
{
    if (status == AVAssetExportSessionStatusCancelled) {
        
        if (_needStartCompressing) {
            [self startMixingVideoWithCompletion:_handler];
            _handler = nil;
        }
    }
}

/**
 导出器的视频合成进度回调

 @param exportSession 导出器
 @param progress 进度
 */
- (void)exportSession:(FSLAVAssetExportSession *)exportSession progress:(CGFloat)progress{
    //合成进度
    [self notifyProgress:progress];
    //fslLDebug(@"dddddd--->%f",progress);
}

@end
