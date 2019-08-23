//
//  AudioVideoDeviceuAthorizationSettings.h
//  AudioVideoSDK
//
//  Created by tutu on 2019/6/6.
//  Copyright © 2019 tutu. All rights reserved.
//

#import "FSLAVDeviceSettings.h"

NS_ASSUME_NONNULL_BEGIN

/**
 *  设备权限设置类型
 */
typedef NS_ENUM(NSInteger, FSLAVDeviceAthorizationSettingsType)
{
    /**
     *  未知类型
     */
    FSLAVDeviceAthorizationSettingsUnknow,
    /**
     *  设置照片权限
     */
    FSLAVDeviceAthorizationSettingsPhoto,
    /**
     * 设置相机权限
     */
    FSLAVDeviceAthorizationSettingsCamera,
    /**
     * 设置定位权限
     */
    FSLAVDeviceAthorizationSettingsLocation,
    /**
     *  设置照片权限
     */
    FSLAVDeviceAthorizationSettingsMicrophone,
    /**其他权限设置*/
};

/**
 *  设备权限设置
 *
 *  @param type        设备权限设置类型
 *  @param openSetting 是否开启权限设置
 */
typedef void (^FSLAVDeviceAthorizationSettingsBlock)(FSLAVDeviceAthorizationSettingsType type, BOOL openSetting);

@interface FSLAVDeviceAthorizationSettings : FSLAVDeviceSettings


/**
 *  检查设备权限
 *
 *  @param controller UIViewController
 *  @param type       设备权限设置类型
 *  @param completed  设备权限设置
 */
+ (void)checkAllowWithController:(UIViewController *)controller type:(FSLAVDeviceAthorizationSettingsType)type completed:(FSLAVDeviceAthorizationSettingsBlock)completed;

@end

NS_ASSUME_NONNULL_END
