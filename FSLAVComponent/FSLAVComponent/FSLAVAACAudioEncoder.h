//
//  FSLAVAudioEncoder.h
//  FSLAVComponent
//
//  Created by tutu on 2019/7/2.
//  Copyright © 2019 tutu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FSLAVAACAudioEncoderInterface.h"

NS_ASSUME_NONNULL_BEGIN

/**
 音频AAC编码器
 */
@interface FSLAVAACAudioEncoder : NSObject<FSLAVAACAudioEncoderInterface>
{
    FSLAVAACAudioConfiguration *_configuration;
}

@property (nonatomic,strong,readonly) FSLAVAACAudioConfiguration *configuration;

@property (nonatomic,weak) id<FSLAVAACAudioEncoderDelegate> encoderDelegate;

#pragma mark -- 音频编码方法一：通过获取到的原始音频数据data格式，进行编码
/**
 音频编码
 
 audioData 音频数据
 timeStamp 时间戳
 */
- (void)encodeAudioData:(NSData *)audioData timeStamp:(uint64_t)timeStamp;

#pragma mark -- 音频编码方法二：通过获取到的原始音频数据CMSampleBufferRef格式，进行编码

/**
 音频编码,通过sampleBuffer格式数据来进行编码
 
 @param sampleBuffer 帧音频数据
 @param timeStamp 时间戳
 */
- (void)encodeAudioSampleBuffer:(CMSampleBufferRef)sampleBuffer timeStamp:(uint64_t)timeStamp;
@end

NS_ASSUME_NONNULL_END
