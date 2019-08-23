//
//  FSLVideoClipViewController.m
//  FSLAVLearningDemo
//
//  Created by tutu on 2018/6/15.
//  Copyright © 2018年 tutu. All rights reserved.
//

#import "FSLAVVideoClipViewController.h"
#import "VideoTrimmerView.h"
#import "PlayerView.h"

@interface FSLAVVideoClipViewController ()<UIGestureRecognizerDelegate, FSLAVVideoClipperDelegate, VideoTrimmerViewDelegate>

@property (nonatomic, strong) NSMutableArray<void (^)(void)> *actionsAfterViewDidLoad;

@property (weak, nonatomic) IBOutlet UILabel *usageLabel;
@property (strong, nonatomic) IBOutletCollection(UIButton) NSArray<UIButton *> *actionButtons;
@property (weak, nonatomic) IBOutlet PlayerView *playerView;
@property (weak, nonatomic) IBOutlet UIImageView *playIconView;

@property (weak, nonatomic) IBOutlet UILabel *selectedTimeLabel;
@property (weak, nonatomic) IBOutlet UILabel *leftTimeLabel;
@property (weak, nonatomic) IBOutlet UILabel *rightTimeLabel;

@property (weak, nonatomic) IBOutlet VideoTrimmerView *trimmerView;
@property (strong, nonatomic) IBOutlet UITapGestureRecognizer *tap;

/**
 视频裁剪对象
 */
@property (nonatomic, strong) FSLAVVideoClipper *movieClipper;

/**
 视频播放器
 */
@property (nonatomic, strong) AVPlayer *player;

@property (nonatomic, strong) id playerTimeObserver;

@property (nonatomic, assign) BOOL playing;

/**
 当前时间
 */
@property (nonatomic, assign) CMTime currentTime;

/**
 选取时间
 */
@property (nonatomic, assign) CMTimeRange selectedTimeRange;

@end

@implementation FSLAVVideoClipViewController

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    if (!_player) return;
    if (_playerTimeObserver) [self.player removeTimeObserver:_playerTimeObserver];
    [_player.currentItem removeObserver:self forKeyPath:@"status"];
    [_player removeObserver:self forKeyPath:@"rate"];
    [_player cancelPendingPrerolls];
    [_player.currentItem cancelPendingSeeks];
    [_player.currentItem.asset cancelLoading];
    _player = nil;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    //[self.navigationController setNavigationBarHidden:NO animated:NO];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.navTitle = @"单视频时间剪辑";
    self.inputURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"555.MP4" ofType:nil]];
    
    // 执行 _actionsAfterViewDidLoad 存储的任务
    for (void (^action)(void) in _actionsAfterViewDidLoad) {
        action();
    }
    _actionsAfterViewDidLoad = nil;
    
    // 国际化
    _usageLabel.text = NSLocalizedStringFromTable(@"tu_APIMovieClipViewController_usage", @"VideoDemo", @"APIMovieClipViewController_usage");
    [_actionButtons[0] setTitle:NSLocalizedStringFromTable(@"tu_视频裁剪", @"VideoDemo", @"视频裁剪") forState:UIControlStateNormal];
}

/**
 添加在视图加载后的操作
 
 @param action 操作 Block
 */
- (void)addActionAfterViewDidLoad:(void (^)(void))action {
    if (!action) return;
    if (self.viewLoaded) {
        action();
    } else {
        if (!_actionsAfterViewDidLoad) {
            _actionsAfterViewDidLoad = [NSMutableArray array];
        }
        [_actionsAfterViewDidLoad addObject:action];
    }
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    return NO;
}

+ (NSString *)textWithTimeInterval:(NSTimeInterval)timeInterval {
    if (isnan(timeInterval)) return nil;
    NSInteger time = (NSInteger)timeInterval;
    NSInteger hours = time / 60 / 60;
    NSInteger minutes = (time / 60) % 60;
    NSInteger seconds = time % 60;
    NSString *text = @"";
    if (hours > 0) {
        text = [text stringByAppendingFormat:@"%02li", hours];
    }
    text = [text stringByAppendingFormat:@"%02li:%02li", minutes, seconds];
    return text;
}

#pragma mark - property

- (void)setInputURL:(NSURL *)inputURL {
    _inputURL = inputURL;
    if (!inputURL) {
        [HUDManager showTextHud:@"无输入视频"];
        return;
    }
    
    __weak typeof(self) weakSelf = self;
    [self addActionAfterViewDidLoad:^{
        [weakSelf setupChipper];
        [weakSelf setupPlayer];
        [weakSelf setupThumbnails];
    }];
}

