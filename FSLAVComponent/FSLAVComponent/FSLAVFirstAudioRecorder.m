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
@property (nonatomic,weak) NSTimer *soundWavesTimer;//音频声波定时器

@end

@implementation FSLAVFirstAudioRecorder

@dynamic delegate;//解决子类协议继承父类协议的delegate命名警告

- (void)dealloc{
    
    if (self.isRecording) [self.recorder stop];
    [self removeSoundWavesTimer];
}

- (instancetype)initWithAudioRecordConfiguration:(FSLAVAudioRecorderConfiguration *)configuration{
    if (self = [self init]) {
        _configuration = configuration;
    }
    return self;
}


#pragma mark -- 懒加载初始化
- (AVAudioRecorder *)recorder{

    if (!_recorder) {

        /*
         url:录音文件保存的路径
         settings: 录音的设置
         error:错误
         */
        NSError *error;
        _recorder = [[AVAudioRecorder alloc] initWithURL:_configuration.savePathURL settings:_configuration.audioConfigure error:&error];
        _recorder.delegate = self;
        //如果要监控声波则必须设置为YES
        _recorder.meteringEnabled = YES;
        if (error) {

            NSAssert(YES, @"录音机初始化失败,请检查参数");
        }

    }
    return _recorder;
}

- (NSTimer *)soundWavesTimer{
    if (!_soundWavesTimer) {

        _soundWavesTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(soundWavesAction) userInfo:nil repeats:YES];
        // 添加到运行循环  NSRunLoopCommonModes:占位模式   主线程
        [[NSRunLoop currentRunLoop] addTimer:_soundWavesTimer forMode:NSRunLoopCommonModes];
        // 如果不改变Mode模式在滑动屏幕的时候定时器就不起作用了
   }

    return _soundWavesTimer;

}//定时器

#pragma mark -- Private methods
//销毁定时器
- (void)removeSoundWavesTimer{
    //销毁定时器
    [self.soundWavesTimer invalidate];
    self.soundWavesTimer = nil;
}

//声波定时事件
- (void)soundWavesAction{

    [self.recorder updateMeters];//更新测量值
    float power = [self.recorder averagePowerForChannel:0];//取得第一个通道的音频，注意音频强度范围时-160到0
    CGFloat progress=(1.0/160.0)*(power+160.0);
    if ([self.delegate respondsToSelector:@selector(didChangedAudioRecordingPowerProgress:)]) {
        [self.delegate didChangedAudioRecordingPowerProgress:progress];
    }
}

/**
 录制时间是否超过最大录制时间
 */
- (BOOL)isMoreRecordTime{
    
    BOOL isMore = NO;
    if (_recordTime >= _configuration.maxRecordDelay) {//当前录制的时间与最大录制时间进行比较
        isMore = YES;
    }
    return YES;
}
/**
 录制时间是否小于最小录制时间
 */
- (BOOL)isLessRecordTime{
    BOOL isLess = NO;
    if (_recordTime <= _configuration.minRecordDelay) {//当前录制的时间与最小录制时间进行比较
        isLess = YES;
    }
    return isLess;
}

#pragma mark -- public methods
#pragma mark -- 录制定时事件
- (void)recordTimerAction{
    
    _configuration.recordTimeLength = _recordTime;
    
    if ([self isLessRecordTime]) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(didChangedAudioRecordState:fromAudioRecorder:outputFileAtURL:)]) {
            [self.delegate didChangedAudioRecordState:FSLAVRecordStateLessMinRecordTime fromAudioRecorder:self outputFileAtURL:_configuration.savePathURL];
        }
    }
    
    if ([self isMoreRecordTime]) {
        
        [self stopRecord];
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(didChangedAudioRecordState:fromAudioRecorder:outputFileAtURL:)]) {
            [self.delegate didChangedAudioRecordState:FSLAVRecordStateMoreMaxRecorTime fromAudioRecorder:self outputFileAtURL:_configuration.savePathURL];
        }
    }
}

#pragma mark -- 开始录音
- (void)startRecord{

    if(_isRecording) return;
    _isRecording = YES;

    //把录音文件加载到缓冲区,录制
    if ([self.recorder prepareToRecord] &&  [self.recorder record]) {

        if ([self isMoreRecordTime]) {//是否超过最大录制时间
            //开始录制声音，并且通过performSelector方法设置在录制声音maxRecordDelay以后执行stopRecordingOnAudioRecorder方法，用于停止录音
            [self performSelector:@selector(stopRecord)
                       withObject:nil
                       afterDelay:_configuration.maxRecordDelay];
        }
    }

    if (_configuration.isAcousticTimer) {//是否开启音频定时器

        self.soundWavesTimer.fireDate = [NSDate distantPast];
    }

    if ([self.delegate respondsToSelector:@selector(didChangedAudioRecordState:fromAudioRecorder:outputFileAtURL:)]) {
        [self.delegate didChangedAudioRecordState:FSLAVRecordStateReadyToRecord fromAudioRecorder:self outputFileAtURL:_configuration.savePathURL];
    }
}

#pragma mark -- 暂停录音
- (void)pauaseRecord{

    if(!_isRecording) return;
    _isRecording = NO;
    [self.recorder pause];

    if (_configuration.isAcousticTimer) {//是否开启音频定时器
        //定时器触发的时机。暂停
        self.soundWavesTimer.fireDate = [NSDate distantFuture];
    }
}

#pragma mark -- 停止录音
- (void)stopRecord{

    //这句代码必须加在[self.recorder stop]之前，否则播放录制的音频声音会小到你听不见
    if(!_isRecording) return;
    _isRecording = NO;
//    [self setAudioSession];
    [self.recorder stop];
    _recordTime = self.recorder.currentTime;
    _isRecording = NO;

    if (_configuration.isAcousticTimer) {//是否开启音频定时器

        //定时器触发的时机。暂停
        self.soundWavesTimer.fireDate = [NSDate distantFuture];
    }
}

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

- (void)reRecording{

    if (!_isRecording) return;
    _isRecording = YES;
    
    [self stopRecord];
    
    _recordTime = 0;
    //清空缓存
    [_configuration clearCacheData];
}

#pragma mark -  AVAudioRecorder  Delegate
//录音完成
- (void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)flag{

    NSLog(@"录音完成");
    if (flag) {
        //暂存录音文件路径

        _configuration.recordTimeLength = _recordTime;
        _isRecording = NO;
    }

    if ([self.delegate respondsToSelector:@selector(didChangedAudioRecordState:fromAudioRecorder:outputFileAtURL:)]) {
        [self.delegate didChangedAudioRecordState:FSLAVRecordStateFinish fromAudioRecorder:self outputFileAtURL:_configuration.savePathURL];
    }
}

//录音失败
- (void)audioRecorderEncodeErrorDidOccur:(AVAudioRecorder *)recorder error:(NSError * __nullable)error{
    
    if(!error) return;
    if ([self.delegate respondsToSelector:@selector(didChangedAudioRecordState:fromAudioRecorder:outputFileAtURL:)]) {
        [self.delegate didChangedAudioRecordState:FSLAVRecordStateFailed fromAudioRecorder:self outputFileAtURL:_configuration.savePathURL];
    }
}

@end
