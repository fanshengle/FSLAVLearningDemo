//
//  FSLAVVideoSplicerOptions.m
//  FSLAVComponent
//
//  Created by TuSDK on 2019/8/15.
//  Copyright © 2019 tutu. All rights reserved.
//

#import "FSLAVVideoSplicerOptions.h"

@implementation FSLAVVideoSplicerOptions

+ (instancetype)defaultOptions{
    return [super defaultOptions];
}

/**
 设置默认参数配置(可以重置父类的默认参数，不设置的话，父类的默认参数会无效)
 */
- (void)setConfig{
    
    [super setConfig];
    
    _meidaType = FSLAVMediaTypeVideo;
    _outputFileType = FSLAVVideoOutputFileTypeQuickTimeMovie;
    _appOutputFileType = AVFileTypeQuickTimeMovie;
    _saveSuffixFormat = @"mov";
    _outputFileName = @"videoSpliceFile";
}

- (AVCaptureVideoOrientation)movieOrientation;
{
    if( !self.mediaAsset) return AVCaptureVideoOrientationPortrait;
    
    AVAssetTrack *assetVideoTrack = [[self.mediaAsset tracksWithMediaType:AVMediaTypeVideo] firstObject];
    
    if( !assetVideoTrack ) return AVCaptureVideoOrientationPortrait;
    
    CGAffineTransform transform = assetVideoTrack.preferredTransform;
    if (transform.a == 0 && transform.b == 1.0 && transform.c == -1.0 && transform.d == 0){
        return AVCaptureVideoOrientationLandscapeRight;
    }else if (transform.a == 0 && transform.b == -1.0 && transform.c == 1.0 && transform.d == 0){
        return AVCaptureVideoOrientationLandscapeLeft;
    }else if (transform.a == -1.0 && transform.b == 0 && transform.c == 0 && transform.d == -1.0){
        return AVCaptureVideoOrientationPortraitUpsideDown;
    }else{
        return AVCaptureVideoOrientationPortrait;
    }
}


@end
