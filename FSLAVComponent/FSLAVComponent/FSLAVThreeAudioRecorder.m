//
//  FSLAVThreeAudioRecorder.m
//  FSLAVComponent
//
//  Created by tutu on 2019/7/8.
//  Copyright © 2019 tutu. All rights reserved.
//

#import "FSLAVThreeAudioRecorder.h"

NSString *const FSLAudioComponentFailedToCreateNotification = @"FSLAudioComponentFailedToCreateNotification";

@interface FSLAVThreeAudioRecorder ()

/**
 音频组件示例,组件实例或对象是音频单元或音频编解码器。
 */
@property (nonatomic, assign) AudioComponentInstance componetInstance;

/**
 音频组件
 */
@property (nonatomic, assign) AudioComponent audioComponent;

/**
 音频采集任务
 */
@property (nonatomic) dispatch_queue_t audioCaptureTaskQueue;

/**
 开启音频采集
 */
@property (nonatomic, assign) BOOL isAudioCapture;
/**文件写入对象*/
@property (nonatomic , strong) NSFileHandle *fileHandle;

@end

@implementation FSLAVThreeAudioRecorder

- (instancetype)initWithAudioRecordOptions:(FSLAVAudioRecorderOptions *)options{
    if (self = [super initWithAudioRecordOptions:options]) {
        
        _audioCaptureTaskQueue = dispatch_queue_create("com.FSLAVComponent.audioCapture.Queue", NULL);
        [self initAudioCaptureSession];
    }
    return self;
}

/**
 文件写入对象
 
 @return fileHandle
 */
- (NSFileHandle *)fileHandle{
    if (!_fileHandle) {
        
        _fileHandle = [NSFileHandle fileHandleForWritingAtPath:[_options createSaveDatePath]];
    }
    return _fileHandle;
}

/**
 *  开启音频采集
 
 *  audiocapture 是否开启音频采集
 */
- (void)setEnableAudioCapture:(BOOL)enableAudioCapture
{
    if (_enableAudioCapture == enableAudioCapture) return;
    _enableAudioCapture = enableAudioCapture;
    if (_enableAudioCapture)
    {
        if (_audioCaptureTaskQueue)
        {
            dispatch_async(_audioCaptureTaskQueue, ^{
                self.isAudioCapture = YES;
                [self resetAudioSessionCategory];
                //启动I/O音频单元，该音频单元又启动与其连接的音频单元处理图。
                AudioOutputUnitStart(self.componetInstance);
            });
        }
    } else
    {
        self.isAudioCapture = NO;
    }
}

/**
 开始录制
 */
- (void)startRecord{
    
    self.enableAudioCapture = YES;
}


/**
 停止录制
 */
- (void)stopRecord{
    
    self.enableAudioCapture = NO;
}


