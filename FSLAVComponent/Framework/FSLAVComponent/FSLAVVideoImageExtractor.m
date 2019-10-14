//
//  FSLAVVideoImageExtractor.m
//  FSLAVComponent
//
//  Created by tutu on 2019/8/21.
//  Copyright © 2019 tutu. All rights reserved.
//

#import "FSLAVVideoImageExtractor.h"

/// 默认最大图像输出尺寸
static const CGSize imageDefaultOutputSize = {180, 180};

@interface FSLAVVideoImageExtractor ()

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
 视频缩略图提取器，用init初始化也可以，需要另外配置videoOptions
 
 @param videoOptions 拼接多视频的配置项
 @return FSLAVVideoImageExtractor
 */
- (instancetype)initWithVideoImageExtractorOptions:(FSLAVVideoImageExtractorOptions *)videoOptions;
{
    if (self = [super init]) {
        _videoOptions = videoOptions;
    }
    return self;
}

#pragma mark -- public methods --- syncExtractImage
/**
 同步提取视频帧
 
 @return 视频帧数据列表
 */
- (NSArray<UIImage *> * _Nullable)syncExtractImageList;
{
    // 若帧数量配置失败则返回 nil
    if(!self.videoOptions.extractFrameCount) return nil;
    
    //所有视频的所有的截帧图片
    NSMutableArray *extractAllFrameImages = [NSMutableArray array];
    
    //依次同步获取每个视频对应截取时间的图片
    for (int i = 0; i < self.extractAllCaptureTimes.count; i++) {
        
        AVAsset *videoAsset = self.videoOptions.videoAssets[i];
        NSArray <NSValue *> *extractCaptureTimes = self.extractAllCaptureTimes[i];
        for (int j = 0; j < extractCaptureTimes.count; j++) {
            //循环遍历过程中产生大量的临时对象，用@autoreleasepool 包起来，让每次循环结束时，可以及时释放临时对象的内存
            @autoreleasepool {
                //截帧时间节点时间
                CMTime time = [extractCaptureTimes[j] CMTimeValue];
                //截帧图片
                UIImage *frameImage = [self extractFrameImageAtTime:time asset:videoAsset];
                if(frameImage) [extractAllFrameImages addObject:frameImage];
            }
        }
    }
    
    return extractAllFrameImages;
}

/**
 同步获取指定时间的视频帧

 @param time 帧所在时间
 @return 视频帧
 */
- (UIImage * _Nullable)syncExtractFrameImageAtTime:(CMTime)time;
{
    // 若帧数量配置失败则返回 nil
    if(!self.videoOptions.extractFrameCount) return nil;
    // 获取需要操作的视频以及对应的截取的时间，若给定时长大于所有视频时长则完成遍历后返回 nil
    NSTimeInterval captureTime = CMTimeGetSeconds(time);
    
    NSInteger videoIndex = -1;
    
    for (int i = 0; i < self.videoOptions.videoAssets.count; i++) {
        AVAsset *videoAsset = self.videoOptions.videoAssets[i];
        NSTimeInterval duration = CMTimeGetSeconds(videoAsset.duration);
        if (captureTime > duration) {
            captureTime -= duration;
        }else{
            
            videoIndex = i;
            break;
        }
    }
    
    if(videoIndex < 0) return nil;
    
    // 同步截取对应视频的对应时间的图片
    AVAsset *videoAsset = self.videoOptions.videoAssets[videoIndex];
    time = CMTimeMakeWithSeconds(captureTime, time.timescale);
    return  [self extractFrameImageAtTime:time asset:videoAsset];
}

#pragma mark -- private methods --- syncExtractImage

/**
 同步提取视频时间节点下的每帧图片
 
 @param time 当前的截帧时间节点
 @param asset 媒体资源
 @return 每帧图片
 */
- (UIImage *)extractFrameImageAtTime:(CMTime)time asset:(AVAsset *)asset;
{
    AVAssetImageGenerator *imageGenerator = [self imageGeneratorWithAsset:asset];
    NSError *error = nil;
    CMTime actualTime = kCMTimeZero;
    //在指定时间或附近返回资产的映像，同步。
    CGImageRef imageRef = [imageGenerator copyCGImageAtTime:time actualTime:&actualTime error:&error];
    if (error || !imageRef) {
        fslLError(@"image generate error: %@", error);
        return nil;
    }
    
    UIImage *frameImage = [UIImage imageWithCGImage:imageRef];
    //释放imageRef
    CGImageRelease(imageRef);
    return frameImage;
}

