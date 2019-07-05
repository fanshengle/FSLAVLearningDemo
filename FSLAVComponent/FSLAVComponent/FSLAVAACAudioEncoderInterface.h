//
//  FSLAVAACAudioEncoderInterface.h
//  FSLAVComponent
//
//  Created by tutu on 2019/7/2.
//  Copyright © 2019 tutu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FSLAVAACAudioConfiguration.h"
#import "FSLAVAudioRTMPFrame.h"

NS_ASSUME_NONNULL_BEGIN
@protocol FSLAVAACAudioEncoderDelegate <NSObject>

/**
 编码器编码过程回调
 
 @param frame 数据
 @param encoder 编码器
 */
- (void)didEncordingStreamingBufferFrame:(FSLAVAudioRTMPFrame *)frame encoder:(id<FSLAVAACAudioEncoderInterface>)encoder;


@end

@protocol FSLAVAACAudioEncoderInterface <NSObject>

/**
 初始化音频配置
 
 @param configuration 音频配置
 @return
 */
- (instancetype)initWithAudioStreamConfiguration:(FSLAVAACAudioConfiguration *)configuration;


@end

NS_ASSUME_NONNULL_END
