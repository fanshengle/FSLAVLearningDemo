//
//  FSLAVAudioEncoderConfiguration.h
//  FSLAVComponent
//
//  Created by tutu on 2019/7/2.
//  Copyright © 2019 tutu. All rights reserved.
//

#import "FSLAVConfiguraction.h"

NS_ASSUME_NONNULL_BEGIN

/**
 音频码率(默认为96Kbps)
 */
typedef NS_ENUM (NSUInteger, FSLAVAACaudioBitRate)
{
    FSLAVAACaudioBitRate_32Kbps = 32000,
    
    FSLAVAACaudioBitRate_64Kbps = 64000,
    
    FSLAVAACaudioBitRate_96Kbps = 96000,
    
    FSLAVAACaudioBitRate_128Kbps = 128000,
    
    FSLAVAACaudioBitRate_Default = FSLAVAACaudioBitRate_96Kbps
};

/**
 采样率 (默认为44.1Hz)
 */
typedef NS_ENUM (NSUInteger, FSLAVAACAudioSampleRate)
{
    
    FSLAVAACAudioSampleRate_16000Hz = 16000,

    FSLAVAACAudioSampleRate_22050Hz = 22050,
    
    FSLAVAACAudioSampleRate_32000Hz = 32000,

    FSLAVAACAudioSampleRate_44100Hz = 44100,
    
    FSLAVAACAudioSampleRate_48000Hz = 48000,
    
    FSLAVAACAudioSampleRate_Default = FSLAVAACAudioSampleRate_32000Hz
};

/**
 音频质量（VideoQuality_Default为默认配置）
 */
typedef NS_ENUM (NSUInteger,  FSLAVAACAudioQuality)
{
    FSLAVAACAudioQuality_min = 0,
    
    FSLAVAACAudioQuality_Low = 1,
    
    FSLAVAACAudioQuality_Medium = 2,
    
    FSLAVAACAudioQuality_High = 3,
    
    FSLAVAACAudioQuality_Max = 4,
    
    FSLAVAACAudioQuality_Default =  FSLAVAACAudioQuality_Medium
};

@interface FSLAVAACAudioConfiguration : FSLAVConfiguraction<NSCoding, NSCopying>

/**
 默认音频配置
 */
+ (instancetype)defaultConfiguration;

/**
 音频配置
 
 @param audioQuality 音频质量
 */
+ (instancetype)defaultConfigurationForQuality:(FSLAVAACAudioQuality)audioQuality;

/**
 音频配置
 
 @param audioQuality 音频质量
 @param channels 声道数
 */
+ (instancetype)defaultConfigurationForQuality:(FSLAVAACAudioQuality)audioQuality channels:(NSInteger)channels;

#pragma mark - Attribute

/**
 声道数目(默认为1)
 */
@property (nonatomic, assign) NSUInteger numberOfChannels;

/**
 采样的位数
 */
@property (nonatomic, assign) NSUInteger bitsPerChannel;

/**
 采样率
 */
@property (nonatomic, assign) FSLAVAACAudioSampleRate audioSampleRate;

/**
 码率
 */
@property (nonatomic, assign) FSLAVAACaudioBitRate audioBitRate;

/**
 编码音频头
 */
@property (nonatomic, assign, readonly) char *asc;

/**
 音频数据长度
 */
@property (nonatomic, assign,readonly) NSUInteger bufferLength;


@end

NS_ASSUME_NONNULL_END
