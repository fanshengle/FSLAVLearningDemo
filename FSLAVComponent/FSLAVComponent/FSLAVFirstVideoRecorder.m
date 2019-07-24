//
//  VideoFirstRecorder.m
//  AudioVideoSDK
//
//  Created by tutu on 2019/6/14.
//  Copyright © 2019 tutu. All rights reserved.
//

#import "FSLAVFirstVideoRecorder.h"
#import <AssetsLibrary/AssetsLibrary.h>

@interface FSLAVFirstVideoRecorder ()
<AVCaptureFileOutputRecordingDelegate,
AVCaptureVideoDataOutputSampleBufferDelegate>

@end

@implementation FSLAVFirstVideoRecorder

@dynamic delegate;//解决子类协议继承父类协议的delegate命名警告

- (instancetype)initWithVideoRecordOptions:(FSLAVVideoRecorderOptions *)options{
    if (self = [super init]) {
        
        _options = options;
        
        [self initAVCaptureSession];
    }
    return self;
}

#pragma mark - 设备配置
- (void)initAVCaptureSession{

    //摄像头为前置
    self.videoCaptureDevice = [self deviceWithPosition:_options.devicePosition];
    
    if (![self.captureSession canAddInput:self.captureDeviceInput]) return;
    if (![self.captureSession canAddOutput:self.captureOutput]) return;
    
    //将设备输入添加到会话中
    [self.captureSession addInput:self.captureDeviceInput];
    [self.captureSession addInput:self.audioCaptureDeviceInput];
    
    //将设备输出添加到会话中
    [self.captureSession addOutput:self.captureOutput];
    
    //设置一系列的参数
    //设置分辨率
    if ([self.captureSession canSetSessionPreset:_options.avSessionPreset]) {
        self.captureSession.sessionPreset = _options.avSessionPreset;
    }
    
    //设置输出对象的一些属性
    //返回带有指定媒体类型的输入端口的连接数组中的第一个连接。
    self.captureConnection = [self.captureOutput connectionWithMediaType:AVMediaTypeVideo];

    //设置防抖
    //视频防抖 是在 iOS 6 和 iPhone 4S 发布时引入的功能。到了 iPhone 6，增加了更强劲和流畅的防抖模式，被称为影院级的视频防抖动。相关的 API 也有所改动 (目前为止并没有在文档中反映出来，不过可以查看头文件）。防抖并不是在捕获设备上配置的，而是在 AVCaptureConnection 上设置。由于不是所有的设备格式都支持全部的防抖模式，所以在实际应用中应事先确认具体的防抖模式是否支持：
    //一个布尔值，指示此连接是否支持视频稳定。
    if (![self.captureConnection isVideoStabilizationSupported]) return;
    //最适合与连接一起使用的稳定模式。
    self.captureConnection.preferredVideoStabilizationMode = AVCaptureVideoStabilizationModeAuto;
    
    //保证视频预览层的视频方向是正确的
    self.captureVideoPreviewLayer.connection.videoOrientation = [self getCaptureVideoOrientation];
    
    //摄像头方向
    self.captureConnection = [self.captureVideoPreviewLayer connection];
    self.captureConnection.videoOrientation = AVCaptureVideoOrientationPortrait;

    //初始化缩放比例
    //self.effectiveScale = self.beginGestureScale = 1.0f;
    
    //给设备添加通知
    [self addNotificationToCaptureDevice:self.videoCaptureDevice ];
}

//容纳不同输出
- (AVCaptureOutput *)captureOutput{
    
    if (!_captureOutput) {
        
        if (_options.recordOutputType == FSLAVVideoRecordMovieFileOutput) {
            
            _captureOutput = self.captureMovieFileOutput;
        }else{
            
            _captureOutput = self.captureVideoDataOutput;
            
            //摄像头采集queue
            dispatch_queue_t queue = dispatch_queue_create("VideoCaptureQueue", DISPATCH_QUEUE_SERIAL);
            [self.captureVideoDataOutput setSampleBufferDelegate:self queue:queue]; // 摄像头数据输出delegate
        }
    }
    return _captureOutput;
}

#pragma mark -- private methods
/**
 移除视频捕捉预览layer
 */
- (BOOL)isRemovePreviewLayer{
    
    if (_captureVideoPreviewLayer) {
        
        if (_options.isOutPreview) {
            
            [_captureVideoPreviewLayer removeFromSuperlayer];
        }
    }
    
    return _options.isOutPreview;
}

/**
 添加视频捕捉预览layer到容器视图上
 */

