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
    AVMutableComposition *_mixComposition;
}

//导出素材
@property (nonatomic,strong) AVAssetExportSession *exporter;

@end

@implementation FSLAVAudioMixer

#pragma mark - setter getter
- (void)setMixAudios:(NSArray<FSLAVAudioMixerOptions *> *)mixAudios;
{
    _mixAudios = mixAudios;
    [self resetMixOperation];
}

- (void)setMainAudio:(FSLAVAudioMixerOptions *)mainAudio;
{
    _mainAudio = mainAudio;
    [self resetMixOperation];
}

/**
 设置默认参数配置
*/
- (void)setConfig;
{
    [super setConfig];
    
}

/**
 销毁对象
 */
- (void)destory{
    [super destory];
    
    [self cancelMixing];
}

#pragma mark - mix method

/**
 初始化音频混合器
 
 @param mainAudio 主音轨
 @return FSLAVAudioMixer
 */
- (instancetype)initWithMixerAudioOptions:(FSLAVAudioMixerOptions *)mainAudio;
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
    [self startMixingAudioWithCompletion:nil];
}

/**
 开始混合音轨，该方法的混合音轨结果有block回调，同时也可通过协议拿到
 */
- (void)startMixingAudioWithCompletion:(void (^ _Nullable)(NSString*, FSLAVMixStatus))handler;
{
    if (!_audioMixParams) {
        
        _audioMixParams = [NSMutableArray array];
    }
    
    if (!_mainAudio) {
        fslLError(@"have not set a valid main track");
        [self notifyStatus:FSLAVMixStatusCancelled];
        return;
    }
    [self notifyStatus:FSLAVMixStatusMixing];
    
    if(!_mixComposition){
        
        //编辑素材环境，创建新组合的可变对象。保证该对象是唯一的
        _mixComposition = [[AVMutableComposition alloc]init];
    }

    //1.处理主音轨
    if (_mainAudio.audioTrack) {
        
        //添加主音轨
        [self addAudioTrack:_mainAudio atTimeRange:_mainAudio.atTimeRange mainTimeRange:_mainAudio.mediaTimeRange];
    }
    
    //2.处理多音轨
    if (_mixAudios && _mixAudios.count > 0) {
        [_mixAudios enumerateObjectsUsingBlock:^(FSLAVMixerOptions * _Nonnull audio, NSUInteger idx, BOOL * _Nonnull stop) {
            //如果音轨为空，跳出遍历
            if(!audio.audioTrack) *stop = YES;
            //判断需要混合的音轨是否大于主音轨时间
            if (CMTIME_COMPARE_INLINE(audio.atTimeRange.duration, >, self.mainAudio.atTimeRange.duration)) {
                //将音轨素材的时间改变成与主音轨一致
                audio.atTimeRange.duration = self.mainAudio.atTimeRange.duration;
            }
            
            //开始合成时间节点时间与该音频持续时间的和
            CMTime atNodeDuration = CMTimeAdd(audio.atNodeTime, audio.atTimeRange.duration);
            //判断是否大于主音轨的持续时间
            if (CMTIME_COMPARE_INLINE(atNodeDuration, >=, self.mainAudio.atTimeRange.duration)) {
                atNodeDuration = kCMTimeZero;
                audio.atNodeTime = atNodeDuration;
            }
            
            //添加音轨
            [self addAudioTrack:audio atTimeRange:audio.atTimeRange mainTimeRange:self.mainAudio.atTimeRange];
        }];
    }
    
    //3.导出多音频合成结果
    [self exportAudioWithCompletionHandler:handler];
}

/**
 取消混合操作
 */
- (void)cancelMixing;
{
    [self notifyStatus:FSLAVMixStatusCancelled];
    [self resetMixOperation];
    [_mainAudio clearOutputFilePath];
}

#pragma mark -- private methods

/**
 添加音轨到混合编辑音轨组合下
 
 @param audioOptions 音轨素材
 @param timeRange 音轨的时间范围(即裁剪的音频有效播放时间范围)
 @param mainTimeRange 主音轨的时间范围
 */
