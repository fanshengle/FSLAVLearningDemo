//
//  FSLAVMediaTimelineSliceComposition.m
//  FSLAVComponent
//
//  Created by tutu on 2019/7/21.
//  Copyright © 2019 tutu. All rights reserved.
//

#import "FSLAVMediaTimelineSliceComposition.h"

@interface FSLAVMediaTimelineSliceComposition()
{
    // 混合的composition
    AVMutableComposition    *_mixComposition;
    // 输出的 session
    FSLAVAssetExportSession *_exporter;
    // 音视频 asset
    AVURLAsset *_mediaAsset;
    
    // 视频码率
    NSUInteger _videoBitRate;
    // 视频size
    CGSize _renderSize;
    
    // 视频总长时间
    CMTime _mediaTotalTime;
    // 视频总长时间
    CMTime allTime;
}

@end

@implementation FSLAVMediaTimelineSliceComposition

#pragma mark -- public methods

/**
 初始化媒体音视频分段时间片编辑器，用init初始化也可以，timeSliceOptions都得自行配置
 
 @param timeSliceOptions 分段时间片编辑配置项
 @return FSLAVMediaTimelineSliceComposition
 */
- (instancetype)initWithTimeSliceCompositionOptions:(FSLAVMediaTimelineSliceOptions *)timeSliceOptions;
{
    if (self == [super init]) {
        _timeSliceOptions = timeSliceOptions;
        
        [self initMediaAsset];
    }
    return self;
}

/**
 初始化媒体素材
 */
- (void)initMediaAsset{
    if (!_mediaAsset) {
        
        //一个布尔值，指示是否应准备好资产以指示精确的持续时间并按时间提供精确的随机访问。
        NSDictionary *options = @{AVURLAssetPreferPreciseDurationAndTimingKey:@NO};
        _mediaAsset = [AVURLAsset URLAssetWithURL:[NSURL fileURLWithPath:_timeSliceOptions.mediaPath] options:options];
        
        //获取原媒体总长时间
        _mediaTotalTime = _mediaAsset.duration;
    }
}

#pragma mark -- 可以处理视频或音频
/**
 * 开始音视频分段时间切片（包括录制变速处理）合成
 */
- (void)startMediaComposition;
{
    switch (_timeSliceOptions.meidaType) {
        case FSLAVMediaTypeAudio:
            [self startAudioComposition];
            break;
        case FSLAVMediaTypeVideo:
            [self startMediaComposition];
            break;
        default:
            break;
    }
}

/**
 * 开始音视频分段时间切片（包括录制变速处理）合成 block回调
 *
 * @param handler 完成回调处理
 */

- (void)startMediaCompositionWithCompletionHandler:(void (^ _Nullable)(NSString *outputFilePath,NSTimeInterval mediaTotalTime, FSLAVMediaTimelineSliceCompositionStatus status))handler;
{
    switch (_timeSliceOptions.meidaType) {
        case FSLAVMediaTypeAudio:
            [self startAudioCompositionWithCompletionHandler:handler];
            break;
        case FSLAVMediaTypeVideo:
            [self startVideoCompositionWithCompletionHandler:handler];
            break;
        default:
            break;
    }
}

/**
 * 取消操作
 */
- (void)cancelMediaComposition;
{
    [self resetCompositionOperation];
    [self notifyStatus:FSLAVMediaTimelineSliceCompositionStatusCancelled];
    
    //清除临时存储地址
    [_timeSliceOptions clearOutputFilePath];
}

#pragma mark --  处理视频（包含音频和视频）
/**
 * 开始变速合成
 */
- (void)startVideoComposition;
{
    [self startVideoCompositionWithCompletionHandler:nil];
}

/**
 * 开始变速合成视频 block回调
 *
 * @param handler 完成回调处理
 */
