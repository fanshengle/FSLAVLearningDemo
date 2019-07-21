//
//  FSLAVTImeRange.m
//  FSLAVComponent
//
//  Created by tutu on 2019/7/12.
//  Copyright © 2019 tutu. All rights reserved.
//

#import "FSLAVTimeRange.h"

@implementation FSLAVTimeRange

#pragma mark - MAKE

/**
 创建一个FSLAVTimeRange对象
 
 @param startTime 开始时间
 @param duration 持续时间
 @return FSLAVTimeRange
 */
+ (instancetype)timeRangeWithStartTime:(CMTime)startTime duration:(CMTime)duration;
{
    return [[self alloc] initWithStartTime:startTime duration:duration];
}

/**
 创建一个FSLAVTimeRange对象
 
 @param startSeconds 开始时间(单位:/s)
 @param durationSeconds 持续时间 (单位:/s)
 @return FSLAVTimeRange
 */
+ (instancetype)timeRangeWithStartSeconds:(Float64)startSeconds durationSeconds:(Float64)durationSeconds;
{
    return [[self alloc] initWithStartSeconds:startSeconds durationSeconds:durationSeconds];
}

/**
 创建一个FSLAVTimeRange对象
 
 @param startTime 开始时间
 @param endTime 结束时间
 @return FSLAVTimeRange
 */
+ (instancetype)timeRangeWithStartTime:(CMTime)startTime endTime:(CMTime)endTime;
{
    return [[self alloc] initWithStartTime:startTime endTime:endTime];
}

/**
 创建一个FSLAVTimeRange对象
 
 @param startSeconds 开始时间 (单位:/s)
 @param endSeconds 结束时间 (单位:/s)
 @return FSLAVTimeRange
 */
+(instancetype)timeRangeWithStartSeconds:(Float64)startSeconds endSeconds:(Float64)endSeconds;
{
    
    FSLAVTimeRange *timeRange = [[FSLAVTimeRange alloc] init];
    timeRange.start = CMTimeMakeWithSeconds(startSeconds, 1*USEC_PER_SEC);
    timeRange.duration = CMTimeMakeWithSeconds(fabs(endSeconds - startSeconds), 1*USEC_PER_SEC);
    timeRange.end = CMTimeAdd(timeRange.start, timeRange.duration);
    return timeRange;
}

/**
 初始化方法
 
 @param startTime 开始时间
 @param duration 持续时间
 @return FSLAVTimeRange
 */
- (instancetype)initWithStartTime:(CMTime)startTime duration:(CMTime)duration;
{
    if (self == [self init]) {
        
        _start = startTime;
        _duration = duration;
        _end = CMTimeAdd(startTime, duration);
    }
    return self;
}

/**
 初始化方法
 
 @param startSeconds 开始时间
 @param durationSeconds 持续时间
 @return FSLAVTimeRange
 */
- (instancetype)initWithStartSeconds:(Float64)startSeconds durationSeconds:(Float64)durationSeconds;
{
    if (self == [self init]) {
        
        _start = CMTimeMakeWithSeconds(startSeconds, 1*USEC_PER_SEC);
        _duration = CMTimeMakeWithSeconds(durationSeconds,1*USEC_PER_SEC);
        _end = CMTimeAdd(_start, _duration);
    }
    return self;
}


/**
 初始化方法
 
 @param startTime 开始时间
 @param endTime 结束时间
 @return FSLAVTimeRange
 */
- (instancetype)initWithStartTime:(CMTime)startTime endTime:(CMTime)endTime;
{
    if (self == [self init]) {
        _start = startTime;
        _end = endTime;
        _duration = CMTimeSubtract(endTime, startTime);
    }
    return self;
}

/**
 初始化方法
 
 @param startSeconds 开始时间
 @param endSeconds 结束时间
 @return FSLAVTimeRange
 */
- (instancetype)initWithStartSeconds:(Float64)startSeconds endSeconds:(Float64)endSeconds;
{
    if (self == [self init]) {
        
        _start = CMTimeMakeWithSeconds(startSeconds, 1*USEC_PER_SEC);
        _duration = CMTimeMakeWithSeconds(fabs(endSeconds - startSeconds), 1*USEC_PER_SEC);
        _end = CMTimeAdd(_start, _duration);
    }
    return self;
}

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
    _start = kCMTimeZero;
    _duration = kCMTimeZero;
    _end = kCMTimeZero;
}
#pragma mark - setter getter

/**
 FSLAVTimeRange转为 CMTimeRange
 
 @return CMTimeRange
 */
- (CMTimeRange)CMTimeRange;
{
    return CMTimeRangeMake(self.start, self.duration);
}

/**
 开始时间秒数
 @return 秒数
 */
- (Float64)startSeconds;
{
    return CMTimeGetSeconds(self.start);
}

/**
 持续时间(秒)
 @return 持续时间
 */
- (Float64)durationSeconds;
{
    return CMTimeGetSeconds(self.duration);
}

/**
 结束时间(秒)
 @return 结束时间
 */
- (Float64)endSeconds;
{
    return CMTimeGetSeconds(CMTimeRangeGetEnd(self.CMTimeRange));
}

/**
 持续时间
 @return 持续时间
 */
- (CMTime)duration;
{
    // 倒序
    if ([self isReverse]) {
        return CMTimeSubtract(_start, _end);
    }
    return CMTimeSubtract(_end, _start);
}

/**
 标识该时间区间是否为倒序
 @return true/false
 */
- (BOOL)isReverse;
{
    return CMTIME_COMPARE_INLINE(_start, >, _end);
}

/**
 时间范围是否有效
 @return true/false
 */
- (BOOL)isValid;
{
    return CMTIMERANGE_IS_VALID(self.CMTimeRange);
}

/**
 是否包含另一个timeRange
 @return true/false
 */
- (BOOL)containsTimeRange:(FSLAVTimeRange *)timeRange;
{
    if (CMTIME_COMPARE_INLINE(timeRange.start, <, self.start) || CMTIME_COMPARE_INLINE(CMTimeAdd(timeRange.start, timeRange.duration), >, CMTimeAdd(self.start, self.duration))) {
        return NO;
    }
    return YES;
}

/**
 校验另一个 timeRange，得到一个新的包含在内的 timeRange
 @return 校验后的 timerange
 */
- (FSLAVTimeRange *)verifyOtherTimeRange:(FSLAVTimeRange *)timeRange;
{
    if (CMTIME_COMPARE_INLINE(timeRange.start, <, self.start) || CMTIME_COMPARE_INLINE(timeRange.start, >=, CMTimeAdd(self.start, self.duration))) {
        timeRange.start = self.start;
    }
    
    if (CMTIME_COMPARE_INLINE(CMTimeAdd(timeRange.start, timeRange.duration), >, self.duration)) {
        timeRange.duration = CMTimeSubtract(self.duration, timeRange.start);
    }
    
    return timeRange;
}

#pragma mark -- NSObject methods
/**
 实现拷贝协议
 
 @param zone NSZone
 @return FSLAVTimeRange
 */
- (id)copyWithZone:(NSZone *)zone;
{
    FSLAVTimeRange *timeRange = [[FSLAVTimeRange alloc] initWithStartTime:self.start endTime:self.end];
    return timeRange;
}


- (NSString *)description;
{
    // 保留三位小数，输出与系统保持一致
    return [NSString stringWithFormat:@"start: %.3f endTime: %.3f",self.startSeconds,self.endSeconds];
}


@end
