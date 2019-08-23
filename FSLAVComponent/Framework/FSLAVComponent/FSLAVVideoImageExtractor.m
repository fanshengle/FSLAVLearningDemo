//
//  FSLAVVideoImageExtractor.m
//  FSLAVComponent
//
//  Created by tutu on 2019/8/21.
//  Copyright © 2019 tutu. All rights reserved.
//

#import "FSLAVVideoImageExtractor.h"

@interface FSLAVVideoImageExtractor ()

@property (nonatomic, assign) NSInteger extractAllFrameCount;

@property (nonatomic, strong) NSArray<AVAsset *> * extractAllVideoAssets;
@property (nonatomic, strong) NSArray<NSArray *> * extractAllFrameImages;
@property (nonatomic, strong) NSArray<NSArray <NSValue *> *> * extractAllCaptureTimes;

@end

@implementation FSLAVVideoImageExtractor

#pragma mark -- init
/**
 类方式初始化
 
 @return FSLAVVideoImageExtractor
 */
+ (instancetype)extractor;
{
    return [[self alloc] init];
}

/**
 视频缩略图提取器，用init初始化也可以，需要另外配置videoOptionsList
 
 @param videoOptionsList 拼接多视频的配置项
 @return FSLAVVideoImageExtractor
 */
- (instancetype)initWithVideoImageExtractorOptionsList:(NSArray<FSLAVVideoImageExtractorOptions *> *)videoOptionsList;
{
    if (self = [super init]) {
        _videoOptionsList = videoOptionsList;
    }
    return self;
}

#pragma mark -- public methods
/**
 同步提取视频帧
 
 @return 视频帧数据列表
 */
//- (NSArray<UIImage *> * _Nullable)syncExtractImageList;
//{
//
//}
//
///**
// 同步获取指定时间的视频帧
//
// @param time 帧所在时间
// @return 视频帧
// */
//- (UIImage * _Nullable)syncExtractFrameImageAtTime:(CMTime)time;
//{
//
//}

/**
 异步获取视频缩略图
 
 @param handler 所有缩略图获取完成后处理器
 @since v1.0.0
 */
- (void)asyncExtractImageList:(TuSDKVideoImageExtractorBlock _Nonnull)handler;
{

    // 所有视频的截取帧图片，每个视频对应一个数组
//    __block NSMutableArray<NSArray *> *allframeImages = [self extractAllFrameCount];
    
    // 异步截取帧图片，并替换 frameImages 对应索引的对象，直到截取的数量足够
    __block NSInteger imageCount = 0;
    NSInteger extractFrameCount = [self extractAllFrameCount];
//    [self asyncExtractImageWithHandler:^(UIImage *image, NSUInteger index) {
//        imageCount += 1;
//        [frameImages replaceObjectAtIndex:index withObject:image];
//        if (imageCount == extractFrameCount) { // 截取图片足够则回调
//            if (handler) handler(frameImages.copy);
//        }
//    }];
}

/**
 异步获取视频缩略图
 
 @param handler 获取到每帧缩略图时的处理回调
 @since v1.0.0
 */
- (void)asyncExtractImageWithHandler:(TuSDKVideoImageExtractorStepImageBlock _Nonnull)handler;
{
    // 若帧数量配置失败则返回
    if (![self extractAllFrameCount]) return;
    
}

#pragma mark private methods

- (NSInteger)extractAllFrameCount;
{
    NSInteger extractAllFrameCount = 0;
    for (FSLAVVideoImageExtractorOptions *options in self.videoOptionsList) {
        extractAllFrameCount += options.extractFrameCount;
    }
    return extractAllFrameCount;
}

- (NSArray <AVAsset *> *)extractAllVideoAssets;
{
    if (!_extractAllVideoAssets) {
        
        NSMutableArray *extractAllVideoAssets = [NSMutableArray array];
        for (FSLAVVideoImageExtractorOptions *options in self.videoOptionsList) {
            // 统一配置多视频提取缩略图
            if (options.videoAssets.count > 0) {
                
                [extractAllVideoAssets addObjectsFromArray:options.videoAssets];
            }else{// 多视频每个视频进行个性化配置
                
                [extractAllVideoAssets addObject:options.videoAsset];
            }
        }
        _extractAllVideoAssets = extractAllVideoAssets;
    }
    
    return _extractAllVideoAssets;
}

- (NSArray<NSArray *> *)extractAllFrameImages;
{
    // 保存当前所有截取帧图片的数组，插入足够数量的对象
    NSMutableArray *frameImages = [NSMutableArray array];
    // 所有视频的截取帧图片，每个视频对应一个数组
    NSMutableArray<NSArray *> *allframeImages = [NSMutableArray arrayWithObject:frameImages];
    for (FSLAVVideoImageExtractorOptions *options in self.videoOptionsList) {
        for (int i = 0; i < options.extractFrameCount; i ++ ) {
            
            [frameImages addObject:@(i)];
        }
    }
    return allframeImages;
}

- (NSArray<NSArray<NSValue *> *> *)extractAllCaptureTimes;
{
    // 累计截取时间
    NSTimeInterval captureTime = 0;
    // 当前计算截取时间的视频索引
    NSUInteger currentVideoIndex = 0;
    // 当前视频截取的时间
    NSMutableArray<NSValue *> *extractVideoCaptureTimes = [NSMutableArray array];
    // 所有视频的截取时间，每个视频对应一个数组
    NSMutableArray<NSArray *> *allCaptureTimes = [NSMutableArray arrayWithObject:extractVideoCaptureTimes];
    for (FSLAVVideoImageExtractorOptions *options in self.videoOptionsList) {
        for (int i = 0; i < options.extractFrameCount; i ++ ) {
            
            // 当前视频截取的时间
             [extractVideoCaptureTimes addObject:[NSValue valueWithCMTime:CMTimeMakeWithSeconds(captureTime, 1.0 * USEC_PER_SEC)]];
            //当前视频的图片提取的时刻
            captureTime += options.extractFrameTimeInterval;
        }
    }
    
    return allCaptureTimes;
}



@end
