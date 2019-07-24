//
//  speedSegmentButton.h
//  FSLAVLearningDemo
//
//  Created by tutu on 2019/7/23.
//  Copyright © 2019 tutu. All rights reserved.
//

#import "SegmentButton.h"

NS_ASSUME_NONNULL_BEGIN

@interface speedSegmentButton : SegmentButton
/**
 变速音效的类型
 */
@property (nonatomic, assign) FSLAVSoundSpeedMode speedMode;

@end

NS_ASSUME_NONNULL_END
