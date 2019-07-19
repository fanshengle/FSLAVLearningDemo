//
//  FSLAVAudioPitchEngineRecorder.m
//  FSLAVComponent
//
//  Created by tutu on 2019/7/18.
//  Copyright © 2019 tutu. All rights reserved.
//

#import "FSLAVAudioPitchEngineRecorder.h"
#import "FSLAVMediaSampleBufferAssistant.h"

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
    
    CMTime _startTime;
    
    // 音频变调处理引擎
    FSLAVAudioPitchEngine *_audioPitch;
}

@end

@implementation FSLAVAudioPitchEngineRecorder

#pragma mark -- init
- (instancetype)initWithAudioRecordOptions:(FSLAVAudioRecoderOptions *)options{
    if (self = [super initWithAudioRecordOptions:options]) {
        
        [self createCaptureSession];
    }
    return self;
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
    if(_isRecording && [_captureSession isRunning]) return;
    _isRecording = YES;
    
    //开始写数据
    [self startWriting];
    //开始捕获音频
    [_captureSession startRunning];
}

/**
 暂停
 */
- (void)pauaseRecord{
    if(!_isRecording && ![_captureSession isRunning]) return;
    _isRecording = NO;
    
    //停止捕获音频
    [_captureSession stopRunning];
    
    //入列缓存结束调用
    [_audioPitch processInputBufferEnd];
    
    typeof(self) weakSelf = self;
    //将所有未完成的输入标记为已完成，并完成输出文件的编写。
    [_audioWriter finishWritingWithCompletionHandler:^{
        weakSelf->_audioWriter = nil;
    }];
}

/**
 停止
 */
- (void)stopRecord{
    
    if(!_isRecording && ![_captureSession isRunning]) return;
    _isRecording = NO;
    
    //停止捕获音频
    [_captureSession stopRunning];
    
    _startTime = kCMTimeInvalid;
    //入列缓存结束调用
    [_audioPitch processInputBufferEnd];
    
    typeof(self) weakSelf = self;
    //将所有未完成的输入标记为已完成，并完成输出文件的编写。
    [_audioWriter finishWritingWithCompletionHandler:^{
        weakSelf->_audioWriter = nil;
    }];
}

/**
 重录
 */
- (void)reRecording{
    
}


#pragma mark  ------------------------------------ FSLAVAudioPitchEngine 核心 API BEGIN ------------------------------------
/**
 step1: 创建音频变调 API
 */
- (void)createAudioEnginePitch:(FSLAVAudioTrackInfo *)trackInfo;
{
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

/**
 step2: 设置音效类型
 */
- (void)setPitchType:(FSLAVSoundPitchType)pitchType;
{
    _pitchType = pitchType;
    _audioPitch.pitchType = pitchType;
}

/**
 * 改变音频音调 [速度设置将失效]
 * pitch 0 > pitch [大于1时声音升调，小于1时为降调]
 * pitchType 与 pitch不能同时设置；因为pitchType就是设置固定值pitch得到的
 */
- (void)setPitch:(float)pitch{
    _pitch = pitch;
    _audioPitch.pitch = pitch;
}

/**
 step3: 将数据送入 FSLAVAudioPitchEngine
 @param sampleBuffer CMSampleBufferRef
 */
- (void)processSampleBuffer:(CMSampleBufferRef)sampleBuffer;
{
    if (!_audioPitch) {
        
        /** 获取 CMSampleBufferRef 音频信息 */
        FSLAVAudioTrackInfo *trackInfo = [[FSLAVAudioTrackInfo alloc] initWithCMAudioFormatDescriptionRef:CMSampleBufferGetFormatDescription(sampleBuffer)];
        
        // 创建 FSLAVAudioPitchEngine 引擎
        [self createAudioEnginePitch:trackInfo];
    }
    
    _isRecording = YES;
    // 获取当前buffer的时间
    CMTime currentSampleTime = CMSampleBufferGetOutputPresentationTimeStamp(sampleBuffer);
    
    if (CMTIME_IS_INVALID(_startTime)) {//时间是否有效
        if (_audioWriter.status != AVAssetWriterStatusWriting) {//是否在写数据
            [_audioWriter startWriting];
        }
        //一定要在startWriting之后调用，该时间定义从源样例的时间轴到编写文件的时间轴的映射
        [_audioWriter startSessionAtSourceTime:currentSampleTime];
        _startTime = currentSampleTime;
    }
    
    /**  调整 CMSampleBufferRef 写入时间 */
    CMSampleBufferRef tempSampleBuffer = [FSLAVMediaSampleBufferAssistant adjustPTS:sampleBuffer byOffset:_startTime];
    //深拷贝sampleBuffer
    CMSampleBufferRef copyBuffer = [FSLAVMediaSampleBufferAssistant sampleBufferCreateCopyWithDeep:tempSampleBuffer];
    CMSampleBufferInvalidate(tempSampleBuffer);
    CFRelease(tempSampleBuffer);
    tempSampleBuffer = NULL;
    
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


@end
