//
//  FSLAVAudioRTMPFrame.h
//  FSLAVComponent
//
//  Created by tutu on 2019/7/4.
//  Copyright © 2019 tutu. All rights reserved.
//

#import "FSLAVRTMPFrame.h"

NS_ASSUME_NONNULL_BEGIN
/**
 音频数据
 */
@interface FSLAVAudioRTMPFrame : FSLAVRTMPFrame

/**
 音频信息
 */
@property (nonatomic, strong) NSData *audioInfo;

@end

NS_ASSUME_NONNULL_END
