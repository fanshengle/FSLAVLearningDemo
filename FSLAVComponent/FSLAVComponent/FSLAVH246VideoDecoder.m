//
//  FSLAVH246VideoDecoder.m
//  FSLAVComponent
//
//  Created by TuSDK on 2019/6/30.
//  Copyright © 2019 tutu. All rights reserved.
//

#import "FSLAVH246VideoDecoder.h"
#import "FSLProxy.h"


#define FreeCharP(p) if (p) {free(p); p = NULL;}
const uint8_t inputStartCode[4] = {0,0,0,1};

@interface FSLAVH246VideoDecoder ()
{
    VTDecompressionSessionRef decompressionSession;//解码会话
    
    /**信息扩展参数配置*/
    CMVideoFormatDescriptionRef videoFormateDesc;//sdp、pps、颜色空间、视频格式等信息扩展
    uint8_t *pSPS;//指向sps的指针地址
    NSInteger pSpsSize;//sps的数据大小
    uint8_t *pPPS;//指向pps的指针地址
    NSInteger pPpsSize;//pps的数据大小
    
    uint8_t *packetBuffer;//视频流数据的buffer指针地址
    long packetSize;//视频流数据的buffer的大小
    
    /**流数据读取设置*/
    NSInputStream *inputStream;//读取.h264文件的流数据
    uint8_t *inputBuffer;
    NSInteger inputSize;
    NSInteger inputMaxSize;
}

//流数据读取定时器
@property (nonatomic , strong) CADisplayLink *dispalyLink;

//在主线程中开辟新的队列来读取数据
@property (nonatomic, strong) dispatch_queue_t decodeQueue;
//@property (nonatomic, strong) AAPLEAGLLayer *playLayer;


@end

@implementation FSLAVH246VideoDecoder

@synthesize sampleBuffer = _sampleBuffer;
@synthesize pixelBuffer = _pixelBuffer;
@synthesize bufferImage = _bufferImage;
@synthesize bufferDisplayLayer = _bufferDisplayLayer;

- (instancetype)init
{
    self = [super init];
    if (self) {
        
        _videoSize = CGSizeMake(1000, 720);
        _bufferShowType = FSLAVH246VideoDecoderBufferShowType_Image;
        //创建了一个队列, 用于解码数据
        _decodeQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    }
    return self;
}

