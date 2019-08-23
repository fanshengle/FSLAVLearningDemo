//
//  FSLAVVideoClipper.m
//  FSLAVComponent
//
//  Created by tutu on 2019/8/1.
//  Copyright © 2019 tutu. All rights reserved.
//

#import "FSLAVVideoClipper.h"
#import "FSLAVAssetExportSession.h"

@interface FSLAVVideoClipper ()<FSLAVAssetExportSessionDelegate>
{
    //音轨混合数组
    NSMutableArray *_audioMixParams;
    // 剪辑的composition
    AVMutableComposition    *_clipComposition;
    // 输出的 session
    FSLAVAssetExportSession *_exporter;
    // 视频 size
    CGSize _renderSize;
    // 视频码率
    NSUInteger _videoBitRate;
    
    // 回调
    void (^_handler)(NSString *filePath, FSLAVClipStatus status);
    // 是否需要手动调用start
    BOOL _needStartCompressing;
}

// 是否保留视频原音，默认 YES，保留视频原音
@property (nonatomic, assign) BOOL enableVideoSound;

// 媒体素材 mediaAsset
@property (nonatomic, strong) AVAsset *videoAsset;

@end

@implementation FSLAVVideoClipper

/**
 初始化视频剪辑器，用init初始化也可以，clipVideo都得自行配置

 @param clipVideo 主视频轨
 @return FSLAVvideoClipper
 */
- (instancetype)initWithClipperVideoOptions:(FSLAVVideoClipperOptions *)clipVideo;
{
    if (self = [super init]) {
        self.clipVideo = clipVideo;
    }
    return self;
}


#pragma mark -- setter getter

- (void)setClipVideo:(FSLAVVideoClipperOptions *)clipVideo{
    _clipVideo = clipVideo;
    
    //将主视频配置好的内容取出来，方便使用
    _enableVideoSound = _clipVideo.enableVideoSound;
    _videoAsset = _clipVideo.mediaAsset;
}

- (void)createVideoAsset;
{
    NSDictionary *options = @{AVURLAssetPreferPreciseDurationAndTimingKey:@NO};
    _videoAsset = [AVURLAsset URLAssetWithURL:_clipVideo.mediaURL options:options];
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
    if (_clipVideo.clipStatus == FSLAVClipStatusClipping) {
        [self cancelClipping];
        _handler = handler;
        _needStartCompressing = YES;
        return;
    }
    
    if (!_clipVideo.mediaURL) {
        
        fslLError(@"Videopath is nil, please choose a video file to mix");
        [self notifyStatus:FSLAVClipStatusFailed];
        return;
    }
    
    if (!_audioMixParams) {
        
        _audioMixParams = [NSMutableArray arrayWithCapacity:1];
    }
    
    if (!_videoAsset) {
        
        [self createVideoAsset];
    }
    
    if (!_clipComposition) {
        
        _clipComposition = [[AVMutableComposition alloc]init];
    }

    //处理视频轨
    AVMutableVideoComposition *mainComposition = [self processMediaOfVideoTrack];
    
    //导出剪辑视频
    [self exportClippedVideoWithVideoComposition:mainComposition completionHandler:handler];
}

/**
 处理视频轨

 @return 带视频说明的编辑对象
 */
