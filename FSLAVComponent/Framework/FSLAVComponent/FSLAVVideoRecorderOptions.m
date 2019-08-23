//
//  FSLAVVideoRecorderoptions.m
//  FSLAVComponent
//
//  Created by tutu on 2019/6/25.
//  Copyright © 2019 tutu. All rights reserved.
//

#import "FSLAVVideoRecorderOptions.h"

@implementation FSLAVVideoRecorderOptions
//必须走一下父类的方法；为了一些父类的默认参数生效
- (instancetype)init
{
    self = [super init];
    if (self) {
        
    }
    return self;
}

/**
 默认视频配置
 
 @return FSLAVVideoRecorderOptions
 */
+ (instancetype)defaultOptions{
    
    FSLAVVideoRecorderOptions *options = [FSLAVVideoRecorderOptions defaultOptionsForSessionPreset: FSLAVCaptureSessionPreset_Default];
    return options;
}

/**
 视频配置(质量)
 
 @param sessionPreset 视频分辨率
 @return FSLAVVideoRecorderOptions
 */
+ (instancetype)defaultOptionsForSessionPreset:(FSLAVCaptureSessionPreset)sessionPreset{
    
    FSLAVVideoRecorderOptions *options = [FSLAVVideoRecorderOptions defaultOptionsForSessionPreset:sessionPreset videoRecordPosition:FSLAVVideoRecordPositionFront];
    return options;
}

/**
 视频配置(质量&是否是横屏)
 
 @param sessionPreset 视频分辨率
 @param videoRecordPosition 摄像机位置
 @return FSLAVVideoRecorderOptions
 */
+ (instancetype)defaultOptionsForSessionPreset:(FSLAVCaptureSessionPreset)sessionPreset videoRecordPosition:(FSLAVVideoRecordPosition)videoRecordPosition{
    
    FSLAVVideoRecorderOptions *options = [FSLAVVideoRecorderOptions new];
    options.sessionPreset = sessionPreset;
    options.recordPosition = videoRecordPosition;
    options.recordOutputType = FSLAVVideoRecordVideoDataOutput;
    options.isOutPreview = YES;
    options.outputFileName = @"VideoFile";
    options.saveSuffixFormat = @"mp4";

    switch (sessionPreset)
    {
        case  FSLAVCaptureSessionPreset_Low:
        {
            options.avSessionPreset = AVCaptureSessionPresetLow;
        }
            break;
        case  FSLAVCaptureSessionPreset_Medium:
        {
            options.avSessionPreset = AVCaptureSessionPresetMedium;
        }
            break;
        case  FSLAVCaptureSessionPreset_High:
        {
            options.avSessionPreset = AVCaptureSessionPresetHigh;
        }
            break;
        default:
            
            options.avSessionPreset = AVCaptureSessionPresetHigh;
            break;
    }
    switch (videoRecordPosition)
    {
        case  FSLAVVideoRecordPositionFront:
        {
            options.devicePosition = AVCaptureDevicePositionFront;
        }
            break;
        case  FSLAVVideoRecordPositionBack:
        {
            options.devicePosition = AVCaptureDevicePositionBack;
        }
            break;
        case  FSLAVVideoRecordPositionUnspecified:
        {
            options.devicePosition = AVCaptureDevicePositionUnspecified;
        }
            break;
        default:
            break;
    }
    return options;
}

/**
 设置默认参数配置(可以重置父类的默认参数，不设置的话，父类的默认参数会无效)
 */
- (void)setConfig;
{
    [super setConfig];
}
@end
