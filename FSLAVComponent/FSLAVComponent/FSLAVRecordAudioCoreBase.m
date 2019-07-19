//
//  FSLAVRecordAudioCoreBase.m
//  FSLAVComponent
//
//  Created by tutu on 2019/6/21.
//  Copyright © 2019 tutu. All rights reserved.
//

#import "FSLAVRecordAudioCoreBase.h"

@implementation FSLAVRecordAudioCoreBase

@dynamic delegate;//解决子类协议继承父类协议的delegate命名警告

#pragma mark -- init
- (instancetype)initWithAudioRecordOptions:(FSLAVAudioRecoderOptions *)options{
    if (self = [super init]) {
        _options = options;
    }
    return self;
}

#pragma mark -- public set
- (void)setSessionCategory:(AVAudioSessionCategory)sessionCategory{
    
    [[AVAudioSession sharedInstance] setCategory:sessionCategory error:nil];
    //[[AVAudioSession sharedInstance] setCategory: AVAudioSessionCategorySoloAmbient error: nil];
    [[AVAudioSession sharedInstance] setActive:YES error:nil];
}

#pragma mark -- 激活Session控制当前的使用场景

/**
 *  初始化音频检查
 */
- (void)setAudioSession{
    
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    //设置播放和录音状态，以便可以在录制完之后播放录音
    [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
    [audioSession setActive:YES error:nil];
}

/**
 重置音频会话分类
 */
- (void)resetAudioSessionCategory;
{
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    NSError *error = nil;
    AVAudioSessionCategoryOptions audioSessionCategoryOptions = AVAudioSessionCategoryOptionMixWithOthers | AVAudioSessionCategoryOptionDuckOthers;
    [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:audioSessionCategoryOptions error:&error];
    if (error) {
        NSLog(@"AVAudioSession set category error: %@", error);
        error = nil;
    }
    [audioSession setActive:YES error:&error];
    if (error) {
        NSLog(@"AVAudioSession active error: %@", error);
        error = nil;
    }
}

#pragma mark -- 媒体写入
- (AVAssetWriter *)audioWriter{
    if (!_audioWriter) {
        NSError *error;
        _audioWriter = [AVAssetWriter assetWriterWithURL:_options.outputFilePathURL fileType:AVFileTypeAppleM4A error:&error];
        if(error){
            fslLError(@"audioWriter init failed :%@",error);
            return nil;
        }
    }
    return _audioWriter;
}

- (AVAssetWriterInput *)audioWriterInput{
    if (!_audioWriterInput) {
        
        _audioWriterInput = [[AVAssetWriterInput alloc] initWithMediaType:AVMediaTypeAudio outputSettings:_options.audioConfigure];
        //一个布尔值，指示输入是否应针对实时源调整其对媒体数据的处理。
        _audioWriterInput.expectsMediaDataInRealTime = YES;
    }
    return _audioWriterInput;
}

/**
 媒体写入器audioWriter开始写入
 */
- (void)startWriting;
{
    [self destory];
    [self.audioWriter startWriting];
}

/**
 媒体写入器audioWriter取消写入
 */
- (void)cancelWriting;
{
    
    [self.audioWriter cancelWriting];
}

/**
 设置回调通知，并委托协议
 
 @param recoderOptions 回调的录制结果
 */
- (void)notifyRecordResult:(FSLAVAudioRecoderOptions *)recoderOptions;
{
    
}

/**
 摧毁对象
 */
- (void)destory{
    [super destory];
    
    if (_audioWriter) {
        //销毁媒体写入器
        [_audioWriter cancelWriting];
        _audioWriter = nil;
    }
}

@end
