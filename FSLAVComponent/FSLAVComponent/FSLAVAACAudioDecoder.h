//
//  FSLAVAACAudioDecoder.h
//  FSLAVComponent
//
//  Created by tutu on 2019/7/10.
//  Copyright © 2019 tutu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>

NS_ASSUME_NONNULL_BEGIN

/**
 音频AAC解码器，网上关于音频AAC的硬解码器内容太少了，到这为止，如果有碰到硬解码知识点，再补，
 这个根本不是纯粹AAC->PCM的解码方式，而是通过AudioQueue内置的解码功能，进行了aac格式的音频播放功能
 关于苹果官方给出的中高层接口：AudioFileStream、AudioFile、AudioQueue、AudioUnitd，
 来进行音频流数据播放的形式，我将会在另一个demo中，独立封装一套接口，类似音乐播放器功能。
 */
@interface FSLAVAACAudioDecoder : NSObject

/**
 播放声音的音量
 */
@property (nonatomic, assign) float volume;

/**
 解码之前，先需要将.aac编码文件中的数据，读取出来
 
 filePath .aac文件路径
 */
- (void)startReadAudioStreamingDataFromPath:(NSString *)filePath;

/**
 播放AAC解码后的PCM数据
 */
- (void)playDecodeAudioPCMData;

@end

NS_ASSUME_NONNULL_END
