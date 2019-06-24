//
//  FSLAVCoreBase.m
//  FSLAVComponent
//
//  Created by tutu on 2019/6/21.
//  Copyright © 2019 tutu. All rights reserved.
//

#import "FSLAVRecordCoreBase.h"

@implementation FSLAVRecordCoreBase

@synthesize savePathURL = _savePathURL;

- (instancetype)init
{
    self = [super init];
    if (self) {
        
        _isAutomaticStop = NO;
        _maxRecordDelay = 0;
    }
    return self;
}

/**
 获取数据操作的本地路径
 
 @return 文件保存的本地目录
 */
- (NSString *)getSaveDatePath{
    
    return nil;
}


@end
