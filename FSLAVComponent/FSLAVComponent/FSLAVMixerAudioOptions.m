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
 重置默认参数配置
 */
- (void)resetConfig{
    
    [super resetConfig];
    
    _mixStatus = FSLAVMixStatusUnknown;
    _outputFileName = @"audioMix";
    _saveSuffixFormat = @"m4a";
    _enableCycleAdd = NO;
}

@end
