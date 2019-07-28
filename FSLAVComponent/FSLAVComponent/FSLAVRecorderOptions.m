//
//  FSLAVRecodeOptions.m
//  FSLAVComponent
//
//  Created by tutu on 2019/7/12.
//  Copyright © 2019 tutu. All rights reserved.
//

#import "FSLAVRecorderOptions.h"

@implementation FSLAVRecorderOptions

/**
 设置默认参数配置(可以重置父类的默认参数，不设置的话，父类的默认参数会无效)
 */
- (void)setConfig;
{
    [super setConfig];
    
    _recordMode = FSLAVRecordModeNormal;
    _recordSpeedMode = FSLAVRecordSpeedMode_Normal;
    
    _isAcousticTimer = NO;
    _minRecordDelay = 3;
    _maxRecordDelay = -1;
}

@end
