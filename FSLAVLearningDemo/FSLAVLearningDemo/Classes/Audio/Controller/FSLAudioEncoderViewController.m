//
//  FSLAudioEncoderViewController.m
//  FSLAVLearningDemo
//
//  Created by tutu on 2019/7/9.
//  Copyright © 2019 tutu. All rights reserved.
//

#import "FSLAudioEncoderViewController.h"

@interface FSLAudioEncoderViewController ()
<FSLAVAudioRecorderDelegate,FSLAVAACAudioEncoderDelegate>

@property (nonatomic , strong) UIButton                  *startBtn;

@property (nonatomic , strong) FSLAVSecondAudioRecorder *audioRecorder0;
@property (nonatomic , strong) FSLAVThreeAudioRecorder *audioRecorder;
@property (nonatomic , strong) FSLAVAACAudioEncoder *audioEncoder;
@property (nonatomic , strong) FSLAVAudioPlayer *audioPlayer;
@property (nonatomic , strong) FSLAVAACAudioDecoder *audioDecoder;
@end

@implementation FSLAudioEncoderViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.navTitle = @"音频编码AAC";
    [self initStartBtn];
}

- (void)initStartBtn
{
    _startBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    _startBtn.frame = CGRectMake(0, 0, 140, 50);
    _startBtn.backgroundColor = [UIColor orangeColor];
    _startBtn.center = CGPointMake([UIScreen mainScreen].bounds.size.width / 2, [UIScreen mainScreen].bounds.size.height - 120);
    [_startBtn addTarget:self action:@selector(startBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
    [_startBtn setTitle:@"Start" forState:UIControlStateNormal];
    [_startBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.view addSubview:_startBtn];
    
    UIButton *playBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    playBtn.frame = CGRectMake(0, 0, 140, 50);
    playBtn.backgroundColor = [UIColor orangeColor];
    playBtn.center = CGPointMake([UIScreen mainScreen].bounds.size.width / 2, [UIScreen mainScreen].bounds.size.height - 240);
    [playBtn addTarget:self action:@selector(playBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
    [playBtn setTitle:@"Play" forState:UIControlStateNormal];
    [playBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.view addSubview:playBtn];
    
    //    UIButton *play2Btn = [UIButton buttonWithType:UIButtonTypeSystem];
    //    play2Btn.frame = CGRectMake(0, 0, 140, 50);
    //    play2Btn.backgroundColor = [UIColor orangeColor];
    //    play2Btn.center = CGPointMake([UIScreen mainScreen].bounds.size.width / 2, [UIScreen mainScreen].bounds.size.height - 320);
    //    [play2Btn addTarget:self action:@selector(play2BtnClicked) forControlEvents:UIControlEventTouchUpInside];
    //    [play2Btn setTitle:@"noDecode" forState:UIControlStateNormal];
    //    [play2Btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    //    [self.view addSubview:play2Btn];
}

- (FSLAVAudioPlayer *)audioPlayer{
    if (!_audioPlayer) {
        _audioPlayer = [[FSLAVAudioPlayer alloc] initWithURL:self.audioRecorder.options.outputFilePath];
    }
    return _audioPlayer;
}

- (FSLAVAACAudioEncoder *)audioEncoder{
    if (!_audioEncoder) {
        
        FSLAVAACEncodeOptions *options = [FSLAVAACEncodeOptions defaultOptions];
        _audioEncoder = [[FSLAVAACAudioEncoder alloc] initWithAudioStreamOptions:options];
        _audioEncoder.encoderDelegate = self;
    }
    return _audioEncoder;
}

- (FSLAVAACAudioDecoder *)audioDecoder{
    
    FSLAVAACEncodeOptions *options = [FSLAVAACEncodeOptions defaultOptions];
    _audioDecoder = [[FSLAVAACAudioDecoder alloc] init];
    [_audioDecoder startReadAudioStreamingDataFromPath:options.exportRandomFilePath];
    //[_audioDecoder startReadAudioStreamingDataFromPath:[[NSBundle mainBundle] pathForResource:@"abc.aac" ofType:nil]];

    return _audioDecoder;
}

- (FSLAVSecondAudioRecorder *)audioRecorder0{
    if (!_audioRecorder0) {
        
        FSLAVAudioRecoderOptions *options = [FSLAVAudioRecoderOptions defaultOptions];
        _audioRecorder0 = [[FSLAVSecondAudioRecorder alloc] initWithAudioRecordOptions:options];
        _audioRecorder0.delegate = self;
    }
    return _audioRecorder0;
}

- (FSLAVThreeAudioRecorder *)audioRecorder{
    if (!_audioRecorder) {
       
        FSLAVAudioRecoderOptions *options = [FSLAVAudioRecoderOptions defaultOptions];
        _audioRecorder = [[FSLAVThreeAudioRecorder alloc] initWithAudioRecordOptions:options];
        _audioRecorder.delegate = self;
    }
    return _audioRecorder;
}

#pragma mark - 播放
- (void)playBtnClicked:(UIButton *)btn
{
    
    [self.audioDecoder playDecodeAudioPCMData];
}


#pragma mark - 录制
- (void)startBtnClicked:(UIButton *)btn
{
    btn.selected = !btn.selected;
    
    if (btn.selected)
    {
        [self.audioRecorder0 startRecord];
        [_startBtn setTitle:@"Stop" forState:UIControlStateNormal];
    }
    else
    {
        [_startBtn setTitle:@"Start" forState:UIControlStateNormal];
        [self.audioRecorder0 stopRecord];
    }
}

- (void)didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromAudioRecorder:(id<FSLAVAudioRecorderInterface>)audioRecorder{
    
    [self.audioEncoder encodeAudioSampleBuffer:sampleBuffer timeStamp:FSL_NOW];
}

- (void)didRecordingAudioData:(NSData *)data recorder:(id<FSLAVAudioRecorderInterface>)recorder{
    
    [self.audioEncoder encodeAudioData:data timeStamp:FSL_NOW];
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
