//
//  FSLAVVideoImageExtractorOptions.h
//  FSLAVComponent
//
//  Created by tutu on 2019/8/22.
//  Copyright © 2019 tutu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "FSLAVLog.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * 视频缩略图提取器的配置项
 */
@interface FSLAVVideoImageExtractorOptions : NSObject
{
    NSTimeInterval _videoDuration;
}
/**
 输入的视频路径
 */
@property (nonatomic, copy, nullable) NSString *videoPath;

/**
 输入的视频地址
 */
@property (nonatomic, copy, nullable) NSURL *videoURL;

/**
 视频资源
 */
@property (nonatomic, strong, nullable) AVAsset *videoAsset;

/**
 视频资源数组
 */
@property (nonatomic, strong, nullable) NSArray<AVAsset *> *videoAssets;

/**
 指定视频轨道图像提取指令，仅为单个视频时有效
 */
@property (nonatomic, copy, nullable) AVVideoComposition *videoComposition;

/**
 提取的视频帧数，自动根据视频长度均匀获取 (extractFrameCount 和 extractFrameTimeInterval 都设置时 优先使用mExtractFrameCount)
 */
@property (nonatomic, assign) NSUInteger extractFrameCount;

/**
 提取帧的时间间隔 (单位：s) 张数不固定
 */
@property (nonatomic, assign) CGFloat extractFrameTimeInterval;


/**
 输出的图片尺寸，不设置则按视频宽高比例计算
 注意：要得到清晰图像，需要宽高分别乘以 [UIScreen mainScreen].scale。
 */
@property (nonatomic, assign) CGSize outputMaxImageSize;

/**
 是否需要精确时间帧获取图片, 默认NO
 */
@property (nonatomic, assign) BOOL isAccurate;

// 当前视频的总时长
@property (nonatomic, assign, readonly) NSTimeInterval videoDuration;

#pragma mark - init
/**
 初始化视频信息
 
 @param videoPath 视频资源地址
 @return 视频信息
 */
- (instancetype)initWithVideoPath:(NSString *)videoPath;

/**
 初始化视频信息
 
 @param videoURL 视频资源地址
 @return 视频信息
 */
- (instancetype)initWithVideoURL:(NSURL *)videoURL;

/**
 初始化视频信息
 
 @param videoAsset 视频资源素材
 @return 视频信息
 */
- (instancetype)initWithVideoAsset:(AVURLAsset *)videoAsset;

/**
 初始化视频信息：多视频统一配置
 
 @param videoAssets 视频资源素材数组
 @return 视频信息
 */
- (instancetype)initWithVideoAssets:(NSArray <AVURLAsset *> *)videoAssets;
@end

NS_ASSUME_NONNULL_END
