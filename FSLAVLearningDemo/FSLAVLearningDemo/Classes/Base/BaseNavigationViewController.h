//
//  BaseNavigationViewController.h
//  TuSDKVideoDemo
//
//  Created by bqlin on 2018/6/20.
//  Copyright © 2018年 TuSDK. All rights reserved.
//

#import "BaseViewController.h"
#import "TopNavigationBar.h"

/**
 拥有自定义顶部导航栏的视图控制器
 */
@interface BaseNavigationViewController : BaseViewController

/**
 顶部自定义导航栏
 */
@property (nonatomic, strong, readonly) TopNavigationBar *topNavigationBar;

/**
 导航栏标题
 */
@property (nonatomic, strong) NSString *navTitle;

/**
 是否显示导航栏的返回按钮
 */
@property (nonatomic, assign) BOOL isShowBackBtn;

/**
 是否显示导航栏的右边按钮
 */
@property (nonatomic, assign) BOOL isShowRightBtn;


/**
 页面内容顶部偏移，即为顶部自定义导航栏高度
 */
@property (nonatomic, assign, readonly) CGFloat topContentOffset;

/**
 导航栏右侧按钮事件回调
 */
@property (nonatomic, copy) void (^rightButtonActionHandler)(__kindof BaseNavigationViewController *controller, UIButton *sender);

/**
 导航栏右侧按钮事件

 @param sender 点击的按钮
 */
- (void)base_rightButtonAction:(UIButton *)sender;

@end
