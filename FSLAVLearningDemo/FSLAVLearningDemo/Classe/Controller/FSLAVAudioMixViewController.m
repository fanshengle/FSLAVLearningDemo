//
//  FSLAVAudioMixViewController.m
//  FSLAVLearningDemo
//
//  Created by bqlin on 2018/6/15.
//  Copyright © 2018年 tutu. All rights reserved.
//

#import "FSLAVAudioMixViewController.h"

/**
 音频索引
 */
typedef NS_ENUM(NSInteger, AudioIndex) {
    // 原音
    AudioMain = 0,
    // 素材一
    Audio1,
    // 素材二
    Audio2
};

@interface FSLAVAudioMixViewController ()<FSLAVAudioMixerDelegate>

@property (strong, nonatomic) IBOutletCollection(UISlider) NSArray *volumeSliders;
@property (strong, nonatomic) IBOutletCollection(UILabel) NSArray *volumeLabels;
@property (weak, nonatomic) IBOutlet UILabel *usageLabel;
@property (strong, nonatomic) IBOutletCollection(UILabel) NSArray<UILabel *> *audioTitleLabels;
@property (strong, nonatomic) IBOutletCollection(UIButton) NSArray<UIButton *> *actionButtons;

/**
 播放按钮
 */
@property (weak, nonatomic) IBOutlet UIButton *playButton;

/**
 音频混合对象
 */
@property (nonatomic, strong) FSLAVAudioMixer *audioMixer;

/**
 混合结果 url
 */
@property (nonatomic, strong) NSURL *resultURL;

/**
 播放对象
 */
@property (nonatomic, strong) AVAudioPlayer *audioPlayer;

/**
 原音播放器
 */
@property (nonatomic, strong) AVAudioPlayer *mainAudioPlayer;

/**
 素材一播放器
 */
@property (nonatomic, strong) AVAudioPlayer *firstMixAudioPlayer;

/**
 素材二播放器
 */
@property (nonatomic, strong) AVAudioPlayer *secondMixAudioPlayer;

/**
 原始音乐素材
 */
@property (nonatomic, strong) FSLAVMixerAudioOptions *mainAudio;

/**
 混音素材1
 */
@property (nonatomic, strong) FSLAVMixerAudioOptions *firstMixAudio;

/**
 混音素材2
 */
@property (nonatomic, strong) FSLAVMixerAudioOptions *secondMixAudio;

@end

@implementation FSLAVAudioMixViewController

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:NO];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupAudioPlayer];
    [self setupAudioMixer];
}

#pragma mark - setup

- (void)setupAudioMixer {
    // 原音
    NSURL *mainAudioURL = [self fileURLWithName:@"111.mp3"];
    _mainAudio = [[FSLAVMixerAudioOptions alloc] initWithAudioURL:mainAudioURL];
    _mainAudio.audioVolume = 0;
//    _mainAudio.atTimeRange = [FSLAVTimeRange makeTimeRangeWithStartSeconds:0 endSeconds:6];
    //是否允许音频循环 默认 NO
    _mainAudio.enableCycleAdd = YES;
    
    // 素材一
    NSURL *firstMixAudioURL = [self fileURLWithName:@"123.mp3"];
    _firstMixAudio = [[FSLAVMixerAudioOptions alloc] initWithAudioURL:firstMixAudioURL];
    _firstMixAudio.audioVolume = 0;
    _firstMixAudio.atTimeRange = [FSLAVTimeRange makeTimeRangeWithStartSeconds:20 endSeconds:10];
    
    // 素材二
    NSURL *secondMixAudioURL = [self fileURLWithName:@"sound_cat.mp3"];
    _secondMixAudio = [[FSLAVMixerAudioOptions alloc] initWithAudioURL:secondMixAudioURL];
    _secondMixAudio.audioVolume = 0;
    _secondMixAudio.atTimeRange = [FSLAVTimeRange makeTimeRangeWithStartSeconds:0 endSeconds:40];
    
    // 创建混音
    _audioMixer = [[FSLAVAudioMixer alloc] init];
    _audioMixer.mixDelegate = self;
    // 设置主音轨
    _audioMixer.mainAudio = _mainAudio;
    
}

- (void)setupAudioPlayer {
    // 创建seekBar
    _mainAudioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:[self fileURLWithName:@"111.mp3"] error:nil];
    _mainAudioPlayer.numberOfLoops = -1;//循环播放
    _mainAudioPlayer.volume = 0;
    [_mainAudioPlayer prepareToPlay];//预先加载音频到内存，播放更流畅
    [_mainAudioPlayer play];

    _firstMixAudioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:[self fileURLWithName:@"123.mp3"] error:nil];
    _firstMixAudioPlayer.numberOfLoops = -1;//循环播放
    _firstMixAudioPlayer.volume = 0;
    [_firstMixAudioPlayer prepareToPlay];//预先加载音频到内存，播放更流畅
    [_firstMixAudioPlayer play];

    _secondMixAudioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:[self fileURLWithName:@"sound_cat.mp3"] error:nil];
    _secondMixAudioPlayer.numberOfLoops = -1;//循环播放
    _secondMixAudioPlayer.volume = 0;
    [_secondMixAudioPlayer prepareToPlay];//预先加载音频到内存，播放更流畅
    [_secondMixAudioPlayer play];
}

