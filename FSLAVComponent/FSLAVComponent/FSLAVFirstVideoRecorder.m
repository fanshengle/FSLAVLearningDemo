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


@property (nonatomic, strong) AVCaptureDevice *device;//获得输入设备（前置摄像头
@property (nonatomic, strong) AVCaptureDeviceInput *captureDeviceInput;//负责从AVCaptureDevice获得输入数据
@property (nonatomic, strong) AVCaptureDevice *audioCaptureDevice;//添加一个音频输入设备
@property (nonatomic, strong) AVCaptureDeviceInput *audioCaptureDeviceInput;//添加一个音频输入设备
@property (nonatomic, strong) AVCaptureSession *captureSession;//负责输入和输出设置之间的数据传递
@property (nonatomic, strong) AVCaptureConnection *captureConnection;//捕获会话中特定的一对捕获输入和捕获输出对象之间的连接。

@property (nonatomic, strong) AVCaptureOutput *captureOutput;
@property (nonatomic, strong) AVCaptureMovieFileOutput *captureMovieFileOutput;//将数据视频输出流写入文件
@property (nonatomic, strong) AVCaptureVideoDataOutput *captureVideoDataOutput;//获取视频帧数据

@property (nonatomic, strong) AVCaptureVideoPreviewLayer *captureVideoPreviewLayer;//相机拍摄预览图层
@property (nonatomic, assign) AVCaptureDevicePosition devicePosion;//摄像头位置

@property (nonatomic, assign) UIBackgroundTaskIdentifier backgroundTaskIdentifier;//后台任务标识

/**相机捕获会话的容器视图*/
@property (nonatomic,strong) UIView *cameraContainerView;

@end

@implementation FSLAVFirstVideoRecorder

- (instancetype)init
{
    self = [super init];
    if (self) {
        
        _recordPosition = FSLAVVideoRecordPositionFront;
        _recordVoiceType =FSLAVVideoRecordVoiceTypeSoundType;
        _recordOutputType =FSLAVVideoRecordMovieFileOutput;
        
    }
    return self;
}

#pragma mark - 设备配置
- (void)initAVCaptureSession{
    
    if (![self.captureSession canAddInput:self.captureDeviceInput]) return;
    if (![self.captureSession canAddOutput:self.captureOutput]) return;
    
    //将设备输入添加到会话中
    [self.captureSession addInput:self.captureDeviceInput];
    [self.captureSession addInput:self.audioCaptureDeviceInput];
    
    //将设备输出添加到会话中
    [self.captureSession addOutput:self.captureOutput];
    
    //设置输出对象的一些属性
    //返回带有指定媒体类型的输入端口的连接数组中的第一个连接。
    self.captureConnection = [self.captureOutput connectionWithMediaType:AVMediaTypeVideo];

    //设置防抖
    //视频防抖 是在 iOS 6 和 iPhone 4S 发布时引入的功能。到了 iPhone 6，增加了更强劲和流畅的防抖模式，被称为影院级的视频防抖动。相关的 API 也有所改动 (目前为止并没有在文档中反映出来，不过可以查看头文件）。防抖并不是在捕获设备上配置的，而是在 AVCaptureConnection 上设置。由于不是所有的设备格式都支持全部的防抖模式，所以在实际应用中应事先确认具体的防抖模式是否支持：
    //一个布尔值，指示此连接是否支持视频稳定。
    if (![self.captureConnection isVideoStabilizationSupported]) return;
    //最适合与连接一起使用的稳定模式。
    self.captureConnection.preferredVideoStabilizationMode = AVCaptureVideoStabilizationModeAuto;
    
    //摄像头方向
    self.captureConnection = [self.captureVideoPreviewLayer connection];
    self.captureConnection.videoOrientation = AVCaptureVideoOrientationPortrait;
    
    //初始化缩放比例
    //self.effectiveScale = self.beginGestureScale = 1.0f;
}

#pragma mark -- 初始化设备硬件
//获得输入设备（前置摄像头）
- (AVCaptureDevice *)device{
    if (!_device) {
        
        _device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    }
    return _device;
}

//添加一个音频输入设备
- (AVCaptureDevice *)audioCaptureDevice{
    if (!_audioCaptureDevice) {
        
        _audioCaptureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
    }
    return _audioCaptureDevice;
}

