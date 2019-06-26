//
//  FSLAVH264VideoEcoder.m
//  FSLAVComponent
//
//  Created by tutu on 2019/6/21.
//  Copyright © 2019 tutu. All rights reserved.
//

#import "FSLAVH264VideoEncoder.h"
#import "FSLAVVideoRTMPFrame.h"

@interface FSLAVH264VideoEncoder ()
{
    /**编码会话*/
    VTCompressionSessionRef compressionSession;
    NSInteger frameCount;
    NSData *sps;
    NSData *pps;
}

/**
 进入后台
 */
@property (nonatomic) BOOL isBackGround;
@end

@implementation FSLAVH264VideoEncoder

- (void)dealloc{
    
    [self destoryCompressionSession];
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        
        [self addNotifaction];
    }
    return self;
}

- (instancetype)initWithVideoStreamConfiguration:(FSLAVH264VideoConfiguration *)configuration{
    
    if (self = [self init]) {
       
        _configuration = configuration;
        [self initCompressionSession];
    }
    return self;
}

/**
 添加进入后台/前台的通知
 */
- (void)addNotifaction{
    
    // app进入后台
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willEnterBackground:) name:UIApplicationWillResignActiveNotification object:nil];
    // app进入前台
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willEnterForeground:) name:UIApplicationDidBecomeActiveNotification object:nil];
}

/**
 销毁编码会话
 */
- (void)destoryCompressionSession{
    
    if (compressionSession) {
        
        //编码完成使其编码器无效，跳出编码会话
        VTCompressionSessionCompleteFrames(compressionSession, kCMTimeInvalid);
        
        //结束压缩编码会话（使其无效）。
        VTCompressionSessionInvalidate(compressionSession);
        //释放编码会话
        CFRelease(compressionSession);
        compressionSession = nil;
    }
}

/**
 初始化编码会话的配置
 */
- (void)initCompressionSession{
    
    [self destoryCompressionSession];
    
    // 1.创建VTCompressionSessionRef
    // 1> 参数一: CFAllocatorRef用于CoreFoundation分配内存的模式 NULL使用默认的分配方式
    // 2> 参数二: 编码出来视频的宽度 width
    // 3> 参数三: 编码出来视频的高度 height
    // 4> 参数四: 编码的标准 : H.264/AVC
    // 5> 参数五/六/七 : NULL
    // 6> 参数八: 编码成功后的回调函数
    // 7> 参数九: 可以传递到回调函数中参数, self : 将当前对象传入
    OSStatus status = VTCompressionSessionCreate(NULL, _configuration.videoSize.width, _configuration.videoSize.height, kCMVideoCodecType_H264, NULL, NULL, NULL, VideoCompressonOutputCallback, (__bridge void *)self, &compressionSession);
    
    //编码会话创建错误，自动跳出
    if (status != noErr)  return;
    
    // 2.在VideoToolbox编码会话上设置属性
    // 2.1.设置实时输出
    VTSessionSetProperty(compressionSession, kVTCompressionPropertyKey_RealTime, kCFBooleanTrue);
    // 2.2.设置帧率
    VTSessionSetProperty(compressionSession, kVTCompressionPropertyKey_ExpectedFrameRate, (__bridge CFTypeRef _Nonnull)@(_configuration.videoFrameRate));
    // 2.3.设置比特率(码率) 1500000/s
    VTSessionSetProperty(compressionSession, kVTCompressionPropertyKey_AverageBitRate, (__bridge CFTypeRef _Nonnull)@(_configuration.videoBitRate)); // bit
    // 2.4. 0、1或2个数据速率的硬限制。
    NSArray *limit = @[@(_configuration.videoBitRate * 1.2), @(1)];
    VTSessionSetProperty(compressionSession, kVTCompressionPropertyKey_DataRateLimits, (__bridge CFTypeRef _Nonnull)limit); // byte
    // 2.5.设置GOP的大小,关键帧之间的最大间隔，也称为关键帧速率。
    VTSessionSetProperty(compressionSession, kVTCompressionPropertyKey_MaxKeyFrameInterval, (__bridge CFTypeRef)@(_configuration.videoMaxKeyframeInterval));
    // 2.6.从一个关键帧到下一个关键帧的最大持续时间(以秒为单位)。
    VTSessionSetProperty(compressionSession, kVTCompressionPropertyKey_MaxKeyFrameIntervalDuration, (__bridge CFTypeRef)@(_configuration.videoMaxKeyframeInterval));
    // 2.7. 已编码位流的概要文件和级别。
    VTSessionSetProperty(compressionSession, kVTCompressionPropertyKey_ProfileLevel, (__bridge CFTypeRef)(_configuration.videoProfileLevel));
    // 2.8. 一个布尔值，指示是否启用帧重排序。
    VTSessionSetProperty(compressionSession, kVTCompressionPropertyKey_AllowFrameReordering, kCFBooleanTrue);
    // 2.9. H.264压缩的熵编码模式。
    VTSessionSetProperty(compressionSession, kVTCompressionPropertyKey_H264EntropyMode, kVTH264EntropyMode_CABAC);
    
    // 3.准备编码
    VTCompressionSessionPrepareToEncodeFrames(compressionSession);
}

