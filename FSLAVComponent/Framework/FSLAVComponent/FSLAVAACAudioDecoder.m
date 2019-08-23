//
//  FSLAVAACAudioDecoder.m
//  FSLAVComponent
//
//  Created by tutu on 2019/7/10.
//  Copyright © 2019 tutu. All rights reserved.
//

#import "FSLAVAACAudioDecoder.h"

//循环峰值
const uint32_t CONST_BUFFER_COUNT = 3;
//是否越界判断值
const uint32_t CONST_BUFFER_SIZE = 0x10000;
@interface FSLAVAACAudioDecoder ()
{
    //表示音频文件对象的不透明数据类型。
    AudioFileID audioFileID;
    //音频流的音频数据格式规范
    AudioStreamBasicDescription audioStreamBasicDescrpition;
    //描述音频数据缓冲区中的一个数据包，其中数据包的大小不同，或者音频数据包之间没有非音频数据。
    AudioStreamPacketDescription *audioStreamPacketDescrption;
    //定义表示音频队列的不透明数据类型。
    AudioQueueRef audioQueue;
    //指向音频队列缓冲区的指针。
    AudioQueueBufferRef audioBuffers[CONST_BUFFER_SIZE];
    
    //数据包索引
    SInt64 readedPacket;
    //数据包数量
    u_int32_t packetNums;
}

@end

@implementation FSLAVAACAudioDecoder

- (instancetype)init
{
    self = [super init];
    if (self) {
        
        _volume = 1.0;
    }
    return self;
}


#pragma mark -- private methods

/**
 处理音频队列抛出的buffer数据

 @param buffer buffer
 @return 处理的返回状态
 */
- (bool)fillBuffer:(AudioQueueBufferRef)buffer {
    bool full = NO;
    uint32_t bytes = 0, packets = (uint32_t)packetNums;

    /**
     8.从音频文件中读取音频数据包。

     inAudioFile#> 一个AudioFileID。
     inUseCache#> 如果需要在读取时缓存数据，则为true，否则为false
     ioNumBytes#> 在输入时，输出缓冲区的大小(以字节为单位)。
     outPacketDescriptions#> 描述返回包的包描述数组。
     inStartingPacket#> 希望返回的第一个包的包索引
     ioNumPackets#> 在输入端，要读取的包的数量，在输出端，要读取的包的数量,数据包实际阅读。
     outBuffer#> outBuffer应该是指向用户分配内存的指针。
     */
    OSStatus status = AudioFileReadPackets(audioFileID, NO, &bytes, audioStreamPacketDescrption, readedPacket, &packets, buffer->mAudioData);    NSAssert(status == noErr, ([NSString stringWithFormat:@"error status %d", status]));

    if (packets > 0) {
        buffer->mAudioDataByteSize = bytes;

        /**
         9.将缓冲区分配给音频队列，以便记录或回放。

         inAQ#> 分配缓冲区的音频队列。
         inBuffer#> 队列的缓冲区(也就是说，要记录到队列中或从队列中播放)。
         inNumPacketDescs#> 由inPacketDescs指针指向的包描述的数量。
         适用的仅用于输出队列，且仅用于可变比特率(VBR)音频格式。通过0表示输入队列(不需要包描述)。
         inPacketDescs#> 包描述的数组。仅适用于输出队列，且仅用于可变比特率(VBR)音频格式。
         为输入队列传递NULL(没有包)需要描述)。
         */
        status = AudioQueueEnqueueBuffer(audioQueue, buffer, packets, audioStreamPacketDescrption);
        NSAssert(status == noErr, ([NSString stringWithFormat:@"error status %d", status]));

        readedPacket += packets;
    }
    else {
        AudioQueueStop(audioQueue, NO);
        full = YES;
    }

    return full;
}

