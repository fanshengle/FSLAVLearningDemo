//
//  FSLAVMediaSampleBufferAssistant.m
//  FSLAVComponent
//
//  Created by tutu on 2019/7/16.
//  Copyright © 2019 tutu. All rights reserved.
//

#import "FSLAVMediaSampleBufferAssistant.h"

@implementation FSLAVMediaSampleBufferAssistant

/**
 获取CMSampleBufferRef音频数据地址
 @param ref 原始数据buffer
 @return 数据地址
 */
+ (int8_t *)processSampleBuffer:(CMSampleBufferRef)buffer;
{
    AudioBufferList audioBufferList;
    CMBlockBufferRef blockBuffer;
    CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer(buffer, NULL, &audioBufferList, sizeof(audioBufferList), NULL, NULL, kCMSampleBufferFlag_AudioBufferList_Assure16ByteAlignment, &blockBuffer);
    
    AudioBuffer audioBuffer = audioBufferList.mBuffers[0];
    int8_t *frame = (int8_t*)audioBuffer.mData;
    
    CMItemCount timingCount;
    CMSampleBufferGetSampleTimingInfoArray(buffer, 0, nil, &timingCount);
    CMSampleTimingInfo* pInfo = (CMSampleTimingInfo *)malloc(sizeof(CMSampleTimingInfo) * timingCount);
    CMSampleBufferGetSampleTimingInfoArray(buffer, timingCount, pInfo, &timingCount);
    
    free(pInfo);
    
    return frame;
}

/**
 重新封包生成CMSampleBufferRef
 @param audioData 音频数据地址
 @param len 音频数据长度
 @param timing 音频数据时间信息
 @param asbd 音频数据格式描述信息
 @return 音频数据
 */
+ (CMSampleBufferRef)createAudioSample:(int8_t *)audioData length:(UInt32)len timing:(CMSampleTimingInfo)timing audioStreamBasicDescription:(AudioStreamBasicDescription)asbd;
{
    AudioBufferList audioBufferList;
    audioBufferList.mNumberBuffers = asbd.mFramesPerPacket;
    audioBufferList.mBuffers[0].mNumberChannels= asbd.mChannelsPerFrame;
    audioBufferList.mBuffers[0].mDataByteSize= len;
    audioBufferList.mBuffers[0].mData = audioData;
    
    CMSampleBufferRef buff = NULL;
    static CMFormatDescriptionRef format = NULL;
    
    OSStatus error = 0;
    error = CMAudioFormatDescriptionCreate(kCFAllocatorDefault, &asbd, 0, NULL, 0, NULL, NULL, &format);
    if (error) {
        return NULL;
    }
    
    error = CMSampleBufferCreate(kCFAllocatorDefault, NULL, false, NULL, NULL, format, len/(2 * asbd.mChannelsPerFrame), 1, &timing, 0, NULL, &buff);
    if (error) {
        return NULL;
    }
    
    error = CMSampleBufferSetDataBufferFromAudioBufferList(buff, kCFAllocatorDefault, kCFAllocatorDefault, 0, &audioBufferList);
    if(error){
        return NULL;
    }
    
    return buff;
}

/**
 重新封包生成CMSampleBufferRef
 @param audioData 音频数据地址
 @param len 音频数据长度
 @param time 音频数据时间
 @param asbd 音频数据格式描述信息
 @return 音频数据
 */
+ (CMSampleBufferRef)createAudioSample:(int8_t *)audioData length:(UInt32)len time:(long long)time audioStreamBasicDescription:(AudioStreamBasicDescription)asbd;
{
    AudioBufferList audioBufferList;
    audioBufferList.mNumberBuffers = asbd.mFramesPerPacket;
    audioBufferList.mBuffers[0].mNumberChannels= asbd.mChannelsPerFrame;
    audioBufferList.mBuffers[0].mDataByteSize= len;
    audioBufferList.mBuffers[0].mData = audioData;
    
    CMSampleBufferRef buff = NULL;
    static CMFormatDescriptionRef format = NULL;
    
    OSStatus error = 0;
    error = CMAudioFormatDescriptionCreate(kCFAllocatorDefault, &asbd, 0, NULL, 0, NULL, NULL, &format);
    if (error) {
        return NULL;
    }
    
    CMTime timeUS = CMTimeMake(time, USEC_PER_SEC);
    CMSampleTimingInfo timingInfo = {CMTimeMake(1, asbd.mSampleRate), timeUS, kCMTimeInvalid};
    
    error = CMSampleBufferCreate(kCFAllocatorDefault, NULL, false, NULL, NULL, format, len/(2 * asbd.mChannelsPerFrame), 1, &timingInfo, 0, NULL, &buff);
    
    CFRelease(format);
    
    if (error) {
        return NULL;
    }
    
    error = CMSampleBufferSetDataBufferFromAudioBufferList(buff, kCFAllocatorDefault, kCFAllocatorDefault, 0, &audioBufferList);
    if(error){
        return NULL;
    }
    
    return buff;
}

