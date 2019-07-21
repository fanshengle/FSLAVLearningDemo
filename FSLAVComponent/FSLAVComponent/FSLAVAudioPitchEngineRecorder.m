//
//  FSLAVAudioPitchEngineRecorder.m
//  FSLAVComponent
//
//  Created by tutu on 2019/7/18.
//  Copyright © 2019 tutu. All rights reserved.
//

#import "FSLAVAudioPitchEngineRecorder.h"
#import "FSLAVMediaSampleBufferAssistant.h"
#import "FSLAVMeidaTimelineSlice.h"
#import "FSLAVMeidaTimelineSlice.h"

@interface  FSLAVAudioPitchEngineRecorder()
<
AVCaptureAudioDataOutputSampleBufferDelegate,
FSLAVAudioPitchEngineDelegate,
AVCaptureVideoDataOutputSampleBufferDelegate
>

{
    AVCaptureDeviceInput *_audioInput;
    AVCaptureAudioDataOutput *_audioOutput;
    AVCaptureSession *_captureSession;
    AVCaptureDevice *_microphone;
    
    dispatch_queue_t audioProcessingQueue;
    
    /** 纠正时间戳偏移量 */
    CMTime _offsetTime;
}


/**
 音频变调处理引擎
 */
@property (nonatomic, strong) FSLAVAudioPitchEngine *audioPitch;

/**
 当前正在录制的音频片段
 */
@property (nonatomic, strong) FSLAVMeidaTimelineSlice *recordingPitchTimeSlice;

/**
 记录全部录制片段
 */
@property (nonatomic, strong) NSMutableArray<FSLAVMeidaTimelineSlice *> *audioFragmentArray;

/**
 记录删除的录制片段
 */
@property (nonatomic, strong) NSMutableArray<FSLAVMeidaTimelineSlice *> *dropFragmentArr;

/**
 录音状态
 */
@property (nonatomic, assign) FSLAVRecordState status;

/**
 已录制的时长
 */
@property (nonatomic, assign, readonly) NSTimeInterval outputDuration;
@end

@implementation FSLAVAudioPitchEngineRecorder

#pragma mark -- init

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self createCaptureSession];
    }
    return self;
}

- (instancetype)initWithAudioRecordOptions:(FSLAVAudioRecorderOptions *)options{
    if (self = [super initWithAudioRecordOptions:options]) {
        
        [self createCaptureSession];
    }
    return self;
}

/**
 设置默认参数配置
 */
- (void)setConfig;
{
    
    _pitchType = FSLAVSoundPitchNormal;
    _audioFragmentArray = [NSMutableArray arrayWithCapacity:2];
    _dropFragmentArr = [NSMutableArray arrayWithCapacity:2];
    
    _options.audioFormat = kAudioFormatMPEG4AAC;
}

/**
 录音捕获会话初始化
 @return BOOL 是否初始化
 */
- (BOOL)createCaptureSession;
{
    if (_captureSession) return NO;
    
    _captureSession = [[AVCaptureSession alloc] init];
    
    //开始配置
    [_captureSession beginConfiguration];
    
    //麦克风设备
    _microphone = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
    //输入
    NSError *error;
    _audioInput = [[AVCaptureDeviceInput alloc] initWithDevice:_microphone error:&error];
    if (error) {
        fslLError(@"audioInput init failed :%@",error);
        return NO;
    }
    //输出
    _audioOutput = [[AVCaptureAudioDataOutput alloc] init];
    
    if ([_captureSession canAddInput:_audioInput])
    {
        [_captureSession addInput:_audioInput];
    }else{
        fslLError(@"Couldn't add audio audioInput");
        return NO;
    }
    if ([_captureSession canAddOutput:_audioOutput])
    {
        [_captureSession addOutput:_audioOutput];
    }else{
        fslLError(@"Couldn't add audio audioOutput");
        return NO;
    }
    
    audioProcessingQueue = dispatch_get_global_queue(0, 0);
    [_audioOutput setSampleBufferDelegate:self queue:audioProcessingQueue];
    
    //结束配置
    [_captureSession commitConfiguration];
    
    return YES;
}

