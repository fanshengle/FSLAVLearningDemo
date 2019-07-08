//
//  FSLAVAudioEncoder.m
//  FSLAVComponent
//
//  Created by tutu on 2019/7/2.
//  Copyright © 2019 tutu. All rights reserved.
//

#import "FSLAVAACAudioEncoder.h"

@interface FSLAVAACAudioEncoder ()
{
    AudioConverterRef audioConverter;//音频编码转码器器
    char *leftBuf;
    char *aacBuffer;
    NSInteger leftLength;
    BOOL enabledWriteVideoFile;
    dispatch_queue_t _encoderQueue;
    dispatch_queue_t _callbackQueue;
}

/**文件写入对象*/
@property (nonatomic , strong) NSFileHandle *fileHandle;

@end

@implementation FSLAVAACAudioEncoder

/**
 销毁
 */
- (void)dealloc
{
    if (aacBuffer) free(aacBuffer);
    if (leftBuf) free(leftBuf);
}

/**
 初始化音频配置
 
 configuration 音频配置
 @return configuration
 */
- (instancetype)initWithAudioStreamConfiguration:(FSLAVAACAudioConfiguration *)configuration
{
    if (self = [super init])
    {
        _configuration = configuration;
        
        if (!leftBuf)
        {
            leftBuf = malloc(_configuration.bufferLength);
        }
        
        if (!aacBuffer)
        {
            aacBuffer = malloc(_configuration.bufferLength);
        }
    }
    return self;
}


/**
  文件写入对象

 @return fileHandle
 */
- (NSFileHandle *)fileHandle{
    if (!_fileHandle) {
        
        _fileHandle = [NSFileHandle fileHandleForWritingAtPath:[_configuration getSaveDatePath]];
    }
    return _fileHandle;
}


/**
 初始化音频编码转码器

 @return 是否创建成功
 */
- (BOOL)initAudioConvert{
    if (audioConverter != nil) {
        return YES;
    }
    /**
     1.设置输入描述信息，音频流的音频数据格式规范。
     */
    // 初始化输出流的结构体描述为0. 很重要。
    AudioStreamBasicDescription inputFormat = {0};
    //采样率
    inputFormat.mSampleRate = _configuration.audioSampleRate;
    //指定流数据格式，格式标识符
    inputFormat.mFormatID = kAudioFormatLinearPCM;
    //指定格式细节的特定于格式的标志。设置为0表示没有格式标志
    inputFormat.mFormatFlags = kAudioFormatFlagIsSignedInteger | kAudioFormatFlagsNativeEndian | kAudioFormatFlagIsPacked;
    //音频数据包中的帧数。对于未压缩的音频，值为1
    inputFormat.mFramesPerPacket = 1;
    //一个音频样本的采样位数（比特数）。
    inputFormat.mBitsPerChannel = (UInt32)_configuration.bitsPerChannel;
    //音频缓冲区中从一帧开始到下一帧开始的字节数。为压缩格式将此字段设置为0。
    inputFormat.mBytesPerFrame = inputFormat.mBitsPerChannel / 8 * inputFormat.mChannelsPerFrame;
    //音频数据包中的字节数。
    inputFormat.mBytesPerPacket = inputFormat.mBytesPerFrame * inputFormat.mFramesPerPacket;

    /**
     2.输出流设置
     */
    AudioStreamBasicDescription outputFormat;
    //初始清零
    memset(&outputFormat, 0, sizeof(outputFormat));
    //音频流，在正常播放情况下的帧率。如果是压缩的格式，这个属性表示解压缩后的帧率。帧率不能为0。
    outputFormat.mSampleRate = inputFormat.mSampleRate;
    //AAC编码 kAudioFormatMPEG4AAC kAudioFormatMPEG4AAC_HE_V2
    outputFormat.mFormatID = kAudioFormatMPEG4AAC;
    //无损编码，0则无
    outputFormat.mFormatFlags = kMPEG4Object_AAC_LC;
    //每一个packet的音频数据大小。如果的动态大小设置为0。动态大小的格式需要用AudioStreamPacketDescription来确定每个packet的大小。
    outputFormat.mBytesPerPacket   = 0;
    //每帧的声道数
    outputFormat.mChannelsPerFrame = (UInt32)_configuration.numberOfChannels;
    //AAC一帧是1024个字节
    outputFormat.mFramesPerPacket = 1024;

    //3.编码器参数设置
    const OSType subtype = kAudioFormatMPEG4AAC;
    AudioClassDescription requestedCodecs[2] = {
        {
            kAudioEncoderComponentType,
            subtype,
            kAppleSoftwareAudioCodecManufacturer
        },
        {
            kAudioEncoderComponentType,
            subtype,
            kAppleHardwareAudioCodecManufacturer
        }
    };
    
    /**
     4.使用特定的编解码器创建一个新的音频转换器。
     inSourceFormat#> 要转换的源音频的格式。
     inDestinationFormat#> 音频要转换为的目标格式。
     inNumberClassDescriptions#> 类描述的数量。
     inClassDescriptions#> 指定要实例化的编解码器的audioclassdescription。
     outAudioConverter#> 成功返回后，指向一个新的AudioConverter实例。
     */
    OSStatus status = AudioConverterNewSpecific(&inputFormat, &outputFormat, 2, requestedCodecs, &audioConverter);
    //设置码率
    UInt32 outputBitrate = _configuration.audioBitrate;
    UInt32 propSize = sizeof(outputBitrate);
    if (status == noErr) {
        status = AudioConverterSetProperty(audioConverter, kAudioConverterEncodeBitRate, propSize, &outputBitrate);
    }else{
        
        return NO;
    }
    return YES;
}

