//
//  FSLAVTimeSlice.h
//  FSLAVComponent
//
//  Created by tutu on 2019/7/20.
//  Copyright © 2019 tutu. All rights reserved.
//

#import "FSLAVTimeRange.h"
#import "FSLAVRecorderOptions.h"

NS_ASSUME_NONNULL_BEGIN

@interface FSLAVMeidaTimelineSlice : FSLAVTimeRange

// 该时间段速率  默认：FSLAVRecordSpeedMode_Normal
@property (nonatomic, assign) FSLAVRecordSpeedMode speedMode;

// 变速调整后对应的该片段时长
@property (nonatomic, assign, readonly) CMTime adjustedTime;

// 是否移除该段视频 默认：NO
@property (nonatomic, assign) BOOL isRemove;

@end

NS_ASSUME_NONNULL_END