#pragma mark -- public methods
/**
 开始
 */
- (void)startRecord{
    
    if(!_isRecording) return;
    _isRecording = YES;
    
    //开始写数据
    [self startWriting];
    //开始捕获音频
    [_captureSession startRunning];
    
    //通知回调
    [self notifyRecordState:FSLAVRecordStateReadyToRecord];
    
    if (_isRecording && _isPaused) {
        //继续录制
        [self resumeRecord];
    }
}

/**
 暂停
 */
- (void)pauaseRecord{
    
    if(!_isRecording) return;
    _isRecording = YES;
    _isPaused = YES;
    
    // 添加当前录制音频的时间切片数据
    [self appendRecordingAudioFrament];
}

/**
 停止
 */
- (void)stopRecord{
    
    if(!_isRecording) return;
    _isRecording = NO;
    
    if (!_isPaused) {//先暂停录制
        [self pauaseRecord];
    }
    
    //停止捕获音频
    [_captureSession stopRunning];
    
    _offsetTime = kCMTimeInvalid;
    //入列缓存结束调用
    [_audioPitch processInputBufferEnd];
    
    //将所有未完成的输入标记为已完成，并完成输出文件的编写。
    [_audioWriter finishWritingWithCompletionHandler:^{
        if (self->_options.outputFilePath) {
            [self startAudioComposition];
        }
        self->_audioWriter = nil;
    }];
}

/**
 重录
 */
- (void)reRecording{
    // 取消录制
    [self cancleRecord];
    
    //开始录制
    [self startRecord];
}

/**
 取消录制
 */
- (void)cancleRecord;
{
    //停止捕获音频数据
    [_captureSession stopRunning];
    //停止写入器写入数据
    [self cancelWriting];
    //删除临时存储文件
    [_options clearOutputFilePath];
 
    //清除音频片段数组
    [self clearAudioFragmentArray];
    
    //通知回调
    [self notifyRecordState:FSLAVRecordStateCanceled];
}

/**
 删除最后一个音频片段
 */
- (void)deleteLastAudioFragment;
{
    if (_audioFragmentArray.count == 0 || _isRecording) return;
    
    FSLAVMeidaTimelineSlice *lastFragment = [self getLastValidSpeedAudioFragment];
    if (lastFragment) {
        lastFragment.isRemove = YES;
        [_dropFragmentArr addObject:lastFragment];
    }
}

#pragma mark -- private methods
/**
 继续录制
 */
- (void)resumeRecord;
{
    if (!_isRecording || !_isPaused) return;
    _isRecording = YES;
    _isPaused = NO;
    
    //通知回调
    [self notifyRecordState:FSLAVRecordStateResume];
}

/**
 合并视频
 */
- (void)startAudioComposition;
{
    if (!_dropFragmentArr.count) {
        
        //状态回调通知
        [self notifyRecordState:FSLAVRecordStateCompleted];
        //录制结果通知回调
        [self notifyRecordResult:_options];
        
        //清除数组
        [self clearAudioFragmentArray];
        return;
    }
    
    FSLAVMediaTimelineSliceOptions *timeSliceOptions = [[FSLAVMediaTimelineSliceOptions alloc] init];
    timeSliceOptions.inputMediaPath = _options.outputFilePath;
    timeSliceOptions.recordOptions = _options;
    
    FSLAVMediaTimelineSliceComposition *audioComposition = [[FSLAVMediaTimelineSliceComposition alloc] init];
    audioComposition.meidaFragmentArr = _audioFragmentArray;
    
    typeof(self) weakself = self;
    [audioComposition startAudioCompositionWithCompletionHandler:^(NSString * _Nonnull outputFilePath, FSLAVMediaTimelineSliceCompositionStatus status) {
        switch (status)
        {
            case FSLAVMediaTimelineSliceCompositionStatusCompleted:
                //通知回调
                [weakself notifyRecordState:FSLAVRecordStateCompleted];
                //替换成合成的输出地址
                weakself->_options.outputFilePath = outputFilePath;
                [weakself notifyRecordResult:weakself->_options];
                
                break;
            case FSLAVMediaTimelineSliceCompositionStatusFailed:
                
                //通知回调
                [weakself notifyRecordState:FSLAVRecordStateFailed];
                break;
            default:
                break;
        }
        
        //清除数组
        [self clearAudioFragmentArray];
    }];
}

