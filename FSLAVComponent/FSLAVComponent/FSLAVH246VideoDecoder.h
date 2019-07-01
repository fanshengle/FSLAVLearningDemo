//
//  FSLAVH246VideoDecoder.h
//  FSLAVComponent
//
//  Created by TuSDK on 2019/6/30.
//  Copyright © 2019 tutu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <VideoToolbox/VideoToolbox.h>
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

#import "AAPLEAGLLayer.h"
NS_ASSUME_NONNULL_BEGIN


typedef NS_ENUM(NSUInteger, FSLAVH246VideoDecodeBufferShowType) {
    FSLAVH246VideoDecodeBufferShowType_Image = 0,
    FSLAVH246VideoDecodeBufferShowType_Pixel = 0,
    FSLAVH246VideoDecodeBufferShowType_Layer,
};


@protocol FSLAVH246VideoDecoderDelegate <NSObject>

/**
 解码器解码过程中解码回调
 
 @param pixelBuffer 解码后的CVPixelBufferRef
 */
- (void)didDecordingStreamingBuffer:(CVPixelBufferRef)pixelBuffer;

@end

@interface FSLAVH246VideoDecoder : NSObject

/**
 视频的宽高，宽高务必设定为2的倍数，否则解码播放时可能出现绿边
 */
@property (nonatomic, assign) CGSize videoSize;

/**
 是否读取完整UIImage图形
 */
@property (nonatomic, assign) BOOL isNeedPerfectImg;

/**
 解码对应数据之后的显示类型
 */
@property (nonatomic, assign) FSLAVH246VideoDecodeBufferShowType bufferShowType;


/**
 解码成YUV数据时的解码BUF
 */
@property (nonatomic, assign, readonly) CVPixelBufferRef pixelBuffer;

/**
 解码成RGB数据时的IMG
 */
@property (nonatomic, strong, readonly) UIImage *bufferImage;

/**内置解码功能，将编码后的所有类型数据，包装成sampleBuffer，放到该预览层观看*/
@property (nonatomic, strong, readonly) AVSampleBufferDisplayLayer *bufferDisplayLayer;

//@property (nonatomic, strong) AAPLEAGLLayer *bufferDisplayLayer;

@property (nonatomic, strong) UIView *contiantView;

@property (nonatomic, weak) id<FSLAVH246VideoDecoderDelegate> decodeDelegate;

/**
 解码之前，先需要将.h264编码文件中的数据，读取出来
 
 filePath .h264文件路径
 */
- (void)startReadStreamingDataFromPath:(NSString *)filePath;

/**
 解码中，停止读取流数据，销毁解码会话，释放解码对象
 */
- (void)endReadStreamingData;

/**
 初始化解码会话
 */
- (void)initDecopressionSession;

/**
 解码中，停止对流数据的解码操作，并释放对象
 */
- (void)endDecodeStreamingData;

/**
 
 开始解码，对视频流数据进行解码
 
 frame 提取到的视频流图像数据buffer，
 frameSize 对应buffer的大小
 */
- (CVPixelBufferRef)decodeStreamingDataBufferFrame:(uint8_t *)frame bufferFrameSize:(long)frameSize;

/**
 将pixelBuffer转成image，解码pixelBuffer的RGB数据时的img
 
 @param pixelBuffer 流数据buffer
 @return image
 */
- (UIImage *)pixelBufferToImage:(CVPixelBufferRef)pixelBuffer;

/**
 buffer快照
 
 @return image
 */
- (UIImage *)snapshot;

@end

NS_ASSUME_NONNULL_END
