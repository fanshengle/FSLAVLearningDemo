//
//  BaseViewController.h
//  FSLAVLearningDemo
//
//  Created by bqlin on 2018/6/15.
//  Copyright © 2018年 tutu. All rights reserved.
//

#import <UIKit/UIKit.h>

/**
 用于继承的控制器基类，以统一样式
 */
@interface BaseViewController : UIViewController
/**
 *  修改状态栏颜色
 */
@property (nonatomic, assign) UIStatusBarStyle StatusBarStyle;

@end
