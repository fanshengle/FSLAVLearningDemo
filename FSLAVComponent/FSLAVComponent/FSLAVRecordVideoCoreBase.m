//
//  FSLAVRecordVideoCoreBase.m
//  FSLAVComponent
//
//  Created by tutu on 2019/6/21.
//  Copyright © 2019 tutu. All rights reserved.
//

#import "FSLAVRecordVideoCoreBase.h"

@implementation FSLAVRecordVideoCoreBase

#pragma mark - 设备配置
- (void)initAVCaptureSession{
    
}


#pragma mark -- 初始化设备硬件
//获得输入设备（前置摄像头）
- (AVCaptureDevice *)videoCaptureDevice{
    if (!_videoCaptureDevice) {
        
        _videoCaptureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    }
    return _videoCaptureDevice;
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
    }
    return _captureSession;
}

//根据摄像机输入设备初始化设备输入对象，用于获得输入数据
- (AVCaptureDeviceInput *)captureDeviceInput{
    if (!_captureDeviceInput) {
        
        if(!self.videoCaptureDevice) return nil;
        NSError *error;
        _captureDeviceInput = [[AVCaptureDeviceInput alloc] initWithDevice:self.videoCaptureDevice error:&error];
        if(error) return nil;
    }
    return _captureDeviceInput;
}

//根据音频输入设备初始化设备输入对象
- (AVCaptureDeviceInput *)audioCaptureDeviceInput{
    if (!_audioCaptureDeviceInput) {
        
        if(!self.videoCaptureDevice) return nil;
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
    }
    return _captureVideoDataOutput;
}

//创建视频预览层，用于实时展示摄像头状态
- (AVCaptureVideoPreviewLayer *)captureVideoPreviewLayer{
    if (!_captureVideoPreviewLayer) {
        
        _captureVideoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.captureSession];
        //填充模式
        _captureVideoPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    }
    return _captureVideoPreviewLayer;
}

#pragma mark - 私有方法
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

#pragma mark - 取得指定位置的摄像头
- (AVCaptureDevice *)deviceWithPosition:(AVCaptureDevicePosition)position
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
    NSInteger phoneVersion = [[[UIDevice currentDevice] systemName] integerValue];
    if (phoneVersion > 10.0) {
        
        AVCaptureDeviceDiscoverySession *deviceSession = [AVCaptureDeviceDiscoverySession  discoverySessionWithDeviceTypes:@[AVCaptureDeviceTypeBuiltInDualCamera] mediaType:AVMediaTypeVideo position:AVCaptureDevicePositionUnspecified];
        return deviceSession.devices;
    } else {
        // Fallback on earlier versions
        return [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    }
}

@end