- (BOOL)isAddPreviewLayer{
    BOOL isAdd = NO;
    if (_captureVideoPreviewLayer) {
        if (!_containerView.layer.sublayers) {// 为空
            isAdd = YES;
            [_containerView.layer addSublayer:_captureVideoPreviewLayer];
        }
    }
    return isAdd;
}

/**
 录制时间是否超过最大录制时间
 */
- (BOOL)isMoreRecordTime{
    
    BOOL isMore = NO;
    if (_recordTime >= _options.maxRecordDelay) {//当前录制的时间与最大录制时间进行比较
        isMore = YES;
    }
    return YES;
}
/**
 录制时间是否小于最小录制时间
 */
- (BOOL)isLessRecordTime{
    BOOL isLess = NO;
    if (_recordTime <= _options.minRecordDelay) {//当前录制的时间与最小录制时间进行比较
        isLess = YES;
    }
    return isLess;
}

#pragma mark -- public methods
/**
 将设备捕捉到的画面呈现到某个view上
 
 @param view 显示具体捕捉画面的视图
 */
- (void)showCaptureSessionOnView:(UIView *)view{
    _containerView = view;
    
    CALayer *layer = view.layer;
    layer.masksToBounds = YES;
    self.captureVideoPreviewLayer.frame = layer.bounds;
    
    //图层预览
    [view.layer addSublayer:self.captureVideoPreviewLayer];
}


/**
 告诉接收器开始运行。
 */
- (void)startRunning{
    
    [self.captureSession startRunning];
    
    [self isAddPreviewLayer];
}

/**
 告诉接收器停止运行。
 */
- (void)stopRunning{
    
    if(!_captureSession) return;

    [self.captureSession stopRunning];

    [self isRemovePreviewLayer];
}

//切换设备的摄像机位置
- (void)switchCameraDevicePosition{
    
    //获取到捕获过的设备
    AVCaptureDevice *currentDevice = [self.captureDeviceInput device];
    //当前设备的摄像头位置
    AVCaptureDevicePosition currentPosition = [currentDevice position];
    //移除视频区域变好是的通知
    [self removeNotificationFromCaptureDevice:currentDevice];
    
    AVCaptureDevice *toChangeDevice;
    AVCaptureDevicePosition toChangePosition = AVCaptureDevicePositionFront;
    if (currentPosition == AVCaptureDevicePositionUnspecified || currentPosition == AVCaptureDevicePositionFront) {
        toChangePosition = AVCaptureDevicePositionBack;
    }
    toChangeDevice = [self deviceWithPosition:toChangePosition];
    [self addNotificationToCaptureDevice:toChangeDevice];
    
    //获得要调整的设备输入对象
    AVCaptureDeviceInput *toChangeDeviceInput = [[AVCaptureDeviceInput alloc] initWithDevice:toChangeDevice error:nil];
    
    //改变会话的配置前一定要先开启配置，配置完成后提交配置改变
    [self.captureSession beginConfiguration];
    //移除原有输入对象
    [self.captureSession removeInput:self.captureDeviceInput];
    //添加新的输入对象
    if (![self.captureSession canAddInput:toChangeDeviceInput]) return;
    [self.captureSession addInput:toChangeDeviceInput];
    self.captureDeviceInput = toChangeDeviceInput;
    //提交会话配置
    [self.captureSession commitConfiguration];
}


/**
 录制定时事件
 */
- (void)recordTimerAction{
    
    _options.maxRecordDelay = _recordTime;
    
    if ([self isLessRecordTime]) {
        [self notifyRecordState:FSLAVRecordStateLessMinRecordTime];
    }
    
    if ([self isMoreRecordTime]) {
        [self notifyRecordState:FSLAVRecordStateMoreMaxRecordTime];
    }
}

/**
 保存视频数据到添加的路径下,录制视频
 */
- (void)startRecord
{
    if(_isRecording) return;
    _isRecording = YES;
    
    if (_options.recordOutputType == FSLAVVideoRecordMovieFileOutput) {
        
        [self.captureMovieFileOutput startRecordingToOutputFileURL:_options.outputFileURL recordingDelegate:self];
    }else{
    }
    
    //添加定时器
    [self removeRecordTimer];
    [self addRecordTimer];
}

//保存视频数据输，结束录制
- (void)stopRecord
{
    if(!_isRecording) return;
    _isRecording = YES;
    
    if (_options.recordOutputType == FSLAVVideoRecordMovieFileOutput) {
        
        if ([self.captureMovieFileOutput isRecording]) [self.captureMovieFileOutput stopRecording];
    }
    
    //移除定时器
    [self removeRecordTimer];
}

