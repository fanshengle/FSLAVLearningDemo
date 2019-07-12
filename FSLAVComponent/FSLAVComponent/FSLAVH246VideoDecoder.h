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
NS_ASSUME_NONNULL_BEGIN


typedef NS_ENUM(NSUInteger, FSLAVH246VideoDecoderBufferShowType) {
    FSLAVH246VideoDecoderBufferShowType_Image = 0,//用image来渲染pixelBuffer
    FSLAVH246VideoDecoderBufferShowType_Pixel = 1,//直接导出pixelBuffer，由用户选择渲染方式
    FSLAVH246VideoDecoderBufferShowType_Layer,//用AVSampleBufferDisplayLayer来渲染sampleBuffer
};

typedef NS_ENUM(NSUInteger, FSLAVH246VideoDecoderState) {
    FSLAVH246VideoDecoderStateStart = 0,//开始解码
    FSLAVH246VideoDecoderStateDecoding = 1,//解码中
    FSLAVH246VideoDecoderStateFinish,//完成解码
};


@class FSLAVH246VideoDecoder;
@protocol FSLAVH246VideoDecoderDelegate <NSObject>

/**
 解码器解码过程中解码回调
 
 @param pixelBuffer 解码后的CVPixelBufferRef
 @param decder 解码器
 */
- (void)didDecodingStreamingDataBuffer:(CVPixelBufferRef)pixelBuffer videoDecoder:(FSLAVH246VideoDecoder *)decder;


/**
 解码器：解码过程中的状态记录

 @param state 解码状态
 @param decder 解码器
 */
- (void)didChangedVideoDecodeState:(FSLAVH246VideoDecoderState)state videoDecoder:(FSLAVH246VideoDecoder *)decder;

@end

@interface FSLAVH246VideoDecoder : NSObject

/**
 视频输出的宽高，宽高务必设定为2的倍数，否则解码播放时可能出现绿边
 */
@property (nonatomic, assign) CGSize videoSize;

/**
 是否读取完整UIImage图形
 */
@property (nonatomic, assign) BOOL isNeedPerfectImg;

/**
 解码对应数据之后的显示类型
 */
@property (nonatomic, assign) FSLAVH246VideoDecoderBufferShowType bufferShowType;

/**
 解码成YUV数据时的解码BUF
 */
@property (nonatomic, assign, readonly) CVPixelBufferRef pixelBuffer;

/**
 解码时，将数据包装成sampleBuffer，用来在AVSampleBufferDisplayLayer层中直接显示
 */
@property (nonatomic, assign, readonly) CMSampleBufferRef sampleBuffer;

/**
 解码成RGB数据时的IMG
 */
@property (nonatomic, strong, readonly) UIImage *bufferImage;

/**
 内置解码功能，将编码后的所有类型数据，包装成sampleBuffer，放到该预览层观看
 */
@property (nonatomic, strong, readonly) AVSampleBufferDisplayLayer *bufferDisplayLayer;


@property (nonatomic, weak) id<FSLAVH246VideoDecoderDelegate> decodeDelegate;

/**
 解码之前，先需要将.h264编码文件中的数据，读取出来
 
 filePath .h264文件路径
 */
- (void)startReadVideoStreamingDataFromPath:(NSString *)filePath;

/**
 解码中，停止读取流数据，销毁解码会话，释放解码对象
 */
- (void)endReadVideoStreamingData;

/**
 初始化解码会话
 */
- (void)initVideoDecopressionSession;

/**
 解码中，停止对流数据的解码操作，并释放对象
 */
- (void)endDecodeVideoStreamingData;

/**
 
 开始解码，对视频流数据进行解码
 
 frame 提取到的视频流图像数据buffer，
 frameSize 对应buffer的大小
 */
- (CVPixelBufferRef)decodeVideoStreamingDataBufferFrame:(uint8_t *)frame bufferFrameSize:(long)frameSize;

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
