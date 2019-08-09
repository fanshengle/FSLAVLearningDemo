//
//  FSLAVVideoMixViewController.m
//  FSLAVLearningDemo
//
//  Created by bqlin on 2018/6/15.
//  Copyright © 2018年 tutu All rights reserved.
//

#import "FSLAVVideoMixViewController.h"
#import "PlayerView.h"

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

@interface FSLAVVideoMixViewController ()<FSLAVVideoMixerDelegate>

@property (strong, nonatomic) IBOutletCollection(UILabel) NSArray<UILabel *> *audioTitleLabels;
@property (strong, nonatomic) IBOutletCollection(UIButton) NSArray<UIButton *> *actionButtons;
@property (strong, nonatomic) IBOutletCollection(UISlider) NSArray *volumeSliders;
@property (strong, nonatomic) IBOutletCollection(UILabel) NSArray<UILabel *> *volumeLabels;
@property (weak, nonatomic) IBOutlet PlayerView *playerView;

/**
 音乐播放器
 */
@property (nonatomic, strong) AVAudioPlayer *firstMixAudioPlayer;
@property (nonatomic, strong) AVAudioPlayer *secondMixAudioPlayer;

/**
 素材一
 */
@property (nonatomic, strong) FSLAVMixerOptions *firstMixAudio;

/**
 素材二
 */
@property (nonatomic, strong) FSLAVMixerOptions *secondMixAudio;


/**
 视频素材
 */
@property (nonatomic, strong) FSLAVMixerOptions *mainVideo;

/**
 视频混合器
 */
@property (nonatomic, strong) FSLAVVideoMixer *movieMixer;

/**
 系统播放器
 */
@property (strong, nonatomic) AVPlayer *player;

@end

@implementation FSLAVVideoMixViewController

- (void)dealloc {
    if (_player) {
        [_player cancelPendingPrerolls];
        [_player.currentItem cancelPendingSeeks];
        [_player.currentItem.asset cancelLoading];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:NO];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupUI];
    [self setupVideoPlayer];
    [self setupAudioPlayer];
    [self setupMovieMixer];
}

- (NSURL *)fileURLWithName:(NSString *)fileName {
    return [[NSBundle mainBundle] URLForResource:fileName withExtension:nil];
}

- (UIImage *)drawCircleImageWithSize:(CGSize)size color:(UIColor *)color {
    UIGraphicsBeginImageContextWithOptions(size, NO, 0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGRect rect = CGRectMake(0, 0, size.width, size.height);
    CGContextAddEllipseInRect(context, rect);
    CGContextSetFillColorWithColor(context, color.CGColor);
    CGContextDrawPath(context, kCGPathFill);
    UIImage *image =  UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

#pragma mark - setup

- (void)setupUI {
    UIImage *thumbImage = [self drawCircleImageWithSize:CGSizeMake(18, 18) color:[UIColor whiteColor]];
    for (UISlider *slider in self.volumeSliders) {
        [slider setThumbImage:thumbImage forState:UIControlStateNormal];
    }
    
    // 国际化
    _audioTitleLabels[0].text = @"原音";
    _audioTitleLabels[1].text = @"素材一";
    _audioTitleLabels[2].text = @"素材二";
    [_actionButtons[0] setTitle:@"合成视频" forState:UIControlStateNormal];
}

- (void)setupMovieMixer {
    NSURL *firstAudioURL = [self fileURLWithName:@"111.mp3"];
    _firstMixAudio = [[FSLAVMixerOptions alloc] initWithMediaURL:firstAudioURL];
    _firstMixAudio.atTimeRange = [FSLAVTimeRange timeRangeWithStartSeconds:6 endSeconds:8];
    _firstMixAudio.atNodeTime = CMTimeMakeWithSeconds(3, 1*USEC_PER_SEC);
    _firstMixAudio.enableCycleAdd = YES;
    
    NSURL *secondAudioURL = [self fileURLWithName:@"222.mp3"];
    _secondMixAudio = [[FSLAVMixerOptions alloc] initWithMediaURL:secondAudioURL];
    _secondMixAudio.atTimeRange = [FSLAVTimeRange timeRangeWithStartSeconds:20 endSeconds:35];
    _secondMixAudio.enableCycleAdd = NO;

    // 初始化音视频混合器对象
    
    NSURL *videoURL = [self fileURLWithName:@"444.mov"];
    _mainVideo = [[FSLAVMixerOptions alloc] initWithMediaURL:videoURL];
    _mainVideo.atTimeRange = [FSLAVTimeRange timeRangeWithStartSeconds:0 endSeconds:10];
    // 是否保留视频原音
    _mainVideo.enableVideoSound = YES;
    
    _movieMixer = [[FSLAVVideoMixer alloc] initWithMixerVideoOptions:_mainVideo];
    _movieMixer.mixDelegate = self;
}

- (void)setupAudioPlayer {
    _firstMixAudioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:[self fileURLWithName:@"111.mp3"] error:nil];
    _firstMixAudioPlayer.numberOfLoops = -1;//循环播放
    _firstMixAudioPlayer.volume = 0.5;
    [_firstMixAudioPlayer prepareToPlay];//预先加载音频到内存，播放更流畅
    [_firstMixAudioPlayer play];
    
    _secondMixAudioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:[self fileURLWithName:@"222.mp3"] error:nil];
    _secondMixAudioPlayer.numberOfLoops = -1;//循环播放
    _secondMixAudioPlayer.volume = 0.5;
    [_secondMixAudioPlayer prepareToPlay];//预先加载音频到内存，播放更流畅
    [_secondMixAudioPlayer play];
}