/**
 重设PTS后获取新的sampleBuffer
 @param sample 原始sampleBuffer
 @param speed 变速比率
 @return 新的sampleBuffer
 */
+ (CMSampleBufferRef)adjustPTS:(CMSampleBufferRef)sample bySpeed:(CGFloat)speed;
{
    CMItemCount count;
    CMSampleBufferGetSampleTimingInfoArray(sample, 0, nil, &count);
    CMSampleTimingInfo* pInfo = (CMSampleTimingInfo*) malloc(sizeof(CMSampleTimingInfo) * count);
    CMSampleBufferGetSampleTimingInfoArray(sample, count, pInfo, &count);
    
    for (CMItemCount i = 0; i < count; i++) {
        pInfo[i].decodeTimeStamp = CMTimeMake(pInfo[i].decodeTimeStamp.value * speed, pInfo[i].decodeTimeStamp.timescale);
        pInfo[i].presentationTimeStamp = CMTimeMake(pInfo[i].presentationTimeStamp.value * speed, pInfo[i].presentationTimeStamp.timescale);
    }
    
    CMSampleBufferRef sout;
    CMSampleBufferCreateCopyWithNewTiming(nil, sample, count, pInfo, &sout);
    free(pInfo);
    
    return sout;
}

/**
 重设PTS后获取新的sampleBuffer
 @param sample 原始sampleBuffer
 @param offset 时间间隔
 @return 新的sampleBuffer
 */
+ (CMSampleBufferRef)adjustPTS:(CMSampleBufferRef)sample byOffset:(CMTime)offset;
{
    CFRetain(sample);
    
    CMItemCount count;
    CMSampleBufferGetSampleTimingInfoArray(sample, 0, nil, &count);
    CMSampleTimingInfo* pInfo = malloc(sizeof(CMSampleTimingInfo) * count);
    CMSampleBufferGetSampleTimingInfoArray(sample, count, pInfo, &count);
    
    for (CMItemCount i = 0; i < count; i++) {
        pInfo[i].decodeTimeStamp = CMTimeSubtract(pInfo[i].decodeTimeStamp, offset);
        pInfo[i].presentationTimeStamp = CMTimeSubtract(pInfo[i].presentationTimeStamp, offset);
    }
    
    CMSampleBufferRef sout;
    CMSampleBufferCreateCopyWithNewTiming(nil, sample, count, pInfo, &sout);
    free(pInfo);
    
    CFRelease(sample);
    return sout;
}

+ (CMSampleBufferRef)copySampleBuffer:(CMSampleBufferRef)sampleBuffer outputTime:(CMTime)outputTime;
{
    if (!sampleBuffer) return NULL;
    
    CFRetain(sampleBuffer);
    
    CMItemCount count;
    CMSampleBufferGetSampleTimingInfoArray(sampleBuffer, 0, nil, &count);
    CMSampleTimingInfo* pInfo = malloc(sizeof(CMSampleTimingInfo) * count);
    CMSampleBufferGetSampleTimingInfoArray(sampleBuffer, count, pInfo, &count);
    
    for (CMItemCount i = 0; i < count; i++) {
        pInfo[i].decodeTimeStamp = outputTime;
        pInfo[i].presentationTimeStamp = outputTime;
    }
    
    CMSampleBufferRef sout;
    CMSampleBufferCreateCopyWithNewTiming(nil, sampleBuffer, count, pInfo, &sout);
    
    CMSampleBufferSetOutputPresentationTimeStamp(sout, outputTime);
    
    free(pInfo);
    
    CFRelease(sampleBuffer);
    return sout;
}

/**
 深拷贝sampleBuffer
 @param sampleBuffer CMSampleBufferRef
 @return CMSampleBufferRef
 */
