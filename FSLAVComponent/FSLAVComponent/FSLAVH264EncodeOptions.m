//
//  FSLAVH264Videooptions.m
//  FSLAVComponent
//
//  Created by tutu on 2019/6/24.
//  Copyright © 2019 tutu. All rights reserved.
//

#import "FSLAVH264EncodeOptions.h"

@implementation FSLAVH264EncodeOptions

#pragma mark -- public methods
//必须走一下父类的方法；为了一些父类的默认参数生效
- (instancetype)init
{
    self = [super init];
    if (self) {
        
    }
    return self;
}

/**
 默认视频配置
 
 @return FSLAVH264EncodeOptions
 */
+ (instancetype)defaultOptions{
    
    FSLAVH264EncodeOptions *options = [FSLAVH264EncodeOptions defaultOptionsForQuality: FSLAVH264VideoQuality_Default];
    return options;
}

/**
 视频配置(质量)
 
 @param videoQuality 视频质量
 @return FSLAVH264EncodeOptions
 */
+ (instancetype)defaultOptionsForQuality:( FSLAVH264VideoQuality)videoQuality{
    
    FSLAVH264EncodeOptions *options = [FSLAVH264EncodeOptions defaultOptionsForQuality:videoQuality outputImageOrientation:UIInterfaceOrientationPortrait];
    return options;
}
/**
 视频配置(质量&是否是横屏)
 
 @param videoQuality 视频质量
 @param outputImageOrientation 屏幕方向
 @return FSLAVH264EncodeOptions
 */
+ (instancetype)defaultOptionsForQuality:( FSLAVH264VideoQuality)videoQuality outputImageOrientation:(UIInterfaceOrientation)outputImageOrientation{
    
    FSLAVH264EncodeOptions *options = [FSLAVH264EncodeOptions new];
    switch (videoQuality)
    {
        case  FSLAVH264VideoQuality_Low1:
        {
            options.sessionPreset = FSLAVH264CaptureSessionPreset360x640;
            options.videoFrameRate = 15;
            options.videoBitRate = 500 * 1000;
            options.videoMaxBitRate = 600 * 1000;
            options.videoMinBitRate = 400 * 1000;
            options.videoSize = CGSizeMake(360, 640);
        }
            break;
        case  FSLAVH264VideoQuality_Low2:
        {
            options.sessionPreset = FSLAVH264CaptureSessionPreset360x640;
            options.videoFrameRate = 20;
            options.videoBitRate = 600 * 1000;
            options.videoMaxBitRate = 720 * 1000;
            options.videoMinBitRate = 500 * 1000;
            options.videoSize = CGSizeMake(360, 640);
        }
            break;
        case  FSLAVH264VideoQuality_Low3:
        {
            options.sessionPreset = FSLAVH264CaptureSessionPreset360x640;
            options.videoFrameRate = 30;
            options.videoBitRate = 800 * 1000;
            options.videoMaxBitRate = 960 * 1000;
            options.videoMinBitRate = 600 * 1000;
            options.videoSize = CGSizeMake(360, 640);
        }
            break;
        case  FSLAVH264VideoQuality_Medium1:
        {
            options.sessionPreset = FSLAVH264CaptureSessionPreset540x960;
            options.videoFrameRate = 15;
            options.videoBitRate = 800 * 1000;
            options.videoMaxBitRate = 960 * 1000;
            options.videoMinBitRate = 500 * 1000;
            options.videoSize = CGSizeMake(540, 960);
        }
            break;
        case  FSLAVH264VideoQuality_Medium2:
        {
            options.sessionPreset = FSLAVH264CaptureSessionPreset540x960;
            options.videoFrameRate = 20;
            options.videoBitRate = 800 * 1000;
            options.videoMaxBitRate = 960 * 1000;
            options.videoMinBitRate = 500 * 1000;
            options.videoSize = CGSizeMake(540, 960);
        }
            break;
        case  FSLAVH264VideoQuality_Medium3:
        {
            options.sessionPreset = FSLAVH264CaptureSessionPreset540x960;
            options.videoFrameRate = 30;
            options.videoBitRate = 1000 * 1000;
            options.videoMaxBitRate = 1200 * 1000;
            options.videoMinBitRate = 500 * 1000;
            options.videoSize = CGSizeMake(540, 960);
        }
            break;
        case  FSLAVH264VideoQuality_High1:
        {
            options.sessionPreset = FSLAVH264CaptureSessionPreset720x1280;
            options.videoFrameRate = 15;
            options.videoBitRate = 1000 * 1000;
            options.videoMaxBitRate = 1200 * 1000;
            options.videoMinBitRate = 500 * 1000;
            options.videoSize = CGSizeMake(720, 1280);
        }
            break;
        case  FSLAVH264VideoQuality_High2:
        {
            options.sessionPreset = FSLAVH264CaptureSessionPreset720x1280;
            options.videoFrameRate = 20;
            options.videoBitRate = 1200 * 1000;
            options.videoMaxBitRate = 1440 * 1000;
            options.videoMinBitRate = 800 * 1000;
            options.videoSize = CGSizeMake(720, 1280);
        }
            break;
        case  FSLAVH264VideoQuality_High3:
        {
            options.sessionPreset = FSLAVH264CaptureSessionPreset720x1280;
            options.videoFrameRate = 30;
            options.videoBitRate = 1200 * 1000;
            options.videoMaxBitRate = 1440 * 1000;
            options.videoMinBitRate = 500 * 1000;
            options.videoSize = CGSizeMake(720, 1280);
        }
            break;
        default:
            break;
    }
    options.videoProfileLevel =  (__bridge NSString *)(kVTProfileLevel_H264_Baseline_4_0);
    options.sessionPreset = [options supportSessionPreset:options.sessionPreset];
    options.videoMaxKeyframeInterval = options.videoFrameRate*3;

    options.outputFileName = @"h264File";
    options.saveSuffixFormat =  @"h264";
    
    return options;
}