- (void)setupVideoPlayer {
    _playerView.backgroundColor = [UIColor clearColor];
    // 添加视频资源
    AVPlayerItem *playerItem = [[AVPlayerItem alloc] initWithURL:[self fileURLWithName:@"444.mov"]];
    // 播放
    _player = [[AVPlayer alloc] initWithPlayerItem:playerItem];
    _player.volume = 0.5;
    // 播放视频需要在AVPlayerLayer上进行显示
    _playerView.player = _player;
    // 循环播放的通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playVideoCycling) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    [_player play];
}

- (void)playVideoCycling {
    [_player seekToTime:kCMTimeZero];
    [_player play];
}

#pragma mark - action

/**
 开始混合
 */
- (IBAction)mixVideoAndAudio {
    [HUDManager showTextHud:@"开始合成..."];
    // 混合的音频
    _movieMixer.mixAudios = @[_firstMixAudio, _secondMixAudio];
    
    // 开始混合
    [_movieMixer startMixingVideoWithCompletion:^(NSString *filePath , FSLAVMixStatus status) {
        
        if (status == FSLAVMixStatusCompleted) {
            
     
            // 操作成功 保存到相册
            UISaveVideoAtPathToSavedPhotosAlbum(filePath, nil, nil, nil);
        } else {
            // 提示失败
            NSLog(@"保存失败");
        }
    }];
}

/**
 取消混合
 */
- (IBAction)cancelMovieMixer {
    if (_movieMixer) {
        [_movieMixer cancelMixing];
    }
}

- (IBAction)volumeSliderAction:(UISlider *)sender {
    AudioIndex index = [self.volumeSliders indexOfObject:sender];
    CGFloat volume = sender.value;
    
    // 更新 UI
    NSString *progressText = [NSNumberFormatter localizedStringFromNumber:@(volume) numberStyle:NSNumberFormatterPercentStyle];
    UILabel *volumeLabel = self.volumeLabels[index];
    volumeLabel.text = progressText;
    
    switch (index) {
        case AudioMain:{
            _player.volume = volume;
            _mainVideo.audioVolume = volume;
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

#pragma mark - FSLAVVideoMixerDelegate

/**
 状态通知代理

 */
- (void)didMixingVideoStatusChanged:(FSLAVMixStatus)status onVideoMix:(FSLAVVideoMixer *)videoMixer{
    
    if (status == FSLAVMixStatusCompleted) {
        [HUDManager showTextHud:@"操作完成，请前往相册查看视频"];
    } else if (status == FSLAVMixStatusFailed) {
        
        [HUDManager showTextHud:@"操作失败，无法生成视频文件"];
    } else if (status == FSLAVMixStatusCancelled) {
        [HUDManager showTextHud:@"出现问题，操作被取消"];
    }
}


/**
 结果通知代理

 */
- (void)didMixedVideoResult:(FSLAVMixerOptions *)result onVideoMix:(FSLAVVideoMixer *)audioMixer{
    NSLog(@"保存结果的临时文件路径 : %@", result.outputFilePath);
}

- (void)didMixingVideoProgressChanged:(CGFloat)progress onVideoMix:(FSLAVVideoMixer *)videoMixer{

    //NSLog(@"视频合成进度 : %f", progress);
}
@end
