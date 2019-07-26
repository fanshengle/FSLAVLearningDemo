//
//  MarkableProgressView.h
//  FSLAVLearningDemo
//
//  Created by bqlin on 2018/7/3.
//  Copyright © 2018年 tutu. All rights reserved.
//

#import <UIKit/UIKit.h>

/**
 可标记进度视图
 */
@interface MarkableProgressView : UIProgressView

/**
 设置录制占位视图
 
 @param progress 进度
 */
- (CALayer *)addPlaceholder:(CGFloat)progress markWidth:(CGFloat)markWidth;

/**
 压入一个标记
 */
- (void)pushMark;

/**
 移除最后一个标记
 */
- (void)popMark;

/**
 重置
 */
- (void)reset;

@end
