//
//  FSLAVComponent.h
//  FSLAVComponent
//
//  Created by tutu on 2019/6/21.
//  Copyright © 2019 tutu. All rights reserved.
//

#import <Foundation/Foundation.h>

/**文件管理类，任意操作Documents、Cache、Library中的文件*/
#import "FSLAVFileManager.h"
/**关于访问麦克风、相机、相册、地理位置权限设置*/
#import "FSLAVDeviceAthorizationSettings.h"
/**消息转发简单处理，解决循环引用，如：NSTimer*/
#import "FSLProxy.h"
/**日志处理类*/
#import "FSLAVLog.h"
/** CMSampleBufferRef 助手*/
#import "FSLAVMediaSampleBufferAssistant.h"


/**音频录制器*/
#import "FSLAVFirstAudioRecorder.h"
/**音频录制器*/
#import "FSLAVSecondAudioRecorder.h"
/**音频录制器*/
#import "FSLAVThreeAudioRecorder.h"
/**音频播放器，alloc初始化的形式*/
#import "FSLAVAudioPlayer.h"
/**音频播放器，单例类的形式*/
#import "FSLAVSingleAudioPlayer.h"
/**音频编码器*/
#import "FSLAVAACAudioEncoder.h"
/**音频解码器*/
#import "FSLAVAACAudioDecoder.h"
/**音频混合器*/
#import "FSLAVAudioMixer.h"
/**音频剪辑器*/
#import "FSLAVAudioClipper.h"


/**视频录制器*/
#import "FSLAVFirstVideoRecorder.h"
/**视频编码器*/
#import "FSLAVH264VideoEncoder.h"
/**视频解码器*/
#import "FSLAVH246VideoDecoder.h"
/**音视频播放器，本地、网络播放*/
#import "FSLAVPlayer.h"



@interface FSLAVComponent : NSObject

/**
 *  设置日志输出级别
 *
 *  @param level 日志输出级别 (默认：FSLAVLogLevelFATAL 不输出)
 */
+ (void)setLogLevel:(FSLAVLogLevel)level;

@end
