//
//  FSLAVAudioRecorderConfiguraction.h
//  FSLAVComponent
//
//  Created by tutu on 2019/6/28.
//  Copyright © 2019 tutu. All rights reserved.
//

#import "FSLAVConfiguraction.h"

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
    
    FSLAVAudioRecordSampleRate_8000Hz = 8000,
    
    FSLAVAudioRecordSampleRate_16000Hz = 16000,
    
    FSLAVAudioRecordSampleRate_22050Hz = 22050,
    //32000
    FSLAVAudioRecordSampleRate_44100Hz = 44100,
    
    FSLAVAudioRecordSampleRate_48000Hz = 48000,
    //96000
    FSLAVAudioRecordSampleRate_Default = FSLAVAudioRecordSampleRate_22050Hz
};


/**
 音频录制的参数配置项
 */
@interface FSLAVAudioRecorderConfiguration : FSLAVConfiguraction


/**音频格式*/
@property (nonatomic,assign) NSUInteger audioFormat;
/**音频采样率 单位是Hz 常见值 22050：人对频率的识别范围是 20HZ - 20000HZ 44100：CD音质 48000 96000 192000，
 超过48000的采样对人耳已经没有意义。这和电影的每秒 24 帧图片的道理差不多。*/
@property (nonatomic,assign) NSUInteger audioSampleRat;
/**音频的通道 声道数 1、2*/
@property (nonatomic,assign) NSUInteger audioChannels;
/**音频采样点位数 比特率  8 16 32*/
@property (nonatomic,assign) NSUInteger audioLinearPCMBit;
/**音频的编码比特率 BPS传输速率 一般为128000bps*/
@property (nonatomic,assign) NSUInteger encoderBitRate;
/**音频频格式是否是大端点*/
@property (nonatomic,assign) NSUInteger audioLinearPCMIsBigEndian;
/**音频格式是否使用浮点数采样*/
@property (nonatomic,assign) NSUInteger audioLinearPCMIsFloat;
/**设置录音质量:声音质量
 需要的参数是一个枚举：
 AVAudioQualityMin    最小的质量
 AVAudioQualityLow    比较低的质量
 AVAudioQualityMedium 中间的质量
 AVAudioQualityHigh   高的质量
 AVAudioQualityMax    最好的质量
 */
@property (nonatomic,assign) NSUInteger audioQuality;
/** ... 其他设置*/

/**音频质量（VideoQuality_Default为默认配置）*/
@property (nonatomic,assign) FSLAVAudioRecordQuality recordQuality;

/** 采样率 (默认为44.1Hz)*/
@property (nonatomic,assign) FSLAVAudioRecordSampleRate recordSampleRate;

/**音频的配置项*/
@property (nonatomic,strong) NSDictionary *audioConfigure;


/**
 默认视频配置
 
 @return FSLAVAudioRecorderConfiguration
 */
+ (instancetype)defaultConfiguration;

/**
 视频配置(质量)
 
 @param audioQuality 视频质量
 @return FSLAVAudioRecorderConfiguraction
 */
+ (instancetype)defaultConfigurationForQuality:(FSLAVAudioRecordQuality)audioQuality;


/**
 视频配置(质量)
 
 @param audioQuality 视频质量
 @param channels 声道数1、2
 @return FSLAVAudioRecorderConfiguraction
 */
+ (instancetype)defaultConfigurationForQuality:(FSLAVAudioRecordQuality)audioQuality channels:(NSInteger)channels;


@end

NS_ASSUME_NONNULL_END
