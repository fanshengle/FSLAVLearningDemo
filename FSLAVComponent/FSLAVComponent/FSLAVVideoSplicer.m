//
//  FSLAVVideoSplicer.m
//  FSLAVComponent
//
//  Created by TuSDK on 2019/8/15.
//  Copyright © 2019 tutu. All rights reserved.
//

#import "FSLAVVideoSplicer.h"
#import "FSLAVAssetExportSession.h"

@interface FSLAVVideoSplicer ()<FSLAVAssetExportSessionDelegate>

// 音轨混合(音量)数组
@property (nonatomic,strong) NSMutableArray<AVMutableAudioMixInputParameters *>  *audioMixParams;
// 视频拼接（调整视频方向）数组
@property (nonatomic,strong) NSMutableArray<AVMutableVideoCompositionLayerInstruction *>  *layerInstructions;
// 视频合并对象
@property (nonatomic,strong) AVMutableComposition  *spliceComposition;
// 输出的 session
@property (nonatomic,strong) FSLAVAssetExportSession  *exporter;
// 视频 size
@property (nonatomic,assign) CGSize renderSize;
// 视频 码率
@property (nonatomic,assign) float videoBitRate;
// 视频 最大帧率
@property (nonatomic,assign) float maxFrameRate;
// 合并的视频总时长
@property (nonatomic,assign) CMTime totalDuration;

@end

@implementation FSLAVVideoSplicer

- (FSLAVVideoSplicerOptions *)spliceOptions;
{
    if (!_spliceOptions) {
        
        _spliceOptions = [[FSLAVVideoSplicerOptions alloc] init];
    }
    return _spliceOptions;
}

#pragma mark -- init
/**
 初始化视频拼接器，用init初始化也可以，需要另外配置videos
 
 @param spliceOptions 拼接视频的配置项
 @return FSLAVVideoSplicer
 */
- (instancetype)initWithSplicerOptions:(FSLAVVideoSplicerOptions *)spliceOptions;
{
    if (self = [super init]) {
        self.spliceOptions = spliceOptions;
    }
    return self;
}

/**
 初始化视频拼接器，用init初始化也可以，需要另外配置videos
 
 @param videos 多视频数组
 @return FSLAVVideoSplicer
 */
- (instancetype)initWithSplicerVideos:(NSArray <FSLAVVideoSplicerOptions *> *)videos;
{

    if (self = [super init]) {
        _videos = videos;
    }
    return self;
}

#pragma mark -- public methods

/**
 * 开始合并视频操作
 */
- (void)startSplicing;
{
    [self startSplicingWithCompletionHandler:nil];
}

/**
 * 开始合并视频操作 block回调
 */
- (void)startSplicingWithCompletionHandler:(void (^ _Nullable)(NSString *filePath, FSLAVSpliceStatus status))handler;
{
    
    if( !_videos || _videos.count == 0)
    {
        fslLError(@"FSLAVVideoSplicer: Invalid movies");
        [self notifyStatus:FSLAVSpliceStatusFailed];
        return;
    }
    
    if (!_audioMixParams) {
        
        _audioMixParams = [NSMutableArray arrayWithCapacity:_videos.count];
    }
    
    if (!_layerInstructions) {
        
        _layerInstructions = [NSMutableArray arrayWithCapacity:_videos.count];
    }
    
    if (!_spliceComposition) {
        
        _spliceComposition = [[AVMutableComposition alloc] init];
    }
    
    // 1.拼接视频
    [self spliceVideos:_videos];
    
    // 2.得到视频说明信息拼接后的VideoComposition对象，在导出时需要用到。
    AVMutableVideoComposition *mainComposition = [self videoCompositionWithTimeRange:CMTimeRangeMake(kCMTimeZero, self.totalDuration)];
    
    // 3.导出拼接视频
    [self exportAsynchronouslyWithVideoCompostion:mainComposition completionHandler:handler];
}

/**
 * 取消合并操作
 */
- (void)cancelSplicing;
{
    [self notifyStatus:FSLAVSpliceStatusCancelled];
    [self resetSplicerOperation];
    [_spliceOptions clearOutputFilePath];
}

/**
 设置默认参数配置
 */
- (void)setConfig;
{
    [super setConfig];
    
    _maxFrameRate = 0;
    _videoBitRate = 0;
    _totalDuration = kCMTimeZero;
}

