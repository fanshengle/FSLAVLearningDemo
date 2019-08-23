//
//  FSLAVH264VideoEncoderInterface.h
//  FSLAVComponent
//
//  Created by tutu on 2019/6/24.
//  Copyright © 2019 tutu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FSLAVH264EncodeOptions.h"
#import "FSLAVVideoRTMPFrame.h"

NS_ASSUME_NONNULL_BEGIN

@protocol FSLAVH264VideoEncoderInterface;

@protocol FSLAVH264VideoEncoderDelegate <NSObject>

@optional
/**
 编码器编码过程中编码回调
 
 @param frame 编码后的数据
 @param encoder 编码器
 */
- (void)didEncordingStreamingBufferFrame:(FSLAVVideoRTMPFrame *)frame encoder:(id<FSLAVH264VideoEncoderInterface>)encoder;

@end


/**
 视频编码器的委托协议（约束）
 */
@protocol FSLAVH264VideoEncoderInterface <NSObject>

@required
/**
 编码:给视频buffer数据进行编码
 
 @param pixelBuffer 视频数据
 @param timeStamp 时间戳
 */
- (void)encodeVideoData:(CVPixelBufferRef)pixelBuffer timeStamp:(uint64_t)timeStamp;

@optional

/**
 码率
 */
@property (nonatomic, assign) NSInteger videoBitRate;

/**
 帧率
 */
@property (nonatomic, assign) NSInteger videoFrameRate;

/**
 初始化配置
 
 @param options 配置
 @return options
 */
- ( instancetype)initWithVideoStreamOptions:(FSLAVH264EncodeOptions *)options;


/**
 停止编码
 */
- (void)stopEncoder;

@end

NS_ASSUME_NONNULL_END
