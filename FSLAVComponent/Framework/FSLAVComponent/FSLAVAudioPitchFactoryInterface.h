//
//  FSLAVAudioPitchFactoryInterface.h
//  FSLAVComponent
//
//  Created by tutu on 2019/7/16.
//  Copyright © 2019 tutu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "FSLAVAudioInfo.h"

NS_ASSUME_NONNULL_BEGIN
/**
 * 音频变调同步协议
 */
@protocol FSLAVAudioPitchFactorySyncInterface <NSObject>

/**
 * 同步音频重变调后数据
 *
 * @param output 数据缓存
 * @param autoRelease  数据是否释放
 */
- (void)syncAudioPitchOutputBuffer:(CMSampleBufferRef)output autoRelease:(BOOL*)autoRelease;

@end

/**
 音频变调工厂协议
 */
@protocol FSLAVAudioPitchFactoryInterface <NSObject>

/**
 * 音频变调同步接口
 */
@property (nonatomic, weak) id<FSLAVAudioPitchFactorySyncInterface> mediaSync;

/**
 * 音频轨道信息：输入采样格式
 */
@property (nonatomic, retain) FSLAVAudioTrackInfo *inputInfo;

/**
 * 改变音频音调 [速度设置将失效]
 * pitch 0 > pitch [大于1时声音升调，小于1时为降调]
 */
@property (nonatomic) float pitch;

/**
 * 改变音频播放速度 [变速不变调, 音调设置将失效]
 * speed 0 > speed
 */
@property (nonatomic) float speed;

/**
 * 是否需要重采样
 */
@property (nonatomic, readonly) BOOL needPitch;

/**
 * 重置变调、变速参数
 */
- (void)reset;

/**
 * 刷新数据
 */
- (void)flush;

/***
 * 入列缓存
 * @param inputBuffer 输入缓存
 * @return 是否已处理
 */
- (BOOL)queueInputBuffer:(CMSampleBufferRef)inputBuffer;

/***
 * 入列缓存结束调用
 * @return 是否已处理
 */
- (BOOL)queueEOS;

/**
 * 释放变调器
 */
- (void)destory;


@end

NS_ASSUME_NONNULL_END
