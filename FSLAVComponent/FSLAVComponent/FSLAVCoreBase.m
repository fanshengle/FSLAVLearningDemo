//
//  FSLAVCoreBase.m
//  FSLAVComponent
//
//  Created by tutu on 2019/7/21.
//  Copyright © 2019 tutu. All rights reserved.
//

#import "FSLAVCoreBase.h"

@implementation FSLAVCoreBase

- (instancetype)init
{
    self = [super init];
    if (self) {
        
        [self setConfig];
    }
    return self;
}

/**
 设置默认参数配置
 */
- (void)setConfig;
{
    
}

/**
 销毁对象，释放对象
 */
- (void)destory;
{
    
}

- (void)dealloc{
    [self destory];
}
@end