#pragma mark -- 懒加载
- (CADisplayLink *)dispalyLink{
    
    if (!_dispalyLink) {
        //消息转发，用了解决循环引用
        FSLProxy *proxy = [FSLProxy proxyWithTarget:self];
        //创建CADisplayLink, 用于定时获取信息
        _dispalyLink = [CADisplayLink displayLinkWithTarget:proxy selector:@selector(startReadStreamingData)];
        [_dispalyLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        [_dispalyLink setPaused:YES];
    }
    return _dispalyLink;
}

#pragma mark -- private methods
- (void)initBufferDisplayLayer{
    
    if(_bufferDisplayLayer) return;
    
    if (_bufferShowType == FSLAVH246VideoDecoderBufferShowType_Layer) {
        
        CGSize size = [[UIScreen mainScreen] bounds].size;
        //用于之后展示视频每帧数据
        _bufferDisplayLayer = [[AVSampleBufferDisplayLayer alloc] init];
        _bufferDisplayLayer.frame = CGRectMake(0, 0, size.width, size.height);
        _bufferDisplayLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    }
}

/**
 解码定时事件，用来读取流数据的每帧buffer
 */
- (void)startReadStreamingData{
    
    dispatch_sync(_decodeQueue, ^{
        // 1.读出流数据
        [self startReadPacketStreamingData];
        
        // 2.如果取出数据为NULL/0, 那么表示数据已经读完, 则停止读取
        if (self->packetBuffer == NULL || self->packetSize == 0) {
            
            if (self.decodeDelegate && [self.decodeDelegate respondsToSelector:@selector(didChangedVideoDecodeState:videoDecoder:)]) {
                [self.decodeDelegate didChangedVideoDecodeState:FSLAVH246VideoDecoderStateFinish videoDecoder:self];
            }
            
            //结束读出流数据
            [self endReadStreamingData];
            return;
        }
        
        // 3.获取NALUSize大小
        uint32_t naluSize = (uint32_t)(self->packetSize - 4);
        // 4.获取指向地址的指针
        uint32_t *pNaluSize = (uint32_t *)self->packetBuffer;
        // 将32位整数从主机的本机字节顺序转换为大端字节格式。
        *pNaluSize = CFSwapInt32HostToBig(naluSize);
        
        // 在buffer的前面填入代表长度的int
        CVPixelBufferRef pixelBuffer = NULL;
        // 0x1F
        // 0x27 0010 0111
        // 0x1F 0001 1111
        // 5.取出类型
        int naluType = self->packetBuffer[4] & 0x1f;
        switch (naluType) {
            case 0x05:
                // 5.1初始化硬解码，并开始解码，并返回解码buffer对象
                //NSLog(@"i frame");
                //
                [self initDecopressionSession];
                
                // 5.2.编码I帧数据
                pixelBuffer = [self decodeStreamingDataBufferFrame:self->packetBuffer bufferFrameSize:self->packetSize];
                break;
            case 0x07:
                // 5.3获取SPS信息，并保存
                self->pSpsSize = self->packetSize - 4;
                self->pSPS = malloc(self->pSpsSize);
                memcpy(self->pSPS, self->packetBuffer + 4, self->pSpsSize);
                break;
            case 0x08:
                // 5.4获取PPS信息，并保存
                self->pPpsSize = self->packetSize - 4;
                self->pPPS = malloc(self->pSpsSize);
                memcpy(self->pPPS, self->packetBuffer + 4, self->pPpsSize);
                break;
            default:
                // 5.5.解码B/P帧数据
                pixelBuffer = [self decodeStreamingDataBufferFrame:self->packetBuffer bufferFrameSize:self->packetSize];
                break;
        }
    
        NSLog(@"++++++>>>> %@", pixelBuffer);
        NSLog(@"Read Nalu size %ld", self->packetSize);
    });
}

/**
从内存中读取数据
*/
- (void)startReadPacketStreamingData{
    if (packetSize && packetBuffer) {
        packetSize = 0;
        FreeCharP(packetBuffer);
    }
    
    if (inputSize < inputMaxSize && inputStream.hasBytesAvailable) {
        inputSize += [inputStream read:inputBuffer + inputSize maxLength:inputMaxSize - inputSize];
    }
    
    if (memcmp(inputBuffer, inputStartCode, 4) == 0) {
        if (inputSize > 4) { // 除了开始码还有内容
            uint8_t *pStart = inputBuffer + 4;
            uint8_t *pEnd = inputBuffer + inputSize;
            while (pStart != pEnd) { //这里使用一种简略的方式来获取这一帧的长度：通过查找下一个0x00000001来确定。
                if(memcmp(pStart - 3, inputStartCode, 4) == 0) { // 是开头
                    packetSize = pStart - inputBuffer - 3;
                    packetBuffer = malloc(packetSize);
                    memcpy(packetBuffer, inputBuffer, packetSize); //复制packet内容到新的缓冲区
                    memmove(inputBuffer, inputBuffer + packetSize, inputSize - packetSize); //把缓冲区前移
                    inputSize -= packetSize;
                    break;
                }
                else {
                    ++pStart;
                }
            }
        }
    }
}

#pragma mark -- decode Block
/**
 硬解码回调函数:解压帧将通过调用outputCallback发出。
 
 decompressionOutputRefCon 反压缩输出putrefcon字段复制回调的引用值VTDecompressionOutputCallbackRecord结构。
 sourceFrameRefCon 帧的参考值，从sourceFrameRefCon参数复制到VTDecompressionSessionDecodeFrame。
 status 如果减压成功，则不会出错;一个错误代码，如果解压不成功。
 infoFlags 包含有关解码操作的信息。
 pixelBuffer 包含解压后的帧，如果解压成功;否则,空。重要提示:视频解压器可能仍然引用其中返回的imageBuffer
 如果没有设置kvtdecodeinfo_imagebuffermodiizable标志，则回调
 设置，则修改返回的imageBuffer是不安全的。
 
 presentationTimeStamp 框架的表示时间戳，它将通过调用来确定
 CMSampleBufferGetOutputPresentationTimeStamp;kCMTimeInvalid(如果不可用)。
 
 presentationDuration 帧的表示持续时间，将通过调用来确定
 CMSampleBufferGetOutputDuration;kCMTimeInvalid(如果不可用)。
 */
static void decompressionOutputCallback(void *decompressionOutputRefCon, void *sourceFrameRefCon, OSStatus status, VTDecodeInfoFlags infoFlags, CVImageBufferRef pixelBuffer, CMTime presentationTimeStamp, CMTime presentationDuration) {
    
    //这俩行必须这样写，这必须这样实现，不然其他地方获取的pixelBuffer都是为空。
    CVPixelBufferRef *outputPixelBuffer = (CVPixelBufferRef *)sourceFrameRefCon;
    *outputPixelBuffer = CVPixelBufferRetain(pixelBuffer);

    FSLAVH246VideoDecoder *decoder = (__bridge FSLAVH246VideoDecoder *)decompressionOutputRefCon;
    if (decoder.decodeDelegate && [decoder.decodeDelegate respondsToSelector:@selector(didDecodingStreamingDataBuffer:videoDecoder:)]) {
        [decoder.decodeDelegate didDecodingStreamingDataBuffer:pixelBuffer videoDecoder:decoder];
    }
}

#pragma mark -- public methods
/**
 解码之前，先需要将.h264编码文件中的数据，读取出来
 
 filePath .h264文件路径
 */
- (void)startReadStreamingDataFromPath:(NSString *)filePath{
    // 1.开始读取数据
    // 1.1.创建NSInputStream, 读取流
    //inputStream = [[NSInputStream alloc] initWithFileAtPath:[[NSBundle mainBundle] pathForResource:@"123" ofType:@"h264"]];
    inputStream = [[NSInputStream alloc] initWithFileAtPath:filePath];
    
    //2.打开流，开始读取
    [inputStream open];
    
    inputSize = 0;
    inputMaxSize = 720 * 1280;
    inputBuffer = malloc(inputMaxSize);
    
    //3.开启定时器，开始读取流数据
    [self.dispalyLink setPaused:NO];
    
    //4.创建渲染buffer的layer层
    [self initBufferDisplayLayer];
}

/**
 初始化解码会话
 */
- (void)initDecopressionSession{
    
    if (decompressionSession) return;
    // 1、定义SPS、PPS数据的数组
    const uint8_t *parameterSetPointers[2] = {pSPS,pPPS};
    const size_t parameterSetSizes[2] = {pSpsSize,pPpsSize};
    
    /**
     2.创建CMVideoFormatDescription对象
     allocator#> 创建CMFormatDescription时使用的CFAllocator。传递NULL以使用默认分配器。
     parameterSetCount#> 要包含在格式描述中的参数集的数目。该参数必须至少为2。
     parameterSetPointers#> 指向包含指向参数集的parameterSetCount指针的C数组
     parameterSetSizes#> 指向一个C数组，该数组包含每个参数集的大小(以字节为单位)。
     NALUnitHeaderLength#> AVC视频样本或AVC参数集样本中NALUnitLength字段的大小(以字节为单位)。通过1,2或4
     formatDescriptionOut#> formatDescriptionOut
     */
    OSStatus status =  CMVideoFormatDescriptionCreateFromH264ParameterSets(NULL, 2, parameterSetPointers, parameterSetSizes, 4, &videoFormateDesc);
    if(status != noErr) return;
    
    // 3.设置解码回调
    VTDecompressionOutputCallbackRecord callBackRecord;
    callBackRecord.decompressionOutputCallback = decompressionOutputCallback;
    //callBackRecord.decompressionOutputRefCon = NULL;
    callBackRecord.decompressionOutputRefCon = (__bridge void *)self;
    
    // 4.设置解码会话参数
    //CFDictionaryRef *destinationPixelBufferAttributes = CFDictionaryCreate(NULL, keys, values, 1, NULL, NULL);
    //NSDictionary *destinationPixelBufferAttributes = @{(__bridge NSString*)kCVPixelBufferPixelFormatTypeKey : @(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)};
    NSDictionary *destinationPixelBufferAttributes = @{
                                                       (id)kCVPixelBufferPixelFormatTypeKey:[NSNumber numberWithInt:kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange],
                                                       //硬解码必须是 kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange
                                                       //或者是kCVPixelFormatType_420YpCbCr8Planar
                                                       //因为iOS是nv12,其他是nv21
                                                       (id)kCVPixelBufferWidthKey:[NSNumber numberWithInt:_videoSize.height * 2],
                                                       (id)kCVPixelBufferHeightKey:[NSNumber numberWithInt:_videoSize.width * 2],
                                                       //这里宽高和编码反的
                                                       (id)kCVPixelBufferOpenGLCompatibilityKey:[NSNumber numberWithBool:YES]
                                                       };

    /**
     5.创建硬解码会话
     allocator#> 会话的分配器。传递NULL以使用默认分配器。
     videoFormat 描述源视频帧。
     videoDecoderSpecification#> 指定必须使用的特定视频解码器。传递NULL让视频工具箱选择解码器。
     destinationImageBufferAttributes#> 描述对发出的像素缓冲区的要求。传递NULL来设置没有需求。
     outputCallback#> 要用解压缩帧调用的回调。当且仅当您将调用VTDecompressionSessionDecodeFrameWithOutputHandler来解码帧时，传递NULL。
     decompressionSessionOut#> 指向一个变量以接收新的解压缩会话。
     */
    status = VTDecompressionSessionCreate(NULL, videoFormateDesc, NULL, (__bridge CFDictionaryRef)destinationPixelBufferAttributes, &callBackRecord, &decompressionSession);
    if (status != noErr) return;
    
    if (self.decodeDelegate && [self.decodeDelegate respondsToSelector:@selector(didChangedVideoDecodeState:videoDecoder:)]) {
        [self.decodeDelegate didChangedVideoDecodeState:FSLAVH246VideoDecoderStateStart videoDecoder:self];
    }
}


/**
 
 开始解码，对视频流数据进行解码

 frame 提取到的视频流图像数据buffer，
 frameSize 对应buffer的大小
 */
- (CVPixelBufferRef)decodeStreamingDataBufferFrame:(uint8_t *)frame bufferFrameSize:(long)frameSize{
    // 1.开始码定位到的NALU，通过之前的frame给blockBuffer赋值
    CMBlockBufferRef blockBuffer = NULL;
    
    /**
     CMBlockBufferCreateWithMemoryBlock接口构造CMBlockBufferRef。

     structureAllocator#> 用于分配CMBlockBuffer对象的分配器。NULL将导致要使用的默认分配器。
     memoryBlock#> 存储缓冲数据的内存块。如果为空，则在需要时分配内存块(通过调用)
     使用所提供的blockAllocator或customBlockSource到CMBlockBufferAssureBlockMemory()。如果非空,
     块将被使用，并将在新的CMBlockBuffer最终确定(即释放为
     最后一次)。
     
     blockLength#> 内存块的总长度(以字节为单位)。不能为零。这是它的大小,如果memoryBlock为空，则提供内存块或要分配的大小。
     blockAllocator#> 如果memoryBlock为空，则用于分配memoryBlock的分配器。如果memoryBlock是非空的，
     如果提供了这个分配器，则使用它来释放它。传递NULL将导致默认分配器
     
     customBlockSource#> 如果非null，它将用于分配和释放内存块(blockAllocator)
     参数被忽略)。如果提供了，并且memoryBlock参数为NULL，那么它的分配()例程必须为空
     非空。如果成功，在分配memoryBlock时将调用一次assign。免费的()
     在处理CMBlockBuffer时调用一次。
     
     offsetToData#> 内存块中的偏移量，CMBlockBuffer应该在内存块中引用数据。
     dataLength#> 内存块中从偏移量开始的相关数据字节数。
     flags#> 特性和控制标志
     blockBufferOut#> 接收新创建的CMBlockBuffer对象，保留计数为1。不能为空。
     */
    OSStatus status = CMBlockBufferCreateWithMemoryBlock(NULL, (void *)frame, frameSize, kCFAllocatorNull, NULL, 0, frameSize, 0, &blockBuffer);
    if(status != noErr) return NULL;
    
    // 3.创建解码的准备对象
    CMSampleBufferRef sampleBuffer = NULL;
    const size_t sampleSizeArray[] = {frameSize};
    
   /**
    将获取到的CMVideoFormatDescriptionRef、CMBlockBufferRef等数据包装成CMSampleBufferRef，进行解码
    
    allocator#> 用于分配CMSampleBuffer对象的分配器。传递kCFAllocatorDefault以使用默认分配器。
    dataBuffer#> 已经包含媒体数据的CMBlockBuffer。不能为空。
    formatDescription#> 媒体数据格式的描述。可以为空。
    numSamples#> CMSampleBuffer中的样本数量。可以是0。
    numSampleTimingEntries#> sampleTimingArray中的条目数。必须是0、1或数字样本。
    sampleTimingArray#> CMSampleTimingInfo结构的数组，每个示例一个结构。
    numSampleSizeEntries#> sampleSizeArray中的条目数。必须是0、1或数字样本。
    sampleSizeArray#> 数组大小条目，每个示例一个条目。如果所有的样本都有
    同样大小，您可以传递包含一个示例大小的单个大小条目。可以为空。必须
    如果样本在缓冲区中不是连续的，则为NULL(例如。非交织音频，其中的通道
    单个示例的值分散在缓冲区中)。
    
    sampleBufferOut#> sampleBufferOut
    @return <#return value
    */
    //status = CMSampleBufferCreateReady(NULL, blockBuffer, videoFormateDesc, 0, 0, NULL, 0, sampleSizeArray, &sampleBuffer);
    status = CMSampleBufferCreateReady(kCFAllocatorDefault, blockBuffer, videoFormateDesc, 1, 0, NULL, 1, sampleSizeArray, &sampleBuffer);
    if(status != noErr) return NULL;

    CVPixelBufferRef outputPixelBuffer = NULL;
    if (_bufferShowType == FSLAVH246VideoDecoderBufferShowType_Layer) {//直接将sampleBuffer传给AVSampleBufferDisplayLayer来显示
        //记录sampleBuffer值
        _sampleBuffer = sampleBuffer;

        CFArrayRef attachments = CMSampleBufferGetSampleAttachmentsArray(sampleBuffer, YES);
        CFMutableDictionaryRef dict = (CFMutableDictionaryRef)CFArrayGetValueAtIndex(attachments, 0);
        CFDictionarySetValue(dict, kCMSampleAttachmentKey_DisplayImmediately, kCFBooleanTrue);
        CFDictionarySetValue(dict, kCMSampleAttachmentKey_IsDependedOnByOthers, kCFBooleanTrue);

        int nalu_type = (frame[4] & 0x1F);
        if (nalu_type == 1) {
            //P-frame
            CFDictionarySetValue(dict, kCMSampleAttachmentKey_NotSync, kCFBooleanTrue);
            CFDictionarySetValue(dict, kCMSampleAttachmentKey_DependsOnOthers, kCFBooleanTrue);
        } else {
            //I-frame
            CFDictionarySetValue(dict, kCMSampleAttachmentKey_NotSync, kCFBooleanFalse);
            CFDictionarySetValue(dict, kCMSampleAttachmentKey_DependsOnOthers, kCFBooleanFalse);
        }
    }else{//显示pixelBuffer
        
        // 3.开始解码
        status = VTDecompressionSessionDecodeFrame(decompressionSession, sampleBuffer, 0, &outputPixelBuffer, NULL);
        //记录pixelBuffer值
        _pixelBuffer = CVPixelBufferRetain(outputPixelBuffer);
        if(status != noErr) return NULL;
        
        if (_bufferShowType == FSLAVH246VideoDecoderBufferShowType_Image) {
            
            _bufferImage = [self pixelBufferToImage:_pixelBuffer];
        }
    }
    
    if (self.decodeDelegate && [self.decodeDelegate respondsToSelector:@selector(didChangedVideoDecodeState:videoDecoder:)]) {
        [self.decodeDelegate didChangedVideoDecodeState:FSLAVH246VideoDecoderStateDecoding videoDecoder:self];
    }
    
    // 4.释放资源
    CFRelease(sampleBuffer);
    CFRelease(blockBuffer);
    return outputPixelBuffer;
}

/**
 将pixelBuffer转成image，解码pixelBuffer的RGB数据时的img
 
 @param pixelBuffer 流数据buffer
 @return image
 */
- (UIImage *)pixelBufferToImage:(CVPixelBufferRef)pixelBuffer
{
    UIImage *image = nil;
    if (!self.isNeedPerfectImg) {
        //第1种绘制（可直接显示，不可保存为文件(无效缺少图像描述参数)）
        CIImage *ciImage = [CIImage imageWithCVPixelBuffer:pixelBuffer];
        image = [UIImage imageWithCIImage:ciImage];
    } else {
        //第2种绘制（可直接显示，可直接保存为文件，相对第一种性能消耗略大）
        CIImage *ciImage = [CIImage imageWithCVPixelBuffer:pixelBuffer];
        CIContext *temporaryContext = [CIContext contextWithOptions:nil];
        CGImageRef videoImage = [temporaryContext createCGImage:ciImage fromRect:CGRectMake(0, 0, CVPixelBufferGetWidth(pixelBuffer), CVPixelBufferGetHeight(pixelBuffer))];
        image = [[UIImage alloc] initWithCGImage:videoImage];
        CGImageRelease(videoImage);
    }
    
    return image;
}


/**
 buffer快照

 @return image
 */
- (UIImage *)snapshot
{
    UIImage *img = nil;
    if (self.bufferDisplayLayer) {
        UIGraphicsBeginImageContext(self.bufferDisplayLayer.bounds.size);
        [self.bufferDisplayLayer renderInContext:UIGraphicsGetCurrentContext()];
        img = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    } else {
        if (_bufferShowType == FSLAVH246VideoDecoderBufferShowType_Pixel) {
            if (self.pixelBuffer) {
                img = [self pixelBufferToImage:self.pixelBuffer];
            }
        } else {
            img = self.bufferImage;
        }
        
        if (!self.isNeedPerfectImg) {
            UIGraphicsBeginImageContext(CGSizeMake(img.size.width, img.size.height));
            [img drawInRect:CGRectMake(0, 0, img.size.width, img.size.height)];
            img = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
        }
    }
    
    return img;
}

#pragma mark -- detory Object
/**
 解码中，停止读取流数据，销毁解码会话，释放解码对象
 */
- (void)endReadStreamingData{
    
    if (!inputStream) return;
    [inputStream close];
    inputStream = nil;
    if (inputBuffer) {
        FreeCharP(inputBuffer);
    }
    
    //销毁定时器
    [self.dispalyLink setPaused:YES];
    self.dispalyLink = nil;
    
    //销毁解码会话等对象
    [self endDecodeStreamingData];
}


/**
 解码中，停止对流数据的解码操作，并释放对象
 */
- (void)endDecodeStreamingData{
    
    if (!decompressionSession) return;
    VTDecompressionSessionInvalidate(decompressionSession);
    CFRelease(decompressionSession);
    decompressionSession = NULL;
    
    CFRelease(videoFormateDesc);
    videoFormateDesc = NULL;
    
    FreeCharP(pSPS);
    FreeCharP(pPPS);
    pSpsSize = pPpsSize = 0;
    
    if(!_bufferDisplayLayer) return;
    [self.bufferDisplayLayer removeFromSuperlayer];
}

- (void)dealloc{
    
    NSLog(@"视频解码器被释放了");
    if (_dispalyLink) {
        [self endReadStreamingData];
    }
}

@end