#pragma mark -- public methods --- asyncExtractImage

/**
 异步获取视频缩略图
 
 @param handler 所有缩略图获取完成后处理器
 @since v1.0.0
 */
- (void)asyncExtractImageList:(FSLAVVideoImageExtractorBlock _Nonnull)handler;
{
    // 保存所有截取帧图片的数组，插入足够数量的对象
    __block NSMutableArray *frameImages = [NSMutableArray array];
    for (NSInteger i = 0; i < self.videoOptions.extractFrameCount; i++) {
        [frameImages addObject:@(i)];
    }
    
    // 异步截取帧图片，并替换 frameImages 对应索引的对象，直到截取的数量足够
    __block NSInteger imageCount = 0;
    NSInteger extractFrameCount = self.videoOptions.extractFrameCount;
    [self asyncExtractImageWithHandler:^(UIImage *image, NSUInteger index) {
        imageCount += 1;
        [frameImages replaceObjectAtIndex:index withObject:image];
        if (imageCount == extractFrameCount) { // 截取图片足够则回调
            if (handler) handler(frameImages.copy);
        }
    }];
}

/**
 异步获取视频缩略图
 
 @param handler 获取到每帧缩略图时的处理回调
 @since v1.0.0
 */
- (void)asyncExtractImageWithHandler:(FSLAVVideoImageExtractorStepImageBlock _Nonnull)handler;
{
    // 若帧数量配置失败则返回
    if (!self.videoOptions.extractFrameCount) return;
    
    // 依次截取图片
    for (int i = 0; i < self.extractAllCaptureTimes.count; i++) {
        
        NSArray *currentVideoCaptureTimes = self.extractAllCaptureTimes[i];
        AVAsset *currentVideo = self.videoOptions.videoAssets[i];
        AVAssetImageGenerator *imageGenerator = [self imageGeneratorWithAsset:currentVideo];
        //在指定时间或接近指定时间为资产创建一系列图像对象，异步。
        [imageGenerator generateCGImagesAsynchronouslyForTimes:currentVideoCaptureTimes completionHandler:^(CMTime requestedTime, CGImageRef  _Nullable image, CMTime actualTime, AVAssetImageGeneratorResult result, NSError * _Nullable error) {
            if (error) { // 遇错则返回
                fslLError(@"generate image error: %@", error);
                return;
            }
            
            // 计算图片最终所在的索引
            NSUInteger finalIndex = [currentVideoCaptureTimes indexOfObject:[NSValue valueWithCMTime:requestedTime]];
            if (i > 0) {
                for (int j = 0; j < i; j ++) {
                    finalIndex += self.extractAllCaptureTimes[j].count;
                }
            }
            
            UIImage *frameImage = [UIImage imageWithCGImage:image];
            dispatch_async(dispatch_get_main_queue(), ^{
                //NSLog(@"image-%zd: %@", finalIndex, frameImage);
                if (handler) handler(frameImage, finalIndex);
            });
        }];
    }
}

#pragma mark -- private methods

/**
 生成 AVAssetImageGenerator 对象

 @param asset 媒体资源
 @return 媒体图片提取器
 */
- (AVAssetImageGenerator *)imageGeneratorWithAsset:(AVAsset *)asset {
    // 若给定的 asset 为空则返回 nil
    if (!asset) return nil;
    
    //提供独立于回放的资产的缩略图或预览图像的对象。
    AVAssetImageGenerator *imageGenerator = [AVAssetImageGenerator assetImageGeneratorWithAsset:asset];
    // 帧率过低，需要精确获取时间
    if (!self.videoOptions.isAccurate) {
        AVAssetTrack *asstTrack = [asset tracksWithMediaType:AVMediaTypeVideo].firstObject;
        if (asstTrack.nominalFrameRate < 10) {
            self.videoOptions.isAccurate = YES;
        }
    }
    // 配置图片提取器
    [self setupImageGenerator:imageGenerator];
    
    return imageGenerator;
}

/**
 配置图片提取器

 @param imageGenerator 媒体图片提取器
 */
