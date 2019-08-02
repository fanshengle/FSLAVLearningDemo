//
//  FSLAVCliperOptions.h
//  FSLAVComponent
//
//  Created by tutu on 2019/7/14.
//  Copyright © 2019 tutu. All rights reserved.
//

#import "FSLAVMediaAssetOptions.h"

NS_ASSUME_NONNULL_BEGIN

/**
 音视频裁剪状态
 */
typedef NS_ENUM(NSInteger,FSLAVClipStatus)
{
    /**
     *  未知状态
     */
    FSLAVClipStatusUnknown,
    
    /**
     * 正在裁剪
     */
    FSLAVClipStatusClipping,
    
    /**
     * 裁剪完成
     */
    FSLAVClipStatusCompleted,
    
    /**
     * 保存失败
     */
    FSLAVClipStatusFailed,
    
    /**
     * 已取消
     */
    FSLAVClipStatusCancelled
};

@interface FSLAVClipperOptions : FSLAVMediaAssetOptions
{
    FSLAVClipStatus _clipStatus;
}

// 状态
@property (nonatomic, assign) FSLAVClipStatus clipStatus;

@end

NS_ASSUME_NONNULL_END