#pragma mark -- 初始化音频捕获会话
- (void)initAudioCaptureSession{
    _isAudioCapture = NO;
    
    //1.获取音频会话实例
    AVAudioSession *session = [AVAudioSession sharedInstance];
    
    //添加通知:当系统的音频路由发生变化时发布
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(handleRouteChange:)
                                                 name: AVAudioSessionRouteChangeNotification
                                               object: session];
    //添加通知:当发生音频中断时发布。
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(handleInterruption:)
                                                 name: AVAudioSessionInterruptionNotification
                                               object: session];
    //2.设置音频单元
    AudioComponentDescription acd;
    //一种唯一的4字节代码，用于标识音频组件的泛型类型
    acd.componentType = kAudioUnitType_Output;
    //这个例子的特殊风味
    acd.componentSubType = kAudioUnitSubType_RemoteIO;
    //供应商标识
    acd.componentManufacturer = kAudioUnitManufacturer_Apple;
    //必须设置为零，除非请求一个已知的特定值
    acd.componentFlags = 0;
    //必须设置为零，除非请求一个已知的特定值
    acd.componentFlagsMask = 0;
    //查找音频单元,查找指定音频组件之后匹配指定AudioComponentDescription结构的下一个组件。
    self.audioComponent = AudioComponentFindNext(NULL, &acd);
    
    //3.获取音频单元实例,创建音频组件的新实例
    OSStatus status = AudioComponentInstanceNew(_audioComponent, &_componetInstance);
    if (status != noErr) {
        NSLog(@"AudioSource new AudioComponent error");
        [self handleAudioComponentCreationFailure];
    }
    
    //4.设置音频单元属性-->可读写 0-->不可读写 1-->可读写
    UInt32 flagOne = 1;
    /**
     设置音频单元属性的值。
     API可用于设置属性的值。属性值对音频单元总是通过引用传递

     inUnit 音频单元
     inID 属性标识符
     inScope 属性的范围
     inElement 范围的元素
     inData 如果不为空，则为将要设置的属性的新值。然后inDataSize应该为零，然后该调用用于删除a以前为属性设置值。
     此删除仅适用于有些属性，因为大多数属性总是有一个默认值，如果没有集。
     inDataSize inData中提供的数据的大小
     */
    status = AudioUnitSetProperty(_componetInstance, kAudioOutputUnitProperty_EnableIO, kAudioUnitScope_Input, 1, &flagOne, sizeof(flagOne));
    if (status != noErr) {
        NSLog(@"AudioUnitSetProperty EnableIO error");
        return;
    }
    
    //5.设置音频流的音频数据格式规范。
    AudioStreamBasicDescription desc = {0};
    //采样率：当流以正常速度播放时，流中每秒数据帧数。对于压缩格式，此字段表示每秒等效解压缩数据的帧数。
    desc.mSampleRate = _options.audioSetting.audioSampleRat;
    //音频格式:指定流中一般音频数据格式的标识符。参见音频数据格式标识符。这个值必须是非零的。
    desc.mFormatID = (UInt32)_options.audioSetting.audioFormat;
    //指定格式细节的特定于格式的标志。设置为0表示没有格式标志。有关适用于每种格式的标志，请参阅音频数据格式标识符。
    desc.mFormatFlags = kAudioFormatFlagIsSignedInteger | kAudioFormatFlagsNativeEndian | kAudioFormatFlagIsPacked;
    //声道数目(默认 2)
    desc.mChannelsPerFrame = (UInt32)_options.audioSetting.audioChannels;
    //音频数据包中的帧数。对于未压缩的音频，值为1。
    //对于可变比特率格式，该值是一个较大的固定数字，比如AAC的1024。对于每个数据包帧数可变的格式，如Ogg Vorbis，将此字段设置为0。
    desc.mFramesPerPacket = 1;
    desc.mBitsPerChannel = (UInt32)_options.audioSetting.audioLinearBitDepth;
    //音频缓冲区中从一帧开始到下一帧开始的字节数。为压缩格式将此字段设置为0。每帧多少字节 bytes -> bit / 8
    desc.mBytesPerFrame = desc.mBitsPerChannel / 8 * desc.mChannelsPerFrame;
    //音频数据包中的字节数。若要指示可变包大小，请将此字段设置为0。
    //对于使用可变包大小的格式，请使用AudioStreamPacketDescription结构指定每个包的大小。
    desc.mBytesPerPacket = desc.mBytesPerFrame * desc.mFramesPerPacket;
    status = AudioUnitSetProperty(_componetInstance, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 1, &desc, sizeof(desc));
    if (status != noErr) {
        NSLog(@"AudioUnitSetProperty StreamFormat error");
        return;
    }
    
    //6.设置回调函数,用于向音频单元注册输入回调函数。
    AURenderCallbackStruct cb;
    cb.inputProcRefCon = (__bridge void *)(self);
    cb.inputProc = handleInputBuffer;
    status = AudioUnitSetProperty(_componetInstance, kAudioOutputUnitProperty_SetInputCallback, kAudioUnitScope_Global, 1, &cb, sizeof(cb));
    if(status != noErr){
        NSLog(@"AudioUnitSetProperty StreamFormat InputCallback error");
        return;
    }
    
    //7.初始化音频单元
    status = AudioUnitInitialize(_componetInstance);
    if (status != noErr) {
        NSLog(@"AudioUnitSetProperty StreamFormat error");
        [self handleAudioComponentCreationFailure];
        return;
    }
    
    //8、设置输入和输出的首选采样率。
    [session setPreferredSampleRate:_options.audioSetting.audioSampleRat error:nil];
    
    //9、重置音频会话分类
    [self resetAudioSessionCategory];
}