- (void)startVideoCompositionWithCompletionHandler:(void (^ _Nullable)(NSString *outputFilePath,NSTimeInterval mediaTotalTime, FSLAVMediaTimelineSliceCompositionStatus status))handler;
{
    // 0.判断资源是否有效
    [self judgeAssetIsVaild];
    
    // 1.从媒体素材中分离出视频轨
    AVAssetTrack *assetVideoTrack = [[_mediaAsset tracksWithMediaType:AVMediaTypeVideo] firstObject];
    
    // 2.输出前需要调整方向 和 构建视频轨编辑环境 videoComposition;
    AVMutableCompositionTrack *compositionVideoTrack = [_mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    //轨道引用的媒体数据的自然维度。size
    _renderSize = assetVideoTrack.naturalSize;
    //轨道引用的媒体数据的估计数据速率，以比特每秒为单位。
    _videoBitRate = (NSUInteger)[assetVideoTrack estimatedDataRate];
    
    // 注：视频 音频 的duration会存在不一致的情况，所以整体时间应以 视频的时间 为准
    _mediaTotalTime = assetVideoTrack.timeRange.duration;
    // 3.将源跟踪的时间范围插入到组合的跟踪中。
    [compositionVideoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, _mediaTotalTime) ofTrack:assetVideoTrack atTime:kCMTimeZero error:nil];
    
    //保留视频原音
    if (_timeSliceOptions.enableVideoSound) {
        
        // 不添加背景音乐，使用视频原声
        NSArray *audioTrackArr = [_mediaAsset tracksWithMediaType:AVMediaTypeAudio];
        if (audioTrackArr.count > 0) {
            //音轨编辑环境
            AVMutableCompositionTrack *compositionAudioTrack = [_mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
            //分离出音轨
            AVAssetTrack *assetAudioTrack = [audioTrackArr firstObject];
            // 给音轨插入以视频为准的时间范围
            [compositionAudioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, _mediaTotalTime) ofTrack:assetAudioTrack atTime:kCMTimeZero error:nil];
            
            //5.调整视频原音轨的分段时间切片
            [self adjustMediaTimeSliceWith:compositionAudioTrack];
        }
    }
    //6.更新视频轨时间切片
    _mediaTotalTime = [self adjustMediaTimeSliceWith:compositionVideoTrack];
    
    //7.导出媒体时间切片编辑结果
    [self exportVideoWithVideoTrack:compositionVideoTrack assetVideoTrack:assetVideoTrack completionHandler:handler];
}


/**
 导出视频：通过视频轨编辑环境、视频轨将时间切片进行更新编辑之后的结果

 @param videoTrack 视频轨编辑环境
 @param assetVideoTrack 视频轨
 @param handler 回调
 */
- (void)exportVideoWithVideoTrack:(AVMutableCompositionTrack *)videoTrack assetVideoTrack:(AVAssetTrack *)assetVideoTrack completionHandler:(void (^)(NSString* outputFilePath,NSTimeInterval mediaTotalTime,FSLAVMediaTimelineSliceCompositionStatus status))handler;
{

    //注意：视频方向不对会引起导出问题；调整视频方向;一个对象，用于修改应用于可变组合中给定轨道的变换、裁剪和不透明度坡道。
    AVMutableVideoCompositionLayerInstruction *layerInstruction = [self adjustVideoOrientationWith:videoTrack assetTrack:assetVideoTrack];
    // 创建最终视频输出方向使用的 VideoComposition
    AVMutableVideoCompositionInstruction *mainInstruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    //指令生效的时间范围。
    mainInstruction.timeRange = CMTimeRangeMake(kCMTimeZero, _mediaTotalTime);
    //指示视频帧应该如何分层和组合
    mainInstruction.layerInstructions = [NSArray arrayWithObject:layerInstruction];

    //表示可变视频合成的对象。
    AVMutableVideoComposition *mainComposition = [AVMutableVideoComposition videoComposition];
    mainComposition.instructions = [NSMutableArray arrayWithObject:mainInstruction];
    //帧率间隔：视频合成应该呈现合成视频帧的时间间隔。
    mainComposition.frameDuration = CMTimeMake(1, assetVideoTrack.nominalFrameRate);
    //视频合成应该呈现的大小。
    mainComposition.renderSize = _renderSize;
    //视频合成应该呈现的比例。
    mainComposition.renderScale = 1.0;
    
    
    //初始化导出素材对象导出器
    if (!_exporter) {
        
        _exporter = [[FSLAVAssetExportSession alloc] initWithAsset:_mixComposition];
        //添加进度观察者
        [self addProgressObserver];
    }
    //导出视频地址
    _exporter.outputURL = _timeSliceOptions.outputFileURL;
    //导出视频类型
    _exporter.outputFileType = _timeSliceOptions.appOutputFileType;
    //导出视频的时间范围
    _exporter.timeRange = CMTimeRangeMake(kCMTimeZero, _mediaTotalTime);
    //指示是否启用视频合成导出，并提供视频合成说明。
    _exporter.videoComposition = mainComposition;
    //指示是否应优化电影以供网络使用。
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
    _exporter.audioSettings = _timeSliceOptions.recordOptions.audioConfigure;
    
    //正在合成通知回调
    [self notifyStatus:FSLAVMediaTimelineSliceCompositionStatusComposing];

    //导出视频素材
    [_exporter exportAsynchronouslyWithCompletionHandler:^{
        
        if (self->_exporter.error)
            fslLError(@"exporter error :  %@",self->_exporter.error);
        
        FSLAVMediaTimelineSliceCompositionStatus exportStatus = FSLAVMediaTimelineSliceCompositionStatusFailed;
        switch (self->_exporter.status)
        {
            case AVAssetExportSessionStatusUnknown:
                exportStatus = FSLAVMediaTimelineSliceCompositionStatusFailed;
                break;
            case AVAssetExportSessionStatusExporting:
                exportStatus = FSLAVMediaTimelineSliceCompositionStatusComposing;
                break;
            case AVAssetExportSessionStatusCompleted:
                exportStatus = FSLAVMediaTimelineSliceCompositionStatusCompleted;
                break;
            case AVAssetExportSessionStatusFailed:
                exportStatus = FSLAVMediaTimelineSliceCompositionStatusFailed;
                break;
            case AVAssetExportSessionStatusCancelled:
                exportStatus = FSLAVMediaTimelineSliceCompositionStatusCancelled;
                break;
            default:
                exportStatus = FSLAVMediaTimelineSliceCompositionStatusFailed;
                break;
        }
        
        //合成状态通知回调
        [self notifyStatus:exportStatus];
        //视频进度通知回调
        [self notifyProgress:1.0];
        if (handler) {
            NSTimeInterval mediaTotalTime = CMTimeGetSeconds(self->_mediaTotalTime);
            handler(self->_timeSliceOptions.outputFilePath,mediaTotalTime,exportStatus);
        }
        //重置合成状态
        [self resetCompositionOperation];
        
        [self removeProgressObserver];
    }];
}