/**
 已录制输出时长，不包含已删除的片段
 
 @return 有效输出时长
 */
- (NSTimeInterval)outputDuration;
{
    float recordingDuration = _isRecording ? CMTimeGetSeconds([self recordingPitchTimeSlicDurationTime]) : 0;
    float recordedDuration = _audioFragmentArray.count ? CMTimeGetSeconds([self getLastAudioFragmentDuration]) - CMTimeGetSeconds([self getAllRemoveAudioFragmentDuration]) : 0;
    
    //更新已录制的有效输出时长
    _options.outputDuration = recordingDuration + recordedDuration;
    
    return recordingDuration + recordedDuration;
}


/**
 将当期录制的音频片段添加到数组
 */
- (void)appendRecordingAudioFrament;
{
    if(!_recordingPitchTimeSlice) return;
    [_audioFragmentArray addObject:_recordingPitchTimeSlice];
    _recordingPitchTimeSlice = nil;
}

/**
 计算录制过程中与开始时间获取持续时间
 @return CMTime
 */
- (CMTime)recordingPitchTimeSlicDurationTime;
{
    if (!_recordingPitchTimeSlice) return kCMTimeZero;
    return _recordingPitchTimeSlice.adjustedTime;
}

/**
 已录制片段的总时长 单位：/s:最后一次录制的结束时间
 @return Float64
 */
- (CMTime)getLastAudioFragmentDuration;
{
    if (_audioFragmentArray.count == 0) return kCMTimeZero;
   
    FSLAVMeidaTimelineSlice *pitchTimeSlice = _audioFragmentArray.lastObject;
    CMTime totalTime = pitchTimeSlice.end;
    return totalTime;
}

/**
 所有的已删除的片段持续时间 单位：/s
 @return Float64
 */
- (CMTime)getAllRemoveAudioFragmentDuration;
{
    CMTime totalTime = kCMTimeZero;
    for (FSLAVMeidaTimelineSlice *fragment in _dropFragmentArr) {
        totalTime = CMTimeAdd(totalTime, fragment.adjustedTime);
    }
    return totalTime;
}

/**
 获取最后一个录制片段
 @return FSLAVMeidaTimelineSlice
 */
- (FSLAVMeidaTimelineSlice *)getLastValidSpeedAudioFragment;
{
    if(_audioFragmentArray.count == 0) return nil;
    
    NSMutableArray<FSLAVMeidaTimelineSlice *> *allTimeRangeArray = [NSMutableArray arrayWithArray:_audioFragmentArray];
    [allTimeRangeArray removeObjectsInArray:_dropFragmentArr];
    FSLAVMeidaTimelineSlice *fragment = [allTimeRangeArray lastObject];
    return fragment;
}

/**
 移除录制声音配置
 */
- (void)removeInputsAndOutputs;
{
    [_captureSession beginConfiguration];
    if (_microphone != nil)
    {
        [_captureSession removeInput:_audioInput];
        [_captureSession removeOutput:_audioOutput];
        _audioInput = nil;
        _audioOutput = nil;
        _microphone = nil;
    }
    [_captureSession commitConfiguration];
}

/**
 清除音频片段数组
 */
- (void)clearAudioFragmentArray;
{
    [_audioFragmentArray removeAllObjects];
    [_dropFragmentArr removeAllObjects];
}

#pragma mark - AVCaptureAudioDataOutputSampleBufferDelegate
- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    if (!_captureSession.isRunning || !_isRecording) return;
    
    
    if(output == _audioOutput){
        
        if (!_audioPitch) {
            //创建音频变调引擎
            [self createAudioEnginePitch:sampleBuffer];
        }
        //将buffer数据喂给音频音调引擎
        [self processSampleBuffer:sampleBuffer];
    }
}


