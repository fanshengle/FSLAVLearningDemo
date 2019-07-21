//
//  FSLAVAudioPitchEngine.h
//  FSLAVComponent
//
//  Created by tutu on 2019/7/16.
//  Copyright © 2019 tutu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "FSLAVAudioInfo.h"
#import "FSLAVAudioPitchEngineInterface.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * 声音处理类型
 * @since v3.0
 */
typedef NS_ENUM(NSUInteger, FSLAVSoundPitchType) {
    // 正常
    FSLAVSoundPitchNormal,
    // 怪兽
    FSLAVSoundPitchMonster,
    // 大叔
    FSLAVSoundPitchUncle,
    // 女生
    FSLAVSoundPitchGirl,
    // 萝莉
    FSLAVSoundPitchLolita,
};

/**
 录制速度模式
 */
typedef NS_ENUM(NSInteger,FSLAVSoundSpeedMode)
{
    /** 标准模式 速度大小1.0 */
    FSLAVSoundSpeedMode_Normal,
    
    /** 快速模式 速度大小1.5 */
    FSLAVSoundSpeedMode_Fast1,
    
    /** 极快模式 速度大小2.0 */
    FSLAVSoundSpeedMode_Fast2,
    
    /** 慢速模式 速度大小0.7 */
    FSLAVSoundSpeedMode_Slow1,
    
    /** 极慢模式  速度大小0.5 */
    FSLAVSoundSpeedMode_Slow2,
};

@protocol FSLAVAudioPitchEngineDelegate;


/**
 音频音调（变声、变速）处理核心工具类
 */
@interface FSLAVAudioPitchEngine : NSObject<FSLAVAudioPitchEngineInterface>

/**
 * 改变音频音调 [速度设置将失效]
 * pitch 0 > pitch [大于1时声音升调，小于1时为降调]
 * pitchType 与 pitch不能同时设置；因为pitchType就是设置固定值pitch得到的
 */
@property (nonatomic) FSLAVSoundPitchType pitchType;

/**
 * 改变音频音调 [速度设置将失效]
 * pitch 0 > pitch [大于1时声音升调，小于1时为降调]
 * pitchType 与 pitch不能同时设置；因为pitchType就是设置固定值pitch得到的
 */
@property (nonatomic) float pitch;

/**
 * 改变音频播放速度 [变速不变调, 音调设置将失效]
 * speedMode 与 speed不能同时设置；因为FSLAVSoundSpeedMode就是设置固定值speed得到的
 */
@property (nonatomic) FSLAVSoundSpeedMode speedMode;

/**
 * 改变音频播放速度 [变速不变调, 音调设置将失效]
 * speed 0 > speed
 */
@property (nonatomic) float speed;

/**
 * FSLAVAudioPitchEngineDelegate
 */
@property (nonatomic, weak) id<FSLAVAudioPitchEngineDelegate> delegate;

/**
 * FSLAVAudioPitchEngine初始化
 * @param inputInfo 音频输入样式
 * @return FSLAVAudioPitchEngine
 */
- (instancetype)initWithInputAudioInfo:(FSLAVAudioTrackInfo *)inputInfo;

@end

#pragma mark - FSLAVAudioPitchEngineDelegate

@protocol FSLAVAudioPitchEngineDelegate

/**
 * 输出音频数据
 * @param output CMSampleBufferRef
 * @param autoRelease 是否释放output
 */
- (void)pitchEngine:(FSLAVAudioPitchEngine *)pitchEngine syncAudioPitchOutputBuffer:(CMSampleBufferRef)output autoRelease:(BOOL *)autoRelease;

@end

NS_ASSUME_NONNULL_END