#pragma mark -- public methods

#pragma mark -- 音频编码方法一：通过获取到的原始音频数据data格式，进行编码
/**
 音频编码
 
 audioData 音频数据
 timeStamp 时间戳
 */
- (void)encodeAudioData:(NSData *)audioData timeStamp:(uint64_t)timeStamp{
    if (![self initAudioConvert]) {
        return;
    }
    if (leftLength + audioData.length >= _configuration.bufferLength) {
        //发送数据
        NSInteger totalSize = leftLength + audioData.length;
        NSInteger encodeCount = totalSize/_configuration.bufferLength;
        
        //指向音频数据缓冲区的指针。
        char *totalBuffer = malloc(totalSize);
        char *pTotalBuffer = totalBuffer;
        
        //memset:作用是在一段内存块中填充某个给定的值，它对较大的结构体或数组进行清零操作的一种最快方法。
        size_t t = 0;
        memset(totalBuffer, (int)totalSize, t);
        memcpy(totalBuffer, leftBuf, leftLength);
        memcpy(totalBuffer + leftLength, audioData.bytes, audioData.length);
        
        for (NSInteger index = 0; index < encodeCount; index++) {
            [self encodeAudioDataBuffer:pTotalBuffer timeStamp:timeStamp];
            pTotalBuffer += _configuration.bufferLength;
        }
        free(totalBuffer);
        
        leftLength = totalSize%self.configuration.bufferLength;
        memset(leftBuf, 0, self.configuration.bufferLength);
        memcpy(leftBuf, totalBuffer + (totalSize - leftLength), leftLength);
    }else{
        
        memcpy(leftBuf + leftLength, audioData.bytes, audioData.length);
        leftLength = leftLength + audioData.length;
    }
}

/**
 编码数据
 
 buffer 音频数据
 timeStamp 时间戳
 */