#pragma mark --  处理音频（只有音频）

/**
 * 开始变速合成
 */
- (void)startAudioComposition;
{
    [self startAudioCompositionWithCompletionHandler:nil];
}

/**
 * 开始裁剪音频
 */
- (void)startAudioCompositionWithCompletionHandler:(void (^ _Nullable)(NSString *outputFilePath,NSTimeInterval mediaTotalTime, FSLAVMediaTimelineSliceCompositionStatus status))handler;
{
    // 0.判断资源是否有效
    [self judgeAssetIsVaild];
    
    NSArray *audioTrackArr = [_mediaAsset tracksWithMediaType:AVMediaTypeAudio];
    if (audioTrackArr.count > 0) {
        //音轨编辑环境
        AVMutableCompositionTrack *compositionAudioTrack = [_mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
        //分离出音轨
        AVAssetTrack *assetAudioTrack = [audioTrackArr firstObject];
        // 给音轨插入以视频为准的时间范围
        [compositionAudioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, _mediaTotalTime) ofTrack:assetAudioTrack atTime:kCMTimeZero error:nil];
        
        //1.调整音频轨的分段时间切片
        _mediaTotalTime = [self adjustMediaTimeSliceWith:compositionAudioTrack];
        //2.导出音频时间切片编辑结果
        [self exportAudioWithAudioTrack:compositionAudioTrack assetAudioTrack:assetAudioTrack completionHandler:handler];
    }
}

/**
 * 单独音频合并
 * @param compositionAudioTrack 混合对象
 * @param assetAudioTrack 音频轨道对象
 * @param handler block
 */