#pragma mark  ------------------------------------ FSLAVAudioPitchEngine 核心 API BEGIN ------------------------------------
/**
 step1: 创建音频变调 API
 */
- (void)createAudioEnginePitch:(CMSampleBufferRef)sampleBuffer;
{
    if (_audioPitch) {
        //重置引擎
        [_audioPitch reset];
        //刷新引擎数据
        [_audioPitch flush];
    }else{
        
        //通过buffer获取音频数据描述信息
        CMFormatDescriptionRef formatRef = CMSampleBufferGetFormatDescription(sampleBuffer);
        /** 获取 CMSampleBufferRef 音频信息 */
        FSLAVAudioTrackInfo *trackInfo = [[FSLAVAudioTrackInfo alloc] initWithCMAudioFormatDescriptionRef:formatRef];
        // 创建 FSLAVAudioPitchEngine 引擎
        // step1: 创建变声 API
        _audioPitch = [[FSLAVAudioPitchEngine alloc] initWithInputAudioInfo:trackInfo];
        _audioPitch.delegate = self;
        //pitch与pitchType只能使一个有效
        if (_pitch) {
            _audioPitch.pitch = self.pitch;
            return;
        }
        _audioPitch.pitchType = self.pitchType;
    }
}

/**
 step2: 设置音效类型
 */
- (void)setPitchType:(FSLAVSoundPitchType)pitchType;
{
    if (_pitchType == pitchType) return;
    _pitchType = pitchType;
    _audioPitch.pitchType = pitchType;
}

/**
 * 改变音频音调 [速度设置将失效]
 * pitch 0 > pitch [大于1时声音升调，小于1时为降调]
 * pitchType 与 pitch不能同时设置；因为pitchType就是设置固定值pitch得到的
 */
- (void)setPitch:(float)pitch{
    if (_pitch == pitch) return;

    _pitch = pitch;
    _audioPitch.pitch = pitch;
}

/**
 step3: 将数据送入 FSLAVAudioPitchEngine
 @param sampleBuffer CMSampleBufferRef
 */
- (void)processSampleBuffer:(CMSampleBufferRef)sampleBuffer;
{
    
    _isRecording = YES;
    //录制状态通知回调
    [self notifyRecordState:FSLAVRecordStateRecording];

    
    //最大时长是否设置
    if (_options.maxRecordDelay != -1) {
        //已经录制的总时长是否大于最大允许的录制时长
        if (self.outputDuration >= _options.maxRecordDelay) {
            [self stopRecord];
            //修正录制时长偏差
            _options.outputDuration = _options.maxRecordDelay;
        }
        return;
    }
    //录制结果通知回调
    [self notifyRecordResult:_options];
    
    if (_isPaused) {//暂停
        _isRecording = NO;
        //录制状态通知回调
        [self notifyRecordState:FSLAVRecordStatePause];
        return;
    }

    /** 记录录制的时间片段 */
    if (!_recordingPitchTimeSlice) {
        _recordingPitchTimeSlice = [[FSLAVMeidaTimelineSlice alloc] init];
        
        //获取最后时间片段的结束时间
        CMTime lastEndTime = [self getLastAudioFragmentDuration];
        //当前正在录制的音频片段的时间赋值:lastEndTime上一次的录制结束时间，这一次录制的开始时间
        _recordingPitchTimeSlice.start = lastEndTime;
        
        //当前buffer显示（z录制）时间
        CMTime sampleBufferTime = CMSampleBufferGetOutputPresentationTimeStamp(sampleBuffer);
        //时间的偏移量,新老两次时间的间隔
        _offsetTime = CMTimeSubtract(sampleBufferTime, lastEndTime);
     }

    /**  调整 CMSampleBufferRef 写入时间 */
    CMSampleBufferRef tempSampleBuffer = [FSLAVMediaSampleBufferAssistant adjustPTS:sampleBuffer byOffset:_offsetTime];
    //深拷贝sampleBuffer
    CMSampleBufferRef copyBuffer = [FSLAVMediaSampleBufferAssistant sampleBufferCreateCopyWithDeep:tempSampleBuffer];
    CMSampleBufferInvalidate(tempSampleBuffer);
    CFRelease(tempSampleBuffer);
    tempSampleBuffer = NULL;
    
    // 获取处理后buffer的时间
    CMTime currentSampleTime = CMSampleBufferGetOutputPresentationTimeStamp(copyBuffer);
    _recordingPitchTimeSlice.end = currentSampleTime;
    
    // 将音频数据送入处理引擎处理
    [_audioPitch processInputBuffer:copyBuffer];
}