/**
 设置默认参数配置(可以重置父类的默认参数，不设置的话，父类的默认参数会无效)
 */
- (void)setConfig;
{
    [super setConfig];
}

#pragma mark -- private methods

/**
 切换视频分辨率
 
 @param sessionPreset 视频分辨率
 @return sessionPreset 当前视频分辨率
 */
- (FSLAVH264CaptureSessionPreset)supportSessionPreset:(FSLAVH264CaptureSessionPreset)sessionPreset
{
    AVCaptureSession *session = [[AVCaptureSession alloc] init];
    AVCaptureDevice *inputCamera;
    
    NSArray *devices = [self obtainAvailableDevices];
    for (AVCaptureDevice *device in devices)
    {
        if ([device position] == AVCaptureDevicePositionFront)
        {
            inputCamera = device;
        }
    }
    AVCaptureDeviceInput *videoInput = [[AVCaptureDeviceInput alloc] initWithDevice:inputCamera error:nil];
    
    if ([session canAddInput:videoInput])
    {
        [session addInput:videoInput];
    }
    
    if (![session canSetSessionPreset:self.avSessionPreset])
    {
        if (sessionPreset == FSLAVH264CaptureSessionPreset720x1280)
        {
            sessionPreset = FSLAVH264CaptureSessionPreset540x960;
            if (![session canSetSessionPreset:self.avSessionPreset])
            {
                sessionPreset = FSLAVH264CaptureSessionPreset360x640;
            }
        } else if (sessionPreset == FSLAVH264CaptureSessionPreset540x960)
        {
            sessionPreset = FSLAVH264CaptureSessionPreset360x640;
        }
    }
    return sessionPreset;
}

//拿到所有可用的摄像头(video)设备
- (NSArray *)obtainAvailableDevices{
    
    if (@available(iOS 10.0, *)) {
        
        AVCaptureDeviceDiscoverySession *deviceSession = [AVCaptureDeviceDiscoverySession discoverySessionWithDeviceTypes:@[AVCaptureDeviceTypeBuiltInWideAngleCamera] mediaType:AVMediaTypeVideo position:AVCaptureDevicePositionUnspecified];
        return deviceSession.devices;
    } else {
        // Fallback on earlier versions
        return [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    }
}

/**
 画质枚举
 
 @return 视频分辨率（画质的清晰度）
 */
- (NSString *)avSessionPreset
{
    NSString *avSessionPreset = nil;
    switch (self.sessionPreset)
    {
        case FSLAVH264CaptureSessionPreset360x640:
        {
            avSessionPreset = AVCaptureSessionPreset640x480;
        }
            break;
        case FSLAVH264CaptureSessionPreset540x960:
        {
            avSessionPreset = AVCaptureSessionPresetiFrame960x540;
        }
            break;
        case FSLAVH264CaptureSessionPreset720x1280:
        {
            avSessionPreset = AVCaptureSessionPreset1280x720;
        }
            break;
        default:
        {
            avSessionPreset = AVCaptureSessionPreset640x480;
        }
            break;
    }
    return avSessionPreset;
}


#pragma mark -- public setter
/**
 最大比特率
 
 @param videoMaxBitRate 最大比特率
 */
- (void)setVideoMaxBitRate:(NSUInteger)videoMaxBitRate
{
    if (videoMaxBitRate <= _videoBitRate) return;
    _videoMaxBitRate = videoMaxBitRate;
}

/**
 最小比特率
 
 @param videoMinBitRate 最小比特率
 */

- (void)setVideoMinBitRate:(NSUInteger)videoMinBitRate
{
    if (videoMinBitRate >= _videoBitRate) return;
    _videoMinBitRate = videoMinBitRate;
}

/**
 视频分辨率
 
 @param sessionPreset 视频分辨率
 */
- (void)setSessionPreset:( FSLAVH264CaptureSessionPreset)sessionPreset
{
    _sessionPreset = sessionPreset;
    _sessionPreset = [self supportSessionPreset:sessionPreset];
}

/**
 视频编码
 @param aCoder 编码器
 */
- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:[NSValue valueWithCGSize:self.videoSize] forKey:@"videoSize"];
    [aCoder encodeObject:@(self.videoFrameRate) forKey:@"videoFrameRate"];
    [aCoder encodeObject:@(self.videoMaxKeyframeInterval) forKey:@"videoMaxKeyframeInterval"];
    [aCoder encodeObject:@(self.videoBitRate) forKey:@"videoBitRate"];
    [aCoder encodeObject:@(self.videoMaxBitRate) forKey:@"videoMaxBitRate"];
    [aCoder encodeObject:@(self.videoMinBitRate) forKey:@"videoMinBitRate"];
    [aCoder encodeObject:@(self.sessionPreset) forKey:@"sessionPreset"];
}

