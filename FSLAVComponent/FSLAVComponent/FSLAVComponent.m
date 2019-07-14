//
//  FSLAVComponent.m
//  FSLAVComponent
//
//  Created by tutu on 2019/6/21.
//  Copyright © 2019 tutu. All rights reserved.
//

#import "FSLAVComponent.h"

@implementation FSLAVComponent

/**
 *  设置日志输出级别
 *
 *  @param level 日志输出级别 (默认：FSLAVLogLevelFATAL 不输出)
 */
+ (void)setLogLevel:(FSLAVLogLevel)level;
{
    [FSLAVLog sharedLog].outputLevel = level;
}

@end