/**
 *  回调
 
 *  inRefCon 回调对象
 *  ioActionFlags 调用的上下文
 *  inTimeStamp 时间戳
 *  inBusNumber 音频单元数量
 *  inNumberFrames 样本帧的数量
 *  ioData 音频数据
 *
 *  @return status
 */
static OSStatus handleInputBuffer(void *inRefCon,
                                  AudioUnitRenderActionFlags *ioActionFlags,
                                  const AudioTimeStamp *inTimeStamp,
                                  UInt32 inBusNumber,
                                  UInt32 inNumberFrames,
                                  AudioBufferList *ioData)
{
    @autoreleasepool {
        FSLAVThreeAudioRecorder *recorder = (__bridge FSLAVThreeAudioRecorder *)inRefCon;
        if(!recorder) return -1;
        
        AudioBuffer buffer;
        //指向音频数据缓冲区的指针。
        buffer.mData = NULL;
        //由mData字段指向的缓冲区中的字节数。
        buffer.mDataByteSize = 0;
        //缓冲区中交错通道的数目。如果数字是1，则缓冲区是非交错的。
        buffer.mNumberChannels = 1;
        
        AudioBufferList bufferList;
        //mBuffers数组中AudioBuffer结构的数目。
        bufferList.mNumberBuffers = 1;
        bufferList.mBuffers[0] = buffer;
        
        /**
         渲染操作，其中ioData将包含音频单元的结果

         inUnit#> 音频单元
         ioActionFlags#> 呈现操作的任何适当操作标志
         inTimeStamp#> 应用于此特定呈现操作的时间戳。当为多个输出总线呈现时间戳通常是相同的对于每个输出总线，
         所以音频单元能够毫无疑问地确定这是相同的渲染操作
         inOutputBusNumber#> 要呈现的输出总线
         inNumberFrames#> 要呈现的样本帧数
         ioData#> 音频单元要呈现到其中的音频缓冲区列表。
         */
        OSStatus status = AudioUnitRender(recorder.componetInstance,
                                          ioActionFlags,
                                          inTimeStamp,
                                          inBusNumber,
                                          inNumberFrames,
                                          &bufferList);
        
        if (!recorder.isAudioCapture)
        {
            dispatch_sync(recorder.audioCaptureTaskQueue, ^{
                AudioOutputUnitStop(recorder.componetInstance);
            });
            
            return status;
        }
        
        if (recorder.muted)
        {
            for (int i = 0; i < bufferList.mNumberBuffers; i++)
            {
                AudioBuffer ab = bufferList.mBuffers[i];
                memset(ab.mData, 0, ab.mDataByteSize);
            }
        }
        
        if (!status)
        {
            
            if (recorder.delegate && [recorder.delegate respondsToSelector:@selector(didRecordingAudioData:recorder:)])
            {
                //获取到PCM原始音频数据
                NSData *audioData = [NSData dataWithBytes:bufferList.mBuffers[0].mData length:bufferList.mBuffers[0].mDataByteSize];
                [recorder.delegate didRecordingAudioData:audioData recorder:recorder];
                NSLog(@"Recorder Audio Data Length ---->%lu",(unsigned long)audioData.length);
            }
        }
        return status;
    }
}

