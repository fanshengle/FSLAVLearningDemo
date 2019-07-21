//
//  FSLAVAudioRecorderOptions.m
//  FSLAVComponent
//
//  Created by tutu on 2019/6/28.
//  Copyright © 2019 tutu. All rights reserved.
//

#import "FSLAVAudioRecorderOptions.h"

@implementation FSLAVAudioRecorderOptions

/**
 默认视频配置
 
 @return FSLAVAudioRecorderOptions
 */
+ (instancetype)defaultOptions;
{
    return [FSLAVAudioRecorderOptions defaultOptionsForQuality:FSLAVAudioRecordQuality_Default];
}
/**
 视频配置(质量)
 
 @param audioQuality 视频质量
 @return FSLAVAudioRecorderOptions
 */
+ (instancetype)defaultOptionsForQuality:(FSLAVAudioRecordQuality)audioQuality;
{
    FSLAVAudioRecorderOptions *options = [FSLAVAudioRecorderOptions defaultOptionsForQuality:FSLAVAudioRecordQuality_Default channels:2];
    
    return options;
}

/**
 视频配置(质量)
 
 @param audioQuality 视频质量
 @param channels 声道数1、2
 @return FSLAVAudioRecorderOptions
 */
+ (instancetype)defaultOptionsForQuality:(FSLAVAudioRecordQuality)audioQuality channels:(NSInteger)channels;
{
    FSLAVAudioRecorderOptions *options = [FSLAVAudioRecorderOptions new];
    //音频编码格式
    options.audioFormat = kAudioFormatLinearPCM;
    //声道数
    options.audioChannels = channels;
    //一种标准的单音流。
    options.mChannelLayoutTag = kAudioChannelLayoutTag_Mono;
    options.audioLinearPCMIsFloat = NO;
    options.audioLinearPCMIsBigEndian = NO;
    
    options.outputFileName = @"audioFile";
    options.saveSuffixFormat = @"caf";
    options.minRecordDelay = 3.f;
    options.maxRecordDelay = 0.f;
    options.isAcousticTimer = YES;
    options.isAutomaticStop = NO;
    
    switch (audioQuality)
    {
        case  FSLAVAudioRecordQuality_min:
        {
            options.audioSampleRat = 16000;
            options.audioBitRate = options.audioChannels == 1 ? FSLAVAudioRecordBitRate_32Kbps : FSLAVAudioRecordBitRate_48Kbps;
            options.audioLinearBitDepth = 8;
            options.audioQuality = AVAudioQualityMin;
        }
            break;
        case  FSLAVAudioRecordQuality_Low:
        {
            options.audioSampleRat = 22050;
            options.audioBitRate = options.audioChannels == 1 ? FSLAVAudioRecordBitRate_48Kbps : FSLAVAudioRecordBitRate_64Kbps;
            options.audioLinearBitDepth = 16;
            options.audioQuality = AVAudioQualityLow;
        }
            break;
        case  FSLAVAudioRecordQuality_Medium:
        {
            options.audioSampleRat = 32000;
            options.audioBitRate = options.audioChannels == 1 ? FSLAVAudioRecordBitRate_64Kbps : FSLAVAudioRecordBitRate_96Kbps;
            options.audioLinearBitDepth = 16;
            options.audioQuality = AVAudioQualityMedium;
        }
            break;
        case  FSLAVAudioRecordQuality_High:
        {
            options.audioSampleRat = 44100;
            options.audioBitRate = options.audioChannels == 1 ? FSLAVAudioRecordBitRate_96Kbps : FSLAVAudioRecordBitRate_128Kbps;
            options.audioLinearBitDepth = 16;
            options.audioQuality = AVAudioQualityHigh;
        }
            break;
        case  FSLAVAudioRecordQuality_Max:
        {
            options.audioSampleRat = 48000;
            options.audioBitRate = options.audioChannels == 1 ? FSLAVAudioRecordBitRate_96Kbps : FSLAVAudioRecordBitRate_128Kbps;
            options.audioLinearBitDepth = 24;
            options.audioQuality = AVAudioQualityMax;
        }
            break;
        default:
            break;
    }
    return options;
}

- (NSDictionary *)audioConfigure{
    if (!_audioConfigure) {
        
        //(2)设置录音的音频参数
        /*
         1 ID号:acc、pcm....
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
                _audioConfigure = @{
                                    AVFormatIDKey:@(_audioFormat),//音频格式
                                    AVSampleRateKey:@(_audioSampleRat),//采样率
                                    AVEncoderBitRateKey:@(_audioSampleRat),//比特率
                                    AVNumberOfChannelsKey:@(_audioChannels),//声道数
                                    AVLinearPCMBitDepthKey:@(_audioLinearBitDepth),//采样位数
                                    AVLinearPCMIsBigEndianKey:@(_audioLinearPCMIsBigEndian),
                                    AVLinearPCMIsFloatKey:@(_audioLinearPCMIsFloat),
                                    AVEncoderAudioQualityKey:@(_audioQuality),
                                    };
            }
                break;
            default:
            {
                //指定文件或硬件中的通道布局
                AudioChannelLayout acl;
                bzero( &acl, sizeof(acl));
                //指示布局的AudioChannelLayoutTag值
                acl.mChannelLayoutTag = (UInt32)_mChannelLayoutTag;
                _audioConfigure = @{
                                    AVFormatIDKey:@(_audioFormat),//音频格式
                                    AVSampleRateKey:@(_audioSampleRat),//采样率
                                    AVEncoderBitRateKey:@(_audioSampleRat),//比特率
                                    AVNumberOfChannelsKey:@(_audioChannels),//声道数
                                    AVEncoderBitDepthHintKey:@(_audioLinearBitDepth),//采样位数
                                    AVChannelLayoutKey:[NSData dataWithBytes: &acl length: sizeof(acl) ],
                                    AVEncoderAudioQualityKey:@(_audioQuality),
                                    };
            }
                break;
        }
       
    }
    return _audioConfigure;
}

@end
