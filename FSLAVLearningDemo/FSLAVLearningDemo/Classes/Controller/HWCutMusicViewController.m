//
//  HWCutMusicViewController.m
//  AVFoundationTest
//
//  Created by tutu on 2019/6/14.
//  Copyright © 2019 wqb. All rights reserved.
//

#import "HWCutMusicViewController.h"
#import <AVFoundation/AVFoundation.h>

@interface HWCutMusicViewController ()<AVAudioPlayerDelegate>

@property (nonatomic, strong) NSURL *audioPath;//音频播放器对象

@property (nonatomic, weak) UITextField *startTxt;
@property (nonatomic, weak) UITextField *endTxt;
@property (nonatomic, assign) CGFloat musicDuration;

@property (nonatomic,strong) FSLAVPlayer *videoPlayer;
@property (nonatomic,strong) FSLAVSingleAudioPlayer *audioPlayer;
@property (nonatomic,strong) FSLAVAudioPlayer *audioPlayer1;

@property (nonatomic,strong) FSLAVH246VideoDecoder *videoDecoder;


@end

@implementation HWCutMusicViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.navTitle = @"音频录制与播放";
    
    CGFloat w = [UIScreen mainScreen].bounds.size.width;
    //视频
    UIButton *videoBtn = [[UIButton alloc] initWithFrame:CGRectMake(50, 100, w - 100, 44)];
    videoBtn.backgroundColor = [UIColor orangeColor];
    [videoBtn setTitle:@"播放原音乐" forState:UIControlStateNormal];
    [videoBtn addTarget:self action:@selector(playBtnOnClick:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:videoBtn];
    
    
    CGFloat width = 50;
    UITextField *startText = [[UITextField alloc] initWithFrame:CGRectMake(CGRectGetMinX(videoBtn.frame), CGRectGetMaxY(videoBtn.frame) + 10, width, width)];
    startText.keyboardType = UIKeyboardTypeNumberPad;
    startText.font = [UIFont systemFontOfSize:15];
    startText.backgroundColor = [UIColor whiteColor];
    startText.textColor = [UIColor blackColor];
    [self.view addSubview:startText];
    _startTxt = startText;
    
    UITextField *endText = [[UITextField alloc] initWithFrame:CGRectMake(CGRectGetMaxX(videoBtn.frame) - width, CGRectGetMaxY(videoBtn.frame) + 10, width, width)];
    endText.keyboardType = UIKeyboardTypeNumberPad;
    endText.font = [UIFont systemFontOfSize:15];
    endText.backgroundColor = [UIColor whiteColor];
    endText.textColor = [UIColor blackColor];
    [self.view addSubview:endText];
    _endTxt = endText;
    
    //拍照
    UIButton *photoBtn = [[UIButton alloc] initWithFrame:CGRectMake(50, 220, w - 100, 44)];
    photoBtn.backgroundColor = [UIColor orangeColor];
    [photoBtn setTitle:@"裁剪音乐并播放" forState:UIControlStateNormal];
    [photoBtn addTarget:self action:@selector(cutMusicBtnOnClick) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:photoBtn];
}

- (FSLAVPlayer *)videoPlayer{
    if (!_videoPlayer) {
        _videoPlayer = [[FSLAVPlayer alloc] initWithURL:[[NSBundle mainBundle] pathForResource:@"111.mp3" ofType:nil]];
//        _videoPlayer = [[FSLAVPlayer alloc] init];
//        _videoPlayer.currentURLStr = [self filePathName:@"111.mp3"];
    }
    return _videoPlayer;
}

- (FSLAVSingleAudioPlayer *)audioPlayer{
    if (!_audioPlayer) {
        _audioPlayer = [FSLAVSingleAudioPlayer player];
        _audioPlayer.currentURLStr = [self filePathName:@"111.mp3"];
    }
    return _audioPlayer;
}
- (FSLAVAudioPlayer *)audioPlayer1{
    if (!_audioPlayer1) {
        _audioPlayer1 = [[FSLAVAudioPlayer alloc] init];
        _audioPlayer1.currentURLStr = [self filePathName:@"111.mp3"];
//        _audioPlayer1 = [[FSLAVAudioPlayer alloc] initWithURL:[self filePathName:@"111.mp3"]];
    }
    return _audioPlayer1;
}

//- (void)playBtnOnClick:(UIButton *)btn{
//    btn.selected = !btn.selected;
//    if (btn.selected) {
//
//        if ([self.videoPlayer isPlaying]) return;
//
//        [self.videoPlayer play];
//    }else{
//
//        if (!self.videoPlayer.isPlaying) return;
//        [self.videoPlayer pause];
//    }
//}

- (FSLAVH246VideoDecoder *)videoDecoder{
    if (!_videoDecoder) {
        _videoDecoder = [[FSLAVH246VideoDecoder alloc] init];
        _videoDecoder.contiantView = self.view;
//        [self.view.layer addSublayer:_videoDecoder.bufferDisplayLayer];
    }
    return _videoDecoder;
}

- (void)playBtnOnClick:(UIButton *)btn{
    btn.selected = !btn.selected;
//    if (btn.selected) {
//
//        [self.audioPlayer1 play];
//
//    }else{
//        [self.audioPlayer1 pause];
//
//    }
    if (btn.selected) {
        
        [self.videoDecoder startReadStreamingDataFromPath:[self filePathName:@"123.h264"]];
        
    }else{
        
        [self.videoDecoder endReadStreamingData];
    }
}

- (CGFloat)musicDuration{
        
    AVAsset *asset = [AVAsset assetWithURL:self.audioPath];
    CMTime duration = asset.duration;
    _musicDuration = duration.value / duration.timescale;
    return _musicDuration;
}


#pragma mark -- 获取本地资源
- (NSString *)filePathName:(NSString *)fileName{
    
    return [[NSBundle mainBundle] pathForResource:fileName ofType:nil];
}



- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    
    [self setEditing:NO];
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