#pragma mark -- public Set

#pragma mark -- 文件写入对象一
- (NSFileHandle *)fileHandle{
    if (!_fileHandle) {
        
        _fileHandle = [NSFileHandle fileHandleForWritingAtPath:[_configuration getSaveDatePath]];
    }
    return _fileHandle;
}

#pragma mark -- 文件写入对象二
- (FILE *)fileHandle2{
    
    if (!_fileHandle2) {
        
        _fileHandle2 = fopen([[_configuration getSaveDatePath] cStringUsingEncoding:NSUTF8StringEncoding], "wb");
    }
    return _fileHandle2;
}

/**
 设置码率
 
 @param videoBitRate 码率
 */
- (void)setVideoBitRate:(NSInteger)videoBitRate
{
    if (_isBackGround) return;
    VTSessionSetProperty(compressionSession, kVTCompressionPropertyKey_AverageBitRate, (__bridge CFTypeRef)@(videoBitRate));
    NSArray *limit = @[@(videoBitRate * 1.2), @(1)];
    VTSessionSetProperty(compressionSession, kVTCompressionPropertyKey_DataRateLimits, (__bridge CFArrayRef)limit);
}

/**
 设置帧率
 
 @param videoFrameRate 帧率
 */
- (void)setVideoFrameRate:(NSInteger)videoFrameRate
{
    if (_isBackGround) return;
    VTSessionSetProperty(compressionSession, kVTCompressionPropertyKey_ExpectedFrameRate, (__bridge CFTypeRef)@(videoFrameRate));
}

/**
 设置代理
 
 @param delegate 代理
 */
- (void)setDelegate:(id<FSLAVH264VideoEncoderDelegate>)delegate
{
    _h264Delegate = delegate;
}

#pragma mark -- publice methods

/**
 停止编码
 */
- (void)stopEncoder
{
    VTCompressionSessionCompleteFrames(compressionSession, kCMTimeIndefinite);
}

/**
 向编码器放入数据
 
 @param pixelBuffer 数据包
 @param timeStamp 时间戳
 */
- (void)encodeVideoData:(CVPixelBufferRef)pixelBuffer timeStamp:(uint64_t)timeStamp{
    if (_isBackGround) return;
    frameCount ++;
    //定义一个表示rational时间值int64/int32的结构。
    CMTime presentationTimeStamp = CMTimeMake(frameCount, (int32_t)_configuration.videoFrameRate);
    
    VTEncodeInfoFlags flags;
    //may be kCMTimeInvalid
    CMTime duration = CMTimeMake(1, (int32_t)_configuration.videoFrameRate);
    
    NSDictionary *properties = nil;
    if (frameCount % (int32_t)_configuration.videoMaxKeyframeInterval) {
        //布尔值，指示当前帧是否强制为关键帧。
        properties = @{(__bridge NSString *)kVTEncodeFrameOptionKey_ForceKeyFrame: @YES};
    }
    
    //时间戳
    NSNumber *timeNumber = @(timeStamp);
    
    // 3.开始编码
    // 1> 参数一: compressionSession
    // 2> 参数二: 需要将CMSampleBufferRef转成CVImageBufferRef(CVPixelBufferRef)
    // 3> 参数三: PTS(presentationTimeStamp)/DTS(DecodeTimeStamp)
    // 4> 参数四: kCMTimeInvalid
    // 5> 参数五: 是在回调函数中第二个参数
    // 6> 参数六: 是在回调函数中第四个参数
    VTCompressionSessionEncodeFrame(compressionSession, pixelBuffer, presentationTimeStamp, duration, (__bridge CFDictionaryRef)properties, (__bridge_retained void *)timeNumber, &flags);
}