/**
 定义指向回调函数的指针，将AAC数据喂给解码器,该函数在重放音频时调用队列已完成从缓冲区中获取数据。应用程序可以重用缓冲区。
 您的应用程序此时可能希望立即重新填充并重新排队已完成的缓冲区。

 inUserData AudioQueueNewOutput函数的inUserData参数指定的值。
 inAQ 调用回调的音频队列。
 buffer 由音频队列提供的音频队列缓冲区。
 */
void inCallbackProc(void *inUserData,AudioQueueRef inAQ,
                 AudioQueueBufferRef buffer){
    NSLog(@"refresh buffer");
    FSLAVAACAudioDecoder *decoder = (__bridge FSLAVAACAudioDecoder *)inUserData;
    if (!decoder) {
        NSLog(@"decoder nil");
        return ;
    }
    if ([decoder fillBuffer:buffer]) {
        NSLog(@"decoder end");
    }
}

#pragma mark -- public methods

/**
 解码之前，先需要将.aac编码文件中的数据，读取出来
 
 filePath .aac文件路径
 */
- (void)startReadAudioStreamingDataFromPath:(NSString *)filePath;
{
    //获取到aac文件URL
    NSURL *aacFileURL = [NSURL fileURLWithPath:filePath];
    
    /**
     1.打开一个现有的音频文件进行阅读或读写。
     
     inFileRef#> 现有音频文件的CFURLRef。
     inPermissions#> 使用权限常量
     inFileTypeHint#> 对于没有文件名扩展名且类型不容易或从数据(ADTS,AC3)中唯一确定的，此提示可用于指示文件类型。
     否则你可以通过0。提示只在操作系统版本10.3.1或更高版本上使用。对于之前的操作系统版本，打开上面描述的文件将会失败。
     outAudioFile#> 成功后，可用于后续的音频文件AudioFile调用。
     */
    OSStatus status = AudioFileOpenURL((__bridge CFURLRef)aacFileURL, kAudioFileReadPermission, 0, &audioFileID);
    if (status != noErr) {
        NSLog(@"aac文件打开失败，检查该文件是否有效");
        return;
    }
    
    //sizeof c语言中的运算符，预估计该变量的内存空间
    uint32_t size = sizeof(audioStreamBasicDescrpition);
    
    /**
     2.获取音频文件属性的值。将AudioFile属性的值隐藏到缓冲区中,获取音频格式信息。
     
     inAudioFile#> 一个AudioFileID。
     inPropertyID#> 一个AudioFileProperty常数。
     ioDataSize#> 输入outPropertyData缓冲区的大小。在输出时写入缓冲区的字节数。
     outPropertyData#> 写入属性数据的缓冲区。
     */
    status = AudioFileGetProperty(audioFileID, kAudioFilePropertyDataFormat, &size, &audioStreamBasicDescrpition);
    if (status != noErr) {
        NSLog(@"音频文件AudioFile调用失败");
        return;
    }
    
    /**
     3.创建一个新的播放音频队列对象。
     
     inFormat#> 指向描述要播放的音频数据格式的结构的指针。为线性PCM，只支持交错格式。支持压缩格式。
     inCallbackProc#> 指向回调函数的指针，该回调函数在音频队列完成播放后被调用一个缓冲区。
     inUserData#> 指向要传递给回调函数的数据的值或指针。
     inCallbackRunLoop#> 调用inCallbackProc的事件循环。如果指定NULL，则回调函数在音频队列的一个内部线程上调用。
     inCallbackRunLoopMode#> 调用回调函数的运行循环模式。
     inFlags#> 保留以备将来使用。通过0。
     outAQ#> 返回时，此变量包含指向新创建的回放音频队列的指针对象。
     */
    status = AudioQueueNewOutput(&audioStreamBasicDescrpition, inCallbackProc, (__bridge void * _Nullable)(self), NULL, NULL, 0, &audioQueue);
    if (status != noErr) {
        NSLog(@"音频队列audioQueue创建失败");
        return;
    }
    
    if (audioStreamBasicDescrpition.mBytesPerPacket == 0 || audioStreamBasicDescrpition.mFramesPerPacket == 0) {
        uint32_t maxSize;
        size = sizeof(maxSize);
        //4.文件中理论上的最大数据包大小。
        status = AudioFileGetProperty(audioFileID, kAudioFilePropertyPacketSizeUpperBound, &size, &maxSize);
        if(status != noErr) return;
        
        if (maxSize > CONST_BUFFER_SIZE) {
            maxSize = CONST_BUFFER_SIZE;
        }
        
        packetNums = CONST_BUFFER_SIZE / maxSize;
        audioStreamPacketDescrption = malloc(sizeof(AudioStreamPacketDescription) * packetNums);
        
    }else{
        packetNums = CONST_BUFFER_SIZE / audioStreamBasicDescrpition.mBytesPerPacket;
        audioStreamPacketDescrption = nil;
    }
    
    // 这里的100 有问题,有正确的方式请替换
    char cookies[100];
    memset(cookies, 0, sizeof(cookies));
    //5.由调用者设置的指向内存的指针。有些文件类型要求在将包写入音频文件之前提供一个魔法cookie
    status = AudioFileGetProperty(audioFileID, kAudioFilePropertyMagicCookieData, &size, cookies);
    
    if (size > 0) {
        
        /**
         6.设置音频队列属性值。
         
         inAQ#> 要设置其属性值的音频队列。
         inID#> 要设置的属性的ID。有关各种属性，请参阅“音频队列属性ID”音频队列属性。
         inData#> 指向要设置的属性值的指针。
         inDataSize#> 属性数据的大小。
         */
        status = AudioQueueSetProperty(audioQueue, kAudioQueueProperty_MagicCookie, cookies, size);
    }
    
    readedPacket = 0;
    // 循环重复 3-5 步，直到整个 AAC 文件被读完。
    for (int i = 0; i < CONST_BUFFER_COUNT; ++i) {
        
        
        /**
         7.请求音频队列对象分配音频队列缓冲区。
         一旦分配，指向缓冲区的指针和缓冲区的大小是固定的，不能是固定的改变了。
         音频队列缓冲区结构中的mAudioDataByteSize字段，AudioQueueBuffer，初始值设置为0。
         
         inAQ#> 要分配缓冲区的音频队列。
         inBufferByteSize#> 新缓冲区的期望大小，以字节为单位。适当的缓冲区大小取决于您将对数据以及音频数据格式执行处理。
         outBuffer#> 返回时，指向新创建的音频缓冲区。中的mAudioDataByteSize字段音频队列缓冲区结构AudioQueueBuffer最初设置为0。
         */
        status = AudioQueueAllocateBuffer(audioQueue, CONST_BUFFER_SIZE, &audioBuffers[i]);
        if (status != noErr) {
            NSLog(@"音频队列audioQueue的队列缓存区分配失败");
            return;
        }
        
        if ([self fillBuffer:audioBuffers[i]]) break;
        
        NSLog(@"buffer%d full", i);
    }
}

/**
 播放AAC解码后的PCM数据
 */
- (void)playDecodeAudioPCMData;
{
    //设置播放音频队列参数值。
    AudioQueueSetParameter(audioQueue, kAudioQueueParam_Volume, _volume);
    /**
     开始播放或录制音频。

     inAQ#> 要启动的音频队列。
     inStartTime#> 指向音频队列应该开始的时间的指针。
     如果你指定了时间使用AudioTimeStamp结构的mSampleTime字段，采样时间为
     引用到关联音频设备的示例帧时间轴。可能是NULL。
     */
    AudioQueueStart(audioQueue, NULL);
}

/**
 销毁audioQueue
 */
- (void)disposeAudioOutputQueue
{
    AudioQueueStop(audioQueue, YES);
    if (audioQueue != NULL)
    {
        AudioQueueDispose(audioQueue,true);
        audioQueue = NULL;
    }
}

- (void)dealloc{
    [self disposeAudioOutputQueue];
}

@end
