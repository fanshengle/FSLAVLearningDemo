//
//  FSLAVMediaSampleBufferAssistant.h
//  FSLAVComponent
//
//  Created by tutu on 2019/7/16.
//  Copyright © 2019 tutu. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN
/**
 CMSampleBufferRef 助手
 */
@interface FSLAVMediaSampleBufferAssistant : NSObject

/**
 获取CMSampleBufferRef音频数据地址
 @param buffer 原始数据buffer
 @return 数据地址
 */
+ (int8_t *)processSampleBuffer:(CMSampleBufferRef)buffer;

/**
 重新封包生成CMSampleBufferRef
 @param audioData 音频数据地址
 @param len 音频数据长度
 @param timing 音频数据时间信息
 @param asbd 音频数据格式描述信息
 @return 音频数据
 */
+ (CMSampleBufferRef)createAudioSample:(int8_t *)audioData length:(UInt32)len timing:(CMSampleTimingInfo)timing audioStreamBasicDescription:(AudioStreamBasicDescription)asbd;

/**
 重新封包生成CMSampleBufferRef
 @param audioData 音频数据地址
 @param len 音频数据长度
 @param time 音频数据时间
 @param asbd 音频数据格式描述信息
 @return 音频数据
 */
+ (CMSampleBufferRef)createAudioSample:(int8_t *)audioData length:(UInt32)len time:(long long)time audioStreamBasicDescription:(AudioStreamBasicDescription)asbd;

/**
 重设PTS后获取新的sampleBuffer
 @param sample 原始sampleBuffer
 @param speed 变速比率
 @return 新的sampleBuffer
 */
+ (CMSampleBufferRef)adjustPTS:(CMSampleBufferRef)sample bySpeed:(CGFloat)speed;

/**
 重设PTS后获取新的sampleBuffer
 @param sample 原始sampleBuffer
 @param offset 时间间隔
 @return 新的sampleBuffer
 */
+ (CMSampleBufferRef)adjustPTS:(CMSampleBufferRef)sample byOffset:(CMTime)offset;


+ (CMSampleBufferRef)copySampleBuffer:(CMSampleBufferRef)sampleBuffer outputTime:(CMTime)outputTime;

/**
 深拷贝sampleBuffer
 @param sampleBuffer CMSampleBufferRef
 @return CMSampleBufferRef
 */
+ (CMSampleBufferRef)sampleBufferCreateCopyWithDeep:(CMSampleBufferRef)sampleBuffer;

/**
 拷贝sampleBuffer
 @param sampleBuffer CMSampleBufferRef
 @return CMSampleBufferRef
 */
+ (CMSampleBufferRef)sampleBufferCreateCopy:(CMSampleBufferRef)sampleBuffer;

@end

NS_ASSUME_NONNULL_END
