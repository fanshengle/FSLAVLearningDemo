//
//  speedSegmentButton.m
//  FSLAVLearningDemo
//
//  Created by tutu on 2019/7/23.
//  Copyright © 2019 tutu. All rights reserved.
//

#import "SpeedSegmentButton.h"

@implementation SpeedSegmentButton


- (void)commonInit {
    [super commonInit];
    
    self.style = SegmentButtonStylePlain;
    self.buttonTitles = @[@"极慢",@"慢速",@"正常",@"快速",@"极快"];
    self.cornerRadius = 1;
    self.selectedIndex = 2;
    self.backgroundColor = [UIColor colorWithWhite:1 alpha:.1];
    self.selectedBackgroundColor = fslRGBA(51, 51, 51, 0.5);
    [self setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self setTitleColor:fslRGB(255, 204, 0) forState:UIControlStateSelected];
}

/**
 选择特殊声效
 
 @param selectedIndex 声效对应的索引
 */
- (void)setSelectedIndex:(NSInteger)selectedIndex {
    
    [super setSelectedIndex:selectedIndex];
    switch (selectedIndex) {
        case 0:{
            // 极慢
            _speedMode = FSLAVSoundSpeedMode_Slow1;
        } break;
        case 1:{
            // 慢速
            _speedMode = FSLAVSoundSpeedMode_Slow2;
        } break;
        case 2:{
            // 原声声效（无特效）
            _speedMode = FSLAVSoundSpeedMode_Normal;
        } break;
        case 3:{
            // 快速
            _speedMode = FSLAVSoundSpeedMode_Fast1;
        } break;
        case 4:{
            // 极快
            _speedMode = FSLAVSoundSpeedMode_Fast2;
        } break;
        default:{} break;
    }
}


@end