/**
 销毁对象，释放对象
 */
- (void)destory{
    [super destory];
    
    [self cancelSplicing];
}

#pragma mark -- private methods

/**
 拼接多视频处理
 
 @param videos 多视频数组
 */
- (void)spliceVideos:(NSArray <FSLAVVideoSplicerOptions *> *)videos{
    if(!_videos) _videos = videos;
    
    //遍历处理多视频
    [videos enumerateObjectsUsingBlock:^(FSLAVVideoSplicerOptions * _Nonnull video, NSUInteger i, BOOL * _Nonnull stop) {
        
        //添加音轨编辑
        [self addAudioTrackWithVideo:video atIndex:i];
        //添加视频轨编辑
        [self addVideoTrackWithVideo:video atIndex:i];
        
        // 记录拼接时间节点，也是拼接视频最后的总时长
        self.totalDuration = CMTimeAdd(self.totalDuration, video.atTimeRange.duration);
    }];
    
    //更新视频拼接的总时长
    _spliceOptions.mediaDuration = CMTimeGetSeconds(self.totalDuration);
}


/**
 异步导出拼接视频
 
 @param videoCompostion AVMutableVideoComposition
 @param handler 回调
 */
- (void)exportAsynchronouslyWithVideoCompostion:(AVMutableVideoComposition *)videoCompostion completionHandler:(void (^ _Nullable)(NSString *filePath, FSLAVSpliceStatus status))handler;
{
    // 创建一个可变的音频混合对象
    AVMutableAudioMix *audioMix = [AVMutableAudioMix audioMix];
    audioMix.inputParameters = [NSArray arrayWithArray:_audioMixParams];
    
    if (!_exporter) {
        _exporter = [[FSLAVAssetExportSession alloc] initWithAsset:self.spliceComposition];
        _exporter.delegate = self;
    }
    _exporter.outputFileType = self.spliceOptions.appOutputFileType;
    _exporter.outputURL = self.spliceOptions.outputFileURL;
    _exporter.audioMix = audioMix;
    _exporter.videoComposition = videoCompostion;
    _exporter.timeRange = CMTimeRangeMake(kCMTimeZero , self.totalDuration);
    _exporter.shouldOptimizeForNetworkUse = YES;

    // 输出视频格式设置
    if (@available(iOS 11.0, *)) {
        _exporter.videoSettings = @{
                                    AVVideoCodecKey:AVVideoCodecTypeH264,
                                    AVVideoWidthKey:[NSNumber numberWithInt:_renderSize.width],
                                    AVVideoHeightKey:[NSNumber numberWithInt:_renderSize.height],
                                    AVVideoCompressionPropertiesKey:@{
                                            AVVideoAverageBitRateKey:[NSNumber numberWithInteger: (_videoBitRate <= 0 ? 1000000 : _videoBitRate)],
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
                                            AVVideoAverageBitRateKey:[NSNumber numberWithInteger: (_videoBitRate <= 0 ? 1000000 : _videoBitRate)],
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
    [self notifyStatus:FSLAVSpliceStatusMerging];
    
    //导出视频素材
    [_exporter exportAsynchronouslyWithCompletionHandler:^{
        
        if (self.exporter.error)
            fslLError(@"exporter error :  %@",self->_exporter.error);
        
        FSLAVSpliceStatus exportStatus = FSLAVSpliceStatusUnknown;
        switch (self.exporter.status)
        {
            case AVAssetExportSessionStatusUnknown:
                exportStatus = FSLAVSpliceStatusUnknown;
                break;
            case AVAssetExportSessionStatusExporting:
                exportStatus = FSLAVSpliceStatusMerging;
                break;
            case AVAssetExportSessionStatusCompleted:
                exportStatus = FSLAVSpliceStatusCompleted;
                break;
            case AVAssetExportSessionStatusFailed:
                exportStatus = FSLAVSpliceStatusFailed;
                break;
            case AVAssetExportSessionStatusCancelled:
                exportStatus = FSLAVSpliceStatusCancelled;
                break;
            default:
                exportStatus = FSLAVSpliceStatusFailed;
                break;
        }
        
        //合成状态通知回调
        [self notifyStatus:exportStatus];
        //视频进度通知回调
        if (handler) {
            
            handler(self.spliceOptions.outputFilePath,exportStatus);
        }
        
        //重置合成状态
        [self resetSplicerOperation];
    }];
}

/**
 添加音轨到混合编辑音轨组合下
 
 @param video 单个视频
 @param index 多视频遍历的当前索引
 @return 返回是否添加成功
 */
- (BOOL)addAudioTrackWithVideo:(FSLAVVideoSplicerOptions *)video atIndex:(NSInteger)index;
{
    
    //保留视频的原音，则处理音频轨
    if (video.enableVideoSound)
    {
        NSArray<AVAssetTrack *> *audioTracks = [video.mediaAsset tracksWithMediaType:AVMediaTypeAudio];
        if (audioTracks.count > 0) {
            
            // 1.分离音轨
            AVAssetTrack *audioAssetTrack = audioTracks.firstObject;
            // 2.创建音轨编辑组合环境
            AVMutableCompositionTrack *compositionAudioTrack = [self.spliceComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
            // 3.添加到音频通道中
            NSError *errorAudio = nil;
            [compositionAudioTrack insertTimeRange:video.atTimeRange.CMTimeRange ofTrack:audioAssetTrack atTime:self.totalDuration error:&errorAudio];
            if (errorAudio)  fslLError(@"Error while add audio track (%d): %@",index,errorAudio);
            
            //4.将音频轨道添加到混合时使用的参数,如：音量控制。
            AVMutableAudioMixInputParameters *mixInput = [AVMutableAudioMixInputParameters audioMixInputParametersWithTrack:compositionAudioTrack];
            //设置音轨音量
            [mixInput setVolume:video.audioVolume atTime:self.totalDuration];
            //保存每个音频音量输入对象
            [self.audioMixParams addObject:mixInput];
            return YES;
        }else{
            
            fslLError(@"This video has no audio tracks.");
            return NO;
        }
    }else{
        
        return NO;
    }
}

/**
 添加视频轨到混合编辑视频轨组合下
 
 @param video 单个视频
 @param index 多视频遍历的当前索引
 @return 返回是否添加成功
 */
- (BOOL)addVideoTrackWithVideo:(FSLAVVideoSplicerOptions *)video atIndex:(NSInteger)index;
{
    NSArray<AVAssetTrack *> *videoTracks = [video.mediaAsset tracksWithMediaType:AVMediaTypeVideo];
    if (videoTracks.count > 0) {
        
        // 1.分离视频轨
        AVAssetTrack *videoAssetTrack = videoTracks.firstObject;
        // 记录视频 size
        CGSize videoSize = videoAssetTrack.naturalSize;
        // 记录最大帧率,按最大的帧率输出，反之，最小帧率输出
        CGFloat frameRate = videoAssetTrack.nominalFrameRate;
        self.maxFrameRate = MAX(frameRate, self.maxFrameRate);
        // 记录最码率,按最大的码率输出，反之，最小码率输出
        self.videoBitRate = MAX(self.videoBitRate, [videoAssetTrack estimatedDataRate]);
        
        // 2.创建视频轨编辑组合环境
        AVMutableCompositionTrack *compositionVideoTrack = [self.spliceComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
        
        // 3.添加到视频轨通道中
        NSError *errorVideo = nil;
        [compositionVideoTrack insertTimeRange:video.atTimeRange.CMTimeRange ofTrack:videoAssetTrack atTime:self.totalDuration error:&errorVideo];
        if (errorVideo)  fslLError(@"Error while add video track (%d): %@",index,errorVideo);
        //4.注意：视频方向不对会引起导出问题；调整视频方向;一个对象，用于修改应用于可变组合中给定轨道的变换、裁剪和不透明度坡道。
        AVMutableVideoCompositionLayerInstruction *layerInstruction = [self adjustVideoOrientationWith:compositionVideoTrack assetTrack:videoAssetTrack videoSize:videoSize atTime:self.totalDuration];
        if (index != self.videos.count - 1) {
            //在指令的时间范围内的特定时间设置不透明度值。
            [layerInstruction setOpacity:0.0 atTime:self.totalDuration];
        }
        // 将视频方向调整对象添加到数组，保存视频方向调整对象
        [self.layerInstructions addObject:layerInstruction];
        return YES;
    }else{
        
        fslLError(@"This video has no video tracks.");
        return NO;
    }
}

/**
 视频说明信息的拼接，如：视频方向调整、帧率、码率、比例
 
 @param timeRange 时间范围
 @return AVMutableVideoComposition
 */
- (AVMutableVideoComposition *)videoCompositionWithTimeRange:(CMTimeRange)timeRange;
{
    // 5.创建最终视频输出方向使用的 VideoComposition
    AVMutableVideoCompositionInstruction *mainInstruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    //指令生效的时间范围。
    mainInstruction.timeRange = timeRange;
    //指示视频帧应该如何分层和组合
    mainInstruction.layerInstructions = self.layerInstructions;
    
    // 6.表示可变视频合成的对象。
    AVMutableVideoComposition *mainComposition = [AVMutableVideoComposition videoComposition];
    mainComposition.instructions = [NSMutableArray arrayWithObject:mainInstruction];
    //帧率间隔：视频合成应该呈现合成视频帧的时间间隔。如：每秒显示30帧：30fps
    mainComposition.frameDuration = CMTimeMake(1, self.maxFrameRate);
    //视频合成应该呈现的大小。
    mainComposition.renderSize = self.renderSize;
    //视频合成应该呈现的比例。
    mainComposition.renderScale = 1.0;
    
    return mainComposition;
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

/**
 重置拼接状态
 */
- (void)resetSplicerOperation;
{
    if (_exporter.status == AVAssetExportSessionStatusExporting || _exporter.status == AVAssetExportSessionStatusWaiting) {
        fslLError(@"Conditions cannot be reset during operation.");
        if (_exporter) {
            [_exporter cancelExport];
        }
    }else{
        if (_exporter) {
            [_exporter cancelExport];
        }
        if (_spliceComposition) {
            [[_spliceComposition tracks] enumerateObjectsUsingBlock:^(AVMutableCompositionTrack * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                [self.spliceComposition removeTrack:obj];
            }];
        }
        
        _spliceComposition = nil;
        _exporter = nil;
        _totalDuration = kCMTimeZero;
    }
}


/**
 多视频拼接的状态通知

 @param status 拼接所处的状态
 */
- (void)notifyStatus:(FSLAVSpliceStatus)status;
{
    if (self.spliceOptions.spliceStatus == status) return;
    self.spliceOptions.spliceStatus = status;
    
    dispatch_sync(dispatch_get_main_queue(), ^{
        
        //拼接的状态
        if ([self.spliceDelegate respondsToSelector:@selector(didSplicingVideoStatusChanged:onVideoSplice:)]) {
            [self.spliceDelegate didSplicingVideoStatusChanged:status onVideoSplice:self];
        }
        
        if (status == FSLAVSpliceStatusCompleted) {
            
            //拼接的所有结果返回
            if ([self.spliceDelegate respondsToSelector:@selector(didSplicedVideoResult:onVideoSplice:)]) {
                [self.spliceDelegate didSplicedVideoResult:self.spliceOptions onVideoSplice:self];
            }
            //拼接视频的输出地址返回
            if ([self.spliceDelegate respondsToSelector:@selector(didCompletedSpliceVideoOutputFilePath:onVideoSplice:)]) {
                [self.spliceDelegate didCompletedSpliceVideoOutputFilePath:self.spliceOptions.outputFilePath onVideoSplice:self];
            }
            //拼接视频的输出总时长
            if ([self.spliceDelegate respondsToSelector:@selector(didCompletedSpliceMediaTotalTime:onVideoSplice:)]) {
                [self.spliceDelegate didCompletedSpliceMediaTotalTime:CMTimeGetSeconds(self.totalDuration) onVideoSplice:self];
            }
        }
    });
}

/**
 通知视频拼接进度
 
 @param progress 当前进度
 */
- (void)notifyProgress:(CGFloat)progress{
    
    dispatch_sync(dispatch_get_main_queue(), ^{
        
        if ([self.spliceDelegate respondsToSelector:@selector(didSplicingVideoProgressChanged:onVideoSplice:)]) {
            [self.spliceDelegate didSplicingVideoProgressChanged:progress onVideoSplice:self];
        }
    });
}

#pragma mark -- FSLAVAssetExportSessionDelegate
- (void)exportSession:(FSLAVAssetExportSession *)exportSession progress:(CGFloat)progress{
    [self notifyProgress:progress];
    //fslLDebug(@"dddddd--->%f",progress);
}

@end
