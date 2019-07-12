//
//  HWCutMusicViewController.m
//  AVFoundationTest
//
//  Created by tutu on 2019/6/14.
//  Copyright © 2019 wqb. All rights reserved.
//

#import "HWCutMusicViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "AAPLEAGLLayer.h"

@interface HWCutMusicViewController ()<AVAudioPlayerDelegate,FSLAVH246VideoDecoderDelegate>

@property (nonatomic, strong) NSURL *audioPath;//音频播放器对象

@property (nonatomic, weak) UITextField *startTxt;
@property (nonatomic, weak) UITextField *endTxt;
@property (nonatomic, assign) CGFloat musicDuration;

@property (nonatomic,strong) FSLAVPlayer *videoPlayer;
@property (nonatomic,strong) FSLAVSingleAudioPlayer *audioPlayer;
@property (nonatomic,strong) FSLAVAudioPlayer *audioPlayer1;

@property (nonatomic,strong) FSLAVH246VideoDecoder *videoDecoder;
@property (nonatomic,strong) UIImageView *imageView;
@property (nonatomic,strong) AAPLEAGLLayer *playlayer;

@end

@implementation HWCutMusicViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.navTitle = @"音频录制与播放";
    
    [self imageView];
    
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

- (UIImageView *)imageView{
    if (!_imageView) {
        _imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, NMScreenWidth, NMScreenHeight)];
        _imageView.backgroundColor = [UIColor redColor];
        _imageView.hidden = YES;
        [self.view addSubview:_imageView];
    }
    return _imageView;
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
        _videoDecoder.bufferShowType = FSLAVH246VideoDecoderBufferShowType_Pixel;
        _videoDecoder.decodeDelegate = self;
    }
    return _videoDecoder;
}
//- (LYOpenGLView *)openGLView{
//    if (!_openGLView) {
//        _openGLView = (LYOpenGLView *)self.view;
//        [_openGLView setupGL];
//
//    }
//    return _openGLView;
//}

- (AAPLEAGLLayer *)playlayer{
    if (!_playlayer) {
        
        // 1.获取mOpenGLView用于之后展示数据
        _playlayer = [[AAPLEAGLLayer alloc] initWithFrame:self.view.bounds];
        _playlayer.backgroundColor = [UIColor blackColor].CGColor;
        [self.view.layer insertSublayer:_playlayer atIndex:0];
    }
    return _playlayer;
}

- (void)playBtnOnClick:(UIButton *)btn{
    btn.selected = !btn.selected;
    if (btn.selected) {
        
        [self.videoDecoder startReadVideoStreamingDataFromPath:[self filePathName:@"123.h264"]];
        
    }else{
        
        [self.videoDecoder endReadVideoStreamingData];
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

#pragma mark -- FSLAVH246VideoDecoderDelegate
- (void)didChangedVideoDecodeState:(FSLAVH246VideoDecoderState)state videoDecoder:(FSLAVH246VideoDecoder *)decder{
   
    if (state == FSLAVH246VideoDecoderStateDecoding) {
        
        if (decder.bufferShowType == FSLAVH246VideoDecoderBufferShowType_Image) {
            
            UIImage *image = [decder pixelBufferToImage:decder.pixelBuffer];
            NSLog(@"image---->%@",image);
            self.imageView.image = image;
            self.imageView.hidden = NO;
        }else if (decder.bufferShowType == FSLAVH246VideoDecoderBufferShowType_Pixel){
            self.playlayer.pixelBuffer = decder.pixelBuffer;
        }else{
            
            if ([decder.bufferDisplayLayer isReadyForMoreMediaData]) {
                [self.view.layer addSublayer:decder.bufferDisplayLayer];
                [decder.bufferDisplayLayer enqueueSampleBuffer:decder.sampleBuffer];
            }
        }
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
