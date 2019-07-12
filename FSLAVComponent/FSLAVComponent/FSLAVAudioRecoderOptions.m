//
//  FSLAVAudioRecorderConfiguraction.m
//  FSLAVComponent
//
//  Created by tutu on 2019/6/28.
//  Copyright © 2019 tutu. All rights reserved.
//

#import "FSLAVAudioRecoderOptions.h"

@implementation FSLAVAudioRecoderOptions

/**
 默认视频配置
 
 @return FSLAVAudioRecorderConfiguraction
 */
+ (instancetype)defaultOptions;
{
    return [FSLAVAudioRecoderOptions defaultOptionsForQuality:FSLAVAudioRecordQuality_Default];
}
/**
 视频配置(质量)
 
 @param audioQuality 视频质量
 @return FSLAVAudioRecorderConfiguraction
 */
+ (instancetype)defaultOptionsForQuality:(FSLAVAudioRecordQuality)audioQuality;
{
    FSLAVAudioRecoderOptions *configuration = [FSLAVAudioRecoderOptions defaultOptionsForQuality:FSLAVAudioRecordQuality_Default channels:2];
    
    return configuration;
}

/**
 视频配置(质量)
 
 @param audioQuality 视频质量
 @param channels 声道数1、2
 @return FSLAVAudioRecorderConfiguraction
 */
+ (instancetype)defaultOptionsForQuality:(FSLAVAudioRecordQuality)audioQuality channels:(NSInteger)channels;
{
    FSLAVAudioRecoderOptions *configuration = [FSLAVAudioRecoderOptions new];
    configuration.outputFileName = @"audioFile";
    configuration.saveSuffixFormat = @"caf";
    configuration.minRecordDelay = 3.f;
    configuration.maxRecordDelay = 0.f;
    configuration.isAcousticTimer = YES;
    configuration.isAutomaticStop = NO;
    switch (audioQuality)
    {
        case  FSLAVAudioRecordQuality_min:
        {
            configuration.audioFormat = kAudioFormatLinearPCM;
            configuration.audioSampleRat = 16000;
            configuration.audioChannels = channels;
            configuration.audioLinearPCMBit = 8;
            configuration.audioLinearPCMIsFloat = NO;
            configuration.audioLinearPCMIsBigEndian = NO;
            configuration.audioQuality = AVAudioQualityMin;
        }
            break;
        case  FSLAVAudioRecordQuality_Low:
        {
            configuration.audioFormat = kAudioFormatLinearPCM;
            configuration.audioSampleRat = 22050;
            configuration.audioChannels = channels;
            configuration.audioLinearPCMBit = 16;
            configuration.audioLinearPCMIsFloat = NO;
            configuration.audioLinearPCMIsBigEndian = NO;
            configuration.audioQuality = AVAudioQualityLow;
        }
            break;
        case  FSLAVAudioRecordQuality_Medium:
        {
            configuration.audioFormat = kAudioFormatLinearPCM;
            configuration.audioSampleRat = 32000;
            configuration.audioChannels = channels;
            configuration.audioLinearPCMBit = 16;
            configuration.audioLinearPCMIsFloat = NO;
            configuration.audioLinearPCMIsBigEndian = NO;
            configuration.audioQuality = AVAudioQualityMedium;
        }
            break;
        case  FSLAVAudioRecordQuality_High:
        {
            configuration.audioFormat = kAudioFormatLinearPCM;
            configuration.audioSampleRat = 44100;
            configuration.audioChannels = channels;
            configuration.audioLinearPCMBit = 16;
            configuration.audioLinearPCMIsFloat = NO;
            configuration.audioLinearPCMIsBigEndian = NO;
            configuration.audioQuality = AVAudioQualityHigh;
        }
            break;
        case  FSLAVAudioRecordQuality_Max:
        {
            configuration.audioFormat = kAudioFormatLinearPCM;
            configuration.audioSampleRat = 48000;
            configuration.audioChannels = channels;
            configuration.audioLinearPCMBit = 24;
            configuration.audioLinearPCMIsFloat = NO;
            configuration.audioLinearPCMIsBigEndian = NO;
            configuration.audioQuality = AVAudioQualityMax;
        }
            break;
        default:
            
            break;
    }
    return configuration;
}

- (NSDictionary *)audioConfigure{
    if (!_audioConfigure) {
        
        //(2)设置录音的音频参数
        /*
         1 ID号:acc
         2 采样率(HZ):每秒从连续的信号中提取并组成离散信号的采样个数
         3 通道的个数:(1 单声道 2 立体声)
         4 采样位数(8 16 24 32) 衡量声音波动变化的参数
         5 大端或者小端 (内存的组织方式)
         6 采集信号是整数还是浮点数
         7 音频编码质量
         */
        NSDictionary *configure = @{
                                    AVFormatIDKey:@(_audioFormat),//音频格式
                                    AVSampleRateKey:@(_audioSampleRat),//采样率
                                    AVNumberOfChannelsKey:@(_audioChannels),//声道数
                                    AVLinearPCMBitDepthKey:@(_audioLinearPCMBit),//采样位数
                                    AVLinearPCMIsBigEndianKey:@(_audioLinearPCMIsBigEndian),
                                    AVLinearPCMIsFloatKey:@(_audioLinearPCMIsFloat),
                                    AVEncoderAudioQualityKey:@(_audioQuality),
                                    };
        _audioConfigure = configure;
    }
    return _audioConfigure;
}

@end
