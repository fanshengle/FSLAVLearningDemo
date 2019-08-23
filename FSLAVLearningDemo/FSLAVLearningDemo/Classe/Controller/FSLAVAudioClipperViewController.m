//
//  FSLAVAudioClipperViewController.m
//  FSLAVLearningDemo
//
//  Created by tutu on 2019/7/14.
//  Copyright © 2019 tutu. All rights reserved.
//

#import "FSLAVAudioClipperViewController.h"

@interface FSLAVAudioClipperViewController ()<FSLAVAudioClipperDelegate,UITextFieldDelegate>



@property (weak, nonatomic) IBOutlet UISlider *volumeSlider;

@property (weak, nonatomic) IBOutlet UILabel *volumeLabel;
@property (weak, nonatomic) IBOutlet UITextField *minTxt;
@property (weak, nonatomic) IBOutlet UITextField *maxTxt;

/**
 素材播放器
 */
@property (nonatomic, strong) AVAudioPlayer *clipAudioPlayer;

/**
 播放对象
 */
@property (nonatomic, strong) AVAudioPlayer *audioPlayer;


/**
 音乐素材
 */
@property (nonatomic, strong) FSLAVAudioClipperOptions *clipAudio;

/**
 音频剪辑对象
 */
@property (nonatomic, strong) FSLAVAudioClipper *audioClipper;

@end

@implementation FSLAVAudioClipperViewController

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    //[self.navigationController setNavigationBarHidden:NO animated:NO];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.navTitle = @"单音频剪辑";
    _minTxt.text = @"0";
    _maxTxt.text = @"6";
    
    [self setupAudioPlayer];
    [self setupAudiClipper];
    
    [self.volumeSlider addTarget:self action:@selector(volumeSliderAction:) forControlEvents:UIControlEventValueChanged];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    [super touchesBegan:touches withEvent:event];
    [self.view endEditing:YES];

}


#pragma mark - setup
- (void)setupAudiClipper {
    // 原音
    NSURL *mainAudioURL = [self fileURLWithName:@"111.mp3"];
    _clipAudio = [[FSLAVAudioClipperOptions alloc] initWithMediaURL:mainAudioURL];
    _clipAudio.audioVolume = 0;
    _clipAudio.atTimeRange = [FSLAVTimeRange timeRangeWithStartSeconds:_minTxt.text.floatValue endSeconds:_maxTxt.text.floatValue];
    
    // 创建剪辑
    _audioClipper = [[FSLAVAudioClipper alloc] init];
    _audioClipper.clipDelegate = self;
    // 设置剪辑音轨
    _audioClipper.clipAudio = _clipAudio;
    
}

- (void)setupAudioPlayer {
    // 创建seekBar
    _clipAudioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:[self fileURLWithName:@"111.mp3"] error:nil];
    _clipAudioPlayer.numberOfLoops = -1;//循环播放
    _clipAudioPlayer.volume = 0;
    [_clipAudioPlayer prepareToPlay];//预先加载音频到内存，播放更流畅
    [_clipAudioPlayer play];
}

- (NSURL *)fileURLWithName:(NSString *)fileName {
    return [[NSBundle mainBundle] URLForResource:fileName withExtension:nil];
}


// 停止播放原始素材音乐
- (void)pauseMaterialAudioPlay {
    [_clipAudioPlayer pause];
}

// 播放原始素材音乐
- (void)playMaterialAudio {
    [_clipAudioPlayer play];
}

// 取消录制的方法
- (void)cancelAudiosClipping {
    [_audioClipper cancelClipping];
}

// 播放音频
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

// 开始剪辑音频
- (IBAction)startClipAudio {
    // 暂停播放素材音乐
    [self pauseMaterialAudioPlay];

    _clipAudio.atTimeRange = [FSLAVTimeRange timeRangeWithStartSeconds:_minTxt.text.floatValue endSeconds:_maxTxt.text.floatValue];

    // TODO: 禁用播放按钮
    //playBtn.enabled = NO;
    [HUDManager showTextHud:@"音频开始剪辑"];
    
    
    [_audioClipper startClippingAudioWithCompletion:^(NSString * filePath, FSLAVClipStatus clipStatus) {
       
        NSLog(@"filePath--->%@",filePath);
    }];
  
}

// 取消剪辑音频
- (IBAction)cancelClipAudio {
 
    [self cancelAudiosClipping];
}

// 删除剪辑导出的音频
- (IBAction)deleteAudio {
    
    if (_clipAudio.outputFileURL) {
        [_clipAudioPlayer pause];
        [_clipAudio clearOutputFilePath];
    }
    
    NSLog(@"result path:%@", _clipAudio.outputFilePath);
    
    [HUDManager showTextHud:@"请重新进行音频剪辑"];
    
    // 播放原音
    [self playMaterialAudio];
}

// 播放剪辑之后的导出音频
- (IBAction)playClipAudio {
    if (_clipAudio.outputFileURL) {
        [self playTheAudioWithURL:_clipAudio.outputFileURL];
    }
}

// 暂停播放剪辑导出的音频
- (IBAction)pauseClipAudio {
    if (_audioPlayer) {
        [_audioPlayer pause];
    }
}

// 音量条滑动
- (void)volumeSliderAction:(UISlider *)sender {
    
    CGFloat volume = sender.value;

    // 更新 UI，获取百分比
    NSString *progressText = [NSNumberFormatter localizedStringFromNumber:@(volume) numberStyle:NSNumberFormatterPercentStyle];
    self.volumeLabel.text = progressText;

    _clipAudioPlayer.volume = volume;
    _clipAudio.audioVolume = volume;
}

#pragma mark - FSLAVAudioMixerDelegate

/**
 状态通知代理
 */
- (void)didClippingAudioStatusChanged:(FSLAVClipStatus)audioStatus onAudioClip:(FSLAVAudioClipper *)audioClipper{
    
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
- (void)didMixedAudioResult:(FSLAVClipperOptions *)result onAudioClip:(FSLAVAudioClipper *)audioClipper{
    if (result.outputFilePath) {
        NSLog(@"result path : %@", result.outputFilePath);
    }
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
