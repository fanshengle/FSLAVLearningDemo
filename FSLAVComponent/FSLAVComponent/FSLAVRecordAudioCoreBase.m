//
//  FSLAVRecordAudioCoreBase.m
//  FSLAVComponent
//
//  Created by tutu on 2019/6/21.
//  Copyright © 2019 tutu. All rights reserved.
//

#import "FSLAVRecordAudioCoreBase.h"

@implementation FSLAVRecordAudioCoreBase

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

@end
