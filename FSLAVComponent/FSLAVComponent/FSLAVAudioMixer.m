//
//  FSLAVAudioMixer.m
//  FSLAVComponent
//
//  Created by tutu on 2019/7/12.
//  Copyright © 2019 tutu. All rights reserved.
//

#import "FSLAVAudioMixer.h"

@interface FSLAVAudioMixer ()
{
    //音轨混合数组
    NSMutableArray *_audioMixParams;
    //编辑视频环境
    AVMutableComposition *composition;
}

//导出素材
@property (nonatomic,strong) AVAssetExportSession *exporter;

@end

@implementation FSLAVAudioMixer

#pragma mark - setter getter
- (void)setMixAudios:(NSArray<FSLAVMixerAudioOptions *> *)mixAudios;
{
    _mixAudios = mixAudios;
    [self resetMixOperation];
}

- (void)setMainAudio:(FSLAVMixerAudioOptions *)mainAudio;
{
    _mainAudio = mainAudio;
    [self resetMixOperation];
}

#pragma mark - mix method

/**
 初始化音频混合器
 
 @param mainAudio 主音轨
 @return FSLAVAudioMixer
 */
- (instancetype)initWithMixerAudioOptions:(FSLAVMixerAudioOptions *)mainAudio;
{
    if (self = [super init]) {
        
        _mainAudio = mainAudio;
    }
    return self;
}


/**
 开始混合音轨，该方法的混合音轨结果没有block回调过程，结果可通过协议拿到
 */
- (void)startMixingAudio;
{
    id block = nil;
    [self startMixingAudioWithCompletion:block];
}
/**
 开始混合音轨，该方法的混合音轨结果有block回调，同时也可通过协议拿到
 */
- (void)startMixingAudioWithCompletion:(void (^)(NSURL*, FSLAVMixStatus))handler;
{
    if (!_audioMixParams) {
        
        _audioMixParams = [NSMutableArray array];
    }
    
    if (!_mainAudio) {
        fslLError(@"have not set a valid main track");
        [self notifyStatus:FSLAVMixStatusCancelled];
    }
    
    //编辑素材环境，创建新组合的可变对象。
    AVMutableComposition *composition = [AVMutableComposition composition];

    //1.处理主音轨
    if (_mainAudio.audioTrack) {
        
        //添加主音轨
        [self addAudioTrack:_mainAudio toComposition:composition atTimeRange:_mainAudio.audioTimeRange mainTimeRange:_mainAudio.audioTimeRange];
    }
    
    //2.处理多音轨
    if (_mixAudios && _mixAudios.count > 0) {
        [_mixAudios enumerateObjectsUsingBlock:^(FSLAVMixerAudioOptions * _Nonnull audio, NSUInteger idx, BOOL * _Nonnull stop) {
            //如果音轨为空，跳出遍历
            if(!audio.audioTrack) *stop = YES;
            //判断需要混合的音轨是否大于主音轨时间
            if (CMTIME_COMPARE_INLINE(audio.atTimeRange.duration, >, self.mainAudio.atTimeRange.duration)) {
                //将音轨素材的时间改变成与主音轨一致
                audio.atTimeRange.duration = self.mainAudio.atTimeRange.duration;
            }
            //混合音轨注意：确保与主音轨的时间长度一致，否则混合会失败
            
            //添加音轨
            [self addAudioTrack:audio toComposition:composition atTimeRange:audio.atTimeRange mainTimeRange:self.mainAudio.atTimeRange];
        }];
    }
    
    //3.创建一个可变的音频混合对象，用于管理混合音频轨道的输入参数。
    AVMutableAudioMix *audioMix = [AVMutableAudioMix audioMix];
    //混合的输入参数数组。
    audioMix.inputParameters = [NSArray arrayWithArray:_audioMixParams];
    
    //4.创建一个输出对象
    if (!_exporter) {
        _exporter = [[AVAssetExportSession alloc]initWithAsset:composition presetName:AVAssetExportPresetAppleM4A];
        
        //添加进度观察者
        [self addProgressObserver];
    }
    _exporter.outputFileType = AVFileTypeAppleM4A;
    _exporter.audioMix = audioMix;
    _exporter.outputURL = _mainAudio.outputFileURL;
    //设置导出的混合音轨操作时间范围
    _exporter.timeRange = CMTimeRangeMake(kCMTimeZero, _mainAudio.atTimeRange.duration);
    
    [self notifyStatus:FSLAVMixStatusMixing];

    //导出混合音轨
    [_exporter exportAsynchronouslyWithCompletionHandler:^{

        FSLAVMixStatus exportStatus = FSLAVMixStatusUnknown;
        switch (self.exporter.status) {
                
            case AVAssetExportSessionStatusFailed: {
                exportStatus = FSLAVMixStatusFailed;
            }
                break;
            case AVAssetExportSessionStatusCompleted: {
                exportStatus = FSLAVMixStatusCompleted;
            }
                break;
            case AVAssetExportSessionStatusUnknown: {
                exportStatus = FSLAVMixStatusFailed;
            }
                break;
            case AVAssetExportSessionStatusExporting: {
                exportStatus = FSLAVMixStatusMixing;
            }
                break;
            case AVAssetExportSessionStatusCancelled: {
                exportStatus = FSLAVMixStatusCancelled;
            }
                break;
                
            default:{
                exportStatus = FSLAVMixStatusFailed;
            }
                break;
        }
        if (self.exporter.error) {
            fslLError(@"exporter audio error : %@",self.exporter.error);
        }
        
        [self notifyStatus:exportStatus];
        if (handler) {
            handler(self.exporter.outputURL,exportStatus);
        }
        
        [self resetMixOperation];
    }];
}

