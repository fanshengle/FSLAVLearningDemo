//
//  FSLAVCoreBase.m
//  FSLAVComponent
//
//  Created by tutu on 2019/6/21.
//  Copyright © 2019 tutu. All rights reserved.
//

#import "FSLAVRecordCoreBase.h"

@implementation FSLAVRecordCoreBase

- (void)dealloc{
    
    [self removeRecordTimer];
}

#pragma mark --  定时器
//添加定时器
- (void)addRecordTimer
{
    if (!_recordTimer) {
        
        _recordTime = 0;
        _recordTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(recordTimerAction) userInfo:nil repeats:YES];
        [[NSRunLoop mainRunLoop] addTimer:_recordTimer forMode:NSRunLoopCommonModes];
    }
}

//定时器事件
- (void)recordTimerAction
{
    _recordTime ++;
    if (self.delegate && [self.delegate respondsToSelector:@selector(didChangeRecordTime:)]) {
        [self.delegate didChangeRecordTime:_recordTime];
    }
    //NSLog(@"++++++++>>>%ld",(long)self.recordTime);
}

//移除定时器
- (void)removeRecordTimer
{
    [_recordTimer invalidate];
    _recordTimer = nil;
}


@end