- (AVMutableVideoComposition *)processMediaOfVideoTrack{
    
    // 1.输出前需要调整方向 和 构建 videoComposition;
    AVMutableCompositionTrack *compositionVideoTrack = [_clipComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    // 2.分离出视频轨道
    AVAssetTrack *assetVideoTrack = [[_videoAsset tracksWithMediaType:AVMediaTypeVideo] firstObject];
    //视频的原始尺寸
    _renderSize = assetVideoTrack.naturalSize;
    //视频的原始 码率
    _videoBitRate = (NSUInteger)[assetVideoTrack estimatedDataRate];
    
    // 3.剪辑有效时间范围插入编辑环境下视频轨
    [compositionVideoTrack insertTimeRange:_clipVideo.atTimeRange.CMTimeRange ofTrack:assetVideoTrack atTime:_clipVideo.atNodeTime error:nil];
    
    if (_enableVideoSound) {
        // 使用视频原声
        NSArray *audioTrackArr = [_videoAsset tracksWithMediaType:AVMediaTypeAudio];
        if (audioTrackArr.count > 0) {
            // 1.分离音轨
            AVAssetTrack *assetAudioTrack = [audioTrackArr firstObject];
            // 2.创建音轨编辑环境
            AVMutableCompositionTrack *compositionAudioTrack = [_clipComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
            // 3.将改有效时间的音轨插入音轨编辑环境
            [compositionAudioTrack insertTimeRange:_clipVideo.atTimeRange.CMTimeRange ofTrack:assetAudioTrack atTime:_clipVideo.atNodeTime error:nil];
            
            // 4.将音频轨道添加到混合时使用的参数,如：音量控制。
            AVMutableAudioMixInputParameters *mixInput = [AVMutableAudioMixInputParameters audioMixInputParametersWithTrack:compositionAudioTrack];
            // 设置音轨音量
            [mixInput setVolume:_clipVideo.audioVolume atTime:kCMTimeZero];
            // 保存音频信息输入
            [_audioMixParams addObject:mixInput];
        }else{
            
            fslLError(@"This video has no audio tracks.");
        }
    }
    
    // 4.调整视频方向
    AVMutableVideoCompositionLayerInstruction * layerInstruction = [self adjustVideoOrientationWith:compositionVideoTrack assetTrack:assetVideoTrack];
    
    // 4.创建最终输出使用的 VideoComposition
    AVMutableVideoCompositionInstruction *mainInstruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    mainInstruction.timeRange = CMTimeRangeMake(kCMTimeZero, _clipVideo.atTimeRange.duration);
    mainInstruction.layerInstructions = [NSArray arrayWithObject:layerInstruction];
    
    // 5.输入视频说明
    AVMutableVideoComposition *mainComposition = [AVMutableVideoComposition videoComposition];
    mainComposition.instructions = [NSArray arrayWithObject:mainInstruction];
    mainComposition.frameDuration = CMTimeMake(1, assetVideoTrack.nominalFrameRate);
    mainComposition.renderSize = _renderSize;
    mainComposition.renderScale = 1.0;
    
    return mainComposition;
}

/**
 导出剪辑视频

 @param mainComposition 输入视频说明
 */
- (void)exportClippedVideoWithVideoComposition:(AVMutableVideoComposition *)mainComposition completionHandler:(void (^)(NSString* outputFilePath, FSLAVClipStatus status))handler;
{
    
    //通过设置删除时间数组的方式来剪辑视频时，就不能使用atTimeRange的方式来剪辑视频。
    if ((_deleteTimeRangeArr && _deleteTimeRangeArr.count > 0) && CMTimeCompare(_clipVideo.atTimeRange.duration, _clipVideo.mediaTimeRange.duration) == 0) {
        
        //获取剪辑的最后输出总时长
        CMTime mediaTotalTime = [self outputLastTimeOfVideoClipWithTotolTime:_videoAsset.duration];
        //更新时间对象
        _clipVideo.atTimeRange = [FSLAVTimeRange timeRangeWithStartTime:kCMTimeZero duration:mediaTotalTime];
        _clipVideo.mediaDuration = CMTimeGetSeconds(mediaTotalTime);
    }
    
    //创建一个可变的音频混合对象,将音频音量设置加到audioMix
    AVMutableAudioMix *audioMix = [AVMutableAudioMix audioMix];
    audioMix.inputParameters = [NSArray arrayWithArray:_audioMixParams];
    
    // 输出
    if (!_exporter) {
        _exporter = [[FSLAVAssetExportSession alloc] initWithAsset:_clipComposition];
        _exporter.delegate = self;
    }
    _exporter.outputURL = _clipVideo.outputFileURL;
    _exporter.outputFileType = _clipVideo.appOutputFileType;
    _exporter.timeRange = CMTimeRangeMake(kCMTimeZero, _clipVideo.atTimeRange.duration);
    _exporter.audioMix = audioMix;
    _exporter.videoComposition = mainComposition;
    _exporter.shouldOptimizeForNetworkUse = YES;
    
    _exporter.videoSettings = @{
                                AVVideoCodecKey:AVVideoCodecH264,
                                AVVideoWidthKey:[NSNumber numberWithInt:_renderSize.width],
                                AVVideoHeightKey:[NSNumber numberWithInt:_renderSize.height],
                                AVVideoCompressionPropertiesKey:@{
                                        AVVideoAverageBitRateKey:[NSNumber numberWithInteger: (_videoBitRate <= 0 ? 1000000 : _videoBitRate)],
                                        AVVideoProfileLevelKey:AVVideoProfileLevelH264Main41,
                                        },
                                };
    
    _exporter.audioSettings =  @{
                                 AVFormatIDKey: @(kAudioFormatMPEG4AAC),
                                 AVNumberOfChannelsKey: @2,
                                 AVSampleRateKey: @44100,
                                 AVEncoderBitRateKey: @128000,
                                 };
    
    [self notifyStatus:FSLAVClipStatusClipping];
    
    [_exporter exportAsynchronouslyWithCompletionHandler:^{
        
        if (self->_exporter.error)
            fslLError(@"exporter error :  %@",self->_exporter.error);
        
        FSLAVClipStatus exportStatus = FSLAVClipStatusFailed;
        switch (self->_exporter.status)
        {
            case AVAssetExportSessionStatusUnknown:
                exportStatus = FSLAVClipStatusFailed;
                break;
            case AVAssetExportSessionStatusExporting:
                exportStatus = FSLAVClipStatusClipping;
                break;
            case AVAssetExportSessionStatusCompleted:
                exportStatus = FSLAVClipStatusCompleted;
                break;
            case AVAssetExportSessionStatusFailed:
                exportStatus = FSLAVClipStatusFailed;
                break;
            case AVAssetExportSessionStatusCancelled:
                exportStatus = FSLAVClipStatusCancelled;
                break;
            default:
                exportStatus = FSLAVClipStatusFailed;
                break;
        }
        
        [self notifyStatus:exportStatus];
        if (handler) {
            handler(self->_clipVideo.outputFilePath, exportStatus);
        }
        
        [self resetClipperOperation];
    }];
    
}

/**
 取消混合操作
 */
- (void)cancelClipping;
{
    [self notifyStatus:FSLAVClipStatusCancelled];
    [self resetClipperOperation];
    [_clipVideo clearOutputFilePath];
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
    
    [self cancelClipping];
}


#pragma mark -- private methods

/**
 排序后从composition中删除对应的视频
 
 @param totalTime 删除前的视频总时长
 @return 删除后的视频总时长
 */
- (CMTime)outputLastTimeOfVideoClipWithTotolTime:(CMTime)totalTime{

    //快速排序
    _deleteTimeRangeArr = [self quickSort:_deleteTimeRangeArr];
    //冒泡排序
    //_deleteTimeRangeArr = [self bubbleSort:_deleteTimeRangeArr];
    
    //最后剪辑之后的输出时间
    CMTime lastTotalTime = totalTime;
    //需要删除的总时间
    CMTime deleteTotalTime = kCMTimeZero;
    
    if (_deleteTimeRangeArr && _deleteTimeRangeArr.count > 0) {
        // 注：数组循环应从大到小进行，因为排序以开始时间由小到大进行，故下标越大记录的删除时间越靠后
        for (NSInteger i = _deleteTimeRangeArr.count - 1; i >= 0; i--) {
            FSLAVTimeRange *timeRange = _deleteTimeRangeArr[i];
            [self removeTimeRange:timeRange];
            //返回删除的总时间
            deleteTotalTime = CMTimeAdd(deleteTotalTime, timeRange.duration);
        }
        //总时间减去删除的总时间得到最后的总时间
        lastTotalTime = CMTimeSubtract(lastTotalTime, deleteTotalTime);
    }
    return lastTotalTime;
}

/**
 * 删除指定timeRange区域的音视频信息
 *
 * @param timeRange 要删除的视频信息
 */
- (void)removeTimeRange:(FSLAVTimeRange *)timeRange;
{
    if (!timeRange.isValid) {//时间范围是无效的
        fslLError(@"%@ timeRange is invalid",[timeRange description]);
        return;
    }
    
    //对媒体资源进行时间剪辑
    [_clipComposition removeTimeRange:CMTimeRangeMake(timeRange.start, timeRange.duration)];
}

#pragma mark -- 对需要删除的视频时间片段进行排序
/**
 冒泡排序：将视频剪辑的时间片段数组，按升序的方式o由小到大进行排序
 1. 从当前元素起，向后依次比较每一对相邻元素，若逆序则交换
 2. 对所有元素均重复以上步骤，直至最后一个元素
 
 @param sortArr 时间片段数组
 @return 排序之后的时间片段数组
 */
- (NSArray<FSLAVTimeRange *> *)bubbleSort:(NSMutableArray<FSLAVTimeRange *> *)sortArr;
{
    
    for (int i = 0; i<sortArr.count-1; i++) {/* 外循环为排序趟数，len个数进行len-1趟 */
        for (int j = 0; j<sortArr.count-1-i; j++) {/* 内循环为每趟比较的次数，第i趟比较len-i次 */
            
            NSInteger left = CMTimeGetSeconds(sortArr[j].start);
            NSInteger right = CMTimeGetSeconds(sortArr[j+1].start);
            if (left>right) {/* 相邻元素比较，若逆序则交换（升序为左大于右，降序反之） */
                
                [sortArr exchangeObjectAtIndex:j withObjectAtIndex:j+1];
            }
        }
    }
    return sortArr;
}

// 对要删除的数组内容根据 开始时间 有小到大进行排序
- (NSArray<FSLAVTimeRange *> *)quickSort:(NSArray<FSLAVTimeRange *> *)sortArr{
    
    NSMutableArray<FSLAVTimeRange *> * resultArr = [NSMutableArray arrayWithArray:sortArr];
    NSInteger first = 0;
    NSInteger last = sortArr.count-1;
    
    [self quickSort:resultArr withFirst:first withLast:last];
    return resultArr;
}

/**
 快速排序：将视频剪辑的时间片段数组，按升序的方式由小到大进行排序

 @param sortArr 时间片段数组
 @param first 首索引
 @param last  末索引
 */
- (void)quickSort:(NSMutableArray<FSLAVTimeRange *> *)sortArr withFirst:(NSInteger)first withLast:(NSInteger)last{
    if (first>=last) {// 递归结束条件
        return;
    }
    NSInteger i = first;
    NSInteger j = last;
    //标兵值(关键值)
    FSLAVTimeRange * keyTime = sortArr[i];
    //查询
    while (i<j) {
        
        // 从右边开始比较，比key大的数位置不变;
        // 从j开始向前搜索，即由后开始向前搜索(j--)，找到第一个小于key的值A[j]，将A[j]和A[i]的值交换；
        while (i<j && CMTimeCompare(sortArr[j].start, keyTime.start) != -1) {
            j--;
        }
        
        // 如果小于标兵就放到前面;只要出现一个比key小的数，将这个数放入左边i的位置
        sortArr[i] = sortArr[j];
        
        // 从左边开始比较，比key小的数位置不变
        // 从i开始向后搜索，即由前开始向后搜索(i++)，找到第一个大于key的A[i]，将A[i]和A[j]的值交换；
        while (i<j && CMTimeCompare(sortArr[i].start, keyTime.start)!=1) {
            i++;
        }
        //如果大于标兵就放到后面,只要出现一个比key大的数，将这个数放入右边j的位置
        sortArr[j] = sortArr[i];
    }
    
    sortArr[i] = keyTime;
    
    // 左递归
    [self quickSort:sortArr withFirst:first withLast:i-1];
    // 右递归
    [self quickSort:sortArr withFirst:i+1 withLast:last];
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
    BOOL isAssetPortrait = NO;
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
    
    if (isAssetPortrait) {
        //交换宽高
        CGSize tempSize = _renderSize;
        _renderSize = CGSizeMake(tempSize.height, tempSize.width);
    }
    // 调整视频方向
    AVMutableVideoCompositionLayerInstruction * layerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoTrack];
    [layerInstruction setTransform:mixedTransform atTime:kCMTimeZero];
    
    return layerInstruction;
}

/**
 设置回调通知，并委托协议
 
 @param status 回调的剪辑状态
 */
- (void)notifyStatus:(FSLAVClipStatus)status;
{
    if(self.clipVideo.clipStatus == status) return;
    self.clipVideo.clipStatus = status;
    FSLRunSynchronouslyOnMainQueue(^{
        //剪辑的状态
        if ([self.clipDelegate respondsToSelector:@selector(didClippingVideoStatusChanged:onVideoClip:)]) {
            [self.clipDelegate didClippingVideoStatusChanged:status onVideoClip:self];
        }
        if (status == FSLAVClipStatusCompleted) {
            
            //剪辑的所有结果返回
            if ([self.clipDelegate respondsToSelector:@selector(didClippedVideoResult:onVideoClip:)]) {
                [self.clipDelegate didClippedVideoResult:self.clipVideo onVideoClip:self];
            }
            //剪辑视频的输出地址返回
            if ([self.clipDelegate respondsToSelector:@selector(didCompletedClipVideoOutputFilePath:onVideoClip:)]) {
                [self.clipDelegate didCompletedClipVideoOutputFilePath:self.clipVideo.outputFilePath onVideoClip:self];
            }
            //剪辑视频的输出总时长
            if ([self.clipDelegate respondsToSelector:@selector(didCompletedClipMediaTotalTime:onVideoClip:)]) {
                [self.clipDelegate didCompletedClipMediaTotalTime:CMTimeGetSeconds(self.clipVideo.atTimeRange.duration) onVideoClip:self];
            }
        }
    });
}
/**
 通知分段时间片段剪辑进度
 
 @param progress 当前进度
 */
- (void)notifyProgress:(CGFloat)progress{
    FSLRunSynchronouslyOnMainQueue(^{
        if ([self.clipDelegate respondsToSelector:@selector(didClippingVideoProgressChanged:onVideoClip:)]) {
            [self.clipDelegate didClippingVideoProgressChanged:progress onVideoClip:self];
        }
    });
}


// 重置剪辑状态
- (void)resetClipperOperation;
{
    if (_exporter.status == AVAssetExportSessionStatusExporting || _exporter.status == AVAssetExportSessionStatusWaiting) {
        if (_exporter) {
            [_exporter cancelExport];
        }
    }else{
        if (_exporter) {
            [_exporter cancelExport];
        }
        if (_clipComposition) {
            [[_clipComposition tracks] enumerateObjectsUsingBlock:^(AVMutableCompositionTrack * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                [self->_clipComposition removeTrack:obj];
            }];
        }
        
        _exporter = nil;
        _clipComposition = nil;
    }
}

#pragma mark - FSLAVAssetExportSessionDelegate
- (void)exportSession:(FSLAVAssetExportSession *)exportSession notifyStatus:(AVAssetExportSessionStatus)status;
{
    if (status == AVAssetExportSessionStatusCancelled) {
        
        if (_needStartCompressing) {
            
            [self startClippingVideoWithCompletion:_handler];
            _handler = nil;
        }
    }
}

- (void)exportSession:(FSLAVAssetExportSession *)exportSession progress:(CGFloat)progress{
    
    [self notifyProgress:progress];
}

@end
