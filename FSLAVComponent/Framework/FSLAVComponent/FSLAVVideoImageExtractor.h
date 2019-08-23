//
//  FSLAVVideoImageExtractor.h
//  FSLAVComponent
//
//  Created by tutu on 2019/8/21.
//  Copyright © 2019 tutu. All rights reserved.
//

#import "FSLAVCoreBase.h"
#import "FSLAVVideoImageExtractorOptions.h"


typedef void(^TuSDKVideoImageExtractorBlock)(NSArray<UIImage *> *_Nullable frameImages);
typedef void(^TuSDKVideoImageExtractorStepImageBlock)(UIImage *_Nonnull frameImage, NSUInteger index);

NS_ASSUME_NONNULL_BEGIN

/**
 * 视频缩略图提取器
 */
@interface FSLAVVideoImageExtractor : FSLAVCoreBase

/**
 一组视频资源
 */
@property (nonatomic, strong, nullable) NSArray<FSLAVVideoImageExtractorOptions *> *videoOptionsList;

#pragma mark -- init
/**
 类方式初始化

 @return FSLAVVideoImageExtractor
 */
+ (instancetype)extractor;

/**
 视频缩略图提取器，用init初始化也可以，需要另外配置videoOptionsList
 
 @param videoOptionsList 拼接多视频的配置项
 @return FSLAVVideoImageExtractor
 */
- (instancetype)initWithVideoImageExtractorOptionsList:(NSArray<FSLAVVideoImageExtractorOptions *> *)videoOptionsList;

#pragma mark -- public methods
/**
 同步提取视频帧
 
 @return 视频帧数据列表
 */
- (NSArray<UIImage *> * _Nullable)syncExtractImageList;

/**
 同步获取指定时间的视频帧
 
 @param time 帧所在时间
 @return 视频帧
 */
- (UIImage * _Nullable)syncExtractFrameImageAtTime:(CMTime)time;

/**
 异步获取视频缩略图
 
 @param handler 所有缩略图获取完成后处理器
 @since v1.0.0
 */
- (void)asyncExtractImageList:(TuSDKVideoImageExtractorBlock _Nonnull)handler;

/**
 异步获取视频缩略图
 
 @param handler 获取到每帧缩略图时的处理回调
 @since v1.0.0
 */
- (void)asyncExtractImageWithHandler:(TuSDKVideoImageExtractorStepImageBlock _Nonnull)handler;


@end

NS_ASSUME_NONNULL_END