//初始化会话
- (AVCaptureSession *)captureSession{
    if (!_captureSession) {
        
        _captureSession = [[AVCaptureSession alloc] init];
        //设置分辨率
        if ([_captureSession canSetSessionPreset:AVCaptureSessionPresetHigh]) {
            _captureSession.sessionPreset = AVCaptureSessionPresetHigh;
        }
    }
    return _captureSession;
}

//容纳不同输出
- (AVCaptureOutput *)captureOutput{
    
    if (!_captureOutput) {
        
        if (_recordOutputType ==FSLAVVideoRecordMovieFileOutput) {
            
            _captureOutput = self.captureMovieFileOutput;
        }else{
            
            _captureOutput = self.captureVideoDataOutput;
        }
    }
    return _captureOutput;
}

//根据摄像机输入设备初始化设备输入对象，用于获得输入数据
- (AVCaptureDeviceInput *)captureDeviceInput{
    if (!_captureDeviceInput) {
        
        if(!self.device) return nil;
        NSError *error;
        _captureDeviceInput = [[AVCaptureDeviceInput alloc] initWithDevice:self.device error:&error];
        if(error) return nil;
    }
    return _captureDeviceInput;
}

//根据音频输入设备初始化设备输入对象
- (AVCaptureDeviceInput *)audioCaptureDeviceInput{
    if (!_audioCaptureDeviceInput) {
        
        if(!self.device) return nil;
        //添加音频设备
        NSError *error = nil;
        _audioCaptureDeviceInput = [[AVCaptureDeviceInput alloc] initWithDevice:self.audioCaptureDevice error:&error];
        if(error) return nil;
    }
    return _audioCaptureDeviceInput;
}

//初始化设备输出对象，用于将输出数据保存到本地
- (AVCaptureMovieFileOutput *)captureMovieFileOutput{
    if (!_captureMovieFileOutput) {
        
        //初始化设备输出对象，用于获得输出数据
        _captureMovieFileOutput = [[AVCaptureMovieFileOutput alloc] init];
        //不设置这个属性，超过10s的视频会没有声音
        _captureMovieFileOutput.movieFragmentInterval = kCMTimeInvalid;
        
    }
    return _captureMovieFileOutput;
}

//获取输出视频帧
- (AVCaptureVideoDataOutput *)captureVideoDataOutput{
    if (!_captureVideoDataOutput) {
        
        _captureVideoDataOutput = [[AVCaptureVideoDataOutput alloc] init];
        
        //输出的压缩设置。
        _captureVideoDataOutput.videoSettings = [NSDictionary dictionaryWithObject:[NSNumber numberWithUnsignedInt:kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange] forKey:(NSString *)kCVPixelBufferPixelFormatTypeKey];
        //指示如果视频帧延迟到达，是否将其删除。
        [_captureVideoDataOutput setAlwaysDiscardsLateVideoFrames:YES];
        
        // 摄像头采集queue
        dispatch_queue_t queue = dispatch_queue_create("VideoCaptureQueue", DISPATCH_QUEUE_SERIAL);
        [_captureVideoDataOutput setSampleBufferDelegate:self queue:queue]; // 摄像头数据输出delegate
    }
    return _captureVideoDataOutput;
}

//创建视频预览层，用于实时展示摄像头状态
- (AVCaptureVideoPreviewLayer *)captureVideoPreviewLayer{
    if (!_captureVideoPreviewLayer) {
        
        _captureVideoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.captureSession];
        //填充模式
        _captureVideoPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
        //保证视频预览层的视频方向是正确的
        _captureVideoPreviewLayer.connection.videoOrientation = [self getCaptureVideoOrientation];
    }
    return _captureVideoPreviewLayer;
}

/**
 将设备捕捉到的画面呈现到某个view上
 
 @param view 显示具体捕捉画面的视图
 */
- (void)showCaptureSessionOnView:(UIView *)view{
    _cameraContainerView = view;
    
    CALayer *layer = view.layer;
    layer.masksToBounds = YES;
    self.captureVideoPreviewLayer.frame = layer.bounds;
    
    //图层预览
    [view.layer addSublayer:self.captureVideoPreviewLayer];
}