- (void)exportAudioWithAudioTrack:(AVMutableCompositionTrack *)compositionAudioTrack assetAudioTrack:(AVAssetTrack *)assetAudioTrack completionHandler:(void (^)(NSString* outputFilePath,NSTimeInterval mediaTotalTime, FSLAVMediaTimelineSliceCompositionStatus status))handler;
{
    //初始化导出素材对象导出器
    if (!_exporter) {
        
        _exporter = [[FSLAVAssetExportSession alloc] initWithAsset:_mixComposition];
    }
    //导出音频地址
    _exporter.outputURL = _timeSliceOptions.outputFileURL;
    //导出视频类型
    _exporter.outputFileType = _timeSliceOptions.appOutputFileType;
    //导出视频的时间范围
    _exporter.timeRange = CMTimeRangeMake(kCMTimeZero, _mediaTotalTime);
    //指示是否应优化电影以供网络使用。
    _exporter.shouldOptimizeForNetworkUse = YES;
    
    // 输出音频格式设置
    _exporter.audioSettings = _timeSliceOptions.recordOptions.audioConfigure;
    
    //正在合成通知回调
    [self notifyStatus:FSLAVMediaTimelineSliceCompositionStatusComposing];
    
    //导出视频素材
    [_exporter exportAsynchronouslyWithCompletionHandler:^{
        
        if (self->_exporter.error)
            fslLError(@"exporter error :  %@",self->_exporter.error);
        
        FSLAVMediaTimelineSliceCompositionStatus exportStatus = FSLAVMediaTimelineSliceCompositionStatusFailed;
        switch (self->_exporter.status)
        {
            case AVAssetExportSessionStatusUnknown:
                exportStatus = FSLAVMediaTimelineSliceCompositionStatusFailed;
                break;
            case AVAssetExportSessionStatusExporting:
                exportStatus = FSLAVMediaTimelineSliceCompositionStatusComposing;
                break;
            case AVAssetExportSessionStatusCompleted:
                exportStatus = FSLAVMediaTimelineSliceCompositionStatusCompleted;
                break;
            case AVAssetExportSessionStatusFailed:
                exportStatus = FSLAVMediaTimelineSliceCompositionStatusFailed;
                break;
            case AVAssetExportSessionStatusCancelled:
                exportStatus = FSLAVMediaTimelineSliceCompositionStatusCancelled;
                break;
            default:
                exportStatus = FSLAVMediaTimelineSliceCompositionStatusFailed;
                break;
        }
        
        //合成状态通知回调
        [self notifyStatus:exportStatus];
        if (handler) {
            NSTimeInterval mediaTotalTime = CMTimeGetSeconds(self->_mediaTotalTime);
            handler(self->_timeSliceOptions.outputFilePath,mediaTotalTime,exportStatus);
        }
        //重置合成状态
        [self resetCompositionOperation];
    }];
}

#pragma mark Shared methods
// 重置合成状态
- (void)resetCompositionOperation;
{
    if (_exporter.status == AVAssetExportSessionStatusExporting || _exporter.status == AVAssetExportSessionStatusWaiting) {
        fslLDebug(@"Conditions cannot be reset during operation.");
        
        if (_exporter) {
            [_exporter cancelExport];
        }
    }else{
        
        if (_exporter) {
            [_exporter cancelExport];
        }
    
        if (_mixComposition) {
            [[_mixComposition tracks]enumerateObjectsUsingBlock:^(AVMutableCompositionTrack * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                [self->_mixComposition removeTrack:obj];
            }];
        }
        
        _mixComposition = nil;
        _exporter = nil;
        _mediaAsset = nil;
    }
}


#pragma mark -- private methods
/**
 判断资源是否有效
 */
- (void)judgeAssetIsVaild{
    
    if (!_timeSliceOptions.mediaPath) {
        fslLError(@"mediaPath is nil, please choose a video file to mix");
        //合成失败状态回调
        [self notifyStatus:FSLAVMediaTimelineSliceCompositionStatusFailed];
        return;
    }
    
    [self initMediaAsset];
    
    if (!_mixComposition) {
        _mixComposition = [[AVMutableComposition alloc] init];
    }
    //开始合成状态回调
    [self notifyStatus:FSLAVMediaTimelineSliceCompositionStatusStart];
}

/**
 增加进度观察者
 */
- (void)addProgressObserver{
    
    if (_exporter) {
        [_exporter addObserver:self forKeyPath:@"progress" options:NSKeyValueObservingOptionNew context:nil];
    }
}

/**
 移除进度观察者
 */
- (void)removeProgressObserver{
    if (_exporter) {
        [_exporter removeObserver:self forKeyPath:@"progress" context:nil];
    }
}

