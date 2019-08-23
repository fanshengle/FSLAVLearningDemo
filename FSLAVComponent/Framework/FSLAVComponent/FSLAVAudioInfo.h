//
//  FSLAVAudioInfo.h
//  FSLAVComponent
//
//  Created by tutu on 2019/7/15.
//  Copyright © 2019 tutu. All rights reserved.
//

#import "FSLAVMediaInfo.h"

NS_ASSUME_NONNULL_BEGIN

@class FSLAVAudioTrackInfo;


/**
 媒体素材中的音频信息

 */
@interface FSLAVAudioInfo : FSLAVMediaInfo

/**
 音频中所有轨道信息
 */
@property (nonatomic,readonly) NSArray<FSLAVAudioTrackInfo *> *audioTrackInfoArray;

@end

#pragma mark - FSLAVAudioTrackInfo

/**
 * 音频轨道信息
 */
@interface FSLAVAudioTrackInfo : NSObject

/**
 通过它可以获取到AudioStreamBasicDescription音频格式信息
 */
@property(nonatomic) CMAudioFormatDescriptionRef audioFormatDescriptionRef;

/**
 帧率
 */
@property (nonatomic) Float64 sampleRate;

/**
 声道数
 */
@property (nonatomic) UInt32 channelsPerFrame;

/**
 每个packet的中frame的个数，等于这个packet中经历了几次采样间隔。帧数据包
 */
@property (nonatomic,readonly) UInt32 framesPerPacket;

/**
 每个packet中数据字节数
 */
@property (nonatomic,readonly) UInt32 bytesPerPacket;

/**
 采样位数
 */
@property (nonatomic) UInt32 bitsPerChannel;


/**
 FSLAVAudioTrackInfo
 
 @param audioTrack AVAssetTrack
 @return FSLAVAudioTrackInfo
 */
+ (instancetype)trackInfoWithAudioAssetTrack:(AVAssetTrack *)audioTrack;

/**
 根据 CMAudioFormatDescriptionRef 初始化 FSLAVAudioTrackInfo
 
 @param audioFormatDescriptionRef CMAudioFormatDescriptionRef
 @return FSLAVAudioTrackInfo
 */
- (instancetype)initWithCMAudioFormatDescriptionRef:(CMFormatDescriptionRef)audioFormatDescriptionRef;



@end

NS_ASSUME_NONNULL_END
