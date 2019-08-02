//
//  FSLAVAudioPitchSegmentRecordViewController.m
//  FSLAVLearningDemo
//
//  Created by tutu on 2019/7/26.
//  Copyright © 2019 tutu. All rights reserved.
//

#import "FSLAVAudioPitchSegmentRecordViewController.h"
#import "MarkableProgressView.h"
#import "speedSegmentButton.h"
#import "PitchSegmentButton.h"
#import "RecordButton.h"

@interface FSLAVAudioPitchSegmentRecordViewController ()<FSLAVAudioRecorderDelegate>

@property (weak, nonatomic) IBOutlet UILabel *usageLab;
@property (weak, nonatomic) IBOutlet UIView *actionPanel;
@property (weak, nonatomic) IBOutlet MarkableProgressView *progressView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bottomBarHeightLayout;
@property (weak, nonatomic) IBOutlet speedSegmentButton *speedBar;
@property (weak, nonatomic) IBOutlet PitchSegmentButton *pitchBar;

// AVPlayer 用以演示音频播放
@property (nonatomic, strong) AVPlayer *audioPlayer;

/**
 音频录制器
 */
@property (nonatomic, strong) FSLAVAudioPitchEngineRecorder *audioRecorder;
/**
 最大录制时长
 */
@property (nonatomic, assign) NSTimeInterval maxReocrdDuration;
/**
 完成录制
 */
@property (nonatomic, assign) BOOL reachMaxReocrdDuration;

@end

@implementation FSLAVAudioPitchSegmentRecordViewController

+ (CGFloat)bottomContentOffset {
    return 40;
}

+ (CGFloat)bottomPreviewOffset {
    return 220;
}

- (void)viewWillDisappear:(BOOL)animated;
{
    [_audioPlayer pause];
    [_audioRecorder cancelRecord];
    
    [super viewWillDisappear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (@available(iOS 11.0, *)) {
        _bottomBarHeightLayout.constant += self.view.safeAreaInsets.bottom;
        [self.view setNeedsUpdateConstraints];
    }
}

- (void)didMoveToParentViewController:(UIViewController *)parent {
    [super didMoveToParentViewController:parent];
    if (parent) {
        _progressView.hidden = NO;
    }
}
- (void)willMoveToParentViewController:(UIViewController *)parent {
    [super willMoveToParentViewController:parent];
    if (!parent) {
        _progressView.hidden = YES;
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    _maxReocrdDuration = 30;
    
    // AVPlayer 用以演示音频播放
    _audioPlayer = [[AVPlayer alloc] init];
    
    _audioRecorder = [[FSLAVAudioPitchEngineRecorder alloc] init];
    _audioRecorder.delegate = self;
    
    [self setupUI];
}

- (void)setupUI {
    
    _progressView.hidden = YES;
    _actionPanel.hidden = YES;
}

- (void)updateActionPanel {
    
    self.actionPanel.hidden = _progressView.progress <= 0.0;
}
- (IBAction)speedSegmentBtn:(speedSegmentButton *)sender {
    
    _audioRecorder.pitchOptions.speedMode = sender.speedMode;
    
    _pitchBar.selectedIndex = 2;
}

- (IBAction)pitchSegmentBtn:(PitchSegmentButton *)sender {
    
    _audioRecorder.pitchOptions.pitchType = sender.pitchType;
    
    _speedBar.selectedIndex = 2;
}

/**
 撤销按钮事件
 */
- (IBAction)undoAction:(UIButton *)sender {
    // 回删
    [_audioRecorder deleteLastAudioFragment];
    
    // 更新音频录制操作界面各控件状态
    [_progressView popMark];
    _reachMaxReocrdDuration = NO;
    
    [self updateActionPanel];
}
/**
 完成按钮事件
 */
- (IBAction)confirmAction:(UIButton *)sender {
    
    // 完成录制
    [_audioRecorder stopRecord];
}
/**
 录制按钮抬手事件
 
 @param sender 按钮
 */
- (IBAction)touchEndAction:(UIButton *)sender {
    
     [_audioPlayer pause];
    // 更新录制操作界面
    [self updateActionPanel];

    if (_reachMaxReocrdDuration) return;
    // 暂停录制
    [_audioRecorder pauseRecord];
}

/**
 录制按钮按下事件
 
 @param sender 按钮
 */
- (IBAction)touchDownAction:(UIButton *)sender {
    
     [_audioPlayer pause];
    if (_reachMaxReocrdDuration) {
        [HUDManager showTextHud:@"已到达最大录制时长"];
        return;
    }
    
    [_audioRecorder startRecord];

    _actionPanel.hidden = YES;
}



#pragma mark -- FSLAVAudioRecorderDelegate

/**
 录制状态通知
 @param recorder 录制对象
 @param status 录制状态
 */
- (void)didRecordingStatusChanged:(FSLAVRecordState)status recorder:(id<FSLAVRecordCoreBaseInterface>)recorder{
    switch (status) {
            // 正在进行音频录制
        case FSLAVRecordStateRecording:{
            
        } break;
            // 暂停音频录制
        case FSLAVRecordStatePause:{
            // 暂停是进行记录
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.progressView pushMark];
            });
        } break;
            // 取消音频录制
        case FSLAVRecordStateCanceled:{
            
        } break;
            // 完成音频录制
        case FSLAVRecordStateCompleted:{
            
        } break;
            // 音频录制失败
        case FSLAVRecordStateFailed:{
            
        } break;
            // 未知状态
        case FSLAVRecordStateUnKnow:{
            
        } break;
            
        default:
            break;
    }
}

/**
 录制完成
 @param filePath 录制结果
 @param recorder 录制对象
 */
- (void)didCompletedOutputFilePath:(NSString *)filePath recorder:(id<FSLAVRecordCoreBaseInterface>)recorder{
    dispatch_async(dispatch_get_main_queue(), ^{
        [HUDManager showTextHud:@"开始播放"];
    });
    [_audioPlayer pause];
    _audioPlayer = [AVPlayer playerWithURL:[NSURL fileURLWithPath:filePath]];
    [_audioPlayer play];
    
    
}

/**
 录制时间回调
 @param recordDuration 已录制时长
 @param recorder 录制对象
 */
- (void)didCompletedOutputDuration:(NSTimeInterval)recordDuration recorder:(id<FSLAVRecordCoreBaseInterface>)recorder{
   
    if (recordDuration >= _maxReocrdDuration) {
        _reachMaxReocrdDuration = YES;
        [_audioRecorder pauseRecord];
        dispatch_async(dispatch_get_main_queue(), ^{
            [HUDManager showTextHud:@"已到达最大录制时长"];
        });
    }
    
    // 更新 UI
    dispatch_async(dispatch_get_main_queue(), ^{
        self.progressView.progress = recordDuration / self.maxReocrdDuration;
    });
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
