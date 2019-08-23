//
//  FSLAVSpliceOptions.h
//  FSLAVComponent
//
//  Created by tutu on 2019/8/15.
//  Copyright © 2019 tutu. All rights reserved.
//

#import "FSLAVMediaAssetOptions.h"

NS_ASSUME_NONNULL_BEGIN

/**
 FSLAVSpliceStatus 视频拼接状态
 */
typedef NS_ENUM(NSInteger,FSLAVSpliceStatus)
{
    /**
     *  未知状态
     */
   FSLAVSpliceStatusUnknown,
    
    /**
     * 正在合并
     */
   FSLAVSpliceStatusMerging,
    
    /**
     * 合并完成
     */
   FSLAVSpliceStatusCompleted,
    
    /**
     * 保存失败
     */
   FSLAVSpliceStatusFailed,
    
    /**
     * 已取消
     */
   FSLAVSpliceStatusCancelled
    
};

@interface FSLAVSplicerOptions : FSLAVMediaAssetOptions
{
    FSLAVSpliceStatus _spliceStatus;
}

// 状态
@property (nonatomic, assign) FSLAVSpliceStatus spliceStatus;

@end

NS_ASSUME_NONNULL_END
