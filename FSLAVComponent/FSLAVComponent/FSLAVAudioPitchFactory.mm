//
//  FSLAVAudioPitchFactory.m
//  FSLAVComponent
//
//  Created by tutu on 2019/7/16.
//  Copyright © 2019 tutu. All rights reserved.
//

#import "FSLAVAudioPitchFactory.h"
#import "FSLAVMediaSampleBufferAssistant.h"
#include "AudioPitch.h"
#include "MediaApple.h"

/**
 * 音频变调器工厂
 */
@interface FSLAVAudioPitchFactory (){
    /** 是否已被释放 */
    BOOL _released;
    /** 音频变调接口 */
    fslAVComponent::AudioPitch *_audioPitch;
    /** 音频描述信息 */
    AudioStreamBasicDescription _asbd;
    /** 音频原始长度 */
    uint32_t _length;
    /** 是否音频第一次数据 */
    BOOL _isFirstFrame;
    /** 开始处理第一次数据时间 */
    long long _startTimeUS;
}

@end

@implementation FSLAVAudioPitchFactory

#pragma mark -- init
/**
 * 创建音频变调器
 * @param info 输入音频轨道信息
 */
+ (id<FSLAVAudioPitchFactoryInterface>)buildWithAudioTrackInfo:(FSLAVAudioTrackInfo *)info;
{
    return [[self alloc] initWithAudioTrackInfo:info];
}

/**
 * 音频变调
 * @param info 输入音频信息
 */
- (id<FSLAVAudioPitchFactoryInterface>)initWithAudioTrackInfo:(FSLAVAudioTrackInfo *)info;
{
    self = [super init];
    if (self) {
        NSAssert(info, @"AudioPitch inputInfoInfo is empty.");
        _inputInfo = info;
        _pitch = 1;
        _speed = 1;
        [self buildAudioPitch];
    }
    return self;
}

/**
 * 创建变调器
 */
- (void)buildAudioPitch;
{
    if (_audioPitch || !_inputInfo) return;
    //采样位数
    uint8_t bitWidth = _inputInfo.bitsPerChannel < 1 ? 16 : _inputInfo.bitsPerChannel;
    //设置音频信息赋值
    fslAVComponent::AudioInfo info = {(uint8_t)_inputInfo.channelsPerFrame,bitWidth,(uint32_t)_inputInfo.sampleRate};
    //设置Apple媒体监听信息
    fslAVComponent::MediaAppleListener *listenner = new fslAVComponent::MediaAppleListener(^(fslAVComponent::AppleAudioData *data){
       
        if (!self->_mediaSync) return;
        //通过处理得到的音频数据重新封包生成CMSampleBufferRef
        CMSampleBufferRef sampleBuffer = [FSLAVMediaSampleBufferAssistant createAudioSample:data->ptr length:(int)data->info.size time:(data->info.timeUs - self->_startTimeUS) audioStreamBasicDescription:self->_asbd];
        BOOL autoRelese = NO;
        //同步音频重变调后数据
        [self->_mediaSync syncAudioPitchOutputBuffer:sampleBuffer autoRelease:&autoRelese];
        
        if(autoRelese){//摧毁buffer
            //使sampleBuffer缓冲区无效。
            CMSampleBufferInvalidate(sampleBuffer);
            CFRelease(sampleBuffer);
            sampleBuffer = NULL;
        }
    });
    
    //初始化音频变调器
    _audioPitch = new fslAVComponent::AudioPitch(info);
    //初始化媒体监听对象
    _audioPitch->setMediaListener(listenner);
}

#pragma mark -- setter getter
/**
 * 切换输入采样格式
 * @param inputInfo 输入音频信息
 */
- (void)setInputInfo:(FSLAVAudioTrackInfo *)inputInfo;
{
    if (!inputInfo) {
        fslLWarn(@"AudioPitch changeFormat need inputInfo.");
        return;
    }
    _inputInfo = inputInfo;
    //采样位数
    uint8_t bitWidth = _inputInfo.bitsPerChannel < 1 ? 16 : _inputInfo.bitsPerChannel;
    fslAVComponent::AudioInfo info = {(uint8_t) _inputInfo.channelsPerFrame, bitWidth, (uint32_t) _inputInfo.sampleRate};
    if (_audioPitch) _audioPitch->changeFormat(info);
}

/**
 * 改变音频音调 [速度设置将失效]
 * @param pitch 0 > pitch [大于1时声音升调，小于1时为降调]
 */
- (void)setPitch:(float)pitch;
{
    if (pitch <= 0 || _pitch == pitch) return;
    _pitch = pitch;
    _speed = 1;
    if (_audioPitch) _audioPitch->changePitch(pitch);
}

/**
 * 改变音频播放速度 [变速不变调, 音调设置将失效]
 * @param speed 0 > speed
 * @since v3.0
 */
