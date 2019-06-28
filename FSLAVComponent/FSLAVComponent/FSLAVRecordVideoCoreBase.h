//
//  FSLAVRecordVideoCoreBase.h
//  FSLAVComponent
//
//  Created by tutu on 2019/6/21.
//  Copyright © 2019 tutu. All rights reserved.
//

#import "FSLAVRecordCoreBase.h"

NS_ASSUME_NONNULL_BEGIN

/**
 视频录制的基础类
 */
@interface FSLAVRecordVideoCoreBase : FSLAVRecordCoreBase
{
    AVCaptureDevice *_videoCaptureDevice;
    AVCaptureDeviceInput *_captureDeviceInput;
    AVCaptureDevice *_audioCaptureDevice;
    AVCaptureDeviceInput *_audioCaptureDeviceInput;
    AVCaptureSession *_captureSession;
    AVCaptureConnection *_captureConnection;
    AVCaptureOutput *_captureOutput;
    AVCaptureMovieFileOutput *_captureMovieFileOutput;
    AVCaptureVideoDataOutput *_captureVideoDataOutput;
    AVCaptureVideoPreviewLayer *_captureVideoPreviewLayer;
    UIView *_containerView;
}

@property (nonatomic, strong) AVCaptureDevice *videoCaptureDevice;//获得输入设备（前置摄像头
@property (nonatomic, strong) AVCaptureDeviceInput *captureDeviceInput;//负责从AVCaptureDevice获得输入数据
@property (nonatomic, strong) AVCaptureDevice *audioCaptureDevice;//添加一个音频输入设备
@property (nonatomic, strong) AVCaptureDeviceInput *audioCaptureDeviceInput;//添加一个音频输入设备
@property (nonatomic, strong) AVCaptureSession *captureSession;//负责输入和输出设置之间的数据传递
@property (nonatomic, strong) AVCaptureConnection *captureConnection;//捕获会话中特定的一对捕获输入和捕获输出对象之间的连接。
@property (nonatomic, strong) AVCaptureOutput *captureOutput;
@property (nonatomic, strong) AVCaptureMovieFileOutput *captureMovieFileOutput;//将数据视频输出流写入文件
@property (nonatomic, strong) AVCaptureVideoDataOutput *captureVideoDataOutput;//获取视频帧数据
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *captureVideoPreviewLayer;//相机拍摄预览图层

@property (nonatomic, strong) UIView *containerView;//预览图层的容器视图


#pragma mark - 设备配置
- (void)initAVCaptureSession;

#pragma mark - 获取视频方向
- (AVCaptureVideoOrientation)getCaptureVideoOrientation;

#pragma mark - 取得指定位置的摄像头
- (AVCaptureDevice *)deviceWithPosition:(AVCaptureDevicePosition)position;

@end

NS_ASSUME_NONNULL_END
