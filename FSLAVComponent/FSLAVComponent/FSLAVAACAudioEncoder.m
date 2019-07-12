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
    
    char *aacBuffer;
    char *pcmBuffer;
    NSInteger pcmBufferLength;
    size_t pcmBufferSize;//用于方法二
    NSInteger tagPerFormatChannels;//标记声道数，用于方法二
    BOOL enabledWriteVideoFile;
    
    dispatch_queue_t _encoderQueue;
}

/**文件写入对象*/
@property (nonatomic , strong) NSFileHandle *fileHandle;
@property (nonatomic) FILE *fileHandle2;

@end

@implementation FSLAVAACAudioEncoder

/**
 销毁
 */
- (void)dealloc
{
    if (aacBuffer) free(aacBuffer);
    if (pcmBuffer) free(pcmBuffer);
}

/**
 初始化音频配置
 
 configuration 音频配置
 @return options
 */
- (instancetype)initWithAudioStreamOptions:(FSLAVAACEncodeOptions *)configuration
{
    if (self = [super init])
    {
        _configuration = configuration;
        
        if (!pcmBuffer)
        {
            pcmBuffer = malloc(_configuration.bufferLength);
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
        
        _fileHandle = [NSFileHandle fileHandleForWritingAtPath:[_configuration createSaveDatePath]];
    }
    return _fileHandle;
}

- (FILE *)fileHandle2{
    if (!_fileHandle2) {
        
        _fileHandle2 = fopen([[_configuration createSaveDatePath] cStringUsingEncoding:NSUTF8StringEncoding], "wb");
    }
    return _fileHandle2;
}

#pragma mark -- private methods
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
    //每帧音频数据中的声道数。这个值必须是非零的。
    inputFormat.mChannelsPerFrame = (UInt32)_configuration.numberOfChannels;
    //音频数据包中的帧数。对于未压缩的音频，值为1
    inputFormat.mFramesPerPacket = 1;
    //一个音频样本的采样位数（比特数）。
    inputFormat.mBitsPerChannel = (UInt32)_configuration.bitsPerChannel;
    //音频缓冲区中从一帧开始到下一帧开始的字节数。为压缩格式将此字段设置为0。
    inputFormat.mBytesPerFrame = inputFormat.mBitsPerChannel / 8 * inputFormat.mChannelsPerFrame;
    //inputFormat.mBytesPerFrame = inputFormat.mBitsPerChannel * inputFormat.mChannelsPerFrame / 8;
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
    UInt32 outputBitRate = _configuration.audioBitRate;
    UInt32 propSize = sizeof(outputBitRate);
    if (status == noErr) {
        status = AudioConverterSetProperty(audioConverter, kAudioConverterEncodeBitRate, propSize, &outputBitRate);
    }else{
        
        return NO;
    }
    return YES;
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
    inputBuffer.mDataByteSize = (UInt32)_configuration.bufferLength;
    
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
    
    //6、设置音频编码信息
    FSLAVAudioRTMPFrame *audioFrame = [[FSLAVAudioRTMPFrame alloc] init];
    audioFrame.timestamp = timeStamp;
    //aacData
    audioFrame.data = [NSData dataWithBytes:aacBuffer length:outBufferList.mBuffers[0].mDataByteSize];
  
    char exeData[2];
    exeData[0] = _configuration.asc[0];
    exeData[1] = _configuration.asc[1];
    audioFrame.audioInfo = [NSData dataWithBytes:exeData length:2];
    if (self.encoderDelegate && [self.encoderDelegate respondsToSelector:@selector(didEncordingStreamingBufferFrame:encoder:)]) {
        [self.encoderDelegate didEncordingStreamingBufferFrame:audioFrame encoder:self];
    }
    
    //7、在每个音频包的开始添加ADTS头信息
    NSData *adtsAudioData = [self addADTSHeaderToAudioPacketWithChannel:_configuration.numberOfChannels dataPacketLength:audioFrame.data.length];
    NSMutableData *fullData = [NSMutableData dataWithData:adtsAudioData];
    //拼接ADTS头数据到AACData
    [fullData appendData:audioFrame.data];
    
    //8、将带有ADTS头完整AAC格式数据写入文件路径下的文件中
//    [self.fileHandle writeData:fullData];
    
    fwrite(adtsAudioData.bytes, 1, adtsAudioData.length, self.fileHandle2);
    fwrite(audioFrame.data.bytes, 1, audioFrame.data.length, self.fileHandle2);
    
    NSLog(@"writer %lu to file",fullData.length);
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
    NSInteger freqIdx = [self sampleRateIndex:self.options.audioSampleRate];
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
 
 frequencyInHz 音频采样率
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

#pragma mark -- AudioCallBack
/**
编码过程中，会要求这个函数来填充输入数据，也就是原始PCM数据
将原始PCM数据喂给编码器
inConverter 编码转换器
ioNumberDataPackets 数据包
ioData 缓冲列表
outDataPacketDescription 缓冲列表个数
inUserData 输出缓冲列表
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


#pragma mark -- public methods
#pragma mark -- 音频编码方法一：通过获取到的原始音频数据data格式，进行编码
/**
 音频编码,通过data格式数据来进行编码
 
 audioData 音频数据
 timeStamp 时间戳
 */
- (void)encodeAudioData:(NSData *)audioData timeStamp:(uint64_t)timeStamp{
    
    //初始化音频编码转码器
    if (![self initAudioConvert]) return;
    
    if (pcmBufferLength + audioData.length >= _configuration.bufferLength) {
        //发送数据
        NSInteger totalSize = pcmBufferLength + audioData.length;
        NSInteger encodeCount = totalSize/_configuration.bufferLength;
        
        //指向音频数据缓冲区的指针。
        char *totalBuffer = malloc(totalSize);
        char *pTotalBuffer = totalBuffer;
        
        //memset:作用是在一段内存块中填充某个给定的值，它对较大的结构体或数组进行清零操作的一种最快方法。
        size_t t = 0;
        memset(totalBuffer, (int)totalSize, t);
        memcpy(totalBuffer, pcmBuffer, pcmBufferLength);
        memcpy(totalBuffer + pcmBufferLength, audioData.bytes, audioData.length);
        
        for (NSInteger index = 0; index < encodeCount; index++) {
            //通过音频的输入格式进行输出AAC格式的编码
            [self encodeAudioDataBuffer:pTotalBuffer timeStamp:timeStamp];
            pTotalBuffer += _configuration.bufferLength;
        }
        free(totalBuffer);
        
        pcmBufferLength = totalSize%self.options.bufferLength;
        memset(pcmBuffer, 0, self.options.bufferLength);
        memcpy(pcmBuffer, totalBuffer + (totalSize - pcmBufferLength), pcmBufferLength);
    }else{
        
        memcpy(pcmBuffer + pcmBufferLength, audioData.bytes, audioData.length);
        pcmBufferLength = pcmBufferLength + audioData.length;
    }
}

#pragma mark -- 音频编码方法二：通过获取到的原始音频数据CMSampleBufferRef格式，进行编码
/**
 音频编码,通过sampleBuffer格式数据来进行编码

 sampleBuffer 帧音频数据
 timeStamp 时间戳
 */
- (void)encodeAudioSampleBuffer:(CMSampleBufferRef)sampleBuffer timeStamp:(uint64_t)timeStamp{
    
    CFRetain(sampleBuffer);
    //初始化音频编码转码器
    if (![self initAudioConvertWithSampleBuffer:sampleBuffer]) return;
    
    //获取到PCM数据并传入编码器
    CMBlockBufferRef blockBuffer = CMSampleBufferGetDataBuffer(sampleBuffer);
    CFRetain(blockBuffer);
    
    /**
     1.获取对CMBlockBuffer表示的数据的访问权。

     theBuffer#> 要操作的CMBlockBuffer。不能为空
     offset#> 缓冲区偏移范围内的偏移量。
     lengthAtOffsetOut#> 返回时，包含在指定偏移量处可用的数据量。可能是NULL。
     totalLengthOut#> 返回时，包含块缓冲区的总数据长度(从偏移量0开始)。
     dataPointerOut#> 返回时，包含指向指定偏移量的数据字节的指针;lengthAtOffset字节可以在这个地址买到。可能是NULL。
     */
    OSStatus status = CMBlockBufferGetDataPointer(blockBuffer, 0, NULL, &pcmBufferSize, &pcmBuffer);
    NSError *error = nil;
    if (status != kCMBlockBufferNoErr) {
        error = [NSError errorWithDomain:NSOSStatusErrorDomain code:status userInfo:nil];
    }
    
    //初始清零
    memset(aacBuffer, 0, _configuration.bufferLength);
    //2、初始化一个输出缓冲区列表
    AudioBufferList outputBufferList = {0};
    outputBufferList.mNumberBuffers = 1;
    outputBufferList.mBuffers[0].mNumberChannels = 1;
    outputBufferList.mBuffers[0].mDataByteSize  = (UInt32)_configuration.bufferLength;
    outputBufferList.mBuffers[0].mData = aacBuffer;
    
    AudioStreamPacketDescription *outPacketDescription = NULL;
    UInt32 ioOutputDataPacketSize = 1;
    /**
     3、开始编码。转换回调函数提供的音频数据，支持非交错和分组格式。
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
    status = AudioConverterFillComplexBuffer(audioConverter, inputSampleBufferDataProc, (__bridge void *)(self), &ioOutputDataPacketSize, &outputBufferList, outPacketDescription);
    //NSLog(@"ioOutputDataPacketSize: %d", (unsigned int)ioOutputDataPacketSize);

    //4、设置音频编码信息
    FSLAVAudioRTMPFrame *audioFrame = [[FSLAVAudioRTMPFrame alloc] init];
    audioFrame.timestamp = timeStamp;
    //aacData
    audioFrame.data = [NSData dataWithBytes:aacBuffer length:outputBufferList.mBuffers[0].mDataByteSize];
    
    char exeData[2];
    exeData[0] = _configuration.asc[0];
    exeData[1] = _configuration.asc[1];
    audioFrame.audioInfo = [NSData dataWithBytes:exeData length:2];
    if (self.encoderDelegate && [self.encoderDelegate respondsToSelector:@selector(didEncordingStreamingBufferFrame:encoder:)]) {
        [self.encoderDelegate didEncordingStreamingBufferFrame:audioFrame encoder:self];
    }
    
    //5、在每个音频包的开始添加ADTS头信息
    NSData *adtsAudioData = [self addADTSHeaderToAudioPacketWithChannel:tagPerFormatChannels dataPacketLength:audioFrame.data.length];
    NSMutableData *fullData = [NSMutableData dataWithData:adtsAudioData];
    //拼接ADTS头数据到AACData
    [fullData appendData:audioFrame.data];
    
    //6、将带有ADTS头完整AAC格式数据写入文件路径下的文件中
    //[self.fileHandle writeData:fullData];
    
    fwrite(adtsAudioData.bytes, 1, adtsAudioData.length, self.fileHandle2);
    fwrite(audioFrame.data.bytes, 1, audioFrame.data.length, self.fileHandle2);
    
    NSLog(@"writer %lu to file",fullData.length);
    
    CFRelease(sampleBuffer);
    CFRelease(blockBuffer);
}

/**
 通过sampleBuffer获取到输入描述信息，初始化音频编码转码器

 sampleBuffer 音频帧数据
 @return 音频转码器是否创建成功
 */
- (BOOL)initAudioConvertWithSampleBuffer:(CMSampleBufferRef)sampleBuffer{
    
    if (audioConverter) {
        
        return YES;
    }else{
        
        pcmBuffer = NULL;
        pcmBufferSize = 0;
    }
    
    //1.通过sampleBuffer获取音频的输入描述信息
    AudioStreamBasicDescription inputFormat = *CMAudioFormatDescriptionGetStreamBasicDescription((CMAudioFormatDescriptionRef)CMSampleBufferGetFormatDescription(sampleBuffer));
    //标记获取的声道数
    tagPerFormatChannels = inputFormat.mChannelsPerFrame;
    
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
    //outputFormat.mChannelsPerFrame = (UInt32)_configuration.numberOfChannels;
    outputFormat.mChannelsPerFrame = inputFormat.mChannelsPerFrame;
    //AAC一帧是1024个字节
    outputFormat.mFramesPerPacket = 1024;
    // 压缩格式设置为0
    outputFormat.mBitsPerChannel = 0;
    // 8字节对齐，填0.
    outputFormat.mReserved = 0;
    //  每帧的大小。每一帧的起始点到下一帧的起始点。如果是压缩格式，设置为0 。
    outputFormat.mBytesPerFrame = 0;
    
    //3.编码器参数设置
    AudioClassDescription *description = [self
                                          getAudioClassDescriptionWithType:kAudioFormatMPEG4AAC
                                          fromManufacturer:kAppleSoftwareAudioCodecManufacturer]; //软编
    /**
     4.使用特定的编解码器创建一个新的音频转换器。
     inSourceFormat#> 要转换的源音频的格式。
     inDestinationFormat#> 音频要转换为的目标格式。
     inNumberClassDescriptions#> 类描述的数量。
     inClassDescriptions#> 指定要实例化的编解码器的audioclassdescription。
     outAudioConverter#> 成功返回后，指向一个新的AudioConverter实例。
     */
    OSStatus status = AudioConverterNewSpecific(&inputFormat, &outputFormat, 1, description, &audioConverter);
    //设置码率
    UInt32 outputBitrate = _configuration.audioBitRate;
    UInt32 propSize = sizeof(outputBitrate);
    if (status == noErr) {
        status = AudioConverterSetProperty(audioConverter, kAudioConverterEncodeBitRate, propSize, &outputBitrate);
    }else{
        
        return NO;
    }
    return YES;
}

/**
 *  获取编解码器
 *
 *  type         编码格式
 *  manufacturer 软/硬编
 *
 编解码器（codec）指的是一个能够对一个信号或者一个数据流进行变换的设备或者程序。这里指的变换既包括将 信号或者数据流进行编码（通常是为了传输、存储或者加密）或者提取得到一个编码流的操作，也包括为了观察或者处理从这个编码流中恢复适合观察或操作的形式的操作。编解码器经常用在视频会议和流媒体等应用中。
 *  @return 指定编码器
 */
- (AudioClassDescription *)getAudioClassDescriptionWithType:(UInt32)type
                                           fromManufacturer:(UInt32)manufacturer
{
    static AudioClassDescription desc;
    
    UInt32 encoderSpecifier = type;
    UInt32 size;
    /**
     检索有关给定属性的信息,获取有关音频格式属性的信息。

     inPropertyID#> 一个AudioFormatPropertyID常数。
     inSpecifierSize#> 说明符数据的大小。
     inSpecifier#> 说明符是用作某些属性的输入参数的数据缓冲区。
     outPropertyDataSize#> outpropertydatasize属性当前值的大小(以字节为单位)。为了得到属性值，您将需要这样大小的缓冲区。
     */
    
    OSStatus statue = AudioFormatGetPropertyInfo(kAudioFormatProperty_Encoders,
                                    sizeof(encoderSpecifier),
                                    &encoderSpecifier,
                                    &size);
    if (statue) {
        NSLog(@"error getting audio format propery info: %d", (int)(statue));
        return nil;
    }
    
    unsigned int count = size / sizeof(AudioClassDescription);
    AudioClassDescription descriptions[count];
    statue = AudioFormatGetProperty(kAudioFormatProperty_Encoders,
                                sizeof(encoderSpecifier),
                                &encoderSpecifier,
                                &size,
                                descriptions);
    if (statue) {
        NSLog(@"error getting audio format propery: %d", (int)(statue));
        return nil;
    }
    
    for (unsigned int i = 0; i < count; i++) {
        if ((type == descriptions[i].mSubType) &&
            (manufacturer == descriptions[i].mManufacturer)) {
            memcpy(&desc, &(descriptions[i]), sizeof(desc));
            return &desc;
        }
    }
    
    return nil;
}

/**
 *  填充PCM到缓冲区
 */
- (size_t)copyPCMSamplesIntoBuffer:(AudioBufferList *)ioData {
    
    size_t originalBufferSize = pcmBufferSize;
    if (!originalBufferSize) {
        return 0;
    }
    ioData->mBuffers[0].mData = pcmBuffer;
    ioData->mBuffers[0].mDataByteSize = (UInt32)pcmBufferSize;
    pcmBuffer = NULL;
    pcmBufferSize = 0;
    return originalBufferSize;
}

/**
 编码过程中，会要求这个函数来填充输入数据，也就是原始PCM数据
 提供要转换的音频数据的回调函数。当转换器准备好接收新的输入数据时，将重复调用此回调。
 
 inConverter 编码转换器
 ioNumberDataPackets 数据包
 ioData 缓冲列表
 outDataPacketDescription 缓冲列表个数
 inUserData 输出缓冲列表
 @return OSStatus
 */
static OSStatus inputSampleBufferDataProc(AudioConverterRef inAudioConverter, UInt32 *ioNumberDataPackets, AudioBufferList *ioData, AudioStreamPacketDescription **outDataPacketDescription, void *inUserData)
{
    FSLAVAACAudioEncoder *encoder = (__bridge FSLAVAACAudioEncoder *)(inUserData);
    UInt32 requestedPackets = *ioNumberDataPackets;
    //NSLog(@"Number of packets requested: %d", (unsigned int)requestedPackets);
    size_t copiedSamples = [encoder copyPCMSamplesIntoBuffer:ioData];
    if (copiedSamples < requestedPackets) {
        //NSLog(@"PCM buffer isn't full enough!");
        *ioNumberDataPackets = 0;
        return -1;
    }
    *ioNumberDataPackets = 1;
    //NSLog(@"Copied %zu samples into ioData", copiedSamples);
    return noErr;
}

@end