#pragma mark - FSLAVAssetExportSession progress
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context{
    
    if ([@"progress" isEqualToString:keyPath]){
        //progress
        id newValue = [change objectForKey:NSKeyValueChangeNewKey];
        CGFloat progerss = 0.9 + ( [newValue floatValue] / 10);
        [self notifyProgress:progerss];
    }
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
 通过轨道编辑环境进行调整分段时间片段的编辑，更新轨道时间切片信息
 
 @param compositionTrack 轨道编辑
 @return 编辑之后的时间
 */
- (CMTime)adjustMediaTimeSliceWith:(AVMutableCompositionTrack *)compositionTrack;
{
    //返回原时间
    if(!_meidaFragmentArr || _meidaFragmentArr.count == 0) return _mediaTotalTime;
    // 未变速前的对应开始时间
    CMTime defaultStartTime = kCMTimeZero;
    // 变速后对应的结束时间
    CMTime resultTime = kCMTimeZero;
    
    //遍历时间片段数组，将每个时间切片c取出
    for (FSLAVMeidaTimelineSlice *timeSlice in _meidaFragmentArr) {
        // 未变速前的对应持续时间
        CMTime defaultDuration = CMTimeSubtract(timeSlice.end, timeSlice.start);
        // 获取新的持续时间
        CMTime resultDuration = [self getNewDurationWithDuration:defaultDuration WithSpeedMode:timeSlice.speedMode];
        // 新的时间范围
        CMTimeRange timeRange = CMTimeRangeMake(resultTime, defaultDuration);
        if (timeSlice.isRemove) {
            //删除被删除的时间片段
            [compositionTrack removeTimeRange:timeRange];
            continue;
        }
        //更改接收器中时间范围的持续时间。
        [compositionTrack scaleTimeRange:timeRange toDuration:resultDuration];
        
        
        //更新每个时间片段的开始时间和结束时间
        defaultStartTime = CMTimeAdd(defaultStartTime, defaultDuration);
        resultTime = CMTimeAdd(resultTime, resultDuration);
    }
    return resultTime;
}

/**
 通过旧的持续时间与变速类型，返回新的持续时间
 
 @param duration 旧的持续时间
 @param speedMode 录制的变速模式
 @return 新的duration
 */
- (CMTime)getNewDurationWithDuration:(CMTime)duration WithSpeedMode:(FSLAVRecordSpeedMode)speedMode;
{
    CGFloat scale = 1.0;
    switch (speedMode) {
        case FSLAVRecordSpeedMode_Slow1:
            scale = 1.5;
            break;
        case FSLAVRecordSpeedMode_Slow2:
            scale = 2.0;
            break;
        case FSLAVRecordSpeedMode_Fast1:
            scale = 0.7;
            break;
        case FSLAVRecordSpeedMode_Fast2:
            scale = 0.5;
            break;
        default:
            break;
    }
    return CMTimeMake(duration.value * scale, duration.timescale);
}

/**
 设置回调通知，并委托协议
 
 @param status 回调的混合状态
 */
- (void)notifyStatus:(FSLAVMediaTimelineSliceCompositionStatus)status;
{
    //将最后媒体素材的时间存入
    _timeSliceOptions.mediaDuration = CMTimeGetSeconds(_mediaTotalTime);
    
    if (![NSThread isMainThread]) {
        dispatch_sync(dispatch_get_main_queue(), ^{
            if ([self.compositionDelegate respondsToSelector:@selector(didCompositionMediaStatusChanged:composition:)]) {
                [self.compositionDelegate didCompositionMediaStatusChanged:status composition:self];
            }
        });
    }else{
        if ([self.compositionDelegate respondsToSelector:@selector(didCompositionMediaStatusChanged:composition:)]) {
            [self.compositionDelegate didCompositionMediaStatusChanged:status composition:self];
        }
    }
    if (status == FSLAVMediaTimelineSliceCompositionStatusCompleted) {
        
        if ([self.compositionDelegate respondsToSelector:@selector(didCompletedCompositionMediaResult:composition:)]) {
            [self.compositionDelegate didCompletedCompositionMediaResult:_timeSliceOptions composition:self];
        }
        if ([self.compositionDelegate respondsToSelector:@selector(didCompletedCompositionOutputFilePath:composition:)]) {
            [self.compositionDelegate didCompletedCompositionOutputFilePath:_timeSliceOptions.outputFilePath composition:self];
        }
        if ([self.compositionDelegate respondsToSelector:@selector(didCompletedCompositionMediaTotalTime:composition:)]) {
            [self.compositionDelegate didCompletedCompositionMediaTotalTime:_timeSliceOptions.mediaDuration composition:self];
        }
    }
}

/**
 通知分段时间片段合成进度
 
 @param progress 当前进度
 */
- (void)notifyProgress:(CGFloat)progress{
    
    if ([self.compositionDelegate respondsToSelector:@selector(didCompositionMediaProgressChanged:composition:)]) {
        [self.compositionDelegate didCompositionMediaStatusChanged:progress composition:self];
    }
}

/**
 销毁
 */
- (void)destory{
    [super destory];
    
    [self cancelMediaComposition];
}

@end