- (void)setSpeed:(float)speed;
{
    if (speed <= 0 || _speed == speed) return;
    _speed = speed;
    _pitch = 1;
    if (_audioPitch) _audioPitch->changeSpeed(speed);
}

/**
 * 是否需要变调
 */
- (BOOL)needPitch;
{
    if (_audioPitch) return _audioPitch->needPitch();
    return NO;
}

/**
 * 重置变调、变速参数
 */
- (void)reset;
{
    _pitch = 1;
    _speed = 1;
    if (_audioPitch) _audioPitch->reset();
}

/**
 * 刷新数据
 */
- (void)flush;
{
    if (_audioPitch) _audioPitch->flush();
}

/***
 * 入列缓存结束调用
 * @return 是否已处理
 */
- (BOOL)queueEOS;
{
    _isFirstFrame = NO;
    if (_audioPitch) return _audioPitch->notifyEOS();
    return NO;
}

/***
 * 入列缓存
 * @param inputBuffer 输入缓存
 * @return 是否已处理
 */
- (BOOL)queueInputBuffer:(CMSampleBufferRef)inputBuffer;
{
    if (!inputBuffer)
    {
        fslLWarn(@"AudioPitch queueInputBuffer need inputBuffer.");
        return NO;
    }
   
    //初始化Apple音频数据
    fslAVComponent::AppleAudioData *data = new fslAVComponent::AppleAudioData();
    //声明BufferInfo缓存信息
    fslAVComponent::BufferInfo bufferInfo;
    //返回CMSampleBuffer的输出表示时间戳。
    CMTime inputSampleTime = CMSampleBufferGetOutputPresentationTimeStamp(inputBuffer);
    int8_t *frame = [self pitchSoundBuffer:inputBuffer];
    
    //设置buffer缓存的信息
    bufferInfo.offset = 0;
    bufferInfo.size = _length;
    bufferInfo.flags = 0;
    bufferInfo.timeUs = CMTimeGetSeconds(inputSampleTime) * 1000000l;
    
    //数据指针
    data -> ptr = frame;
    //数据信息
    data -> info = bufferInfo;
    
    //媒体缓存定义
    fslAVComponent::TBuffer mBuffer = make_shared<fslAVComponent::MediaBufferApple>(data);
    if(_audioPitch) return _audioPitch->queueInputBuffer(mBuffer);
    
    return NO;
}

/**
 * 处理buffe设置信息
 * @param ref 输入缓存
 */
- (int8_t *)pitchSoundBuffer:(CMSampleBufferRef)ref;
{
    //音频数据的buffer缓冲区列表
    AudioBufferList audioBufferList;
    CMBlockBufferRef blockBuffer;
    //创建一个包含来自CMSampleBuffer的数据的AudioBufferList，以及一个引用该AudioBufferList中的数据的CMBlockBuffer。
    //指示音频缓冲区列表中涉及的内存是16字节对齐的。
    CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer(ref, NULL, &audioBufferList, sizeof(audioBufferList), NULL, NULL, kCMSampleBufferFlag_AudioBufferList_Assure16ByteAlignment, &blockBuffer);
    
    //获取buffer列表首地址
    AudioBuffer audioBuffer = audioBufferList.mBuffers[0];
    //拿到数据
    int8_t *frame = (int8_t*)audioBuffer.mData;
    
    //初始化buffer长度内存空间
    int8_t *copyFrame = (int8_t *)malloc(audioBuffer.mDataByteSize);
    memcpy(copyFrame, frame, audioBuffer.mDataByteSize);
    
    //音频原始长度
    _length = audioBuffer.mDataByteSize;
    
    if (!_isFirstFrame) {
        _isFirstFrame = YES;
        
        //获取audioformat的描述信息
        CMAudioFormatDescriptionRef audioFormatDesc = (CMAudioFormatDescriptionRef)CMSampleBufferGetFormatDescription(ref);
        //获取输入asbd的格式信息
        AudioStreamBasicDescription inAudioStreamBasicDescription = *(CMAudioFormatDescriptionGetStreamBasicDescription(audioFormatDesc));
        
        _asbd = inAudioStreamBasicDescription;
        //返回CMSampleBuffer的输出表示时间戳。
        CMTime inputSampleTime = CMSampleBufferGetOutputPresentationTimeStamp(ref);
        _startTimeUS = CMTimeGetSeconds(inputSampleTime) * 1000000l;
    }
    
    CFRelease(blockBuffer);
    
    return copyFrame;
}


/**
 * 释放变调器
 */
- (void)destory;
{
    if (_released) return;
    _released = YES;
    
    if (_audioPitch) {
        delete _audioPitch;
        _audioPitch = nullptr;
    }
}


/**
 * 释放变调器
 */
- (void)dealloc;{
    [self destory];
}
@end