//重录视频
- (void)reRecording{
    
    
}

#pragma mark -- 代理
#pragma mark -- AVCaptureFileOutputRecordingDelegate
#pragma mark - 视频输出代理开始录制
-(void)captureOutput:(AVCaptureFileOutput *)captureOutput didStartRecordingToOutputFileAtURL:(NSURL *)fileURL fromConnections:(NSArray *)connections{
    //SHOWMESSAGE(@"开始录制");
    [self notifyRecordState:FSLAVRecordStateReadyToRecord];
}


#pragma mark - 录制完成回调
-(void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray *)connections error:(NSError *)error{
    //上传视频转换视频名称代码，不要直接干了就是
    //SHOWMESSAGE(@"上传中");
    //NSString * uploadAddress = [outputFileURL absoluteString];;
    //uploadVideoObject * upload = [[uploadVideoObject alloc]init];
    //NSMutableString * mString = [NSMutableString stringWithString:uploadAddress];
    //NSString *strUrl = [mString stringByReplacingOccurrencesOfString:@"file://" withString:@""];
    //[upload uploadVideo:strUrl];
    
    //视频录入完成之后在后台将视频存储到相册
    [self notifyRecordState:FSLAVRecordStateCompleted];
}

#pragma mark -- AVCaptureVideoDataOutputSampleBufferDelegate
- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection{
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(didOutputSampleBuffer:fromVideoRecorder:)]) {
        [self.delegate didOutputSampleBuffer:sampleBuffer fromVideoRecorder:self];
    }
}

#pragma mark --通知
//给输入设备添加通知
- (void)addNotificationToCaptureDevice:(AVCaptureDevice *)captureDevice
{
    //注意添加区域改变捕获通知必须首先设置设备允许捕获
    [self changeDeviceProperty:^(AVCaptureDevice *captureDevice) {
        captureDevice.subjectAreaChangeMonitoringEnabled = YES;
    }];
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    //捕获区域发生改变
    [notificationCenter addObserver:self selector:@selector(areaChange:) name:AVCaptureDeviceSubjectAreaDidChangeNotification object:captureDevice];
}

//改变设备属性的统一操作方法
- (void)changeDeviceProperty:(void (^)(AVCaptureDevice *))propertyChange
{
    AVCaptureDevice *captureDevice = [self.captureDeviceInput device];
    NSError *error;
    //注意改变设备属性前一定要首先调用lockForConfiguration:调用完之后使用unlockForConfiguration方法解锁
    if ([captureDevice lockForConfiguration:&error]) {
        propertyChange(captureDevice);
        [captureDevice unlockForConfiguration];
    }else {
        NSLog(@"设置设备属性过程发生错误，错误信息：%@", error.localizedDescription);
    }
}

//捕获区域改变
- (void)areaChange:(NSNotification *)notification
{
    NSLog(@"捕获区域改变");
}

//移除区域发生改变的通知
- (void)removeNotificationFromCaptureDevice:(AVCaptureDevice *)captureDevice{
    //当AVCaptureDevice实例检测到视频主题区域发生重大更改时发布。
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter removeObserver:self name:AVCaptureDeviceSubjectAreaDidChangeNotification object:captureDevice];
}


//设置聚焦点
- (void)focusWithMode:(AVCaptureFocusMode)focusMode exposureMode:(AVCaptureExposureMode)exposureMode atPoint:(CGPoint)point
{
    [self changeDeviceProperty:^(AVCaptureDevice *captureDevice) {
        if ([captureDevice isFocusModeSupported:focusMode]) {
            [captureDevice setFocusMode:AVCaptureFocusModeAutoFocus];
        }
        if ([captureDevice isFocusPointOfInterestSupported]) {
            [captureDevice setFocusPointOfInterest:point];
        }
        if ([captureDevice isExposureModeSupported:exposureMode]) {
            [captureDevice setExposureMode:AVCaptureExposureModeAutoExpose];
        }
        if ([captureDevice isExposurePointOfInterestSupported]) {
            [captureDevice setExposurePointOfInterest:point];
        }
    }];
}

/**
 录制状态：代理通知回调
 
 @param state 视频录制状态
 */
- (void)notifyRecordState:(FSLAVRecordState)state{
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(didRecordingStatusChanged:recorder:)]) {
        [self.delegate didRecordingStatusChanged:state recorder:self];
    }
}

@end