#pragma mark - NSNotification

/**
 进入后台
 
 @param notification 消息
 */
- (void)willEnterBackground:(NSNotification *)notification
{
    _isBackGround = YES;
}

/**
 进入前台
 
 @param notification 消息
 */
- (void)willEnterForeground:(NSNotification *)notification
{
    [self initCompressionSession];
    _isBackGround = NO;
}

#pragma mark - VideoCallBack
#pragma mark - 获取编码后的数据
/**
 4.通过硬编码回调获取h264数据
 @param VTref 获取H264Encoder的对象指针
 @param VTFrameRef 时间戳
 @param status 状态
 @param infoFlags 编码信息状态
 @param sampleBuffer 编码后的数据包
 */
static void VideoCompressonOutputCallback(void *VTref, void *VTFrameRef, OSStatus status, VTEncodeInfoFlags infoFlags, CMSampleBufferRef sampleBuffer)
{
    //1、判断该帧是否是关键帧
    if(!sampleBuffer) return;
    //返回对CMSampleBuffer的可变样例附件字典的不可变数组的引用(CMSampleBuffer中的每个样例有一个字典)。
    CFArrayRef array = CMSampleBufferGetSampleAttachmentsArray(sampleBuffer, true);
    if(!array) return;
    //获取第一帧数据
    CFDictionaryRef dic = (CFDictionaryRef)CFArrayGetValueAtIndex(array, 0);
    if(!dic) return;
    //是否为关键帧
    BOOL keyframe = !CFDictionaryContainsKey(dic, kCMSampleAttachmentKey_NotSync);
    //获取时间戳
    uint64_t timeStamp = [((__bridge_transfer NSNumber *)VTFrameRef) longLongValue];
    
    FSLAVH264VideoEncoder *videoEncoder = (__bridge FSLAVH264VideoEncoder *)VTref;
    if(status != noErr) return;
    
    // 2.如果是关键帧, 获取SPS/PPS数据, 并且写入文件
    //获取sps和pps，sps和pps数据可以作为一个普通h264帧，放在h264视频流的最前面。
    if (keyframe && !videoEncoder->sps) {
        // 2.1.从CMSampleBufferRef获取CMFormatDescriptionRef
        CMFormatDescriptionRef format = CMSampleBufferGetFormatDescription(sampleBuffer);
        
        // 2.2.获取SPS信息
        const uint8_t *spsOut;
        size_t spsSize,spsCount;
         /**
         2.3.返回H.264格式描述中包含的参数集。
         @ CMFormatDescriptionRef 对CMFormatDescription对象的引用。
         @ parameterSetIndex 返回参数集的索引
         @ parameterSetSizeOut 指向要接收参数集的指针。如果不需要此信息，则传递NULL。
         @ parameterSetCountOut 包含在videoDesc中的AVC解码器配置记录中的参数集的数量。如果不需要此信息，则传递NULL。
         @ NALUnitHeaderLengthOut 指向一个int，以接收AVC视频样本或AVC参数集样本中NALUnitLength字段的大小(以字节为单位)。如果不需要此信息，则传递NULL。
          */
        OSStatus statusCode = CMVideoFormatDescriptionGetH264ParameterSetAtIndex(format, 0, &spsOut, &spsSize, &spsCount, NULL);
        if (statusCode != noErr) return;

        // 2.4.获取PPS信息
        const uint8_t *ppsOut;
        size_t ppsSize, ppsCount;
        statusCode = CMVideoFormatDescriptionGetH264ParameterSetAtIndex(format, 1, &ppsOut, &ppsSize, &ppsCount, NULL);
        if (statusCode != noErr) return;
        
        // 2.5.将SPS/PPS转成NSData, 并且写入文件
        NSData *spsData = [NSData dataWithBytes:spsOut length:spsSize];
        NSData *ppsData = [NSData dataWithBytes:ppsOut length:ppsSize];
        
        videoEncoder->sps = spsData;
        videoEncoder->pps = ppsData;
        
        // 2.6.写入文件
        [videoEncoder writeHeaderDataSps:spsData pps:ppsData];
    }
    
    
    // 3.获取编码后的数据, 写入文件
    // 3.1.获取真正的视频帧数据CMBlockBufferRef
    CMBlockBufferRef dataBuffer = CMSampleBufferGetDataBuffer(sampleBuffer);
    size_t length, totalLength;
    char *dataPointer;
    /**
     3.2. 获取对CMBlockBuffer表示的数据的访问权。
     @ dataBuffer 要操作的CMBlockBuffer。不能为空
     @ 0 缓冲区偏移范围内的偏移量。
     @ length 返回时，包含在指定偏移量处可用的数据量。可能是NULL。
     @ totalLength 返回时，包含块缓冲区的总数据长度(从偏移量0开始)。
     @ dataPointer 返回时，包含指向指定偏移量的数据字节的指针;lengthAtOffset字节
     可以在这个地址买到。可能是NULL。
     @ kCMBlockBufferNoErr如果数据在给定CMBlockBuffer内的指定偏移量处可访问，则为false。
     */
    OSStatus statusCodeRet = CMBlockBufferGetDataPointer(dataBuffer, 0, &length, &totalLength, &dataPointer);
    if(statusCodeRet != noErr) return;
    
    // 3.3.一帧的图像可能需要写入多个NALU单元 --> Slice切换
    size_t bufferOffset = 0;
    static const int AVCCHeaderLength = 4;
    while (bufferOffset < totalLength - AVCCHeaderLength) {
        
        // 3.4.从起始位置拷贝AVCCHeaderLength长度的地址, 计算NALULength
        uint32_t NALUnitLength = 0;
        memcpy(&NALUnitLength, dataPointer + bufferOffset, AVCCHeaderLength);
        //将32位整数从大端字节格式转换为主机的本机字节顺序。
        // 大端模式/小端模式-->系统模式
        // H264编码的数据是大端模式(字节序)
        NALUnitLength = CFSwapInt32BigToHost(NALUnitLength);

        // 3.5.从dataPointer开始, 根据长度创建NSData，将数据到导入协议
        FSLAVVideoRTMPFrame *videoFrame = [[FSLAVVideoRTMPFrame alloc] init];
        videoFrame.timestamp = timeStamp;
        videoFrame.data = [[NSData alloc] initWithBytes:(dataPointer + bufferOffset + AVCCHeaderLength) length:NALUnitLength];
        videoFrame.sps = videoEncoder->sps;
        videoFrame.pps = videoEncoder->pps;
        
        if (videoEncoder.h264Delegate && [videoEncoder.h264Delegate respondsToSelector:@selector(videoEncoder:videoFrame:)])
        {
            [videoEncoder.h264Delegate videoEncoder:videoEncoder videoFrame:videoFrame];
        }
        
        // 3.6.写入文件
        [videoEncoder writeEncodedData:videoFrame.data isKeyFrame:YES];
        
        // 3.7.重新设置bufferOffset
        bufferOffset += AVCCHeaderLength + NALUnitLength;
    }
}

