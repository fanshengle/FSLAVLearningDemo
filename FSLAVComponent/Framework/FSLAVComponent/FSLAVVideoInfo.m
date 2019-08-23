//
//  FSLAVVideoInfo.m
//  FSLAVComponent
//
//  Created by tutu on 2019/7/15.
//  Copyright © 2019 tutu. All rights reserved.
//

#import "FSLAVVideoInfo.h"

@implementation FSLAVVideoInfo

/**
 是否为4k视频
 */
- (BOOL)is4K;
{
    
    CGSize naturalSize = self.videoTrackInfoArray.firstObject.naturalSize;
    CGFloat maxSide = MAX(naturalSize.width, naturalSize.height);
    return maxSide >= 3840;
}

/**
 同步加载视频信息
 
 @param asset AVAsset
 */
- (void)loadSynchronouslyForAssetInfo:(AVAsset *)asset;
{
    //使用信号量了监控异步线程同步加载
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    [self loadAsynchronouslyForAssetInfo:asset completionHandler:^{
        //发送信号量，该函数会对信号量的值进行加1操作。
        dispatch_semaphore_signal(semaphore);
    }];
    
    //检测信号量是否为0，不为0，将信号量减1，为0，则一直等待，阻塞当前线程
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    
}

/**
 异步加载音频信息
 
 @param asset AVAsset
 @param handler 完成后回调
 */
- (void)loadAsynchronouslyForAssetInfo:(AVAsset *)asset completionHandler:(void (^)(void))handler;
{
    if (asset == nil) return;
    
    NSMutableArray<FSLAVVideoTrackInfo *> *videoTrackInfoArray = [NSMutableArray arrayWithCapacity:1];
    _videoTrackInfoArray = videoTrackInfoArray;

    //获取媒体素材的持续时间
    _duration = asset.duration;
    
    //异步加载指定键(属性名)的值。
    [asset loadValuesAsynchronouslyForKeys:@[@"tracks",@"duration"] completionHandler: ^{
        
        //同步线程加载
        dispatch_sync(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            
            NSError *error;
            AVKeyValueStatus trackStatus = [asset statusOfValueForKey:@"tracks" error:&error];
            if (trackStatus != AVKeyValueStatusLoaded || error) {
                fslLError(@"videoTrack loadValuesAsynchronouslyForKeys is failed : %@",error);
                if (handler) handler();
                return ;
            }
            
            self->_duration = asset.duration;
            
            //获取所有视频轨道信息
            NSArray *videoTracks = [asset tracksWithMediaType:AVMediaTypeVideo];
            //遍历视频轨数组来进行FSLAVVideoTrackInfo值入
            [videoTracks enumerateObjectsUsingBlock:^(AVAssetTrack *videoTrack, NSUInteger idx, BOOL * _Nonnull stop) {
                
                //通过获取到的videoTrack就能读取音频数据包中信息了
                FSLAVVideoTrackInfo *videoTrackInfo = [[FSLAVVideoTrackInfo alloc] initWithVideoAssetTrack:videoTrack];
                //目的：将得到的视频轨道数据，缓存起来备用
                [videoTrackInfoArray addObject:videoTrackInfo];
            }];
            
            if(handler){
                
                handler();
            }
        });
    }];

}

@end

#pragma mark - FSLAVVideTrackInfo

@implementation FSLAVVideoTrackInfo

/**
 trackInfoWithVideoAssetTrack
 
 @param videoTrack AVAssetTrack
 @return FSLAVVideoTrackInfo
 */
+ (instancetype)trackInfoWithVideoAssetTrack:(AVAssetTrack *)videoTrack
{
    FSLAVVideoTrackInfo *trackInfo = [[FSLAVVideoTrackInfo alloc] initWithVideoAssetTrack:videoTrack];
    return trackInfo;
}

/**
 根据 AVAssetTrack 初始化 FSLAVVideoTrackInfo
 
 @param videoTrack AVAssetTrack
 @return FSLAVVideoTrackInfo
 */
- (instancetype)initWithVideoAssetTrack:(AVAssetTrack *)videoTrack
{
    if (self = [super init])
    {
        
        _naturalSize = videoTrack.naturalSize;
        _presentSize = CGSizeMake(_naturalSize.width, _naturalSize.height);
        _preferredTransform = videoTrack.preferredTransform;
        _orientation = [self preferredTransformToRotation:_preferredTransform];
        _estimatedDataRate = videoTrack.estimatedDataRate;
        _nominalFrameRate = videoTrack.nominalFrameRate;
        _minFrameDuration = videoTrack.minFrameDuration;
        
        _isTransposedSize = (_orientation == UIImageOrientationRight || _orientation == UIImageOrientationLeft);
        
        //进行方向转换
        if (_isTransposedSize)
            _presentSize = CGSizeMake(_naturalSize.height, _naturalSize.width);
    }
    
    return self;
}

/**
 根据获取到的image方向信息preferredTransform，进行方向判断

 @param transform preferredTransform
 @return imageRotation
 */
- (FSLAVVideoImageRotationMode)preferredTransformToRotation:(CGAffineTransform)transform{
    
    if (transform.a == 0 && transform.b == 1.0 && transform.c == -1.0 && transform.d == 0)
        return FSLAVVideoImageRotateRight;
    else if (transform.a == 0 && transform.b == -1.0 && transform.c == 1.0 && transform.d == 0)
        return FSLAVVideoImageRotateLeft;
    else if (transform.a == 1.0 && transform.b == 0 && transform.c == 0 && transform.d == 1.0)
        return FSLAVVideoImageNoRotation;
    else if (transform.a == -1.0 && transform.b == 0 && transform.c == 0 && transform.d == -1.0)
        return FSLAVVideoImageRotate180;
    else
        return FSLAVVideoImageNoRotation;
}

/**
 描述信息
 
 @return NSString
 */
- (NSString *)description;
{
    NSMutableString *description = [NSMutableString new];
    [description appendFormat:@"  naturalSize : %@ \n ",NSStringFromCGSize(_naturalSize)];
    [description appendFormat:@"  presentSize : %@ \n ",NSStringFromCGSize(_presentSize)];
    [description appendFormat:@"  estimatedDataRate : %f \n ",_estimatedDataRate];
    [description appendFormat:@"  nominalFrameRate : %f \n ",_nominalFrameRate];
    [description appendFormat:@"  orientation : %ld \n ",_orientation];
    
    return description;
}

@end

