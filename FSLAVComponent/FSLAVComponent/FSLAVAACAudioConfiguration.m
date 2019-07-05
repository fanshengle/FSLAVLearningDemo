//
//  FSLAVAudioEncoderConfiguration.m
//  FSLAVComponent
//
//  Created by tutu on 2019/7/2.
//  Copyright © 2019 tutu. All rights reserved.
//

#import "FSLAVAACAudioConfiguration.h"
@interface FSLAVAACAudioConfiguration ()


@end


@implementation FSLAVAACAudioConfiguration

/**
 音频默认配置
 */
+ (instancetype)defaultConfiguration
{
    return [FSLAVAACAudioConfiguration defaultConfigurationForQuality:FSLAVAACAudioQuality_Default];
}

/**
 音频配置
 
 @param audioQuality 音频质量
 */
+ (instancetype)defaultConfigurationForQuality:(FSLAVAACAudioQuality)audioQuality
{
    return [FSLAVAACAudioConfiguration defaultConfigurationForQuality:FSLAVAACAudioQuality_Default channels:1];
}

/**
 音频配置
 
 @param audioQuality 音频质量
 @param channels 声道数
 */
+ (instancetype)defaultConfigurationForQuality:(FSLAVAACAudioQuality)audioQuality channels:(NSInteger)channels;
{
    FSLAVAACAudioConfiguration *audioConfig = [FSLAVAACAudioConfiguration new];
    audioConfig.numberOfChannels = channels;
    audioConfig.bitsPerChannel = 16;
    switch (audioQuality)
    {
        case FSLAVAACAudioQuality_min:
        {
            audioConfig.audioBitrate = audioConfig.numberOfChannels == 1 ? FSLAVAACAudioBitRate_32Kbps : FSLAVAACAudioBitRate_64Kbps;
            audioConfig.audioSampleRate = FSLAVAACAudioSampleRate_16000Hz;
        }
            break;
        case FSLAVAACAudioQuality_Low:
        {
            audioConfig.audioBitrate = FSLAVAACAudioBitRate_64Kbps;
            audioConfig.audioSampleRate = FSLAVAACAudioSampleRate_32000Hz;
        }
            break;
        case FSLAVAACAudioQuality_Medium:
        {
            audioConfig.audioBitrate = FSLAVAACAudioBitRate_96Kbps;
            audioConfig.audioSampleRate = FSLAVAACAudioSampleRate_44100Hz;
        }
            break;
        case FSLAVAACAudioQuality_High:
        {
            audioConfig.audioBitrate = FSLAVAACAudioBitRate_128Kbps;
            audioConfig.audioSampleRate = FSLAVAACAudioSampleRate_48000Hz;
        }
            break;
        default:
        {
            audioConfig.audioBitrate = FSLAVAACAudioBitRate_96Kbps;
            audioConfig.audioSampleRate = FSLAVAACAudioSampleRate_44100Hz;
        }
            break;
    }

    return audioConfig;
}

/**
 初始化
 */
- (instancetype)init
{
    if (self = [super init])
    {
        _asc = malloc(2);
    }
    return self;
}

/**
 销毁对象
 */
- (void)dealloc
{
    if (_asc) free(_asc);
}

#pragma mark Setter
/**
 设置音频取样频率
 */
- (void)setAudioSampleRate:(FSLAVAACAudioSampleRate)audioSampleRate
{
    if (_audioSampleRate) return;
    _audioSampleRate = audioSampleRate;
    NSInteger sampleRateIndex = [self sampleRateIndex:audioSampleRate];
    self.asc[0] = 0x10 | ((sampleRateIndex>>1) & 0x7);
    self.asc[1] = ((sampleRateIndex & 0x1)<<7) | ((self.numberOfChannels & 0xF) << 3);
}

/**
 设置音频通道数
 */
- (void)setNumberOfChannels:(NSUInteger)numberOfChannels
{
    if (_numberOfChannels) return;
    _numberOfChannels = numberOfChannels;
    NSInteger sampleRateIndex = [self sampleRateIndex:self.audioSampleRate];
    self.asc[0] = 0x10 | ((sampleRateIndex>>1) & 0x7);
    self.asc[1] = ((sampleRateIndex & 0x1)<<7) | ((numberOfChannels & 0xF) << 3);
}

