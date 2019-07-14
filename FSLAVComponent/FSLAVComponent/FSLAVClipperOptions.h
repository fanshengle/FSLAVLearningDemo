//
//  FSLAVCliperOptions.h
//  FSLAVComponent
//
//  Created by TuSDK on 2019/7/14.
//  Copyright © 2019 tutu. All rights reserved.
//

#import "FSLAVAudioOptions.h"

NS_ASSUME_NONNULL_BEGIN

/**
 TuSDKMovieClipper 视频裁剪状态
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

@interface FSLAVClipperOptions : FSLAVAudioOptions
{
    FSLAVClipStatus _clipStatus;
}
// 状态
@property (nonatomic, readonly, assign) FSLAVClipStatus clipStatus;


@end

NS_ASSUME_NONNULL_END