- (void)addAudioTrack:(FSLAVMixerOptions *)audioOptions atTimeRange:(FSLAVTimeRange *)timeRange mainTimeRange:(FSLAVTimeRange *)mainTimeRange;
{
    
    //1.从素材中分离的音轨
    AVAssetTrack *audioTrack = audioOptions.audioTrack;
    
    NSError *error = nil;
    BOOL insertResult = NO;
    
    //2.设置音频播放的时间区间
    CMTimeRange atTimeRange = CMTimeRangeMake(timeRange.start, CMTIME_COMPARE_INLINE(timeRange.duration, >, mainTimeRange.duration) ? mainTimeRange.duration : timeRange.duration);
    
    //3.在音频素材的编辑环境下添加音轨
    AVMutableCompositionTrack *compositionTrack = [_mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    
    //4.将音频轨道添加到混合时使用的参数。
    AVMutableAudioMixInputParameters *mixInput = [AVMutableAudioMixInputParameters audioMixInputParametersWithTrack:compositionTrack];
    //设置音轨音量
    [mixInput setVolume:audioOptions.audioVolume atTime:audioOptions.atNodeTime];
    [_audioMixParams addObject:mixInput];
    
    if (!audioOptions.enableCycleAdd || CMTIME_COMPARE_INLINE(atTimeRange.duration, >, mainTimeRange.duration)) {//不需要循环播放
        
        //5.将源跟踪的时间范围插入到组合的音轨中。
        insertResult = [compositionTrack insertTimeRange:atTimeRange ofTrack:audioTrack atTime:audioOptions.atNodeTime error:&error];
        if (!insertResult) {
            fslLError(@"mix insert error : %@",error);
        }
    }else{//循环
        
        //多音轨合成的时间节点（意味在什么时间点上开始合成,以主音轨为准）
        //CMTime nextAtTime = mainTimeRange.start;
        CMTime nextAtTime = audioOptions.atNodeTime;
        
        //最后输出的总时长（以主音轨为准）
        CMTime audioDurationTime = mainTimeRange.duration;
        //6.通过合成节点遍历音轨总时长，达到循环添加音轨的目的
        while (CMTIME_COMPARE_INLINE(nextAtTime, <=, audioDurationTime)) {
            
            /**7.循环过程中：还未合成的剩余时间,返回两个CMTimes的差值。*/
            CMTime remainingTime = CMTimeSubtract(audioDurationTime, nextAtTime);
            //通过这个剩余时间，判断需要合成的音轨时间范围是否超过了剩余时间，超过的话，则更新音轨的时间范围
            if (CMTIME_COMPARE_INLINE(remainingTime, <, audioDurationTime)) {
                //8.更新音轨持续时间
                atTimeRange.duration = remainingTime;
            }
            
            //9.将源跟踪的时间范围插入到组合的音轨中。
            insertResult = [compositionTrack insertTimeRange:atTimeRange ofTrack:audioTrack atTime:nextAtTime error:&error];
            if (!insertResult) {
                fslLError(@"enableCycleAdd mix insert error 1: %@",error);
                break;
            }
            
            //返回两个CMTimes的和值
            nextAtTime = CMTimeAdd(nextAtTime, atTimeRange.duration);
        }
    }
}

/**
 * 导出多音频合成结果
 
 * @param handler block
 */
- (void)exportAudioWithCompletionHandler:(void (^ _Nullable)(NSString*, FSLAVMixStatus))handler;
{
    //1.创建一个可变的音频混合对象，用于管理混合音频轨道的输入参数。
    AVMutableAudioMix *audioMix = [AVMutableAudioMix audioMix];
    //混合的输入参数数组。
    audioMix.inputParameters = [NSArray arrayWithArray:_audioMixParams];
    
    //2.创建一个输出对象
    if (!_exporter) {
        _exporter = [[AVAssetExportSession alloc]initWithAsset:_mixComposition presetName:AVAssetExportPresetAppleM4A];
    }
    _exporter.outputFileType = _mainAudio.appOutputFileType;
    _exporter.audioMix = audioMix;
    _exporter.outputURL = _mainAudio.outputFileURL;
    //设置导出的混合音轨操作时间范围
    _exporter.timeRange = CMTimeRangeMake(kCMTimeZero, _mainAudio.atTimeRange.duration);
    
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
            handler(self.mainAudio.outputFilePath,exportStatus);
        }
        
        [self resetMixOperation];
    }];
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
        if ([self.mixDelegate respondsToSelector:@selector(didCompletedMixAudioOutputPath:onAudioMix:)]) {
            [self.mixDelegate didCompletedMixAudioOutputPath:_mainAudio.outputFilePath onAudioMix:self];
        }
    }
}

@end
