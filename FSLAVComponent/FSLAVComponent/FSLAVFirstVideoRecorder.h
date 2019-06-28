//
//  VideoFirstRecorder.h
//  AudioVideoSDK
//
//  Created by tutu on 2019/6/14.
//  Copyright © 2019 tutu. All rights reserved.
//

#import "FSLAVRecordVideoCoreBase.h"
#import "FSLAVVideoRecorderInterface.h"

NS_ASSUME_NONNULL_BEGIN

/**
 视频第一选择录制器
 */

@interface FSLAVFirstVideoRecorder : FSLAVRecordVideoCoreBase<FSLAVVideoRecorderInterface>
{
    FSLAVVideoRecorderConfiguration *_configuration;
}

/**
 视频配置项
 */
@property (nonatomic, strong , readonly) FSLAVVideoRecorderConfiguration *configuration;

/**
 代理
 */
@property (nonatomic, weak) id<FSLAVVideoRecorderDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
