//
//  AudioVideoDeviceSettings.h
//  AudioVideoSDK
//
//  Created by tutu on 2019/6/6.
//  Copyright © 2019 tutu. All rights reserved.
//

#import "FSLAVSettings.h"


NS_ASSUME_NONNULL_BEGIN
/**
 *  系统相册授权错误
 */
typedef NS_ENUM(NSInteger, FSLAVAssetsAuthorizationError){
    /**
     *  未定义
     */
    FSLAVAssetsAuthorizationErrorNotDetermined = 0,
    /**
     *  限制访问
     */
    FSLAVAssetsAuthorizationErrorRestricted,
    /**
     *  拒绝访问
     */
    FSLAVAssetsAuthorizationErrorDenied
};

/**
 *  系统相册授权回调
 *
 *  @param error 是否返回错误信息
 */
typedef void (^FSLAVSDKTSAssetsManagerAuthorBlock)(NSError *error);

/**
 *  系统相册授权回调
 *
 *  @param error 是否返回错误信息
 */
typedef void (^FSLAVAssetsLibraryAuthorBlock)(NSError *error);

@interface FSLAVDeviceSettings : FSLAVSettings

#pragma mark - Camera
/**
 *  测试系统摄像头授权状态
 *
 *  @return    返回是否授权
 */
+ (BOOL)hasVideoAuthor;

/**
 *  相机设备总数
 *
 *  @return 相机设备总数
 */
+ (int)getCameraCounts;

/**
 *  获取相机设备（前置或后置） 后置优先
 *
 *  @return 相机设备
 */
+ (AVCaptureDevice *)getBackOrFrontCamera;


#pragma mark - Photo
/**
 *  是否用户已授权访问系统相册
 *
 *  @return 是否用户已授权访问系统相册
 */
+ (BOOL)hasAuthor;
/**
 *  是否未决定授权
 *
 *  @return 是否未决定授权
 */
+ (BOOL)notDetermined;

/**
 *  低版本小于8.0测试系统相册授权状态
 *
 *  @param authorBlock 系统相册授权回调
 */
+ (void)lowVersionTestLibraryAuthor:(FSLAVSDKTSAssetsManagerAuthorBlock)authorBlock;

/**
 *  测试系统相册授权状态
 *
 *  @param authorBlock 系统相册授权回调
 */
+ (void)testLibraryAuthor:(FSLAVSDKTSAssetsManagerAuthorBlock)authorBlock;

#pragma mark - Microphone
/**
 *  是否用户已授权访问系统麦克风
 *
 *  @return 是否用户已授权访问系统麦克风
 */
+ (BOOL)haseMicrophoneAuthor;
@end

NS_ASSUME_NONNULL_END
