//
//  TopNavigationBar.h
//  TuSDKVideoDemo
//
//  Created by bqlin on 2018/6/20.
//  Copyright © 2018年 TuSDK. All rights reserved.
//

#import <UIKit/UIKit.h>

/**
 自定义顶部导航栏
 */
@interface TopNavigationBar : UIView

/**
 返回按钮
 */
@property (nonatomic, strong) UIButton *backButton;
/**
 标题tlab
 */
@property (nonatomic, strong) UILabel *titleLab;
/**
 右侧按钮
 */
@property (nonatomic, strong) UIButton *rightButton;

@end
