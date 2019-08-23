//
//  FSLAVAudioInfo.m
//  FSLAVComponent
//
//  Created by tutu on 2019/7/15.
//  Copyright © 2019 tutu. All rights reserved.
//

#import "FSLAVAudioInfo.h"

@implementation FSLAVAudioInfo

/**
 同步加载音频信息
 
 @param asset AVAsset
 */
-(void)loadSynchronouslyForAssetInfo:(AVAsset *)asset;
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
    
    NSMutableArray<FSLAVAudioTrackInfo *> *audioTrackInfoArray = [NSMutableArray arrayWithCapacity:1];
    _audioTrackInfoArray = audioTrackInfoArray;

    //获取媒体素材的持续时间
    _duration = asset.duration;
    
    //异步加载指定键(属性名)的值。
    [asset loadValuesAsynchronouslyForKeys:@[@"tracks",@"duration"] completionHandler: ^{
        
        //同步线程加载
        dispatch_sync(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
           
            NSError *error;
            AVKeyValueStatus trackStatus = [asset statusOfValueForKey:@"tracks" error:&error];
            if (trackStatus != AVKeyValueStatusLoaded || error) {
                fslLError(@"audioTrack loadValuesAsynchronouslyForKeys is failed : %@",error);
                if (handler) handler();
                return ;
            }
            
            self->_duration = asset.duration;

            //获取所有音频的轨道信息数组
            NSArray<AVAssetTrack *> *audioTracks = [asset tracksWithMediaType:AVMediaTypeAudio];
            
            //遍历音轨数组来进行FSLAVAudioTrackInfo值入
            [audioTracks enumerateObjectsUsingBlock:^(AVAssetTrack * audioTrack, NSUInteger idx, BOOL * _Nonnull stop) {
                //获取音轨的格式描述
                NSArray *audioFormatInfo = audioTrack.formatDescriptions;
                if (audioFormatInfo.count == 0) *stop = YES;
                //用于操作音频cmformatdescription的同义词类型。
                CMAudioFormatDescriptionRef audioFormatDescriptionRef = (CMAudioFormatDescriptionRef)CFBridgingRetain([audioFormatInfo objectAtIndex:0]);
                //通过获取到的CMAudioFormatDescriptionRef就能读取音频数据包中信息了
                FSLAVAudioTrackInfo *audioTrackInfo = [[FSLAVAudioTrackInfo alloc] initWithCMAudioFormatDescriptionRef:audioFormatDescriptionRef];
                CFRelease(audioFormatDescriptionRef);
                //目的：将得到的音轨数据，缓存起来备用
                [audioTrackInfoArray addObject:audioTrackInfo];
            }];
            
            if (handler) {
                
                handler();
            }
        });
    }];
}

/**
 描述信息，NSLog(@"%@",xx);description不设置NSObject默认打印出来的信息就是<类名: 对象的内存地址>
 description可以重写，这样打印该方法所属的类就会打印出更多的信息
 
 @return NSString
 */
- (NSString *)description{
    
    NSMutableString *description = [[NSMutableString alloc] init];
    [_audioTrackInfoArray enumerateObjectsUsingBlock:^(FSLAVAudioTrackInfo * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        [description appendFormat:@"\n [ \n trackIndex : %ld \n %@ \n ]\n",idx,obj];
    }];
    
    return description;
}

@end


#pragma mark - FSLAVAudioTrackInfo

@implementation FSLAVAudioTrackInfo

- (instancetype)init{
    if (self = [super init])
    {
        _sampleRate = 44100;
        _channelsPerFrame = 2;
        _bitsPerChannel = 16;
    }
    
    return self;
}

/**
 根据 CMAudioFormatDescriptionRef 初始化 FSLAVAudioTrackInfo
 
 @param audioFormatDescriptionRef CMAudioFormatDescriptionRef
 @return FSLAVAudioTrackInfo
 */
- (instancetype)initWithCMAudioFormatDescriptionRef:(CMAudioFormatDescriptionRef)audioFormatDescriptionRef
{
    if (!audioFormatDescriptionRef) return nil;
    
    //音频流中的格式信息
    AudioStreamBasicDescription *sourceBasicDesc = (AudioStreamBasicDescription *)CMAudioFormatDescriptionGetStreamBasicDescription(audioFormatDescriptionRef);
    if (self = [self initWithAudioStreamBasicDescription:sourceBasicDesc])
    {
        _audioFormatDescriptionRef =  CFRetain(audioFormatDescriptionRef);
    }
    
    return self;
}


/**
 从音频流的音频数据格式规范中提取相关音频信息。

 @param audioStreamBasicDescription 音频数据格式规范
 @return FSLAVAudioTrackInfo
 */
- (instancetype)initWithAudioStreamBasicDescription:(AudioStreamBasicDescription *)audioStreamBasicDescription;
{
    if (self = [super init])
    {
        _sampleRate = audioStreamBasicDescription -> mSampleRate;
        _channelsPerFrame = audioStreamBasicDescription -> mChannelsPerFrame;
        _bytesPerPacket = audioStreamBasicDescription -> mBytesPerPacket;
        _bitsPerChannel = audioStreamBasicDescription -> mBitsPerChannel;
        _framesPerPacket = audioStreamBasicDescription -> mFramesPerPacket;
    }
    
    return self;
}

/**
 FSLAVAudioTrackInfo
 
 @param audioTrack (AVAssetTrack *)
 @return FSLAVAudioTrackInfo
 */
+ (instancetype)trackInfoWithAudioAssetTrack:(AVAssetTrack *)audioTrack
{
    NSArray *audioFormatInfos = audioTrack.formatDescriptions;
    if ([audioFormatInfos count] > 0)
    {
        CMAudioFormatDescriptionRef audioFormatDescriptionRef = (CMAudioFormatDescriptionRef)CFBridgingRetain([audioFormatInfos objectAtIndex:0]);
        FSLAVAudioTrackInfo *audioTrackInfo = [[FSLAVAudioTrackInfo alloc] initWithCMAudioFormatDescriptionRef:audioFormatDescriptionRef];
        CFRelease(audioFormatDescriptionRef);
        return audioTrackInfo;
    }
    
    return nil;
}

/**
 描述信息，NSLog(@"%@",xx);description不设置NSObject默认打印出来的信息就是<类名: 对象的内存地址>
 description可以重写，这样打印该方法所属的类就会打印出更多的信息
 
 @return NSString
 */
- (NSString *)description;
{
    NSMutableString *description = [NSMutableString new];
    [description appendFormat:@"  sampleRate : %f \n ",_sampleRate];
    [description appendFormat:@"  channelsPerFrame : %d \n ",_channelsPerFrame];
    [description appendFormat:@"  bytesPerPacket : %d \n ",_bytesPerPacket];
    [description appendFormat:@"  bitsPerChannel : %d \n ",_bitsPerChannel];
    [description appendFormat:@"  framesPerPacket : %d \n ",_framesPerPacket];
    return description;
}


- (void)dealloc
{
    if (_audioFormatDescriptionRef) {
        CFRelease(_audioFormatDescriptionRef);
        _audioFormatDescriptionRef = nil;
    }
}

@end