#pragma mark FSLAVAudioPitchEngineDelegate

/**
 step4: 接收 FSLAVAudioPitchEngine 处理后的数据
 @param pitchEngine 音频处理对象
 @param outputBuffer 变调变速后的音频数据
 @param autoRelease 是否释放音频数据，默认为NO
 */
- (void)pitchEngine:(FSLAVAudioPitchEngine *)pitchEngine syncAudioPitchOutputBuffer:(CMSampleBufferRef)outputBuffer autoRelease:(BOOL *)autoRelease;
{
    if (outputBuffer && _isRecording) {
        
        if (_audioWriter.status == AVAssetWriterStatusWriting) {
            CMTime currentSampleTime = CMSampleBufferGetOutputPresentationTimeStamp(outputBuffer);
            //一个布尔值，指示输入是否准备好接受更多的媒体数据。
            while (!_audioWriterInput.readyForMoreMediaData) {
                //创建并返回一个日期对象，该对象设置为当前日期和时间的给定秒数。
                NSDate *maxDate = [NSDate dateWithTimeIntervalSinceNow:0.5];
                //运行循环，直到指定的日期，在此期间，它处理来自所有附加输入源的数据。
                [[NSRunLoop currentRunLoop] runUntilDate:maxDate];
            }
            if (!_audioWriterInput.readyForMoreMediaData)
            {
                
                fslLDebug(@"2: Had to drop an audio frame %@", CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, currentSampleTime)));
            }else{
                //拼接buffer数据
                if (![_audioWriterInput appendSampleBuffer:outputBuffer])
                    fslLDebug(@"Problem appending audio buffer at time: %@", CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, currentSampleTime)));
            }
        }
    }
    
    // 标识 syncAudioPitchOutputBuffer 回调处理完成后  FSLAVAudioPitchEngine 是否自动回收 outputBuffer
    // 如果后续需要对 outputBuffer 异步处理，可以将 autoRelease 设为 NO,或对 outputBuffer 进行 deep copy，防止 syncAudioPitchOutputBuffer 处理完成后被回收。
    *autoRelease = YES;
}
#pragma mark  ------------------------------------ FSLAVAudioPitchEngine 核心 API END ------------------------------------

/**
 录制状态：代理通知回调
 
 @param state 音频录制状态
 */
- (void)notifyRecordState:(FSLAVRecordState)state{
    
    if ([self.delegate respondsToSelector:@selector(didRecordingStatusChanged:recorder:)])
        [self.delegate didRecordingStatusChanged:state recorder:self];
}

/**
 录制结果：代理通知回调

 @param recoderOptions 音频的配置项结果
 */
- (void)notifyRecordResult:(FSLAVAudioRecorderOptions *)recoderOptions{
    
    if ([self.delegate respondsToSelector:@selector(didRecordedAudioResult:recorder:)])
        [self.delegate didRecordedAudioResult:recoderOptions recorder:self];
}

/**
 摧毁音频音调引擎
 */
- (void)destory{
    [super destory];
    
    if (_audioPitch) {
        [_audioPitch destory];
        _audioPitch = nil;
    }
    [self.options clearOutputFilePath];
    
    [_audioOutput setSampleBufferDelegate:nil queue:dispatch_get_main_queue()];
    [self removeInputsAndOutputs];
}


@end
