//
//  BaseViewController.m
//  TuSDKVideoDemo
//
//  Created by bqlin on 2018/6/15.
//  Copyright © 2018年 TuSDK. All rights reserved.
//

#import "BaseViewController.h"

@interface BaseViewController ()

@end

@implementation BaseViewController
#pragma mark -- 设置状态栏风格
- (UIStatusBarStyle)preferredStatusBarStyle{
    
    return _StatusBarStyle;
}

#pragma mark -- 动态更新状态栏颜色
-(void)setStatusBarStyle:(UIStatusBarStyle)StatusBarStyle{
    _StatusBarStyle = StatusBarStyle;
    [self setNeedsStatusBarAppearanceUpdate];
}

#pragma mark -- 所有状态栏默认不隐藏
- (BOOL)prefersStatusBarHidden{
    
    return NO;
}
-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    
    [[UIApplication sharedApplication].keyWindow endEditing:YES];
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    // 只支持竖屏
    return UIInterfaceOrientationMaskPortrait;
}

- (BOOL)shouldAutorotate {
    // 不允许旋转
    return NO;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    // 背景色为黑色
    self.view.backgroundColor = [UIColor blackColor];
    
    //默认导航栏样式：黑字
    self.StatusBarStyle = UIStatusBarStyleDefault;
    
    //不需要系统为你设置边缘距离：iOS11以前automaticallyAdjustsScrollViewInsets设置为No，iOS11以上的新特性，这句代码必须设置，
    if (@available(iOS 11.0, *)) {
        
        [[UIScrollView appearance] setContentInsetAdjustmentBehavior:UIScrollViewContentInsetAdjustmentNever];
    }else {
        
        //automaticallyAdjustsScrollViewInsets根据按所在界面的status bar，navigationbar，与tabbar的高度，自动调整scrollview的inset,设置为no，不让viewController调整，我们自己修改布局即可~。该属性是针对scrollview及其子类的，例如tableView和collectionView，但是该属性只对控制器视图层级中第一个scrollview及其子类起作用，如果视图层级中存在多个scrollview及其子类，官方建议该属性设置为no，此时应该手动设置它的inseps:当你发现tableview莫名其妙地向下偏移导航栏的高度时，就是这个属性在作怪，将其设置为no即可
        self.automaticallyAdjustsScrollViewInsets = NO;
    }
}


@end
