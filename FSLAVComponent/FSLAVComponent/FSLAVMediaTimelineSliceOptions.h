//
//  FSLAVMediaTimelineSliceOptions.h
//  FSLAVComponent
//
//  Created by TuSDK on 2019/7/21.
//  Copyright © 2019 tutu. All rights reserved.
//

#import "FSLAVMediaOptions.h"
#import "FSLAVAudioRecorderOptions.h"

NS_ASSUME_NONNULL_BEGIN

/**
 FSLAVMediaTimelineSliceComposition
 将一个音视频的一个或多个多个片段进行（包括快慢速）编辑合成状态
 */
typedef NS_ENUM(NSInteger,FSLAVMediaTimelineSliceCompositionStatus)
{
    /**
     *  未知状态
     */
    FSLAVMediaTimelineSliceCompositionStatusUnknown,
    
    /**
     *  开始合成
     */
    FSLAVMediaTimelineSliceCompositionStatusStart,
    
    /**
     * 正在合成
     */
    FSLAVMediaTimelineSliceCompositionStatusComposing,
    
    /**
     * 操作完成
     */
    FSLAVMediaTimelineSliceCompositionStatusCompleted,
    
    /**
     * 保存失败
     */
    FSLAVMediaTimelineSliceCompositionStatusFailed,
    
    /**
     * 已取消
     */
    FSLAVMediaTimelineSliceCompositionStatusCancelled,
};

/**
 媒体资源音视频分段时间线（包括快慢速）编辑工具的配置项
 */
@interface FSLAVMediaTimelineSliceOptions : FSLAVMediaOptions

// 状态
@property (nonatomic, readonly, assign) FSLAVMediaTimelineSliceCompositionStatus status;

/**
 音频录制配置项
 */
@property (nonatomic, strong) FSLAVAudioRecorderOptions *recordOptions;


@end


NS_ASSUME_NONNULL_END
