//
//  FSLH264VideoViewController.m
//  FSLAVLearningDemo
//
//  Created by tutu on 2019/6/25.
//  Copyright © 2019 tutu. All rights reserved.
//

#import "FSLH264VideoViewController.h"


@interface FSLH264VideoViewController ()<FSLAVVideoRecorderDelegate,FSLAVH264VideoEncoderDelegate>

/**
 视频录制配置
 */
@property (nonatomic, strong) FSLAVVideoRecorderConfiguration *recorderConfiguration;

/**
 视频编码配置
 */
@property (nonatomic, strong) FSLAVH264VideoConfiguration *encoderConfiguration;

/**
 视频录制器
 */
@property (nonatomic,strong) FSLAVFirstVideoRecorder<FSLAVVideoRecorderInterface>  *videoRecorder;

@property (nonatomic,strong) FSLAVH264VideoEncoder<FSLAVH264VideoEncoderInterface> *h264VideoEncoder;

@property (nonatomic,strong) UIView *contantView;

@end


@implementation FSLH264VideoViewController

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    [self.videoRecorder startRunning];
}

- (void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];

    [self.videoRecorder stopRecord];
}


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.navTitle = @"";
    //开始
    CGFloat w = [UIScreen mainScreen].bounds.size.width;
    _contantView = [[UIView alloc] initWithFrame:CGRectMake(0, NMNavbarHeight, w, NMScreenHeight-NMNavbarHeight)];
    [self.view addSubview:_contantView];
    
    UIButton *videoBtn = [[UIButton alloc] initWithFrame:CGRectMake(50, 100, w - 100, 44)];
    videoBtn.backgroundColor = [UIColor orangeColor];
    [videoBtn setTitle:@"开始" forState:UIControlStateNormal];
    [videoBtn addTarget:self action:@selector(startAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:videoBtn];
    
    //结束
    UIButton *photoBtn = [[UIButton alloc] initWithFrame:CGRectMake(50, 220, w - 100, 44)];
    photoBtn.backgroundColor = [UIColor orangeColor];
    [photoBtn setTitle:@"结束" forState:UIControlStateNormal];
    [photoBtn addTarget:self action:@selector(endAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:photoBtn];
}

- (FSLAVFirstVideoRecorder<FSLAVVideoRecorderInterface> *)videoRecorder{

    if (!_videoRecorder) {
        
        _videoRecorder = [[FSLAVFirstVideoRecorder alloc] initWithVideoRecordConfiguration:[FSLAVVideoRecorderConfiguration defaultConfiguration]];
        [_videoRecorder showCaptureSessionOnView:self.contantView];
//        _videoRecorder.delegate = self;
        [_videoRecorder setDelegate:self];
        
    }
    return _videoRecorder;
}

- (FSLAVH264VideoEncoder<FSLAVH264VideoEncoderInterface> *)h264VideoEncoder{
    
    if (!_h264VideoEncoder) {
        
        _h264VideoEncoder = [[FSLAVH264VideoEncoder alloc] initWithVideoStreamConfiguration:[FSLAVH264VideoConfiguration defaultConfiguration]];
        _h264VideoEncoder.h264Delegate = self;
    }
    return _h264VideoEncoder;
}

- (void)startAction:(UIButton *)btn{
    
    [self.videoRecorder startRecord];
}

- (void)endAction:(UIButton *)btn{

    [self.videoRecorder stopRecord];
    [self.videoRecorder stopRunning];
}


#pragma mark -- FSLAVVideoRecorderDelegate
- (void)didChangedVideoRecordState:(FSLAVRecordState)state fromVideoRecorder:(id<FSLAVVideoRecorderInterface>)videoRecorder outputFileAtURL:(NSURL *)fileURL{
    
}

- (void)didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromVideoRecorder:(id<FSLAVVideoRecorderInterface>)videoRecorder{
    
    // 1.将CMSampleBufferRef转成CVImageBufferRef
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    [self.h264VideoEncoder encodeVideoData:imageBuffer timeStamp:(CACurrentMediaTime()*1000)];
}

#pragma mark -- FSLAVRecordCoreBaseDelegate
- (void)didChangedRecordCurrentTotalTimeLength:(NSTimeInterval)recordTimeLength{
    
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