- (void)encodeAudioDataBuffer:(char *)buffer timeStamp:(uint64_t)timeStamp
{
    //1、初始化一个输入缓冲区
    //保存和描述音频数据的缓冲区。
    AudioBuffer inputBuffer;
    //缓冲区中交错通道的数目。如果数字是1，则缓冲区是非交错的。
    inputBuffer.mNumberChannels = 1;
    //指向音频数据缓冲区的指针。
    inputBuffer.mData = buffer;
    
    //2、初始化一个输入缓冲区列表
    //保存音频缓冲器结构的可变长度数组。
    AudioBufferList inputBufferList;
    //缓冲区中交错通道的数目。如果数字是1，则缓冲区是非交错的。
    inputBufferList.mNumberBuffers = 1;
    //将可变数组的首地址改成缓冲区指向地址
    inputBufferList.mBuffers[0] = inputBuffer;
    
    //3、初始化一个输出缓冲区列表
    AudioBufferList outBufferList;
    //mBuffers数组中AudioBuffer结构的数目。
    outBufferList.mNumberBuffers = 1;
    //缓冲区中交错通道的数目。如果数字是1，则缓冲区是非交错的。
    outBufferList.mBuffers[0].mNumberChannels = inputBuffer.mNumberChannels;
    //设置缓冲区大小
    outBufferList.mBuffers[0].mDataByteSize = inputBuffer.mDataByteSize;
    //设置输出格式AAC的缓冲区指针
    outBufferList.mBuffers[0].mData = aacBuffer;
    
    //4、设置outOutputData的容量
    UInt32 outputDataPacketSize = 1;
    /**
     5、开始编码。转换回调函数提供的音频数据，支持非交错和分组格式。
     audioConverter <# 要使用的音频转换器。
     inputDataProc <# 提供输入数据的回调函数。
     inputBufferList <# 用于回调函数的值。
     ioOutputDataPacketSize#> 方法中以包表示的outOutputData的容量,转换器的输出格式。在退出时，转换的包的数目
     写入outOutputData的数据。
     outOutputData#> 转换后的输出数据被写入这个缓冲区。
     outPacket <# 如果非空，并且转换器的输出使用包描述，则包描述被写入这个数组。
     它一定指向一个记忆能够保存*ioOutputDataPacketSize包描述的块。(参见AudioFormat.h了解确定是否为音频格式的方法
     使用包的描述)。
     */
    
    OSStatus status = AudioConverterFillComplexBuffer(audioConverter, inputDataProc, &inputBufferList, &outputDataPacketSize, &outBufferList, NULL);
    if(status != noErr) return;
    
    FSLAVAudioRTMPFrame *audioFrame = [[FSLAVAudioRTMPFrame alloc] init];
    audioFrame.timestamp = timeStamp;
    audioFrame.data = [NSData dataWithBytes:aacBuffer length:outBufferList.mBuffers[0].mDataByteSize];
    
    //设置音频编码信息
    char exeData[2];
    exeData[0] = _configuration.asc[0];
    exeData[1] = _configuration.asc[1];
    audioFrame.audioInfo = [NSData dataWithBytes:exeData length:2];
    if (self.encoderDelegate && [self.encoderDelegate respondsToSelector:@selector(didEncordingStreamingBufferFrame:encoder:)]) {
        [self.encoderDelegate didEncordingStreamingBufferFrame:audioFrame encoder:self];
    }
    
    //在每个音频包的开始添加ADTS头信息
    NSData *adtsAudioData = [self addADTSHeaderToAudioPacketWithChannel:_configuration.numberOfChannels dataPacketLength:audioFrame.data.length];
    [self.fileHandle writeData:adtsAudioData];
}

/**
 *  在每个音频数据包的开始添加头
 *  Add ADTS header at the beginning of each and every AAC packet.
 *  This is needed as MediaCodec encoder generates a packet of raw
 *  AAC data.
 *
 *  Note the packetLen must count in the ADTS header itself.
 *  See: http://wiki.multimedia.cx/index.php?title=ADTS
 *  Also: http://wiki.multimedia.cx/index.php?title=MPEG-4_Audio#Channel_Configurations
 **/
- (NSData *)addADTSHeaderToAudioPacketWithChannel:(NSInteger)channel dataPacketLength:(NSInteger)dataPacketLength
{
    int adtsLength = 7;
    char *packet = malloc(sizeof(char) * adtsLength);
    int profile = 2;
    NSInteger freqIdx = [self sampleRateIndex:self.configuration.audioSampleRate];
    int chanCfg = (int)channel;
    NSUInteger fullLength = adtsLength + dataPacketLength;
    packet[0] = (char)0xFF;
    packet[1] = (char)0xF9;
    packet[2] = (char)(((profile-1)<<6) + (freqIdx<<2) +(chanCfg>>2));
    packet[3] = (char)(((chanCfg&3)<<6) + (fullLength>>11));
    packet[4] = (char)((fullLength&0x7FF) >> 3);
    packet[5] = (char)(((fullLength&7)<<5) + 0x1F);
    packet[6] = (char)0xFC;
    NSData *data = [NSData dataWithBytesNoCopy:packet length:adtsLength freeWhenDone:YES];
    return data;
}

/**
 枚举
 
 @param frequencyInHz 音频采样率
 @return sampleRateIndex 不同采样率不同的index
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

#pragma mark - AudioCallBack

/**
编码过程中，会要求这个函数来填充输入数据，也就是原始PCM数据

@param inConverter 编码转换器
@param ioNumberDataPackets 数据包
@param ioData 缓冲列表
@param outDataPacketDescription 缓冲列表个数
@param inUserData 输出缓冲列表
@return OSStatus
*/
OSStatus inputDataProc(AudioConverterRef inConverter, UInt32 *ioNumberDataPackets, AudioBufferList *ioData, AudioStreamPacketDescription * *outDataPacketDescription, void *inUserData)
{
    
    AudioBufferList bufferList = *(AudioBufferList *)inUserData;
    ioData->mBuffers[0].mNumberChannels = 1;
    ioData->mBuffers[0].mData = bufferList.mBuffers[0].mData;
    ioData->mBuffers[0].mDataByteSize = bufferList.mBuffers[0].mDataByteSize;
    return noErr;
}