+ (CMSampleBufferRef)sampleBufferCreateCopyWithDeep:(CMSampleBufferRef)sampleBuffer;
{
    AudioBufferList audioBufferList;
    CMBlockBufferRef blockBuffer;
    //Create an AudioBufferList containing the data from the CMSampleBuffer,
    //and a CMBlockBuffer which references the data in that AudioBufferList.
    CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer(sampleBuffer, NULL, &audioBufferList, sizeof(audioBufferList), NULL, NULL, 0, &blockBuffer);
    NSUInteger size = sizeof(audioBufferList);
    char buffer[size];
    
    memcpy(buffer, &audioBufferList, size);
    //This is the Audio data.
    NSData *bufferData = [NSData dataWithBytes:buffer length:size];
    
    const void *copyBufferData = [bufferData bytes];
    copyBufferData = (char *)copyBufferData;
    
    CMSampleBufferRef copyBuffer = NULL;
    OSStatus status = -1;
    
    /* Format Description */
    
    AudioStreamBasicDescription audioFormat = *CMAudioFormatDescriptionGetStreamBasicDescription((CMAudioFormatDescriptionRef) CMSampleBufferGetFormatDescription(sampleBuffer));
    
    CMFormatDescriptionRef format = NULL;
    CMAudioFormatDescriptionCreate(kCFAllocatorDefault, &audioFormat, 0, nil, 0, nil, nil, &format);
    
    
    CMFormatDescriptionRef formatdes = NULL;
    status = CMFormatDescriptionCreate(NULL, kCMMediaType_Audio, 'lpcm', NULL, &formatdes);
    if (status != noErr)
    {
        NSLog(@"Error in CMAudioFormatDescriptionCreator");
        CFRelease(blockBuffer);
        return nil;
    }
    
    /* Create sample Buffer */
    CMItemCount framesCount = CMSampleBufferGetNumSamples(sampleBuffer);
    CMSampleTimingInfo timing   = {.duration= CMTimeMake(1, audioFormat.mSampleRate), .presentationTimeStamp= CMSampleBufferGetPresentationTimeStamp(sampleBuffer), .decodeTimeStamp= CMSampleBufferGetDecodeTimeStamp(sampleBuffer)};
    
    status = CMSampleBufferCreate(kCFAllocatorDefault, nil , NO,nil,nil,format, framesCount, 1, &timing, 0, nil, &copyBuffer);
    
    if( status != noErr) {
        NSLog(@"Error in CMSampleBufferCreate");
        CFRelease(blockBuffer);
        return nil;
    }
    
    /* Copy BufferList to Sample Buffer */
    AudioBufferList receivedAudioBufferList;
    memcpy(&receivedAudioBufferList, copyBufferData, sizeof(receivedAudioBufferList));
    
    //Creates a CMBlockBuffer containing a copy of the data from the
    //AudioBufferList.
    status = CMSampleBufferSetDataBufferFromAudioBufferList(copyBuffer, kCFAllocatorDefault , kCFAllocatorDefault, 0, &receivedAudioBufferList);
    if (status != noErr) {
        NSLog(@"Error in CMSampleBufferSetDataBufferFromAudioBufferList");
        CFRelease(blockBuffer);
        return nil;
    }
    
    CFRelease(blockBuffer);
    
    return copyBuffer;
}

/**
 拷贝sampleBuffer
 @param sampleBuffer CMSampleBufferRef
 @return CMSampleBufferRef
 */
+ (CMSampleBufferRef)sampleBufferCreateCopy:(CMSampleBufferRef)sampleBuffer;
{
    CFRetain(sampleBuffer);
    
    CMBlockBufferRef dataBuffer = CMSampleBufferGetDataBuffer(sampleBuffer);
    //CVPixelBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    
    CMFormatDescriptionRef formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer);
    
    CMItemCount timingCount;
    CMSampleBufferGetSampleTimingInfoArray(sampleBuffer, 0, nil, &timingCount);
    CMSampleTimingInfo* pInfo = malloc(sizeof(CMSampleTimingInfo) * timingCount);
    CMSampleBufferGetSampleTimingInfoArray(sampleBuffer, timingCount, pInfo, &timingCount);
    
    CMItemCount sampleCount = CMSampleBufferGetNumSamples(sampleBuffer);
    
    CMItemCount sizeArrayEntries;
    CMSampleBufferGetSampleSizeArray(sampleBuffer, 0, nil, &sizeArrayEntries);
    size_t *sizeArrayOut = malloc(sizeof(size_t) * sizeArrayEntries);
    CMSampleBufferGetSampleSizeArray(sampleBuffer, sizeArrayEntries, sizeArrayOut, &sizeArrayEntries);
    
    CMSampleBufferRef sout = nil;
    
    if(dataBuffer){
        
        CMSampleBufferCreate(kCFAllocatorDefault, dataBuffer, YES, nil,nil, formatDescription, sampleCount, timingCount, pInfo, sizeArrayEntries, sizeArrayOut, &sout);
    }else{
        
    }
    
    free(pInfo);
    free(sizeArrayOut);
    CFRelease(sampleBuffer);
    
    return sout;
}
@end