- (void)setPlaying:(BOOL)playing {
    _playing = playing;
    if (!_trimmerView.dragging) _playIconView.hidden = playing;
}

- (void)setCurrentTime:(CMTime)currentTime {
    [_player.currentItem cancelPendingSeeks];
    __weak typeof(self) weakSelf = self;
    [_player seekToTime:currentTime toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero completionHandler:^(BOOL finished) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf updateUIWithTime:weakSelf.currentTime];
        });
    }];
}
- (CMTime)currentTime {
    return _player.currentItem.currentTime;
}

- (void)setSelectedTimeRange:(CMTimeRange)selectedTimeRange {
    _selectedTimeRange = selectedTimeRange;
    NSTimeInterval rangeInterval = CMTimeGetSeconds(selectedTimeRange.duration);
    _selectedTimeLabel.text = [NSString stringWithFormat:@"已选择%.1f秒", rangeInterval];
    _leftTimeLabel.text = [self.class textWithTimeInterval:CMTimeGetSeconds(selectedTimeRange.start)];
    _rightTimeLabel.text = [self.class textWithTimeInterval:CMTimeGetSeconds(CMTimeRangeGetEnd(selectedTimeRange))];
}

#pragma mark - setup

- (void)setupChipper {
    
    FSLAVVideoClipperOptions *clipOptions = [FSLAVVideoClipperOptions defaultOptions];
    clipOptions.mediaURL = _inputURL;
    
    _movieClipper = [[FSLAVVideoClipper alloc] initWithClipperVideoOptions:clipOptions];
    _movieClipper.clipDelegate = self;
}

- (void)setupPlayer {
    _player = [[AVPlayer alloc] initWithURL:_inputURL];
    self.playerView.player = _player;
    
    [_player addObserver:self forKeyPath:@"rate" options:NSKeyValueObservingOptionNew context:nil];
    [_player.currentItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerEnd:) name:AVPlayerItemDidPlayToEndTimeNotification object:_player.currentItem];
    _tap.enabled = NO;
}

- (void)setupThumbnails {
//    TuSDKVideoImageExtractor *imageExtractor = [TuSDKVideoImageExtractor createExtractor];
//    imageExtractor.videoPath = _inputURL;
//    imageExtractor.extractFrameCount = 20;
//    [imageExtractor asyncExtractImageList:^(NSArray<UIImage *> * images) {
//        self.trimmerView.thumbnailsView.thumbnails = images;
//    }];
}

- (void)readyToPlay {
    const NSTimeInterval duration = CMTimeGetSeconds(_player.currentItem.duration);
    if (duration < 3 || duration > 60) {
        [HUDManager showTextHud:@"建议选择大于3秒，小于60秒的视频"];
    }
    _tap.enabled = YES;
    
    // 监听播放进度
    [self addTimeObserver];
    
    // 设置时间标签
    self.selectedTimeRange = [_trimmerView selectedTimeRangeAtDuration:_player.currentItem.duration];
}

#pragma mark - action

- (IBAction)playerViewTapAction:(UITapGestureRecognizer *)sender {
    if (_playing) {
        [_player pause];
    } else {
        [_player play];
    }
}

- (IBAction)clipButtonAction:(UIButton *)sender {
    // 视频裁剪 API
    NSMutableArray *dropArray = [NSMutableArray array];
    const NSTimeInterval duration = CMTimeGetSeconds(_player.currentItem.duration);
    const NSTimeInterval startTime = CMTimeGetSeconds(_selectedTimeRange.start);
    const NSTimeInterval endTime = CMTimeGetSeconds(CMTimeRangeGetEnd(_selectedTimeRange));
    if (startTime >=0 && startTime < duration) {
        FSLAVTimeRange *leftCutTimeRange = [FSLAVTimeRange timeRangeWithStartSeconds:0 endSeconds:startTime];
        [dropArray addObject:leftCutTimeRange];
    }
    if (endTime < duration && endTime > 0) {
        FSLAVTimeRange *rightCutTimeRange = [FSLAVTimeRange timeRangeWithStartSeconds:endTime endSeconds:duration];
        [dropArray addObject:rightCutTimeRange];
    }
    _movieClipper.clipVideo.atTimeRange = [FSLAVTimeRange timeRangeWithStartSeconds:startTime endSeconds:endTime];
    [HUDManager showTextHud:@"正在裁剪..."];
//    _movieClipper.deleteTimeRangeArr = dropArray;
    [_movieClipper startClippingVideoWithCompletion:^(NSString * _Nonnull filePath, FSLAVClipStatus status) {
        if (status == FSLAVClipStatusCompleted) {
            // 操作成功 保存到相册
            UISaveVideoAtPathToSavedPhotosAlbum(filePath, nil, nil, nil);
        } else if (status == FSLAVClipStatusFailed || status == FSLAVClipStatusCancelled || status == FSLAVClipStatusUnknown) {
            
        }
    }];
   
}

