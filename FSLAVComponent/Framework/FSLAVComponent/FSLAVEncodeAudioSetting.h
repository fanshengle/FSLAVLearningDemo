//
//  FSLAVEncodeAudioSetting.h
//  FSLAVComponent
//
//  Created by tutu on 2019/8/1.
//  Copyright © 2019 tutu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface FSLAVEncodeAudioSetting : NSObject

/**音频格式*/
@property (nonatomic,assign) NSUInteger audioFormat;

/**音频采样率 单位是Hz 常见值 22050：人对频率的识别范围是 20HZ - 20000HZ 44100：CD音质 48000 96000 192000，
 超过48000的采样对人耳已经没有意义。这和电影的每秒 24 帧图片的道理差不多。*/
@property (nonatomic,assign) NSUInteger audioSampleRat;

/**音频的通道 声道数 1、2*/
@property (nonatomic,assign) NSUInteger audioChannels;

//----------aac格式使用
/**音频的编码比特率 BPS传输速率 一般为128000bps*/
@property (nonatomic,assign) NSUInteger encoderBitRate;

//----------带pcm的字段是PCM格式专用，也可以不设置，不影响
/**音频频格式是否是大端点*/
@property (nonatomic,assign) NSUInteger audioLinearPCMIsBigEndian;

/**音频格式是否使用浮点数采样*/
@property (nonatomic,assign) NSUInteger audioLinearPCMIsFloat;

/**一个布尔值，指示音频格式是无交错(YES)还是交错(NO)。*/
@property (nonatomic,assign) NSUInteger audioLinearPCMIsNonInterleaved;


/**音频采样点位数 比特率  8 16（16位基本可以满足所有的情况了）24 32*/
@property (nonatomic,assign) NSUInteger audioLinearBitDepth;


/** ... 其他设置*/

/** 音频的配置项*/
@property (nonatomic,strong) NSDictionary *audioConfigure;


/**
 类方法创建音频设置PCM编码格式

 @return audioSetting
 */
+ (instancetype)PCMAudioSetting;

/**
 类方法创建音频设置AAC编码格式
 
 @return audioSetting
 */
+ (instancetype)AACAuidoSetting;

/**
 初始化音频设置PCM编码格式

 @param channels 声道数
 @return audioSetting
 */
- (instancetype)initPCMAudioSettingWithChannels:(NSInteger)channels;

/**
 初始化音频设置AAC编码格式

 @param channels 声道数
 @return audioSetting
 */
- (instancetype)initAACAudioSettingWithChannels:(NSInteger)channels;

@end

NS_ASSUME_NONNULL_END
