//
//  FSLAVTImeRange.h
//  FSLAVComponent
//
//  Created by tutu on 2019/7/12.
//  Copyright © 2019 tutu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN


/**
 时间配置类，音视频合成、剪辑、拼接等功能中会使用到
 */
@interface FSLAVTimeRange : NSObject<NSCopying>

#pragma mark - Properties

/**
 开始时间
 */
@property (nonatomic,assign) CMTime start;

/**
 持续时间
 */
@property (nonatomic,assign) CMTime duration;

/**
 结束时间 只读类型 若需要修改结束时间,请通过修改duration进行
 */
@property (nonatomic,assign) CMTime end;

/**
 开始时间
 */
@property (nonatomic,assign,readonly) Float64 startSeconds;

/**
 持续时间
 */
@property (nonatomic,assign,readonly) Float64 durationSeconds;

/**
 结束时间 只读类型 若需要修改结束时间,请通过修改duration进行
 */
@property (nonatomic,assign,readonly) Float64 endSeconds;

/**
 时间范围
 */
@property (nonatomic,assign,readonly) CMTimeRange CMTimeRange;

/**
 标识该时间区间是否为倒序， @return true/false
 */
@property (nonatomic, readonly) BOOL isReverse;

/**
 标识该时间区间是否有效， @return true/false
 */
@property (nonatomic, readonly) BOOL isValid;

#pragma mark - MAKE

/**
 创建一个FSLAVTimeRange对象
 
 @param startTime 开始时间
 @param duration 持续时间
 @return FSLAVTimeRange
 */
+ (instancetype)timeRangeWithStartTime:(CMTime)startTime duration:(CMTime)duration;

/**
 创建一个FSLAVTimeRange对象
 
 @param startSeconds 开始时间
 @param durationSeconds 持续时间
 @return FSLAVTimeRange
 */
+ (instancetype)timeRangeWithStartSeconds:(Float64)startSeconds durationSeconds:(Float64)durationSeconds;

/**
 创建一个FSLAVTimeRange对象
 
 @param startTime 开始时间
 @param endTime 结束时间
 @return FSLAVTimeRange
 */
+ (instancetype)timeRangeWithStartTime:(CMTime)startTime endTime:(CMTime)endTime;

/**
 创建一个FSLAVTimeRange对象
 
 @param startSeconds 开始时间
 @param endSeconds 结束时间
 @return FSLAVTimeRange
 */
+ (instancetype)timeRangeWithStartSeconds:(Float64)startSeconds endSeconds:(Float64)endSeconds;

/**
 初始化方法
 
 @param startTime 开始时间
 @param duration 持续时间
 @return FSLAVTimeRange
 */
- (instancetype)initWithStartTime:(CMTime)startTime duration:(CMTime)duration;

/**
 初始化方法
 
 @param startSeconds 开始时间
 @param durationSeconds 持续时间
 @return FSLAVTimeRange
 */
- (instancetype)initWithStartSeconds:(Float64)startSeconds durationSeconds:(Float64)durationSeconds;

/**
 初始化方法
 
 @param startTime 开始时间
 @param endTime 结束时间
 @return FSLAVTimeRange
 */
- (instancetype)initWithStartTime:(CMTime)startTime endTime:(CMTime)endTime;

/**
 初始化方法
 
 @param startSeconds 开始时间
 @param endSeconds 结束时间
 @return FSLAVTimeRange
 */
- (instancetype)initWithStartSeconds:(Float64)startSeconds endSeconds:(Float64)endSeconds;

#pragma mark - Methods

/**
 设置默认参数配置
 */
- (void)setConfig;

/**
 是否包含另一个timeRange
 
 @return true/false
 */
- (BOOL)containsTimeRange:(FSLAVTimeRange *)timeRange;

/**
 校验另一个 timeRange，得到一个新的包含在内的 timeRange
 
 @return 校验后的 timerange
 */
- (FSLAVTimeRange *)verifyOtherTimeRange:(FSLAVTimeRange *)timeRange;

@end

NS_ASSUME_NONNULL_END
