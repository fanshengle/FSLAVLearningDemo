//
//  AudioVideoSettings.m
//  AudioVideoSDK
//
//  Created by tutu on 2019/6/6.
//  Copyright © 2019 tutu. All rights reserved.
//

#import "FSLAVSettings.h"

@implementation FSLAVSettings

/**
 *  获取应用名称
 *
 *  @return 应用名称
 */
+ (NSString *)getAppName;
{
    NSString *appName = [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString *)kCFBundleNameKey];
    
    // 从InfoPlist.strings 读取
    if (!appName) appName = [[NSBundle mainBundle] localizedStringForKey:@"CFBundleDisplayName" value:nil table:@"InfoPlist"];
    
    return appName;
}

/**
 *  系统版本号
 *
 *  @return 系统版本号 e.g. @"4.0"
 */
+ (CGFloat)getSystemFloatVersion;
{
    return [[self getSystemVersion] floatValue];
}

/**
 *  系统版本号
 *
 *  @return 系统版本号 e.g. @"4.0.2"
 */
+ (NSString *)getSystemVersion;
{
    return [[UIDevice currentDevice] systemVersion];
}

/**
 *  开启应用设置页面
 */
+ (void)openAppSettings  NS_AVAILABLE_IOS(8_0);
{
    if ([self getSystemFloatVersion] < 8.0) return;
    if([self getSystemFloatVersion] < 10.0){
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString: UIApplicationOpenSettingsURLString]];
    }else{
        
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString: UIApplicationOpenSettingsURLString] options:@{} completionHandler:nil];
    }
}
@end
