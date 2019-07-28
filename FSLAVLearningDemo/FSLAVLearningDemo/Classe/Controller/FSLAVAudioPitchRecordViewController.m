//
//  FSLAVAudioPitchRecordViewController.m
//  FSLAVLearningDemo
//
//  Created by sprint on 2018/11/28.
//  Copyright © 2018年 tutu. All rights reserved.
//

#import "FSLAVAudioPitchRecordViewController.h"
#import "FSLAVAudioPitchEngineRecorder.h"
#import "speedSegmentButton.h"
#import "PitchSegmentButton.h"

@interface FSLAVAudioPitchRecordViewController ()<FSLAVAudioRecorderDelegate>
{
    // FSLAVAudioPitchEngineRecorder 用以演示音频采集和音频变声处理 API
    FSLAVAudioPitchEngineRecorder *_audioPitchRecoder;
    
    // AVPlayer 用以演示音频播放
    AVPlayer *_audioPlayer;
}
@property (strong, nonatomic) IBOutletCollection(UIButton) NSArray *actionButtons;
@property (weak, nonatomic) IBOutlet UILabel *usageLabel;

@property (weak, nonatomic) IBOutlet UIButton *startAudioRecordBtn;
@property (weak, nonatomic) IBOutlet UIButton *reRecordingAudioBtn;
@property (weak, nonatomic) IBOutlet UIButton *stopAudioRecordBtn;
@property (weak, nonatomic) IBOutlet UIButton *playAudioRecordBtn;

@property (weak, nonatomic) IBOutlet speedSegmentButton *speedBar;
@property (weak, nonatomic) IBOutlet PitchSegmentButton *pitchBar;

@end

@implementation FSLAVAudioPitchRecordViewController

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:NO];
}

- (void)viewDidLoad;
{
    [super viewDidLoad];

    // AVPlayer 用以演示音频播放
    _audioPlayer = [[AVPlayer alloc] init];
    
    // APIAudioPitchEngineRecorder 用以演示音频采集和音频变声处理 API
    _audioPitchRecoder = [[FSLAVAudioPitchEngineRecorder alloc] init];
    _audioPitchRecoder.delegate = self;
    
    _usageLabel.text = @"请点击「开始录音」按钮开始录制音频，录制完成后点击「结束并播放录音」生成并播放音频文件。";
    [_actionButtons[0] setTitle:@"开始录音" forState:UIControlStateNormal];
    [_actionButtons[1] setTitle:@"结束录音" forState:UIControlStateNormal];
    [_actionButtons[2] setTitle:@"重新录音" forState:UIControlStateNormal];
    [_actionButtons[3] setTitle:@"播放录音" forState:UIControlStateNormal];

}

- (void)viewWillDisappear:(BOOL)animated;
{
    [_audioPlayer pause];
    [_audioPitchRecoder cancelRecord];
    
    [super viewWillDisappear:animated];
}

/**
 启动音频采集及音频变声处理
 */
- (IBAction)startRecordingAudio;
{
    [_audioPlayer pause];
    
    _startAudioRecordBtn.enabled = NO;
    _stopAudioRecordBtn.enabled = YES;
    _reRecordingAudioBtn.enabled = YES;
    _playAudioRecordBtn.enabled = NO;
    
    [_audioPitchRecoder startRecord];
    [HUDManager showTextHud:@"录音已经开始"];
}

/**
 重新录制音频
 */
- (IBAction)reRecordingAudio {
    
    [_audioPlayer pause];
    
    _startAudioRecordBtn.enabled = NO;
    _stopAudioRecordBtn.enabled = YES;
    _reRecordingAudioBtn.enabled = NO;
    _playAudioRecordBtn.enabled = NO;

    [_audioPitchRecoder reRecording];
    [HUDManager showTextHud:@"重现录音"];
}

/**
 停止音频采集并播放音效
 */
- (IBAction)finishRecordingAudio;
{
    [_audioPitchRecoder stopRecord];
    
    _startAudioRecordBtn.enabled = YES;
    _stopAudioRecordBtn.enabled = NO;
    _reRecordingAudioBtn.enabled = NO;
    _playAudioRecordBtn.enabled = YES;
    [HUDManager showTextHud:@"录音结束"];
}

- (IBAction)playRecordedAudio;
{
    [HUDManager showTextHud:@"开始播放"];

    [_audioPlayer pause];
    _audioPlayer = [AVPlayer playerWithURL:_audioPitchRecoder.options.outputFileURL];

    [_audioPlayer play];
    NSLog(@"_audioPitchRecoder.options.outputFilePath-->%@",_audioPitchRecoder.options.outputFilePath);
}
#pragma mark - action

- (IBAction)speedSegmentButtionAction:(speedSegmentButton *)sender {
    _audioPitchRecoder.speedMode = sender.speedMode;
    
    _pitchBar.selectedIndex = 2;
}


/**
 变声分段按钮点击事件
 */
- (IBAction)pitchSegmentButtonAction:(PitchSegmentButton *)sender {
    
    _audioPitchRecoder.pitchType = sender.pitchType;
    
    _speedBar.selectedIndex = 2;
}


#pragma mark APIAudioPitchEngineRecorderDelegate

/**
 录制完成
 @param filePath 录制结果
 @param recorder 录制对象
 */
- (void)didCompletedOutputFilePath:(NSString *)filePath recorder:(id<FSLAVRecordCoreBaseInterface>)recorder{
    
}

@end
