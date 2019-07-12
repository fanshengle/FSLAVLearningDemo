//
//  FSLAVMixerOptions.h
//  FSLAVComponent
//
//  Created by tutu on 2019/7/12.
//  Copyright © 2019 tutu. All rights reserved.
//

#import "FSLAVOptions.h"

NS_ASSUME_NONNULL_BEGIN

/**
 FSLAVMixer 音视频混合状态
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

@interface FSLAVMixerOptions : FSLAVOptions

/**
 音视频混合状态
 */
@property (nonatomic, readonly, assign) FSLAVAudioMixStatus status;



@end

NS_ASSUME_NONNULL_END