#pragma mark -- private methods
/**
 将获取得到的sps、pps写入保存在本地的目录文件中
 
 @param sps 序列参数集
 @param pps 图像参数集
 */
- (void)writeHeaderDataSps:(NSData*)sps pps:(NSData*)pps
{
    // 1.拼接NALU的header
    const char bytes[] = "\x00\x00\x00\x01";
    size_t length = (sizeof bytes) - 1;
    NSData *ByteHeader = [NSData dataWithBytes:bytes length:length];

    // 2.将NALU的头&NALU的体写入文件
    [self.fileHandle writeData:ByteHeader];
    [self.fileHandle writeData:sps];
    [self.fileHandle writeData:ByteHeader];
    [self.fileHandle writeData:pps];
}


/**
 将编码后到数据写入到对应的目录文件中
 
 @param data 编码后的数据
 @param isKeyFrame 是否为关键帧
 */
- (void)writeEncodedData:(NSData*)data isKeyFrame:(BOOL)isKeyFrame
{
    NSLog(@"gotEncodedData %d", (int)[data length]);
    if (self.fileHandle != NULL)
    {
        const char bytes[] = "\x00\x00\x00\x01";
        size_t length = (sizeof bytes) - 1; //string literals have implicit trailing '\0'
        NSData *ByteHeader = [NSData dataWithBytes:bytes length:length];
        [self.fileHandle  writeData:ByteHeader];
        [self.fileHandle  writeData:data];
    }
}

@end
