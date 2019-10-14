//
//  FSLAVVideoThumbnailsViewController.m
//  FSLAVLearningDemo
//
//  Created by bqlin on 2018/6/15.
//  Copyright © 2018年 tutu. All rights reserved.
//

#import "FSLAVVideoThumbnailsViewController.h"
#import "PlayerView.h"

static const CGFloat kMargin = 16;
static const int kCountAtRow = 5;

@interface FSLAVVideoThumbnailsViewController ()

@property (nonatomic, strong) NSMutableArray<void (^)(void)> *actionsAfterViewDidLoad;

@property (strong, nonatomic) IBOutletCollection(UIButton) NSArray<UIButton *> *actionButtons;
@property (weak, nonatomic) IBOutlet PlayerView *playerView;
@property (weak, nonatomic) IBOutlet UIScrollView *thumbnailScrollView;

@property (nonatomic, assign) CGFloat imageWidth;

/**
 视频图像提取器
 */
@property (nonatomic, strong) FSLAVVideoImageExtractor *imageExtractor;

/**
 返回的缩略图
 */
@property (nonatomic, strong) NSArray<UIImage*> *thumbnails;

/**
 系统播放器
 */
@property (strong, nonatomic) AVPlayer *player;

@end

@implementation FSLAVVideoThumbnailsViewController

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
    
    // 添加后台、前台切换的通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(enterBackFromFront) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(enterFrontFromBack) name:UIApplicationWillEnterForegroundNotification object:nil];
    
    self.navTitle = @"单视频获取缩略图";
    
    _imageWidth = (CGRectGetWidth([UIScreen mainScreen].bounds) - kMargin) / kCountAtRow - kMargin;
    
    // 执行 _actionsAfterViewDidLoad 存储的任务
    for (void (^action)(void) in _actionsAfterViewDidLoad) {
        action();
    }
    _actionsAfterViewDidLoad = nil;
    
    // 国际化
    [_actionButtons[0] setTitle:@"获取缩略图" forState:UIControlStateNormal];
}

- (NSURL *)fileURLWithName:(NSString *)fileName {
    return [[NSBundle mainBundle] URLForResource:fileName withExtension:nil];
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

#pragma mark - 后台切换操作

/**
 进入后台
 */
- (void)enterBackFromFront {
    if (_player.rate != 0) {
        [_player pause];
    }
 }

/**
 后台到前台
 */
- (void)enterFrontFromBack {
     if (_player.rate == 0) {
         [_player play];
     }
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
        [weakSelf setupVideoPlayer];
        [weakSelf setupVideoThumbnailsExtractor];
    }];
}

#pragma mark - setup
/// 初始化视频缩略图提取器
- (void)setupVideoThumbnailsExtractor {
    
    FSLAVVideoImageExtractorOptions *videoOptions = [[FSLAVVideoImageExtractorOptions alloc] init];
    videoOptions.videoURL = self.inputURL;
    videoOptions.extractFrameCount = 20;
    
    _imageExtractor = [FSLAVVideoImageExtractor extractor];
    _imageExtractor.videoOptions = videoOptions;
}

- (void)setupVideoPlayer {
    _playerView.backgroundColor = [UIColor clearColor];
    // 添加视频资源
    AVPlayerItem *playerItem = [[AVPlayerItem alloc] initWithURL:_inputURL];
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
 异步获取缩略图
 */
- (IBAction)gainThumbnails {
    [_imageExtractor asyncExtractImageList:^(NSArray<UIImage *> * images) {
        // 获取到返回的视频的缩略图
        self.thumbnails = images;
    }];
    
    // 获取某一时刻的图片
    // UIImage *image = [imageExtractor frameImageAtTime:CMTimeMake(7, 1)];
}

/**
 重新获取
 */
- (IBAction)resetGain {
    self.thumbnails = nil;
}

#pragma mark - property

- (void)setThumbnails:(NSArray<UIImage *> *)thumbnails {
    _thumbnails = thumbnails;
    
    if (_thumbnailScrollView.subviews.count) {
        for (UIImageView *view in _thumbnailScrollView.subviews) {
            [view removeFromSuperview];
        }
    }
    
    if (!thumbnails.count) return;
    const CGSize thumbnailSize = thumbnails.firstObject.size;
    CGFloat imageHeight = _imageWidth / thumbnailSize.width * thumbnailSize.height;
    CGFloat x = 0, y = 0;
    for (int i = 0; i < thumbnails.count; i++) {
        x = kMargin + (_imageWidth + kMargin) * (i % kCountAtRow);
        y = kMargin + (imageHeight + kMargin) * floor(i / kCountAtRow);
        
        UIImage *image = thumbnails[i];
        
        UIImageView *imageView = [self imageViewWithImage:image];
        imageView.frame = CGRectMake(x, y, _imageWidth, imageHeight);
    }
    self.thumbnailScrollView.contentSize = CGSizeMake(CGRectGetWidth(self.thumbnailScrollView.bounds), y + imageHeight + kMargin);
}

- (UIImageView *)imageViewWithImage:(UIImage *)image {
    if (!image) return nil;
    UIImageView *imageView = [[UIImageView alloc] init];
    imageView.image = image;
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    imageView.layer.borderColor = [UIColor whiteColor].CGColor;
    imageView.layer.borderWidth = 1;
    [self.thumbnailScrollView addSubview:imageView];
    return imageView;
}

@end