/**
 取消混合操作
 */
- (void)cancelMixing;
{
    if (_exporter) {
        if (_exporter.status == AVAssetExportSessionStatusExporting || _exporter.status == AVAssetExportSessionStatusWaiting) {
            
            [_mainAudio clearOutputFilePath];
            [self notifyStatus:FSLAVMixStatusCancelled];
            [self resetMixOperation];
        }
    }
}

#pragma mark -- private methods

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

// 重置混合状态
- (void)resetMixOperation;
{
    if (_exporter.status == AVAssetExportSessionStatusExporting || _exporter.status == AVAssetExportSessionStatusWaiting) {
        fslLWarn(@"Conditions cannot be reset during operation.");
        if (_exporter) {
            [_exporter cancelExport];
        }
    }else{
        if (_audioMixParams) {
            [_audioMixParams removeAllObjects];
        }
        if (_exporter) {
            [_exporter cancelExport];
        }
        
        [self removeProgressObserver];
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
            if ([self.mixDelegate respondsToSelector:@selector(didMixingAudioStatusChanged:onAudioMix:)]) {
                [self.mixDelegate didMixingAudioStatusChanged:status onAudioMix:self];
            }
        });
    }else{
        if ([self.mixDelegate respondsToSelector:@selector(didMixingAudioStatusChanged:onAudioMix:)]) {
            [self.mixDelegate didMixingAudioStatusChanged:status onAudioMix:self];
        }
    }
    if (status == FSLAVMixStatusCompleted) {
        if ([self.mixDelegate respondsToSelector:@selector(didMixedAudioResult:onAudioMix:)]) {
            [self.mixDelegate didMixedAudioResult:_mainAudio onAudioMix:self];
        }
    }
}

/**
 添加音轨到混合编辑音轨组合下

 @param audioOptions 音轨素材
 @param composition 混合音轨组合类
 @param timeRange 音轨的时间范围
 @param mainTimeRange 主音轨的时间范围
 */
- (void)addAudioTrack:(FSLAVMixerAudioOptions *)audioOptions toComposition:(AVMutableComposition *)composition atTimeRange:(FSLAVTimeRange *)timeRange mainTimeRange:(FSLAVTimeRange *)mainTimeRange;
{
    
    //1.从素材中分离的音轨
    AVAssetTrack *audioTrack = audioOptions.audioTrack;
    
    NSError *error = nil;
    BOOL insertResult = NO;
    
    //2.设置音频播放的时间区间
    CMTimeRange atTimeRange = CMTimeRangeMake(timeRange.start, CMTIME_COMPARE_INLINE(timeRange.duration, >, mainTimeRange.duration) ? mainTimeRange.duration : timeRange.duration);
    
    //3.在音频素材的编辑环境下添加音轨
    AVMutableCompositionTrack *compositionTrack = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    
    //4.将音频轨道添加到混合时使用的参数。
    AVMutableAudioMixInputParameters *mixInput = [AVMutableAudioMixInputParameters audioMixInputParametersWithTrack:compositionTrack];
    //设置音轨音量
    [mixInput setVolume:audioOptions.audioVolume atTime:mainTimeRange.start];
    [_audioMixParams addObject:mixInput];
    
    if (!_mainAudio.enableCycleAdd || CMTIME_COMPARE_INLINE(atTimeRange.duration, >, mainTimeRange.duration)) {//不需要x循环播放
        
        //5.将源跟踪的时间范围插入到组合的音轨中。
        insertResult = [compositionTrack insertTimeRange:atTimeRange ofTrack:audioTrack atTime:mainTimeRange.start error:&error];
    }else{//循环
        
        //6.获取音轨的总音轨时间范围；
        CMTimeRange contentTimeRange =  CMTimeRangeMake(kCMTimeZero, CMTIME_COMPARE_INLINE(audioTrack.timeRange.duration, >,atTimeRange.duration) ? atTimeRange.duration : audioTrack.timeRange.duration);
        
        CMTime nextAtTime = atTimeRange.start;
        CMTime audioDurationTime = contentTimeRange.duration;
        CMTime insertDurationTime = contentTimeRange.start;
        
        //7.遍历音轨总时长，达到循环添加音轨的目的
        while (CMTIME_COMPARE_INLINE(nextAtTime, <, audioDurationTime)) {
            
            /**8.剩余时间,返回两个CMTimes的差值。*/
            CMTime remainingTime = CMTimeSubtract(atTimeRange.duration, insertDurationTime);
            if (CMTIME_COMPARE_INLINE(remainingTime, <, audioDurationTime)) {
                //9.更新音轨总时长为剩余时长
                contentTimeRange.duration = remainingTime;
            }
            
            //10.将源跟踪的时间范围插入到组合的音轨中。
            insertResult = [compositionTrack insertTimeRange:contentTimeRange ofTrack:audioTrack atTime:nextAtTime error:&error];
            if (!insertResult) {
                fslLError(@"mix insert error 1: %@",error);
                break;
            }
            
            //返回两个CMTimes的和值
            nextAtTime = CMTimeAdd(nextAtTime, contentTimeRange.duration);
            insertDurationTime = CMTimeAdd(insertDurationTime, contentTimeRange.duration);
        }
    }
}

/**
 通知分段时间片段合成进度
 
 @param progress 当前进度
 */
- (void)notifyProgress:(CGFloat)progress{
    
//    if ([self.compositionDelegate respondsToSelector:@selector(didCompositionMediaProgressChanged:progress:composition:)]) {
//        [self.compositionDelegate didCompositionMediaStatusChanged:progress composition:self];
//    }
}
/**
 销毁对象
 */
- (void)destory{
    [super destory];
    
    [self cancelMixing];
}

@end
