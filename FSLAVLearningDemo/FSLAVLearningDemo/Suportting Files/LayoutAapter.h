//
//  LayoutAapter.h
//  NewMinister
//
//  Created by 范声乐 on 2018/9/28.
//  Copyright © 2018年 范声乐. All rights reserved.
//

#ifndef LayoutAapter_h
#define LayoutAapter_h


//获取系统对象
#define NMApplication            [UIApplication sharedApplication]
#define NMAppWindow              [[[UIApplication sharedApplication] delegate] window]
#define NMShareAppDelegate       [NMAppDelegate shareAppDelegate]
#define NMRootViewController     [[[[UIApplication sharedApplication] delegate] window] rootViewController]
#define NMUserDefaults           [NSUserDefaults standardUserDefaults]
#define NMNotificationCenter     [NSNotificationCenter defaultCenter]

//取得屏幕的宽、高
#define NMScreenWidth            [[UIScreen mainScreen] bounds].size.width
#define NMScreenHeight           [[UIScreen mainScreen] bounds].size.height
#define NMScreenBounds           [[UIScreen mainScreen] bounds]

//适配的比例
#define Iphone6ScaleWidth        NMScreenWidth/375.0
//根据ip6的屏幕适配所有来拉伸(适配)
#define NMScaleValue(value)        ((value)*(NMScreenWidth/375.0f))

#define NMHeightScaleValue(value)        ((value)*(NMScreenHeight/667.0f))

//根据适配ip5需要屏幕来拉伸(适配)
#define NMRealValue(value)        (NMScreenWidth == 320 ? (value)*(NMScreenWidth/375.0f):value)

//获取各个
#define NMStatusBarHeight        [[UIApplication sharedApplication] statusBarFrame].size.height                         //状态栏高度
#define NMNavbarHeight           ([[UIApplication sharedApplication] statusBarFrame].size.height>20?84:64)              //导航栏和标签栏的总高度
#define NMTabbarHeight           ([[UIApplication sharedApplication] statusBarFrame].size.height>20?83:49)              //底部Tabbar高度

#define NMBottomBarHeight         49.0//底部按钮视图高度

//#define NMTopBarHeight           (NMStatusBarHeight + NMNavBarHeight)                                                   //导航栏和标签栏的总高度

#define NMAdapter(value1,value2)           ([[UIApplication sharedApplication] statusBarFrame].size.height>20?value1:value2)              //适配布局

//带状态栏的自适应高度
#define NMAdapterTopH(value)         ([[UIApplication sharedApplication] statusBarFrame].size.height>20?(value + 20):value)            //适配顶部布局
//带状态栏的自适应高度
#define NMAdapterBottomH(value)         ([[UIApplication sharedApplication] statusBarFrame].size.height>20?(value + 34):value)            //适配底部布局


#define AudioVideoString(key, comment) \
[[NSBundle mainBundle] localizedStringForKey:(key) value:comment table:@"AudioVideoSDK"]
#endif /* LayoutAapter_h */
