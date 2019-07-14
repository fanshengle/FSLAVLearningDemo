//
//  FSLAVCliperAudioOptions.m
//  FSLAVComponent
//
//  Created by TuSDK on 2019/7/14.
//  Copyright © 2019 tutu. All rights reserved.
//

#import "FSLAVCliperAudioOptions.h"

@implementation FSLAVCliperAudioOptions

/**
 重置默认参数配置
 */
- (void)resetConfig{
    [super resetConfig];
    
    _clipStatus = FSLAVClipStatusUnknown;
    _outputFileName = @"audioCliper";
    _saveSuffixFormat = @"m4a";
}



@end
