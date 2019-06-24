//
//  FSLAVH264VideoEncoderInterface.h
//  FSLAVComponent
//
//  Created by tutu on 2019/6/24.
//  Copyright © 2019 tutu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FSLAVH264VideoConfiguration.h"
#import "FSLAVVideoRTMPFrame.h"

NS_ASSUME_NONNULL_BEGIN

@protocol FSLAVH264VideoEncoderInterface;

@protocol FSLAVH264VideoEncoderDelegate <NSObject>

/**
 编码器编码后回调
 
 @param encoder 编码器
 @param frame 数据
 */
- (void)videoEncoder:(id<FSLAVH264VideoEncoderInterface>)encoder videoFrame:(FSLAVVideoRTMPFrame *)frame;

@end


/**
 视频编码器的委托协议（约束）
 */
@protocol FSLAVH264VideoEncoderInterface <NSObject>

@required
/**
 编码视频数据
 
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
 
 @param configuration 配置
 @return configuration
 */
- ( instancetype)initWithVideoStreamConfiguration:(FSLAVH264VideoConfiguration *)configuration;

/**
 设置代理
 
 @param delegate 代理
 */
- (void)setDelegate:(id<FSLAVH264VideoEncoderDelegate>)delegate;

/**
 停止编码
 */
- (void)stopEncoder;

@end

NS_ASSUME_NONNULL_END
