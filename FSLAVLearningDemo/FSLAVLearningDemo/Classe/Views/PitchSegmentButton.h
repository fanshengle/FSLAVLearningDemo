//
//  PitchSegmentButton.h
//  FSLAVLearningDemo
//
//  Created by bqlin on 2018/9/26.
//  Copyright © 2018年 tutu. All rights reserved.
//

#import "SegmentButton.h"

/**
 变声分段按钮
 */
@interface PitchSegmentButton : SegmentButton

/**
 变声音效的类型
 */
@property (nonatomic, assign) FSLAVSoundPitchType pitchType;

@end
