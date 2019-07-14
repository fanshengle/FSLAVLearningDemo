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
 
 @param start 开始时间
 @param duration 持续时间
 @return FSLAVTimeRange
 */
+ (instancetype)makeTimeRangeWithStart:(CMTime)start duration:(CMTime)duration;
{
    FSLAVTimeRange *timeRange = [[FSLAVTimeRange alloc] init];
    timeRange.start = start;
    timeRange.duration = duration;
    return timeRange;
}

/**
 创建一个FSLAVTimeRange对象
 
 @param startSeconds 开始时间(单位:/s)
 @param durationSeconds 持续时间 (单位:/s)
 @return FSLAVTimeRange
 */
+ (instancetype)makeTimeRangeWithStartSeconds:(Float64)startSeconds durationSeconds:(Float64)durationSeconds;
{
    FSLAVTimeRange *timeRange = [[FSLAVTimeRange alloc] init];
    
    timeRange.start = CMTimeMakeWithSeconds(startSeconds, 1*USEC_PER_SEC);
    timeRange.duration = CMTimeMakeWithSeconds(durationSeconds,1*USEC_PER_SEC);
    return timeRange;
}

/**
 创建一个FSLAVTimeRange对象
 
 @param start 开始时间
 @param end 结束时间
 @return FSLAVTimeRange
 */
+ (instancetype)makeTimeRangeWithStart:(CMTime)start end:(CMTime)end;
{
    
    FSLAVTimeRange *timeRange = [[FSLAVTimeRange alloc] init];
    
    CMTimeRange range = CMTimeRangeFromTimeToTime(start,end);
    
    timeRange.start = range.start;
    timeRange.duration = range.duration;
    return timeRange;
}

/**
 创建一个FSLAVTimeRange对象
 
 @param startSeconds 开始时间 (单位:/s)
 @param endSeconds 结束时间 (单位:/s)
 @return FSLAVTimeRange
 */
+(instancetype)makeTimeRangeWithStartSeconds:(Float64)startSeconds endSeconds:(Float64)endSeconds;
{
    
    FSLAVTimeRange *timeRange = [[FSLAVTimeRange alloc] init];
    timeRange.start = CMTimeMakeWithSeconds(startSeconds, 1*USEC_PER_SEC);
    timeRange.duration = CMTimeMakeWithSeconds(fabs(endSeconds - startSeconds), 1*USEC_PER_SEC);
    
    return timeRange;
}

- (instancetype)init;
{
    if (self = [super init])
    {
        _start = kCMTimeZero;
        _duration = kCMTimeZero;
    }
    
    return self;
}

#pragma mark - setter getter

/**
 TuSDKTimeRange转为 CMTimeRange
 
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

- (NSString *)description;
{
    // 保留三位小数，输出与系统保持一致
    return [NSString stringWithFormat:@"start: %.3f end: %.3f",self.startSeconds,self.endSeconds];
}


@end
