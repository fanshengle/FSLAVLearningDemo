//
//  FSLAVAudioInfo.m
//  FSLAVComponent
//
//  Created by tutu on 2019/7/12.
//  Copyright © 2019 tutu. All rights reserved.
//

#import "FSLAVMixerAudioOptions.h"

@implementation FSLAVMixerAudioOptions

/**
 设置默认参数配置(可以重置父类的默认参数，不设置的话，父类的默认参数会无效)
 */
- (void)setConfig{
    
    [super setConfig];
    
    _outputFileName = @"audioMix";
    _saveSuffixFormat = @"m4a";
    _enableCycleAdd = NO;
}

@end
