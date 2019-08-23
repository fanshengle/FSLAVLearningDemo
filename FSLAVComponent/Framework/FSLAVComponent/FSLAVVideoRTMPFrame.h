//
//  FSLAVH264VideoRTMPFrame.h
//  FSLAVComponent
//
//  Created by tutu on 2019/6/24.
//  Copyright © 2019 tutu. All rights reserved.
//

#import "FSLAVRTMPFrame.h"

NS_ASSUME_NONNULL_BEGIN
/**
 视频数据
 */
@interface FSLAVVideoRTMPFrame : FSLAVRTMPFrame

/**
 是否关键帧
 */
@property (nonatomic, assign) BOOL isKeyFrame;

/**
 序列的参数集
 */
@property (nonatomic, strong) NSData *sps;

/**
 图像的参数集
 */
@property (nonatomic, strong) NSData *pps;

@end

NS_ASSUME_NONNULL_END