#pragma mark --
- (BOOL)initAudioConvertWithSampleBuffer:(CMSampleBufferRef)sampleBuffer{
    
    if (audioConverter) {
        return YES;
    }
    
    //1.通过sampleBuffer获取音频的输入描述信息
    AudioStreamBasicDescription inputFormat = *CMAudioFormatDescriptionGetStreamBasicDescription((CMAudioFormatDescriptionRef)CMSampleBufferGetFormatDescription(sampleBuffer));
    
    /**
     2.输出流设置
     */
    // 初始化输出流的结构体描述为0. 很重要。
    AudioStreamBasicDescription outputFormat = {0};
    //音频流，在正常播放情况下的帧率。如果是压缩的格式，这个属性表示解压缩后的帧率。帧率不能为0。
    outputFormat.mSampleRate = inputFormat.mSampleRate;
    //AAC编码 kAudioFormatMPEG4AAC kAudioFormatMPEG4AAC_HE_V2
    outputFormat.mFormatID = kAudioFormatMPEG4AAC;
    //无损编码，0则无
    outputFormat.mFormatFlags = kMPEG4Object_AAC_LC;
    //每一个packet的音频数据大小。如果的动态大小设置为0。动态大小的格式需要用AudioStreamPacketDescription来确定每个packet的大小。
    outputFormat.mBytesPerPacket   = 0;
    //每帧的声道数
    outputFormat.mChannelsPerFrame = (UInt32)_configuration.numberOfChannels;
    //AAC一帧是1024个字节
    outputFormat.mFramesPerPacket = 1024;
    // 压缩格式设置为0
    outputFormat.mBitsPerChannel = 0;
    // 8字节对齐，填0.
    outputFormat.mReserved = 0;
    //  每帧的大小。每一帧的起始点到下一帧的起始点。如果是压缩格式，设置为0 。
    outputFormat.mBytesPerFrame = 0;

    //3.编码器参数设置
    const OSType subtype = kAudioFormatMPEG4AAC;
    AudioClassDescription requestedCodecs[2] = {
        {
            kAudioEncoderComponentType,
            subtype,
            kAppleSoftwareAudioCodecManufacturer
        },
        {
            kAudioEncoderComponentType,
            subtype,
            kAppleHardwareAudioCodecManufacturer
        }
    };
    
    /**
     4.使用特定的编解码器创建一个新的音频转换器。
     inSourceFormat#> 要转换的源音频的格式。
     inDestinationFormat#> 音频要转换为的目标格式。
     inNumberClassDescriptions#> 类描述的数量。
     inClassDescriptions#> 指定要实例化的编解码器的audioclassdescription。
     outAudioConverter#> 成功返回后，指向一个新的AudioConverter实例。
     */
    OSStatus status = AudioConverterNewSpecific(&inputFormat, &outputFormat, 2, requestedCodecs, &audioConverter);
    //设置码率
    UInt32 outputBitrate = _configuration.audioBitrate;
    UInt32 propSize = sizeof(outputBitrate);
    if (status == noErr) {
        status = AudioConverterSetProperty(audioConverter, kAudioConverterEncodeBitRate, propSize, &outputBitrate);
    }else{
        
        return NO;
    }
    return YES;
}

- (void)encodeAudioSampleBuffer:(CMSampleBufferRef)sampleBuffer timeStamp:(uint64_t)timeStamp{
    
    CFRetain(sampleBuffer);
//    dispatch_async(_encoderQueue, ^{
//        if (![self initAudioConvertWithSampleBuffer:sampleBuffer]) return ;
//        CMBlockBufferRef blockBuffer = CMSampleBufferGetDataBuffer(sampleBuffer);
//        CFRetain(blockBuffer);
//        OSStatus status = CMBlockBufferGetDataPointer(blockBuffer, 0, <#size_t * _Nullable lengthAtOffsetOut#>, <#size_t * _Nullable totalLengthOut#>, <#char * _Nullable * _Nullable dataPointerOut#>)
//
//    });
//
}

@end
