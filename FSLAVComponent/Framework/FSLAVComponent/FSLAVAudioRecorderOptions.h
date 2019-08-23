//
//  FSLAVAudioRecorderOptions.h
//  FSLAVComponent
//
//  Created by tutu on 2019/6/28.
//  Copyright © 2019 tutu. All rights reserved.
//

#import "FSLAVRecorderOptions.h"
#import "FSLAVEncodeAudioSetting.h"

NS_ASSUME_NONNULL_BEGIN

/**
 音频质量（VideoQuality_Default为默认配置）
 */
typedef NS_ENUM (NSUInteger,  FSLAVAudioRecordQuality)
{
    FSLAVAudioRecordQuality_min = 0,
    
    FSLAVAudioRecordQuality_Low = 1,
    
    FSLAVAudioRecordQuality_Medium = 2,
    
    FSLAVAudioRecordQuality_High = 3,
    
    FSLAVAudioRecordQuality_Max = 4,

    FSLAVAudioRecordQuality_Default =  FSLAVAudioRecordQuality_Medium
};

/**
 采样率 (默认为44.1Hz)
 */
typedef NS_ENUM (NSUInteger, FSLAVAudioRecordSampleRate)
{
    
    FSLAVAudioRecordSampleRate_16000Hz = 16000,
    
    FSLAVAudioRecordSampleRate_22050Hz = 22050,
    
    FSLAVAudioRecordSampleRate_32000Hz = 32000,
    //32000
    FSLAVAudioRecordSampleRate_44100Hz = 44100,
    
    FSLAVAudioRecordSampleRate_48000Hz = 48000,
    //96000
    FSLAVAudioRecordSampleRate_Default = FSLAVAudioRecordSampleRate_32000Hz
};

/**
 采样位数(默认为16d)
 */
typedef NS_ENUM (NSUInteger, FSLAVAudioRecordBitDepth)
{
    FSLAVAudioRecordBitDepth_8d  = 8,
    
    FSLAVAudioRecordBitDepth_16d = 16,
    
    FSLAVAudioRecordBitDepth_24d = 24,
    
    FSLAVAudioRecordBitDepth_32d = 32,
    
    FSLAVAudioRecordBitDepth_Default = FSLAVAudioRecordBitDepth_16d
};

/**
 音频码率(默认为64Kbps)
 */
typedef NS_ENUM (NSUInteger, FSLAVAudioRecordBitRate)
{
    FSLAVAudioRecordBitRate_32Kbps = 32000,
    
    FSLAVAudioRecordBitRate_48Kbps = 48000,

    FSLAVAudioRecordBitRate_64Kbps = 64000,
    
    FSLAVAudioRecordBitRate_96Kbps = 96000,
    
    FSLAVAudioRecordBitRate_128Kbps = 128000,
    
    FSLAVAudioRecordBitRate_Default = FSLAVAudioRecordBitRate_64Kbps
};

/**
 音频录制的参数配置项
 */
@interface FSLAVAudioRecorderOptions : FSLAVRecorderOptions
{
    FSLAVAudioRecordQuality _recordQuality;
    NSUInteger _audioChannels;
    FSLAVAudioRecordSampleRate _recordSampleRate;
    FSLAVAudioRecordBitDepth _recordBitDepth;
    FSLAVAudioRecordBitRate _recordBitRate;
    FSLAVEncodeAudioSetting *_audioSetting;
}

/**
 是否开启音频声波定时器,默认NO
 */
@property (nonatomic, assign) BOOL isAcousticTimer;

/** 音频质量（VideoQuality_Default为默认配置）*/
@property (nonatomic,assign) FSLAVAudioRecordQuality recordQuality;

/**音频的通道 声道数 1、2*/
@property (nonatomic,assign) NSUInteger audioChannels;

/** 采样率 (默认为44.1Hz)*/
@property (nonatomic,assign) FSLAVAudioRecordSampleRate recordSampleRate;

/** 采样率 (默认为采样位数(默认为16d))*/
@property (nonatomic,assign) FSLAVAudioRecordBitDepth recordBitDepth;

/** 比特率 (默认为64Kbps)*/
@property (nonatomic,assign) FSLAVAudioRecordBitRate recordBitRate;

/** 音频编码设置*/
@property (nonatomic,strong) FSLAVEncodeAudioSetting *audioSetting;

@end

NS_ASSUME_NONNULL_END