/**
 设置音频数据长度
 */
- (NSUInteger)bufferLength
{
    return 1024*2*self.numberOfChannels;
}


#pragma mark - CustomMethod
/**
 设置音频取样频率对应枚举
 */
- (NSInteger)sampleRateIndex:(NSInteger)frequencyInHz
{
    NSInteger sampleRateIndex = 0;
    switch (frequencyInHz)
    {
        case 96000:
            sampleRateIndex = 0;
            break;
        case 88200:
            sampleRateIndex = 1;
            break;
        case 64000:
            sampleRateIndex = 2;
            break;
        case 48000:
            sampleRateIndex = 3;
            break;
        case 44100:
            sampleRateIndex = 4;
            break;
        case 32000:
            sampleRateIndex = 5;
            break;
        case 24000:
            sampleRateIndex = 6;
            break;
        case 22050:
            sampleRateIndex = 7;
            break;
        case 16000:
            sampleRateIndex = 8;
            break;
        case 12000:
            sampleRateIndex = 9;
            break;
        case 11025:
            sampleRateIndex = 10;
            break;
        case 8000:
            sampleRateIndex = 11;
            break;
        case 7350:
            sampleRateIndex = 12;
            break;
        default:
            sampleRateIndex = 15;
    }
    return sampleRateIndex;
}

#pragma mark -- 系统化设置
/**
 归档，解码
 */
- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:@(self.numberOfChannels) forKey:@"numberOfChannels"];
    [aCoder encodeObject:@(self.audioSampleRate) forKey:@"audioSampleRate"];
    [aCoder encodeObject:@(self.audioBitrate) forKey:@"audioBitrate"];
    [aCoder encodeObject:[NSString stringWithUTF8String:self.asc] forKey:@"asc"];
}

/**
 归档，编码初始化
 */
- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    _numberOfChannels = [[aDecoder decodeObjectForKey:@"numberOfChannels"] unsignedIntegerValue];
    _audioSampleRate = [[aDecoder decodeObjectForKey:@"audioSampleRate"] unsignedIntegerValue];
    _audioBitrate = [[aDecoder decodeObjectForKey:@"audioBitrate"] unsignedIntegerValue];
    _asc = strdup([[aDecoder decodeObjectForKey:@"asc"] cStringUsingEncoding:NSUTF8StringEncoding]);
    return self;
}

/**
 判断音频初始化配置是否一致
 */
- (BOOL)isEqual:(id)other
{
    if (other == self)
    {
        return YES;
    } else if (![super isEqual:other])
    {
        return NO;
    } else
    {
        FSLAVAACAudioConfiguration *object = other;
        return object.numberOfChannels == self.numberOfChannels &&
        object.audioBitrate == self.audioBitrate &&
        strcmp(object.asc, self.asc) == 0 &&
        object.audioSampleRate == self.audioSampleRate;
    }
}

/**
 哈希排序
 */
- (NSUInteger)hash
{
    NSUInteger hash = 0;
    NSArray *values = @[@(_numberOfChannels),
                        @(_audioSampleRate),
                        [NSString stringWithUTF8String:self.asc],
                        @(_audioBitrate)];
    
    for (NSObject *value in values)
    {
        hash ^= value.hash;
    }
    return hash;
}

/**
 拷贝音频配置
 */
- (id)copyWithZone:(NSZone *)zone
{
    FSLAVAACAudioConfiguration *other = [self.class defaultConfiguration];
    return other;
}

/**
 返回对象的描述信息
 */
- (NSString *)description
{
    NSMutableString *desc = @"".mutableCopy;
    [desc appendFormat:@"<FSLAVAACAudioConfiguration: %p>", self];
    [desc appendFormat:@" numberOfChannels:%zi", self.numberOfChannels];
    [desc appendFormat:@" audioSampleRate:%zi", self.audioSampleRate];
    [desc appendFormat:@" audioBitrate:%zi", self.audioBitrate];
    [desc appendFormat:@" audioHeader:%@", [NSString stringWithUTF8String:self.asc]];
    return desc;
}

@end