- (void)playerEnd:(NSNotification *)notification {
    self.currentTime = _selectedTimeRange.start;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey, id> *)change context:(void *)context {
    AVPlayerItem *playerItem = (AVPlayerItem *)object;
    
    if ([keyPath isEqualToString:@"status"]) {
        if (playerItem.status == AVPlayerItemStatusReadyToPlay) {
            [self readyToPlay];
        } else if (playerItem.status == AVPlayerItemStatusFailed){
            NSLog(NSLocalizedStringFromTable(@"tu_视频加载出错", @"VideoDemo", @"视频加载出错"));
        }
    }
    if ([keyPath isEqualToString:@"rate"]) {
        self.playing = _player.rate != 0.0;
    }
}

- (void)addTimeObserver {
    __weak typeof(self) weakSelf = self;
    [self.player addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(0.1, USEC_PER_SEC) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
        [weakSelf updateUIWithTime:time];
        if (weakSelf.player.rate != .0 && CMTIME_COMPARE_INLINE(weakSelf.currentTime, >=, CMTimeRangeGetEnd(weakSelf.selectedTimeRange))) {
            weakSelf.currentTime = weakSelf.selectedTimeRange.start;
        }
    }];
}

- (void)updateUIWithTime:(CMTime)time {
    [_trimmerView setCurrentTime:time atDuration:_player.currentItem.duration];
}

#pragma mark - VideoTrimmerViewDelegate

- (void)trimmer:(id<VideoTrimmerViewProtocol>)trimmer updateProgress:(double)progress atLocation:(TrimmerTimeLocation)location {
    NSTimeInterval duration = CMTimeGetSeconds(_player.currentItem.duration);
    NSTimeInterval targetTime = duration * progress;
    self.currentTime = CMTimeMakeWithSeconds(targetTime, _player.currentItem.duration.timescale);
    
    if (location == TrimmerTimeLocationLeft || location == TrimmerTimeLocationRight) {
        self.selectedTimeRange = [_trimmerView selectedTimeRangeAtDuration:_player.currentItem.duration];
    }
}

- (void)trimmer:(id<VideoTrimmerViewProtocol>)trimmer didStartAtLocation:(TrimmerTimeLocation)location {
    [_player pause];
    _playIconView.hidden = YES;
}

- (void)trimmer:(id<VideoTrimmerViewProtocol>)trimmer didEndAtLocation:(TrimmerTimeLocation)location {
    _playIconView.hidden = _playing;
}

#pragma mark - TuSDKMovieClipperDelegate

/**
状态通知代理
 @param status lsqMovieClipperSessionStatus
@param videoClipper FSLAVVideoClipper
*/
- (void)didClippingVideoStatusChanged:(FSLAVClipStatus)status onVideoClip:(FSLAVVideoClipper *)videoClipper{
    
    NSLog(@"FSLAVVideoClipper 的目前的状态是 ： %ld",(long)status);
    
    if (status == FSLAVClipStatusCompleted) {
        [HUDManager showTextHud:@"操作完成，请前往相册查看视频"];
    } else if (status == FSLAVClipStatusFailed) {
        [HUDManager showTextHud:@"操作失败，无法生成视频文件"];
    } else if (status == FSLAVClipStatusCancelled) {
        [HUDManager showTextHud:@"出现问题，操作被取消"];
    } else if (status == FSLAVClipStatusClipping) {
        // 正在剪裁
    }
}

/**
 导出地址通知代理
 
 @param filePath 导出地址
 @param videoClipper  FSLAVVideoClipper
 */
- (void)didCompletedClipVideoOutputFilePath:(NSString *)filePath onVideoClip:(FSLAVVideoClipper *)videoClipper{
    NSLog(@"视频的临时文件的路径 ：%@", filePath);

}

@end