/**
 *  处理音频采集错误
 */
- (void)handleAudioComponentCreationFailure
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:FSLAudioComponentFailedToCreateNotification object:nil];
    });
}

/**
 *  处理消息
 
 *  notification 消息
 */
- (void)handleRouteChange:(NSNotification *)notification
{
    NSString *seccReason = @"";
    NSInteger reason = [[[notification userInfo] objectForKey:AVAudioSessionRouteChangeReasonKey] integerValue];
    switch (reason) {
        case AVAudioSessionRouteChangeReasonNoSuitableRouteForCategory:
            seccReason = @"The route changed because no suitable route is now available for the specified category.";
            NSLog(@"%@",seccReason);
            break;
        case AVAudioSessionRouteChangeReasonWakeFromSleep:
            seccReason = @"The route changed when the device woke up from sleep.";
            NSLog(@"%@",seccReason);
            break;
        case AVAudioSessionRouteChangeReasonOverride:
            seccReason = @"The output route was overridden by the app.";
            NSLog(@"%@",seccReason);
            break;
        case AVAudioSessionRouteChangeReasonCategoryChange:
            seccReason = @"The category of the session object changed.";
            NSLog(@"%@",seccReason);
            break;
        case AVAudioSessionRouteChangeReasonOldDeviceUnavailable:
            seccReason = @"The previous audio output path is no longer available.";
            NSLog(@"%@",seccReason);
            break;
        case AVAudioSessionRouteChangeReasonNewDeviceAvailable:
            seccReason = @"A preferred new audio output path is now available.";
            NSLog(@"%@",seccReason);
            break;
        case AVAudioSessionRouteChangeReasonUnknown:
        default:
            seccReason = @"The reason for the change is unknown.";
            NSLog(@"%@",seccReason);
            break;
    }
}

/**
 *  一个音频中断发生时作出处理
 
 *  notification 消息
 */
- (void)handleInterruption:(NSNotification *)notification
{
    NSInteger reason = 0;
    NSString *reasonStr = @"";
    if ([notification.name isEqualToString:AVAudioSessionInterruptionNotification])
    {
        reason = [[[notification userInfo] objectForKey:AVAudioSessionInterruptionTypeKey] integerValue];
        if (reason == AVAudioSessionInterruptionTypeBegan)
        {
            if (self.isAudioCapture)
            {
                if (_audioCaptureTaskQueue)
                {
                    dispatch_sync(_audioCaptureTaskQueue, ^{
                        //停止I/O音频单元，而该音频单元又停止与之连接的音频单元处理图形。
                        AudioOutputUnitStop(self.componetInstance);
                    });
                }
            }
        }
        
        if (reason == AVAudioSessionInterruptionTypeEnded)
        {
            reasonStr = @"AVAudioSessionInterruptionTypeEnded";
            NSNumber *seccondReason = [[notification userInfo] objectForKey:AVAudioSessionInterruptionOptionKey];
            switch ([seccondReason integerValue]) {
                case AVAudioSessionInterruptionOptionShouldResume:
                    if (self.isAudioCapture) {
                        if (_audioCaptureTaskQueue)
                        {
                            dispatch_async(_audioCaptureTaskQueue, ^{
                                AudioOutputUnitStart(self.componetInstance);
                            });
                        }
                    }
                    break;
                default:
                    break;
            }
        }
        
    }
}



#pragma mark -- 对象销毁方法
/**
 *  销毁
 */
- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    if (_audioCaptureTaskQueue)
    {
        dispatch_sync(_audioCaptureTaskQueue, ^{
            if (self.componetInstance)
            {
                AudioOutputUnitStop(self.componetInstance);
                AudioComponentInstanceDispose(self.componetInstance);
                self.componetInstance = nil;
                self.audioComponent = nil;
            }
        });
    }
}
@end
