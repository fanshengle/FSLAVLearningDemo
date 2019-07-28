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
// 保存到本地FSLAVSandboxDirType下的音视频文件Str路径
@property (nonatomic, strong) NSString *outputFilePath;

@end

@implementation FSLAVVideoMixer

#pragma mark - setter getter
- (void)setMixAudios:(NSArray<FSLAVMixerOptions *> *)mixAudios;
{
    _mixAudios = mixAudios;
}

- (void)setMainVideo:(FSLAVMixerOptions *)mainVideo{
    if(_mainVideo == mainVideo) return;
    _mainVideo = mainVideo;
    
    _enableCycleAdd = _mainVideo.enableCycleAdd;
    _enableVideoSound = _mainVideo.enableVideoSound;
    _videoTimeRange = _mainVideo.atTimeRange;
    _videoAtNodeTime = _mainVideo.atNodeTime;
    _videoAsset = _mainVideo.mediaAsset;
    _outputFilePath = _mainVideo.outputFilePath;
}

/**
 设置默认参数配置
 */
- (void)setConfig;
{
    [super setConfig];
    _mainVideo.meidaType = FSLAVMediaTypeVideo;
}

#pragma mark -- mixing methods
/**
 初始化音视频混合器，用init初始化也可以，mainVideo都得自行配置
 
 @param mainVideo 主视频轨
 @return FSLAVAudioMixer
 */
