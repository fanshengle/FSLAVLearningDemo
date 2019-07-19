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
 设置默认参数配置
 */
- (void)setConfig{
    
    [super setConfig];
    
    _outputFileName = @"audioMix";
    _saveSuffixFormat = @"m4a";
    _enableCycleAdd = NO;
}

@end
