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
 设置默认参数配置
 */
- (void)setConfig;
{
    [super setConfig];
    
    _isAutomaticStop = NO;
    _isAcousticTimer = NO;
    _minRecordDelay = 3;
    _maxRecordDelay = -1;
}
@end