- (instancetype)initWithMixerVideoOptions:(FSLAVMixerOptions *)mainVideo;
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
    

    typeof(self) weakSelf = self;
    // 1.优先处理视频音轨与多音频进行混合，最后返回合成音频的地址
    [self processVideoOfAudioMixWithCompletion:^(NSString *mixAudioFilePath) {
        
        //2. 导出音视频合成视频：通过视频轨编辑环境
        [weakSelf exportVideoWithMixAudioPath:mixAudioFilePath CompletionHandler:handler];
    }];
}


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
            FSLAVMixerOptions *mainAudio;
            if (audioTracks.count > 0) {
                
                AVAssetTrack *mainAudioTrack = [audioTracks firstObject];
                mainAudio = [[FSLAVMixerOptions alloc] init];
                mainAudio.mediaTrack = mainAudioTrack;
                //是否循环添加音频
                mainAudio.enableCycleAdd = _enableCycleAdd;
                //将视频轨设置的参数赋给视频的音轨
                mainAudio.atTimeRange = _videoTimeRange;
                mainAudio.atNodeTime = _videoAtNodeTime;
            }else{
                
                fslLError(@"This video has no audio tracks.");
                mainAudio = [[FSLAVMixerOptions alloc]init];
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

            FSLAVMixerOptions *mainAudio = [[FSLAVMixerOptions alloc]init];
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
                FSLAVMixerOptions *mainAudio = [[FSLAVMixerOptions alloc] init];
                //是否循环添加音频
                mainAudio.enableCycleAdd = _enableCycleAdd;
                mainAudio.mediaTrack = mainAudioTrack;
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

// 保留原音时，添加背景音乐，首先 音频与音频 混合
- (void)mixAudioWithMainTrack:(FSLAVMixerOptions *)mainAudio completionHandler:(void (^)(NSString *filePath))handler;
{
    FSLAVAudioMixer *audioMix = [[FSLAVAudioMixer alloc]init];
    audioMix.mainAudio = mainAudio;
    audioMix.mixAudios = _mixAudios;
    
    [audioMix startMixingAudioWithCompletion:^(NSString *filePath, FSLAVMixStatus status) {
        if (status == FSLAVMixStatusCompleted) {
            if (handler) {
                handler(filePath);
            }
        }else{
            
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
    }
    
    //1-2.分离视频轨
    AVAssetTrack *assetVideoTrack = [[_videoAsset tracksWithMediaType:AVMediaTypeVideo] firstObject];
    // 注：视频 音频 的duration会存在不一致的情况，所以整体时间应以 视频的时间 为准
    NSUInteger videoBitRate = (NSUInteger)[assetVideoTrack estimatedDataRate];
    _renderSize = assetVideoTrack.naturalSize;
    
    //2-2.创建视频轨接收器。输出前需要调整方向 和 构建 videoComposition;
    AVMutableCompositionTrack *compositionVideoTrack = [_mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    
    //3-2.在合成时间节点插入该视频时间范围的视频轨
    NSError *error = nil;
    [compositionVideoTrack insertTimeRange:_videoTimeRange.CMTimeRange ofTrack:assetVideoTrack atTime:_videoAtNodeTime error:&error];
    if (error) {
        fslLError(@"_compositionVideoTrack insert error : %@",error);
    }
    
    //4.注意：视频方向不对会引起导出问题；调整视频方向;一个对象，用于修改应用于可变组合中给定轨道的变换、裁剪和不透明度坡道。
    AVMutableVideoCompositionLayerInstruction *layerInstruction = [self adjustVideoOrientationWith:compositionVideoTrack assetTrack:assetVideoTrack];
    // 创建最终视频输出方向使用的 VideoComposition
    AVMutableVideoCompositionInstruction *mainInstruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    //指令生效的时间范围。
    mainInstruction.timeRange = _videoTimeRange.CMTimeRange;
    //指示视频帧应该如何分层和组合
    mainInstruction.layerInstructions = [NSArray arrayWithObject:layerInstruction];
    
    //5.表示可变视频合成的对象。
    AVMutableVideoComposition *mainComposition = [AVMutableVideoComposition videoComposition];
    mainComposition.instructions = [NSMutableArray arrayWithObject:mainInstruction];
    //帧率间隔：视频合成应该呈现合成视频帧的时间间隔。
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
        self.mainVideo.mixStatus = exportStatus;
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
- (AVMutableVideoCompositionLayerInstruction *)adjustVideoOrientationWith:(AVMutableCompositionTrack *)videoTrack assetTrack:(AVAssetTrack *)assetVideoTrack;
{
    UIImageOrientation videoOrientation = UIImageOrientationUp;
    //判断方向是否改变了
    BOOL isAssetPortrait = NO;
    /**
     用于绘制二维图形的仿射变换矩阵:在轨道的存储容器中指定的转换。 放大、缩小、平移
     a: 对应sx就是视图宽放大或缩小的比例，初始值1，一倍大小。
     b: 旋转会用到，初始值0。
     c: 旋转会用到，初始值0。
     d: 对应sy就是视图高放大或缩小的比例，初始值1，一倍大小。
     tx: 视图x轴平移，初始值0，没有平移。
     ty: 视图y轴平移，初始值0，没有平移。
     CGAffineTransform的（a，b，c，d，tx，ty）：默认：[ 1 0 0 1 0 0 ]
     */
    CGAffineTransform transform = assetVideoTrack.preferredTransform;
    
    CGFloat translationX = 0;
    CGFloat translationY = 0;
    CGFloat radio = 0;
    CGFloat videoWidth = _renderSize.width;
    CGFloat videoHeight = _renderSize.height;
    
    if (transform.a == 0 && transform.b == 1.0 && transform.c == -1.0 && transform.d == 0) {
        videoOrientation = UIImageOrientationRight;
        isAssetPortrait = YES;
        translationX = videoWidth * (videoHeight/videoWidth);
        translationY = 0;
        radio = M_PI_2;
    }else if (transform.a == 0 && transform.b == -1.0 && transform.c == 1.0 && transform.d == 0) {
        videoOrientation = UIImageOrientationLeft;
        isAssetPortrait = YES;
        translationY = videoHeight * (videoWidth/videoHeight);
        radio = M_PI_2*3;
    }else if (transform.a == -1.0 && transform.b == 0 && transform.c == 0 && transform.d == -1.0) {
        videoOrientation = UIImageOrientationDown;
        translationX = videoWidth;
        translationY = videoHeight;
        radio = M_PI;
    }else{
        //正常
        videoOrientation = UIImageOrientationUp;
        translationX = 0;
        translationY = 0;
        radio = 0;
    }
    
    
    // 旋转
    CGAffineTransform rotation = CGAffineTransformMakeRotation(radio);
    // 平移
    CGAffineTransform translateToCenter = CGAffineTransformMakeTranslation(translationX, translationY);
    //返回由组合两个现有仿射变换构造的仿射变换矩阵。
    CGAffineTransform mixedTransform = CGAffineTransformConcat(rotation, translateToCenter);
    
    if (isAssetPortrait) {
        //交换宽高
        CGSize tempSize = _renderSize;
        _renderSize = CGSizeMake(tempSize.height, tempSize.width);
    }
    
    // 调整视频方向
    AVMutableVideoCompositionLayerInstruction *layerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoTrack];
    //在指令的时间范围内每次设置转换值。
    [layerInstruction setTransform:mixedTransform atTime:kCMTimeZero];
    
    return layerInstruction;
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

#pragma mark -- private methods
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
        _exporter = nil;
    }
}

/**
 设置回调通知，并委托协议
 
 @param status 回调的混合状态
 */
- (void)notifyStatus:(FSLAVMixStatus)status;
{
    if (![NSThread isMainThread]) {
        dispatch_sync(dispatch_get_main_queue(), ^{
            if ([self.mixDelegate respondsToSelector:@selector(didMixingVideoStatusChanged:onVideoMix:)]) {
                [self.mixDelegate didMixingVideoStatusChanged:status onVideoMix:self];
            }
        });
    }else{
        //合成的状态
        if ([self.mixDelegate respondsToSelector:@selector(didMixingVideoStatusChanged:onVideoMix:)]) {
            [self.mixDelegate didMixingVideoStatusChanged:status onVideoMix:self];
        }
    }
    if (status == FSLAVMixStatusCompleted) {
        
        //合成的所有结果返回
        if ([self.mixDelegate respondsToSelector:@selector(didMixedVideoResult:onVideoMix:)]) {
            [self.mixDelegate didMixedVideoResult:_mainVideo onVideoMix:self];
        }
        //合成视频的输出地址返回
        if ([self.mixDelegate respondsToSelector:@selector(didCompletedMixVideoOutputFilePath:onVideoMix:)]) {
            [self.mixDelegate didCompletedMixVideoOutputFilePath:_mainVideo.outputFilePath onVideoMix:self];
        }
        if ([self.mixDelegate respondsToSelector:@selector(didCompletedCompositionMediaTotalTime:onVideoMix:)]) {
            [self.mixDelegate didCompletedCompositionMediaTotalTime:CMTimeGetSeconds(_mainVideo.atTimeRange.duration) onVideoMix:self];
        }
    }
}


/**
 通知分段时间片段合成进度
 
 @param progress 当前进度
 */
- (void)notifyProgress:(CGFloat)progress{

    if ([self.mixDelegate respondsToSelector:@selector(didMixingVideoProgressChanged:onVideoMix:)]) {
        [self.mixDelegate didMixingVideoProgressChanged:progress onVideoMix:self];
    }
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

/**
 销毁对象，释放对象
 */
- (void)destory{
    [super destory];
    
}
@end
