//
//  FSLAVAudioRecorderOptions.m
//  FSLAVComponent
//
//  Created by tutu on 2019/6/28.
//  Copyright © 2019 tutu. All rights reserved.
//

#import "FSLAVAudioRecorderOptions.h"

@implementation FSLAVAudioRecorderOptions

//必须走一下父类的方法；为了一些父类的默认参数生效
- (instancetype)init
{
    self = [super init];
    if (self) {
        
    }
    return self;
}

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
  
    options.audioLinearPCMIsFloat = NO;
    options.audioLinearPCMIsBigEndian = NO;
    
    options.outputFileName = @"audioFile";
    options.saveSuffixFormat = @"caf";

    switch (audioQuality)
    {
        case  FSLAVAudioRecordQuality_min:
        {
            options.recordSampleRate = FSLAVAudioRecordSampleRate_16000Hz;
            options.audioSampleRat = 16000;
            options.encoderBitRate = options.audioChannels == 1 ? FSLAVAudioRecordBitRate_32Kbps : FSLAVAudioRecordBitRate_48Kbps;
            options.audioLinearBitDepth = 8;
        }
            break;
        case  FSLAVAudioRecordQuality_Low:
        {
            options.recordSampleRate = FSLAVAudioRecordSampleRate_22050Hz;
            options.audioSampleRat = 22050;
            options.encoderBitRate = options.audioChannels == 1 ? FSLAVAudioRecordBitRate_48Kbps : FSLAVAudioRecordBitRate_64Kbps;
            options.audioLinearBitDepth = 16;
        }
            break;
        case  FSLAVAudioRecordQuality_Medium:
        {
            options.recordSampleRate = FSLAVAudioRecordSampleRate_32000Hz;
            options.audioSampleRat = 32000;
            options.encoderBitRate = options.audioChannels == 1 ? FSLAVAudioRecordBitRate_64Kbps : FSLAVAudioRecordBitRate_96Kbps;
            options.audioLinearBitDepth = 16;
        }
            break;
        case  FSLAVAudioRecordQuality_High:
        {
            options.recordSampleRate = FSLAVAudioRecordSampleRate_44100Hz;
            options.audioSampleRat = 44100;
            options.encoderBitRate = options.audioChannels == 1 ? FSLAVAudioRecordBitRate_96Kbps : FSLAVAudioRecordBitRate_128Kbps;
            options.audioLinearBitDepth = 16;
        }
            break;
        case  FSLAVAudioRecordQuality_Max:
        {
            options.recordSampleRate = FSLAVAudioRecordSampleRate_48000Hz;
            options.audioSampleRat = 48000;
            options.encoderBitRate = options.audioChannels == 1 ? FSLAVAudioRecordBitRate_96Kbps : FSLAVAudioRecordBitRate_128Kbps;
            options.audioLinearBitDepth = 24;
        }
            break;
        default:
            break;
    }
    return options;
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
                                    AVLinearPCMIsNonInterleaved:@(NO),//一个布尔值，指示音频格式是无交错(YES)还是交错(NO)。
                                    AVChannelLayoutKey:[NSData dataWithBytes: &acl length: sizeof(acl)]
                                    };
            }
                break;
            default:
            {
//                //指定文件或硬件中的通道布局
//                AudioChannelLayout acl;
//                bzero( &acl, sizeof(acl));
//                //转码格式为aac时，不能设置采样位数AVEncoderBitDepthHintKey，也不能设置AVEncoderAudioQualityKey音频质量
//                if (_audioChannels == 1) {
//
//                    //指示布局的AudioChannelLayoutTag值
//                    //一种标准的单音流。
//                    acl.mChannelLayoutTag = kAudioChannelLayoutTag_Mono;
//
//                }else{//双声道
//
//                    //标准立体声流。
//                    acl.mChannelLayoutTag = kAudioChannelLayoutTag_Stereo;
//                }
                _audioConfigure = @{
                                    AVFormatIDKey:@(_audioFormat),//音频格式
                                    AVSampleRateKey:@(_audioSampleRat),//采样率
                                    AVEncoderBitRateKey:@(_encoderBitRate),//比特率
                                    AVNumberOfChannelsKey:@(_audioChannels),//声道数
                                    AVChannelLayoutKey:[NSData dataWithBytes: &acl length: sizeof(acl)]
                                    };
            }
                break;
        }
       
    }
    return _audioConfigure;
}


/**
 设置默认参数配置(可以重置父类的默认参数，不设置的话，父类的默认参数会无效)
 */
- (void)setConfig;
{
    [super setConfig];
}
@end
