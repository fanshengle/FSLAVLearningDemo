//
//  FSLAVVideoRecorderConfiguration.m
//  FSLAVComponent
//
//  Created by tutu on 2019/6/25.
//  Copyright © 2019 tutu. All rights reserved.
//

#import "FSLAVVideoRecorderConfiguration.h"

@implementation FSLAVVideoRecorderConfiguration


/**
 默认视频配置
 
 @return FSLAVVideoRecorderConfiguration
 */
+ (instancetype)defaultConfiguration{
    
    FSLAVVideoRecorderConfiguration *configuration = [FSLAVVideoRecorderConfiguration defaultConfigurationForSessionPreset: FSLAVCaptureSessionPreset_Default];
    return configuration;
}

/**
 视频配置(质量)
 
 @param sessionPreset 视频分辨率
 @return FSLAVVideoRecorderConfiguration
 */
+ (instancetype)defaultConfigurationForSessionPreset:(FSLAVCaptureSessionPreset)sessionPreset{
    
    FSLAVVideoRecorderConfiguration *configuration = [FSLAVVideoRecorderConfiguration defaultConfigurationForSessionPreset:sessionPreset videoRecordPosition:FSLAVVideoRecordPositionFront];
    return configuration;
}

/**
 视频配置(质量&是否是横屏)
 
 @param sessionPreset 视频分辨率
 @param videoRecordPosition 摄像机位置
 @return FSLAVVideoRecorderConfiguration
 */
+ (instancetype)defaultConfigurationForSessionPreset:(FSLAVCaptureSessionPreset)sessionPreset videoRecordPosition:(FSLAVVideoRecordPosition)videoRecordPosition{
    
    FSLAVVideoRecorderConfiguration *configuration = [FSLAVVideoRecorderConfiguration new];
    configuration.sessionPreset = sessionPreset;
    configuration.recordPosition = videoRecordPosition;
    configuration.recordOutputType = FSLAVVideoRecordVideoDataOutput;
    configuration.isOutPreview = YES;
    configuration.outputFileName = @"VideoFile";
    configuration.saveSuffixFormat = @"mp4";

    switch (sessionPreset)
    {
        case  FSLAVCaptureSessionPreset_Low:
        {
            configuration.avSessionPreset = AVCaptureSessionPresetLow;
        }
            break;
        case  FSLAVCaptureSessionPreset_Medium:
        {
            configuration.avSessionPreset = AVCaptureSessionPresetMedium;
        }
            break;
        case  FSLAVCaptureSessionPreset_High:
        {
            configuration.avSessionPreset = AVCaptureSessionPresetHigh;
        }
            break;
        default:
            
            configuration.avSessionPreset = AVCaptureSessionPresetHigh;
            break;
    }
    switch (videoRecordPosition)
    {
        case  FSLAVVideoRecordPositionFront:
        {
            configuration.devicePosition = AVCaptureDevicePositionFront;
        }
            break;
        case  FSLAVVideoRecordPositionBack:
        {
            configuration.devicePosition = AVCaptureDevicePositionBack;
        }
            break;
        case  FSLAVVideoRecordPositionUnspecified:
        {
            configuration.devicePosition = AVCaptureDevicePositionUnspecified;
        }
            break;
        default:
            break;
    }
    return configuration;
}


@end
