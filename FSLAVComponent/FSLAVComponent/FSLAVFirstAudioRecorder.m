//
//  AudioFirstVoiceRecorder.m
//  AudioVideoSDK
//
//  Created by tutu on 2019/6/6.
//  Copyright © 2019 tutu. All rights reserved.
//

#import "FSLAVFirstAudioRecorder.h"

@interface FSLAVFirstAudioRecorder ()
<AVAudioRecorderDelegate>

@property (nonatomic,strong) AVAudioRecorder *recorder;//音频录制器
@property (nonatomic,weak) NSTimer *timer;//音频声波定时器

@end

@implementation FSLAVFirstAudioRecorder

- (void)dealloc{
    
    if (self.isRecording) [self.recorder stop];
    //销毁定时器
    [self.timer invalidate];
    self.timer = nil;
}

//- (instancetype)init
//{
//    self = [super init];
//    if (self) {
//
//        [self initRecordSession];
//        self.isAcousticTimer = YES;
//    }
//    return self;
//}
//
//- (instancetype)initWithAudioRecordConfiguration:(FSLAVAudioRecorderConfiguration *)configuration{
//    if (self = [super init]) {
//        _configuration = configuration;
//
//    }
//    return self;
//}
//
///**
// *  初始化音频检查
// */
//- (void)initRecordSession{
//
//    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
//    //设置播放和录音状态，以便可以在录制完之后播放录音
//    [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
//    [audioSession setActive:YES error:nil];
//}
//
//#pragma mark -- 懒加载初始化
//- (AVAudioRecorder *)recorder{
//
//    if (!_recorder) {
//
//        /*
//         url:录音文件保存的路径
//         settings: 录音的设置
//         error:错误
//         */
//        NSError *error;
//        _recorder = [[AVAudioRecorder alloc] initWithURL:_configuration.savePathURL settings:_configuration.audioConfigure error:&error];
//        _recorder.delegate = self;
//        //如果要监控声波则必须设置为YES
//        _recorder.meteringEnabled = YES;
//        if (error) {
//
//            NSAssert(YES, @"录音机初始化失败,请检查参数");
//        }
//
//    }
//    return _recorder;
//}
//
//- (NSTimer *)timer{
//    if (!_timer) {
//
//        _timer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(upDataProgress) userInfo:nil repeats:YES];
//    }
//
//    return _timer;
//
//}//定时器
//
//#pragma mark -- Action
//- (void)upDataProgress{
//
//    [self.recorder updateMeters];//更新测量值
//    float power = [self.recorder averagePowerForChannel:0];//取得第一个通道的音频，注意音频强度范围时-160到0
//    CGFloat progress=(1.0/160.0)*(power+160.0);
//    if ([self.audioVideoProtocol respondsToSelector:@selector(audioPowerChangeProgress:)]) {
//        [self.audioVideoProtocol audioPowerChangeProgress:progress];
//    }
//}
//
//#pragma mark -- 开始录音
//- (void)startRecord{
//
//    if(self.isRecording) return;
//    if(![self.recorder isRecording]) return;
//    self.isRecording = YES;
//
//    //把录音文件加载到缓冲区,录制
//    if ([self.recorder prepareToRecord] &&  [self.recorder record]) {
//
//        if (self.isAutomaticStop) {//是否自动停止录制
//            //开始录制声音，并且通过performSelector方法设置在录制声音maxRecordDelay以后执行stopRecordingOnAudioRecorder方法，用于停止录音
//            [self performSelector:@selector(stopRecord)
//                       withObject:nil
//                       afterDelay:self.maxRecordDelay];
//        }
//    }
//
//    if (self.isAcousticTimer) {//是否开启音频定时器
//
//        self.timer.fireDate = [NSDate distantPast];
//    }
//
//    if ([self.audioVideoProtocol respondsToSelector:@selector(audioVideoRecorderWillStartState:)]) {
//        [self.audioVideoProtocol audioVideoRecorderWillStartState:AudioVideoRecordingStart];
//    }
//}
//
//#pragma mark -- 暂停录音
//- (void)pauaseRecord{
//
//    if(![self.recorder isRecording]) return;
//    [self.recorder pause];
//
//    if (self.isAcousticTimer) {//是否开启音频定时器
//
//        //定时器触发的时机。暂停
//        self.timer.fireDate = [NSDate distantFuture];
//    }
//}
//
//#pragma mark -- 停止录音
//- (void)stopRecord{
//
//    //这句代码必须加在[self.recorder stop]之前，否则播放录制的音频声音会小到你听不见
//    [self setAudioSession];
//    [self.recorder stop];
//
//    self.recordTimeLength = self.recorder.currentTime;
//    self.isRecording = NO;
//
//    if (self.isAcousticTimer) {//是否开启音频定时器
//
//        //定时器触发的时机。暂停
//        self.timer.fireDate = [NSDate distantFuture];
//    }
//}
//
///**
// *  此处需要恢复设置回放标志，否则会导致其它播放声音也会变小
// */
//- (void)setAudioSession{
//
//    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
//    //设置播放和录音状态，以便可以在录制完之后播放录音
//    [audioSession setCategory:AVAudioSessionCategoryPlayback error:nil];
//    [audioSession setActive:YES error:nil];
//}
//
//- (void)reRecording{
//
//    if (self.isRecording) {
//        [self stopRecord];
//    }
//    self.recordTimeLength = 0;
//    [self cleanFileCache];
//}
//
//#pragma mark -  AVAudioRecorder  Delegate
//- (void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)flag{
//
//    NSLog(@"录音完成");
//
//    NSString *outputPath = @"";
//    NSInteger recordTimeLength = 0;
//    if (flag) {
//        //暂存录音文件路径
//
//        outputPath = [NSString stringWithContentsOfURL:[self getSavePath] encoding:NSUTF8StringEncoding error:nil];
//        recordTimeLength = self.recordTimeLength;
//        self.isRecording = NO;
//    }
//
//    if ([self.audioVideoProtocol respondsToSelector:@selector(audioVideoRecorderDidFinishState:outputPath:recordTimeLength:)]) {
//        [self.audioVideoProtocol audioVideoRecorderDidFinishState:AudioVideoRecordingSuccess outputPath:outputPath recordTimeLength:recordTimeLength];
//    }
//}//录音完成

@end