- (void)setupImageGenerator:(AVAssetImageGenerator *)imageGenerator {
    
    // 仅为单个视频时，配置 videoComposition
    if (self.videoOptions.videoAssets.count == 1) imageGenerator.videoComposition = self.videoOptions.videoComposition;
    
    // 配置轨道画面变换
    imageGenerator.appliesPreferredTrackTransform = YES;
    // 配置精确时间获取图片
    imageGenerator.requestedTimeToleranceAfter = imageGenerator.requestedTimeToleranceBefore
    = self.videoOptions.isAccurate ? kCMTimeZero : kCMTimePositiveInfinity;
    
    // 配置输出的最大尺寸
    if (CGSizeEqualToSize(self.videoOptions.outputMaxImageSize, CGSizeZero)) {
        // 计算视频数组中最小的尺寸
        CGSize minNaturalSize = CGSizeZero;
        CGFloat scale = [UIScreen mainScreen].scale;
        CGSize defaultSize = CGSizeMake(imageDefaultOutputSize.width * scale, imageDefaultOutputSize.height * scale);
        for (int i = 0; i < self.videoOptions.videoAssets.count; i++) {
            AVAsset *asset = self.videoOptions.videoAssets[i];
            //获取原视频的原尺寸
            CGSize naturalSize = [asset tracksWithMediaType:AVMediaTypeVideo].lastObject.naturalSize;
            if (naturalSize.width * naturalSize.height < minNaturalSize.width * minNaturalSize.height) {
                minNaturalSize = naturalSize;
            }
        }
        // 与默认尺寸比较得出适合的尺寸
        if (minNaturalSize.width > defaultSize.width || minNaturalSize.height > defaultSize.height) {
            //返回一个缩放后的CGRect，该CGRect在包围对象中保持指定的宽高比。
            CGSize matchSize = AVMakeRectWithAspectRatioInsideRect(minNaturalSize, (CGRect){CGPointZero, imageDefaultOutputSize}).size;
            self.videoOptions.outputMaxImageSize = CGSizeMake(matchSize.width * scale, matchSize.height * scale);
        } else {
            
            self.videoOptions.outputMaxImageSize = defaultSize;
        }
    }
    
    imageGenerator.maximumSize = self.videoOptions.outputMaxImageSize;
}

/**
 提取所有视频所有帧的时间节点集合
 
 @return 所有视频的帧时间节点集合
 */
- (NSArray<NSArray<NSValue *> *> *)extractAllCaptureTimes;
{
    if (!_extractAllCaptureTimes) {
        
        // 经过的视频时长，一个视频算完截取时间则增加该视频的时长
        NSTimeInterval passVideoDuration = 0;
        // 累计截取时间
        NSTimeInterval captureTime = 0;
        // 当前视频截取的时间
        NSMutableArray<NSValue *> *extractCaptureTimes = [NSMutableArray array];
        // 所有视频的截取时间，每个视频对应一个数组
        NSMutableArray<NSArray *> *extractAllCaptureTimes = [NSMutableArray arrayWithObject:extractCaptureTimes];
        
        // 当前计算截取时间的视频索引
        NSUInteger currentVideoIndex = 0;
        for (int i = 0; i < self.videoOptions.extractFrameCount; i ++ ) {
            // 取出
            AVAsset *currentVideo = self.videoOptions.videoAssets[currentVideoIndex];
            NSTimeInterval previousVideoDuration = CMTimeGetSeconds(currentVideo.duration);
            // 多视频options.videoAssets大于1时，重置下一个视频的时间数组
            if (captureTime > passVideoDuration + previousVideoDuration) {
                currentVideoIndex += 1;
                if(currentVideoIndex > self.videoOptions.videoAssets.count) break;
                passVideoDuration += previousVideoDuration;
                extractCaptureTimes = [NSMutableArray array];
                [extractAllCaptureTimes addObject:extractCaptureTimes];
            }
            
            NSTimeInterval currentVideoCaptureTime = captureTime - passVideoDuration;
            [extractCaptureTimes addObject:[NSValue valueWithCMTime:CMTimeMakeWithSeconds(currentVideoCaptureTime, currentVideo.duration.timescale)]];
            captureTime += self.videoOptions.extractFrameTimeInterval;
        }
        
        _extractAllCaptureTimes = extractAllCaptureTimes;
    }

    return _extractAllCaptureTimes;
}

@end
