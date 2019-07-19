//
//  FSLAVRecodeOptions.m
//  FSLAVComponent
//
//  Created by tutu on 2019/7/12.
//  Copyright © 2019 tutu. All rights reserved.
//

#import "FSLAVRecoderOptions.h"

@implementation FSLAVRecoderOptions

/**
 设置默认参数配置
 */
- (void)setConfig;
{
    [super setConfig];
    
    _isAutomaticStop = NO;
    _maxRecordDelay = 0;
}
@end
