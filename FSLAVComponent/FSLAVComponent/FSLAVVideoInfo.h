//
//  FSLAVVideoInfo.h
//  FSLAVComponent
//
//  Created by tutu on 2019/7/15.
//  Copyright © 2019 tutu. All rights reserved.
//

#import "FSLAVMediaInfo.h"
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class FSLAVVideoTrackInfo;


/**
 媒体素材中的视频信息
 */
@interface FSLAVVideoInfo : FSLAVMediaInfo

/**
 视频中所有轨道信息
 */
@property (nonatomic,readonly) NSArray<FSLAVVideoTrackInfo *> *videoTrackInfoArray;

/**
 是否为4k视频
  */
@property(nonatomic, readonly) BOOL is4K;

@end


#pragma mark - FSLAVVideTrackInfo

/**
 * 视频image方向，ImageOrientation
 */
typedef NS_ENUM(NSUInteger, FSLAVVideoImageRotationMode) {
    
    FSLAVVideoImageNoRotation,
    FSLAVVideoImageRotateLeft,
    FSLAVVideoImageRotateRight,
    FSLAVVideoImageFlipVertical,
    FSLAVVideoImageFlipHorizonal,
    FSLAVVideoImageRotateRightFlipVertical,
    FSLAVVideoImageRotateRightFlipHorizontal,
    FSLAVVideoImageRotate180
};
/**
 * 视频轨道信息
 */
@interface FSLAVVideoTrackInfo : NSObject

/**
 轨道引用的媒体数据的自然维度。
 */
@property (nonatomic,readonly) CGSize naturalSize;

/**
 通过得到的naturalSize纬度，设置当前状态下合适维度
 */
@property (nonatomic,readonly) CGSize presentSize;

/*!
  轨道的帧速率，以帧每秒为单位。
 */
@property (nonatomic,readonly) CGFloat nominalFrameRate;

/**
 跑道框架的最小持续时间。
 */
@property (nonatomic, readonly) CMTime minFrameDuration;

/**
 视频宽高是否需要交换
 */
@property(nonatomic, readonly) BOOL isTransposedSize;

/**
 在轨道的存储容器中指定的转换，作为用于显示目的的可视化媒体数据的首选转换。
 */
@property (nonatomic,readonly) CGAffineTransform preferredTransform;

/**
 轨道引用的媒体数据的估计数据速率，以比特每秒为单位。
 */
@property (nonatomic, readonly) float estimatedDataRate;

/**
 rotation
 */
@property(nonatomic, readonly) FSLAVVideoImageRotationMode orientation;


/**
 FSLAVVideoTrackInfo
 
 @param videoTrack FSLAVVideoTrackInfo
 @return FSLAVVideoTrackInfo
 */
+ (instancetype)trackInfoWithVideoAssetTrack:(AVAssetTrack *)videoTrack;

/**
 根据 AVAssetTrack 初始化 FSLAVVideoTrackInfo
 
 @param videoTrack AVAssetTrack
 @return FSLAVVideoTrackInfo
 */
- (instancetype)initWithVideoAssetTrack:(AVAssetTrack *)videoTrack;

@end

NS_ASSUME_NONNULL_END