/**
 编码器初始化
 
 @param aDecoder 编码器
 @return self
 */
- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    _videoSize = [[aDecoder decodeObjectForKey:@"videoSize"] CGSizeValue];
    _videoFrameRate = [[aDecoder decodeObjectForKey:@"videoFrameRate"] unsignedIntegerValue];
    _videoMaxKeyframeInterval = [[aDecoder decodeObjectForKey:@"videoMaxKeyframeInterval"] unsignedIntegerValue];
    _videoBitRate = [[aDecoder decodeObjectForKey:@"videoBitRate"] unsignedIntegerValue];
    _videoMaxBitRate = [[aDecoder decodeObjectForKey:@"videoMaxBitRate"] unsignedIntegerValue];
    _videoMinBitRate = [[aDecoder decodeObjectForKey:@"videoMinBitRate"] unsignedIntegerValue];
    _sessionPreset = [[aDecoder decodeObjectForKey:@"sessionPreset"] unsignedIntegerValue];
    return self;
}

/**
 哈希
 
 @return hash
 */
- (NSUInteger)hash
{
    NSUInteger hash = 0;
    NSArray *values = @[[NSValue valueWithCGSize:self.videoSize],
                        @(self.videoFrameRate),
                        @(self.videoMaxKeyframeInterval),
                        @(self.videoBitRate),
                        @(self.videoMaxBitRate),
                        @(self.videoMinBitRate),
                        self.avSessionPreset,
                        @(self.sessionPreset)];
    
    for (NSObject *value in values)
    {
        hash ^= value.hash;
    }
    return hash;
}

/**
 判断配置是否相同
 
 @param other 视频配置
 @return 是否相同
 */
- (BOOL)isEqual:(id)other
{
    if (other == self)
    {
        return YES;
    } else if (![super isEqual:other])
    {
        return NO;
    } else
    {
        FSLAVH264EncodeOptions *object = other;
        return CGSizeEqualToSize(object.videoSize, self.videoSize) &&
        object.videoFrameRate == self.videoFrameRate &&
        object.videoMaxKeyframeInterval == self.videoMaxKeyframeInterval &&
        object.videoBitRate == self.videoBitRate &&
        object.videoMaxBitRate == self.videoMaxBitRate &&
        object.videoMinBitRate == self.videoMinBitRate &&
        [object.avSessionPreset isEqualToString:self.avSessionPreset] &&
        object.sessionPreset == self.sessionPreset;
    }
}

/**
 拷贝
 
 @param zone 视频配置
 @return defaultOptions
 */
- (id)copyWithZone:(NSZone *)zone
{
    FSLAVH264EncodeOptions *other = [self.class defaultOptions];
    return other;
}

/**
 返回对象的描述信息
 */
- (NSString *)description
{
    NSMutableString *desc = @"".mutableCopy;
    [desc appendFormat:@" videoSize:%@", NSStringFromCGSize(self.videoSize)];
    [desc appendFormat:@" videoFrameRate:%zi", self.videoFrameRate];
    [desc appendFormat:@" videoMaxKeyframeInterval:%zi", self.videoMaxKeyframeInterval];
    [desc appendFormat:@" videoBitRate:%zi", self.videoBitRate];
    [desc appendFormat:@" videoMaxBitRate:%zi", self.videoMaxBitRate];
    [desc appendFormat:@" videoMinBitRate:%zi", self.videoMinBitRate];
    [desc appendFormat:@" avSessionPreset:%@", self.avSessionPreset];
    [desc appendFormat:@" sessionPreset:%zi", self.sessionPreset];
    return desc;
}


@end
