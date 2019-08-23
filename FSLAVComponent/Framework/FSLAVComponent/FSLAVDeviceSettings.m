//
//  AudioVideoDeviceSettings.m
//  AudioVideoSDK
//
//  Created by tutu on 2019/6/6.
//  Copyright © 2019 tutu. All rights reserved.
//

#import "FSLAVDeviceSettings.h"

/**
 *  设备权限设置
 */
@interface FSLAVDeviceSettings()

@end

@implementation FSLAVDeviceSettings

#pragma mark - Camera

/**
 *  测试系统摄像头授权状态
 *
 *  @return    返回是否授权
 */
+ (BOOL)hasVideoAuthor;
{
    if ([self getSystemFloatVersion] < 7.0) return YES;
    
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    
    if(authStatus == AVAuthorizationStatusAuthorized || authStatus == AVAuthorizationStatusNotDetermined)return YES;
    
    return NO;
}
/**
 *  相机设备总数
 *
 *  @return 相机设备总数
 */
+ (int)getCameraCounts;
{
    
    int count = 0;
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in devices)
    {
        switch ([device position]) {
            case AVCaptureDevicePositionBack:
            case AVCaptureDevicePositionFront:
                count++;
                break;
            default:
                break;
        }
    }
    return count;
}

/**
 *  获取相机设备（前置或后置） 后置优先
 *
 *  @return 相机设备
 */
+ (AVCaptureDevice *)getBackOrFrontCamera;
{
    AVCaptureDevice *frontCamera = nil;
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in devices)
    {
        switch ([device position]) {
            case AVCaptureDevicePositionBack:
                return device;
            case AVCaptureDevicePositionFront:
                frontCamera = device;
                break;
            default:
                break;
        }
    }
    return frontCamera;
}

#pragma mark - Photo
/**
 *  是否用户已授权访问系统相册
 *
 *  @return 是否用户已授权访问系统相册
 */
+ (BOOL)hasAuthor;
{
    int version = [[[UIDevice currentDevice] systemVersion] intValue];
    
    if (version < 6.0) {
        return YES;
    }
    else if (version < 8.0)
    {
        ALAuthorizationStatus status = [ALAssetsLibrary authorizationStatus];
        return status == ALAuthorizationStatusAuthorized;
    }
    else
    {
        PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];
        return status == PHAuthorizationStatusAuthorized;
    }
}

/**
 *  是否未决定授权
 *
 *  @return 是否未决定授权
 */
+ (BOOL)notDetermined;
{
    int version = [[[UIDevice currentDevice] systemVersion] intValue];
    
    if (version < 6.0) {
        return YES;
    }
    else if (version < 8.0)
    {
        ALAuthorizationStatus status = [ALAssetsLibrary authorizationStatus];
        return status == ALAuthorizationStatusNotDetermined;
    }
    else
    {
        PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];
        return status == PHAuthorizationStatusNotDetermined;
    }
}

/**
 获取系统相册对象
 
 @return 返回系统相册对象
 */
+ (ALAssetsLibrary *)getDefaultLibrary;
{
    static dispatch_once_t pred = 0;
    static ALAssetsLibrary *library = nil;
    dispatch_once(&pred, ^{
        library = [[ALAssetsLibrary alloc] init];
    });
    return library;
}

/**
 *  低版本小于8.0测试系统相册授权状态
 *
 *  @param authorBlock 系统相册授权回调
 */
+ (void)lowVersionTestLibraryAuthor:(FSLAVSDKTSAssetsManagerAuthorBlock)authorBlock;
{
    if (!authorBlock) return;
    NSError *error = nil;
    if ([self hasAuthor]){
        authorBlock(error);
        return;
    };
    
    // 测试授权
    [[self getDefaultLibrary] enumerateGroupsWithTypes:ALAssetsGroupLibrary usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
        *stop = YES;
        // 为空时是最后一次执行
        if (!group) {
            NSError *error = nil;
            authorBlock(error);
        }
    } failureBlock:^(NSError *error) {
        authorBlock(error);
    }];
}

/**
 *  测试系统相册授权状态
 *
 *  @param authorBlock 系统相册授权回调
 */
+ (void)testLibraryAuthor:(FSLAVSDKTSAssetsManagerAuthorBlock)authorBlock;
{
    if (!authorBlock) return;
    
    if ([self hasAuthor]){
        NSError *error = nil;
        authorBlock(error);
        return;
    };
    
    if ([[[UIDevice currentDevice] systemVersion] intValue] < 8.0) {
        [self lowVersionTestLibraryAuthor:^(NSError * _Nonnull error) {
            authorBlock(error);
        }];
        return;
    }
    
    [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
        
        NSError *error = nil;
        
        if (status != PHAuthorizationStatusAuthorized) {
            NSInteger code = FSLAVAssetsAuthorizationErrorNotDetermined;
            switch (status) {
                case FSLAVAssetsAuthorizationErrorRestricted:
                    code = FSLAVAssetsAuthorizationErrorRestricted;
                    break;
                case PHAuthorizationStatusDenied:
                    code = FSLAVAssetsAuthorizationErrorDenied;
                    break;
                default:
                    break;
            }
            error = [NSError errorWithDomain:[NSString stringWithFormat:@"%@", [self class]]
                                        code:code userInfo:nil];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            authorBlock(error);
        });
    }];
}


#pragma mark - Microphone
/**
 *  是否用户已授权访问系统麦克风
 *
 *  @return 是否用户已授权访问系统麦克风
 */
+ (BOOL)haseMicrophoneAuthor;
{
    int version = [[[UIDevice currentDevice] systemVersion] intValue];
    BOOL isAuthorization = YES;
    if (version < 7.0) {
        isAuthorization = YES;
    }
    AVAuthorizationStatus videoAuthStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeAudio];
    if (videoAuthStatus == AVAuthorizationStatusNotDetermined) {// 未询问用户是否授权
        AVAudioSession *audioSession = [AVAudioSession sharedInstance];
        //方式1:
        __block BOOL isAuthorizationWeak;
        [audioSession requestRecordPermission:^(BOOL granted) {
            isAuthorizationWeak = granted;
            if (granted) {
                
                NSLog(@"麦克风打开了");
            } else {
                
                NSLog(@"麦克风关闭了");
            }
        }];
        isAuthorization = isAuthorizationWeak;
        //方式2:
//        if ([audioSession respondsToSelector:@selector(requestRecordPermission:)]) {
//            [audioSession performSelector:@selector(requestRecordPermission:) withObject:^(BOOL granted) {
//                isAuthorization = granted;

//            }];
//        }
    } else if(videoAuthStatus == AVAuthorizationStatusRestricted || videoAuthStatus == AVAuthorizationStatusDenied) {
        // 未授权
        return NO;
    } else{
        // 已授权
        return YES;
    }
    return YES;
}

@end
