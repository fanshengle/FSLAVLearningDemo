//
//  FSLAVSecondAudioRecorder.m
//  FSLAVComponent
//
//  Created by tutu on 2019/7/3.
//  Copyright © 2019 tutu. All rights reserved.
//

#import "FSLAVSecondAudioRecorder.h"

@interface FSLAVSecondAudioRecorder ()<AVCaptureAudioDataOutputSampleBufferDelegate>
{
    dispatch_queue_t _audioCaptureQueue;//一个音频捕获队列
}

@property (nonatomic , strong) AVCaptureDevice           *audioDevice;//音频设备
@property (nonatomic , strong) AVCaptureSession          *audioSession;//音频会话
@property (nonatomic , strong) AVCaptureDeviceInput      *audioDeviceInput;//音频输入
@property (nonatomic , strong) AVCaptureAudioDataOutput  *audioDataOutput;//音频输出
@property (nonatomic , strong) AVCaptureConnection       *audioConnection;//音频连接


@end

@implementation FSLAVSecondAudioRecorder
@dynamic delegate;//解决子类协议继承父类协议的delegate命名警告



- (instancetype)initWithAudioRecordConfiguration:(FSLAVAudioRecorderConfiguration *)configuration{
    if (self = [super init]) {
        _configuration = configuration;
        
        _audioCaptureQueue = dispatch_queue_create("Audio Capture Queue", DISPATCH_QUEUE_SERIAL);
        [self initAudioRecordSession];
    }
    return self;
}

/**
 初始化音频录制会话
 */
- (void)initAudioRecordSession{
    
    if(![self.audioSession canAddInput:self.audioDeviceInput]) return;
    if(![self.audioSession canAddOutput:self.audioDataOutput]) return;
    
    [self.audioSession addInput:self.audioDeviceInput];
    [self.audioSession addOutput:self.audioDataOutput];
    
    //引入音频帧捕获代理
    [self.audioDataOutput setSampleBufferDelegate:self queue:_audioCaptureQueue];
    self.audioConnection = [self.audioDataOutput connectionWithMediaType:AVMediaTypeAudio];
}

#pragma mark -- 懒加载
- (AVCaptureDevice *)audioDevice{
    if (!_audioDevice) {
        
        _audioDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
    
    }
    return _audioDevice;
}

- (AVCaptureDeviceInput *)audioDeviceInput{
    if (!_audioDeviceInput) {
     
        if (!self.audioDevice) return nil;
        NSError *error;
        _audioDeviceInput = [[AVCaptureDeviceInput alloc] initWithDevice:self.audioDevice error:&error];
        if (error) {
            NSAssert(YES, @"设备输入失败");
        }
    }
    return _audioDeviceInput;
}

- (AVCaptureAudioDataOutput *)audioDataOutput{
    if (!_audioDataOutput) {
        
        _audioDataOutput = [[AVCaptureAudioDataOutput alloc] init];
    }
    return _audioDataOutput;
}

- (AVCaptureSession *)audioSession{
    if (!_audioSession) {
    
        if (!self.audioDevice) return nil;
        _audioSession = [[AVCaptureSession alloc] init];
        
    }
    return _audioSession;
}

#pragma mark -- public methods
- (void)startRecord{
    
    [self.audioSession startRunning];
}

- (void)stopRecord{
    
    [self.audioSession stopRunning];
}

#pragma mark -- delegate
#pragma mark -- AVCaptureAudioDataOutputSampleBufferDelegate
- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection{
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(didOutputSampleBuffer:fromAudioRecorder:)]) {
        [self.delegate didOutputSampleBuffer:sampleBuffer fromAudioRecorder:self];
    }
}


@end
