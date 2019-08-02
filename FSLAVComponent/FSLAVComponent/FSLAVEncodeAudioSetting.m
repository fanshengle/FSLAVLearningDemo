//
//  FSLAVEncodeAudioSetting.m
//  FSLAVComponent
//
//  Created by tutu on 2019/8/1.
//  Copyright © 2019 tutu. All rights reserved.
//

#import "FSLAVEncodeAudioSetting.h"

@implementation FSLAVEncodeAudioSetting

/**
 类方法创建音频设置PCM编码格式
 
 @return audioSetting
 */
+ (instancetype)PCMAudioSetting;
{
    return [[self alloc] initPCMAudioSettingWithChannels:1];
}

/**
 类方法创建音频设置AAC编码格式
 
 @return audioSetting
 */
+ (instancetype)AACAuidoSetting;
{
    return [[self alloc] initAACAudioSettingWithChannels:1];
}

/**
 初始化音频设置PCM编码格式
 
 @param channels 声道数
 @return audioSetting
 */
- (instancetype)initPCMAudioSettingWithChannels:(NSInteger)channels;
{
    if (self = [super init]) {
        
        _audioFormat = kAudioFormatLinearPCM;
        _audioSampleRat = 44100;
        _audioChannels = channels;
        _audioLinearBitDepth = 16;
        _audioLinearPCMIsFloat = NO;
        _audioLinearPCMIsBigEndian = NO;
        _audioLinearPCMIsNonInterleaved = NO;
    }
    return self;
}
/**
 初始化音频设置AAC编码格式
 
 @param channels 声道数
 @return audioSetting
 */
- (instancetype)initAACAudioSettingWithChannels:(NSInteger)channels;
{
    if (self = [super init]) {
        
        _audioFormat = kAudioFormatMPEG4AAC;
        _audioSampleRat = 44100;
        _audioChannels = channels;
        _encoderBitRate = 640000;
    }
    return self;
}

- (NSDictionary *)audioConfigure{
    if (!_audioConfigure) {
        
        //指定文件或硬件中的通道布局
        AudioChannelLayout acl;
        bzero( &acl, sizeof(acl));
        //转码格式为aac时，不能设置采样位数AVEncoderBitDepthHintKey，也不能设置AVEncoderAudioQualityKey音频质量
        if (_audioChannels == 1) {
            
            //指示布局的AudioChannelLayoutTag值
            //一种标准的单音流。
            acl.mChannelLayoutTag = kAudioChannelLayoutTag_Mono;
            
        }else{//双声道
            
            //标准立体声流。
            acl.mChannelLayoutTag = kAudioChannelLayoutTag_Stereo;
        }
        
        //(2)设置录音的音频参数
        /*
         1 ID号:pcm、acc....
         2 采样率(HZ):每秒从连续的信号中提取并组成离散信号的采样个数
         3 比特率（bit）：每秒传输的数据量字节
         4 通道的个数:(1 单声道 2 立体声)
         5 采样位数(8 16 24 32) 衡量声音波动变化的参数
         6 大端或者小端 (内存的组织方式)
         7 采集信号是整数还是浮点数
         8 音频编码质量
         */
        switch (_audioFormat) {
            case kAudioFormatLinearPCM:
            {
                //转码格式为pcm时，不能设置比特率AVEncoderBitRateKey，也不能设置AVEncoderAudioQualityKey音频质量
                _audioConfigure = @{
                                    AVFormatIDKey:@(_audioFormat),//音频格式
                                    AVSampleRateKey:@(_audioSampleRat),//采样率
                                    AVNumberOfChannelsKey:@(_audioChannels),//声道数
                                    AVLinearPCMBitDepthKey:@(_audioLinearBitDepth),//采样位数
                                    AVLinearPCMIsBigEndianKey:@(_audioLinearPCMIsBigEndian),// 音频采用高位优先的记录格
                                    AVLinearPCMIsFloatKey:@(_audioLinearPCMIsFloat),//是否采用浮点数采样
                                    AVLinearPCMIsNonInterleaved:@(_audioLinearPCMIsNonInterleaved),//指示音频格式是无交错(YES)还是交错(NO)。
                                    AVChannelLayoutKey:[NSData dataWithBytes: &acl length: sizeof(acl)]//指定文件或硬件中的通道布局
                                    };
            }
                break;
            default:
            {
                _audioConfigure = @{
                                    AVFormatIDKey:@(_audioFormat),//音频格式
                                    AVSampleRateKey:@(_audioSampleRat),//采样率
                                    AVEncoderBitRateKey:@(_encoderBitRate),//编码比特率
                                    AVNumberOfChannelsKey:@(_audioChannels),//声道数
                                    AVChannelLayoutKey:[NSData dataWithBytes: &acl length: sizeof(acl)]//指定文件或硬件中的通道布局
                                    };
            }
                break;
        }
        
    }
    return _audioConfigure;
}

@end