#pragma mark --Action
/**
 告诉接收器开始运行。
 */
- (void)startRunning{
    
    if (_captureSession) {
        
        [self.captureSession startRunning];
    }else{
        //初始化
        [self initAVCaptureSession];
        [self.captureSession startRunning];
    }
}
/**
 告诉接收器停止运行。
 */
- (void)stopRunning{
    
    if(!_captureSession) return;
    [self.captureSession stopRunning];
}


/**
 保存视频数据到添加的路径下
 */
- (void)saveVideoToLocalPath{

    if (_recordOutputType ==FSLAVVideoRecordMovieFileOutput) {
        
        [self.captureMovieFileOutput startRecordingToOutputFileURL:self.savePathURL recordingDelegate:self];
    }
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
    toChangeDevice = [self getCameraDeviceWithPosition:toChangePosition];
    
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

#pragma mark - 私有方法
//取得指定位置的摄像头
- (AVCaptureDevice *)getCameraDeviceWithPosition:(AVCaptureDevicePosition)position
{
    
    NSArray *devices = [self obtainAvailableDevices];
    if(!devices) return nil;
    for (AVCaptureDevice *device in devices) {
        if ([device position] == position) {
            return device;
        }
    }
    return nil;
}

//拿到所有可用的摄像头(video)设备
- (NSArray *)obtainAvailableDevices{
    
    if (@available(iOS 10.0, *)) {
        
        AVCaptureDeviceDiscoverySession *deviceSession = [AVCaptureDeviceDiscoverySession discoverySessionWithDeviceTypes:@[AVCaptureDeviceTypeBuiltInWideAngleCamera] mediaType:AVMediaTypeVideo position:AVCaptureDevicePositionUnspecified];
        return deviceSession.devices;
    } else {
        // Fallback on earlier versions
        return [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    }
}

#pragma mark - 获取视频方向
- (AVCaptureVideoOrientation)getCaptureVideoOrientation {
    
    AVCaptureVideoOrientation result;
    UIDeviceOrientation deviceOrientation = [UIDevice currentDevice].orientation;
    switch (deviceOrientation) {
        case UIDeviceOrientationPortrait:
        case UIDeviceOrientationFaceUp:
        case UIDeviceOrientationFaceDown:
            result = AVCaptureVideoOrientationPortrait;
            break;
        case UIDeviceOrientationPortraitUpsideDown:
            //如果这里设置成AVCaptureVideoOrientationPortraitUpsideDown，则视频方向和拍摄时的方向是相反的。
            result = AVCaptureVideoOrientationPortrait;
            break;
        case UIDeviceOrientationLandscapeLeft:
            result = AVCaptureVideoOrientationLandscapeRight;
            break;
        case UIDeviceOrientationLandscapeRight:
            result = AVCaptureVideoOrientationLandscapeLeft;
            break;
        default:
            result = AVCaptureVideoOrientationPortrait;
            break;
    }
    return result;
}

#pragma mark -- 代理
#pragma mark -- AVCaptureFileOutputRecordingDelegate
#pragma mark - 视频输出代理开始录制
-(void)captureOutput:(AVCaptureFileOutput *)captureOutput didStartRecordingToOutputFileAtURL:(NSURL *)fileURL fromConnections:(NSArray *)connections{
    //    SHOWMESSAGE(@"开始录制");
}


#pragma mark - 录制完成回调
-(void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray *)connections error:(NSError *)error{
    //    上传视频转换视频名称代码，不要直接干了就是
    //    SHOWMESSAGE(@"上传中");
    //    NSString * uploadAddress = [outputFileURL absoluteString];;
    //    uploadVideoObject * upload = [[uploadVideoObject alloc]init];
    //    NSMutableString * mString = [NSMutableString stringWithString:uploadAddress];
    //    NSString *strUrl = [mString stringByReplacingOccurrencesOfString:@"file://" withString:@""];
    //    [upload uploadVideo:strUrl];
    //    //视频录入完成之后在后台将视频存储到相
}


#pragma mark -- AVCaptureVideoDataOutputSampleBufferDelegate
//
- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection{
    
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

@end
