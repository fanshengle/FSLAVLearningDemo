//
//  FSLAVCliperAudioOptions.m
//  FSLAVComponent
//
//  Created by tutu on 2019/7/14.
//  Copyright © 2019 tutu. All rights reserved.
//

#import "FSLAVCliperAudioOptions.h"

@implementation FSLAVCliperAudioOptions

/**
 设置默认参数配置
 */
- (void)setConfig{
    [super setConfig];
    
    _outputFileName = @"audioCliper";
    _saveSuffixFormat = @"m4a";
}



@end
