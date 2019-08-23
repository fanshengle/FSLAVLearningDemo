//
//  FSLAVMixerOptions.h
//  FSLAVComponent
//
//  Created by tutu on 2019/7/12.
//  Copyright © 2019 tutu. All rights reserved.
//

#import "FSLAVMediaAssetOptions.h"

NS_ASSUME_NONNULL_BEGIN

/**
 音频混合状态
 */
typedef NS_ENUM(NSInteger,FSLAVMixStatus)
{
    /**
     *  未知状态
     */
    FSLAVMixStatusUnknown,
    
    /**
     * 正在混合
     */
    FSLAVMixStatusMixing,
    
    /**
     * 操作完成
     */
    FSLAVMixStatusCompleted,
    
    /**
     * 操作失败
     */
    FSLAVMixStatusFailed,
    
    /**
     * 已取消
     */
    FSLAVMixStatusCancelled
    
};

@interface FSLAVMixerOptions : FSLAVMediaAssetOptions
{
    FSLAVMixStatus _mixStatus;
}

/**
 音视频混合状态
 */
@property (nonatomic, assign) FSLAVMixStatus mixStatus;

// 音轨是否可循环添加播放 默认 NO 不循环
@property (nonatomic, assign) BOOL enableCycleAdd;

@end

NS_ASSUME_NONNULL_END
