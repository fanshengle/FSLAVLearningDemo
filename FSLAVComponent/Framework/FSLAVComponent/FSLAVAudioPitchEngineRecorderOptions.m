//
//  FSLAVAudioPitchEngineRecorderOptions.m
//  FSLAVComponent
//
//  Created by tutu on 2019/8/1.
//  Copyright © 2019 tutu. All rights reserved.
//

#import "FSLAVAudioPitchEngineRecorderOptions.h"

@implementation FSLAVAudioPitchEngineRecorderOptions

/**
 * 改变音频音调 [速度设置将失效]
 * pitch 0 > pitch [大于1时声音升调，小于1时为降调]
 * pitchType 与 pitch不能同时设置；因为pitchType就是设置固定值pitch得到的
 */
- (void)setPitchType:(FSLAVSoundPitchType)pitchType{
    if(_pitchType == pitchType) return;
    _pitchType = pitchType;
    
    _isSetPitch = NO;
    _isSetPitchType = YES;
    _isSetSpeed = NO;
    _isSetSpeedMode = NO;
}

/**
 * 改变音频音调 [速度设置将失效]
 * pitch 0 > pitch [大于1时声音升调，小于1时为降调]
 * pitchType 与 pitch不能同时设置；因为pitchType就是设置固定值pitch得到的
 */
- (void)setPitch:(float)pitch{
    if(_pitch == pitch) return;
    _pitch = pitch;
    
    _isSetPitch = YES;
    _isSetPitchType = NO;
    _isSetSpeed = NO;
    _isSetSpeedMode = NO;
}

/**
 * 改变音频播放速度 [变速不变调, 音调设置将失效]
 * speedMode 与 speed不能同时设置；因为FSLAVSoundSpeedMode就是设置固定值speed得到的
 */
- (void)setSpeedMode:(FSLAVSoundSpeedMode)speedMode{
    if(_speedMode == speedMode) return;
    _speedMode = speedMode;
    
    _isSetPitch = NO;
    _isSetPitchType = NO;
    _isSetSpeed = NO;
    _isSetSpeedMode = YES;
}

/**
 * 改变音频播放速度 [变速不变调, 音调设置将失效]
 * speed 0 > speed
 */
- (void)setSpeed:(float)speed;
{
    if(_speed == speed) return;
    _speed = speed;
    _isSetPitch = NO;
    _isSetPitchType = NO;
    _isSetSpeed = YES;
    _isSetSpeedMode = NO;
}

/**
 设置默认参数配置(可以重置父类的默认参数，不设置的话，父类的默认参数会无效)
 */
- (void)setConfig;
{
    [super setConfig];
    
    _speedMode = FSLAVSoundSpeedMode_Normal;
    _pitchType = FSLAVSoundPitchNormal;
    
    _audioSetting.audioFormat = kAudioFormatMPEG4AAC;
    _enableCreateFilePath = NO;
    _outputFileName = @"audioPitchRecordFile";
    _saveSuffixFormat = @"m4a";
}

@end
