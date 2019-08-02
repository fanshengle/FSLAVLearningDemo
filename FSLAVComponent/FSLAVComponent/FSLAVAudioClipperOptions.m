//
//  FSLAVAudioClipperOptions.m
//  FSLAVComponent
//
//  Created by tutu on 2019/8/2.
//  Copyright © 2019 tutu. All rights reserved.
//

#import "FSLAVAudioClipperOptions.h"

@implementation FSLAVAudioClipperOptions

+ (instancetype)defaultOptions{
    return [super defaultOptions];
}

/**
 设置默认参数配置(可以重置父类的默认参数，不设置的话，父类的默认参数会无效)
 */
- (void)setConfig{
    
    [super setConfig];
    
    _meidaType = FSLAVMediaTypeAudio;
    _outputFileType = FSLAVAudioOutputFileTypeM4A;
    _appOutputFileType = AVFileTypeAppleM4A;
    _saveSuffixFormat = @"m4a";
    _outputFileName = @"audioClipFile";
    
//    _audioSetting = [FSLAVEncodeAudioSetting AACAuidoSetting];
}
@end