- (NSURL *)fileURLWithName:(NSString *)fileName {
    return [[NSBundle mainBundle] URLForResource:fileName withExtension:nil];
}

#pragma mark -

// 停止播放原始素材音乐
- (void)pauseMaterialAudioPlay {
    [_mainAudioPlayer pause];
    [_firstMixAudioPlayer pause];
    [_secondMixAudioPlayer pause];
}

// 播放原始素材音乐
- (void)playMaterialAudio {
    [_mainAudioPlayer play];
    [_firstMixAudioPlayer play];
    [_secondMixAudioPlayer play];
}

// 取消录制的方法
- (void)cancelAudiosMixing {
    [_audioMixer cancelMixing];
}

- (void)playTheAudioWithURL:(NSURL *)URL {
    if (_audioPlayer) {
        [_audioPlayer stop];
        _audioPlayer = nil;
    }
    if (!URL) {
        NSLog(@"AudioURL is invalid.");
    }
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    [audioSession setCategory:AVAudioSessionCategoryPlayback error:nil];
    [audioSession setActive:YES error:nil];
    
    NSError *playerError = nil;
    _audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:URL error:&playerError];
    if (playerError) {
        NSLog(@"player error : %@", playerError);
        return;
    }
    _audioPlayer.numberOfLoops = 0;
    [_audioPlayer prepareToPlay];
    _audioPlayer.volume = 1;
    [_audioPlayer play];
}

#pragma mark - Action

/// 开始音频混合
- (IBAction)startAudiosMixing {
    // 暂停播放素材音乐
    [self pauseMaterialAudioPlay];
    // 开始混合
    _audioMixer.mixAudios = @[_firstMixAudio, _secondMixAudio];
    // TODO: 禁用播放按钮
    //playBtn.enabled = NO;
    [HUDManager showTextHud:@"音频开始混合"];
    
    __weak typeof(self) weakSelf = self;
    [_audioMixer startMixingAudioWithCompletion:^(NSURL *fileURL, FSLAVMixStatus status) {
        weakSelf.resultURL = fileURL;
    }];
}

/// 删除生成的音频临时文件
- (IBAction)deleteMixedAudioAndPlay {
    if (_resultURL) {
        [_audioPlayer pause];
        [_mainAudio clearOutputFilePath];
        _resultURL = nil;
    }
    
    NSLog(@"result path:%@", _resultURL.path);
    
    [HUDManager showTextHud:@"请重新调节音量，进行音频混合"];

    // 更新 UI
    for (int i = 0; i < self.volumeSliders.count; i++) {
        UISlider *slider = self.volumeSliders[i];
        slider.value = 0;
        UILabel *label = self.volumeLabels[i];
        label.text = @"0%";
        [self volumeSliderAction:self.volumeSliders[i]];
    }
    
    // 播放原音
    [self playMaterialAudio];
}

/// 播放混音
- (IBAction)playMixedAudio {
    if (_resultURL) {
        [self playTheAudioWithURL:_resultURL];
    }
}

/// 暂停 audioPlayer
- (IBAction)pauseMixedAudioPlay {
    if (_audioPlayer) {
        [_audioPlayer pause];
    }
}

- (IBAction)volumeSliderAction:(UISlider *)sender {
    AudioIndex index = [self.volumeSliders indexOfObject:sender];
    CGFloat volume = sender.value;
    
    // 更新 UI
    NSString *progressText = [NSNumberFormatter localizedStringFromNumber:@(volume) numberStyle:NSNumberFormatterPercentStyle];
    UILabel *label = self.volumeLabels[index];
    label.text = progressText;
    
    switch (index) {
        case AudioMain:{
            _mainAudioPlayer.volume = volume;
            _mainAudio.audioVolume = volume;
        } break;
        case Audio1:{
            _firstMixAudioPlayer.volume = volume;
            _firstMixAudio.audioVolume = volume;
        } break;
        case Audio2:{
            _secondMixAudioPlayer.volume = volume;
            _secondMixAudio.audioVolume = volume;
        } break;
    }
}

#pragma mark - FSLAVAudioMixerDelegate

/**
 状态通知代理
 */
- (void)didMixedAudioStatusChanged:(FSLAVMixStatus)audioStatus onAudioMix:(FSLAVAudioMixer *)audioMixer{
    
    if (audioStatus == FSLAVMixStatusCompleted) {
        [HUDManager showTextHud:@"操作完成，请点击「播放」，播放混合好的音频"];
        
        // TODO: 启用播放按钮
        //playBtn.enabled = YES;
    } else if (audioStatus == FSLAVMixStatusCancelled) {
        
    } else if (audioStatus == FSLAVMixStatusFailed) {
        
    }
}

/**
 结果通知代理
 
 */
- (void)didMixedAudioResult:(FSLAVMixerAudioOptions *)result onAudioMix:(FSLAVAudioMixer *)audioMixer{
    if (result.outputFilePath) {
        NSLog(@"result path : %@", result.outputFilePath);
        _resultURL = [NSURL URLWithString:result.outputFilePath];
    }
}


@end
