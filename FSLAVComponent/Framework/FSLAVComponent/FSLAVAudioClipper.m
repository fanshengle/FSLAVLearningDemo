//
//  FSLAVAudioCliper.m
//  FSLAVComponent
//
//  Created by tutu on 2019/7/14.
//  Copyright © 2019 tutu. All rights reserved.
//

#import "FSLAVAudioClipper.h"

@interface FSLAVAudioClipper ()
{
    //导出素材会话
    AVAssetExportSession *_exporter;
    //剪辑 编辑视频环境
    AVMutableComposition *_clipComposition;
}

@end

@implementation FSLAVAudioClipper

#pragma mark - setter getter

- (void)setClipAudio:(FSLAVAudioClipperOptions *)clipAudio{
    _clipAudio = clipAudio;
    [self resetClipperOperation];
}

#pragma mark -- init
/**
 初始化音频剪辑器，用init初始化也可以，clipAudio都得自行配置
 
 @param clipAudio 需要裁剪的音轨
 @return FSLAVAudioCliper
 */
- (instancetype)initWithCliperAudioOptions:(FSLAVAudioClipperOptions *)clipAudio;
{
    if (self = [super init]) {
        _clipAudio = clipAudio;
    }
    return self;
}

/**
 设置默认参数配置
 */
- (void)setConfig;
{
    [super setConfig];
    
}

/**
 销毁对象
 */
- (void)destory{
    [super destory];
    
    [self cancelClipping];
}

#pragma mark -- public methods
/**
 开始剪辑音轨，该方法的剪辑音轨结果没有block回调过程，结果可通过协议拿到
 */
- (void)startClippingAudio;
{
    [self startClippingAudioWithCompletion:nil];
}

/**
 开始剪辑音轨，该方法的剪辑音轨结果有block回调，同时也可通过协议拿到
 */
- (void)startClippingAudioWithCompletion:(void (^ _Nullable)(NSString*, FSLAVClipStatus))handler;
{
    
    if (!_clipAudio) {
        fslLError(@"have not set a valid audio track");
        [self notifyStatus:FSLAVClipStatusCancelled];
        return;
    }
    [self notifyStatus:FSLAVClipStatusClipping];

    if(!_clipComposition){
        
        //编辑素材环境，创建新组合的可变对象。保证该对象是唯一的
        _clipComposition = [[AVMutableComposition alloc]init];
    }
    

    //2.导出音频剪辑结果
    [self exportAudioWithCompletionHandler:handler];
}

/**
 * 导出音频剪辑结果
 
 * @param handler block
 */
- (void)exportAudioWithCompletionHandler:(void (^ _Nullable)(NSString*, FSLAVClipStatus))handler;
{
    
    //在音频素材的编辑环境下添加音轨
    AVMutableCompositionTrack *compositionTrack = [_clipComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    NSError *error = nil;
    BOOL insertResult = NO;
    //将源跟踪的时间范围插入到组合的音轨中。
    insertResult = [compositionTrack insertTimeRange:_clipAudio.atTimeRange.CMTimeRange ofTrack:_clipAudio.audioTrack atTime:_clipAudio.atNodeTime error:&error];
    if (!insertResult) {
        fslLError(@"mix insert error : %@",error);
    }
    
    //将音频轨道添加到混合时使用的参数。
    AVMutableAudioMixInputParameters *mixInput = [AVMutableAudioMixInputParameters audioMixInputParametersWithTrack:compositionTrack];
    //设置音轨音量
    [mixInput setVolume:_clipAudio.audioVolume atTime:_clipAudio.atNodeTime];
    //创建一个可变的音频混合对象，用于管理混合音频轨道的输入参数。
    AVMutableAudioMix *audioMix = [AVMutableAudioMix audioMix];
    //混合的输入参数数组。
    audioMix.inputParameters = @[mixInput];
    
    //通过设置删除时间数组的方式来剪辑视频时，就不能使用atTimeRange的方式来剪辑视频。
    if ((_deleteTimeRangeArr && _deleteTimeRangeArr.count > 0) && CMTimeCompare(_clipAudio.atTimeRange.duration, _clipAudio.mediaTimeRange.duration) == 0) {
        
        //获取剪辑的最后输出总时长
        CMTime mediaTotalTime = [self outputLastTimeOfAudioClipWithTotolTime:_clipAudio.mediaAsset.duration];
        //更新时间对象
        _clipAudio.atTimeRange = [FSLAVTimeRange timeRangeWithStartTime:kCMTimeZero duration:mediaTotalTime];
        _clipAudio.mediaDuration = CMTimeGetSeconds(mediaTotalTime);
    }
    
    if (!_exporter) {
        //1.创建导出素材会话
        _exporter = [AVAssetExportSession exportSessionWithAsset:_clipAudio.mediaAsset presetName:AVAssetExportPresetAppleM4A];
    }
    
    //2.导出剪辑音频到该路径下
    _exporter.outputURL = _clipAudio.outputFileURL;
    //3.设置导出音频的数据格式.m4a
    _exporter.outputFileType = _clipAudio.appOutputFileType;
    //4.剪辑重点：设置剪辑的时间范围
    _exporter.timeRange = CMTimeRangeMake(kCMTimeZero, _clipAudio.atTimeRange.duration);
    _exporter.audioMix = audioMix;

    //5.导出音轨的状态回调
    [_exporter exportAsynchronouslyWithCompletionHandler:^{
        FSLAVClipStatus exportStatus = FSLAVClipStatusUnknown;
        switch (self->_exporter.status) {
                
            case AVAssetExportSessionStatusFailed: {
                exportStatus = FSLAVClipStatusFailed;
            }
                break;
            case AVAssetExportSessionStatusCompleted: {
                exportStatus = FSLAVClipStatusCompleted;
            }
                break;
            case AVAssetExportSessionStatusUnknown: {
                exportStatus = FSLAVClipStatusFailed;
            }
                break;
            case AVAssetExportSessionStatusExporting: {
                exportStatus = FSLAVClipStatusClipping;
            }
                break;
            case AVAssetExportSessionStatusCancelled: {
                exportStatus = FSLAVClipStatusCancelled;
            }
                break;
                
            default:{
                exportStatus = FSLAVClipStatusFailed;
            }
                break;
        }
        if (self->_exporter.error) {
            fslLError(@"exporter audio error : %@",self->_exporter.error);
        }
        
        [self notifyStatus:exportStatus];
        
        if (handler) {
            handler(self.clipAudio.outputFilePath,exportStatus);
        }
        
        [self resetClipperOperation];
    }];
}

/**
 取消剪辑操作
 */
- (void)cancelClipping;
{
    [self notifyStatus:FSLAVClipStatusCancelled];
    [self resetClipperOperation];
    [_clipAudio clearOutputFilePath];
}

#pragma mark -- private methods
/**
 排序后从composition中删除对应的视频
 
 @param totalTime 删除前的视频总时长
 @return 删除后的视频总时长
 */
- (CMTime)outputLastTimeOfAudioClipWithTotolTime:(CMTime)totalTime{
    
    //快速排序
    _deleteTimeRangeArr = [self quickSort:_deleteTimeRangeArr];
    //冒泡排序
    //_deleteTimeRangeArr = [self bubbleSort:_deleteTimeRangeArr];
    
    //最后剪辑之后的输出时间
    CMTime lastTotalTime = totalTime;
    //需要删除的总时间
    CMTime deleteTotalTime = kCMTimeZero;
    
    if (_deleteTimeRangeArr && _deleteTimeRangeArr.count > 0) {
        // 注：数组循环应从大到小进行，因为排序以开始时间由小到大进行，故下标越大记录的删除时间越靠后
        for (NSInteger i = _deleteTimeRangeArr.count - 1; i >= 0; i--) {
            FSLAVTimeRange *timeRange = _deleteTimeRangeArr[i];
            [self removeTimeRange:timeRange];
            //返回删除的总时间
            deleteTotalTime = CMTimeAdd(deleteTotalTime, timeRange.duration);
        }
        //总时间减去删除的总时间得到最后的总时间
        lastTotalTime = CMTimeSubtract(lastTotalTime, deleteTotalTime);
    }
    return lastTotalTime;
}

/**
 * 删除指定timeRange区域的音视频信息
 *
 * @param timeRange 要删除的视频信息
 */
- (void)removeTimeRange:(FSLAVTimeRange *)timeRange;
{
    if (!timeRange.isValid) {//时间范围是无效的
        fslLError(@"%@ timeRange is invalid",[timeRange description]);
        return;
    }
    
    //对媒体资源进行时间剪辑
    [_clipComposition removeTimeRange:CMTimeRangeMake(timeRange.start, timeRange.duration)];
}

#pragma mark -- 对需要删除的视频时间片段进行排序
/**
 冒泡排序：将视频剪辑的时间片段数组，按升序的方式o由小到大进行排序
 1. 从当前元素起，向后依次比较每一对相邻元素，若逆序则交换
 2. 对所有元素均重复以上步骤，直至最后一个元素
 
 @param sortArr 时间片段数组
 @return 排序之后的时间片段数组
 */
- (NSArray<FSLAVTimeRange *> *)bubbleSort:(NSMutableArray<FSLAVTimeRange *> *)sortArr;
{
    
    for (int i = 0; i<sortArr.count-1; i++) {/* 外循环为排序趟数，len个数进行len-1趟 */
        for (int j = 0; j<sortArr.count-1-i; j++) {/* 内循环为每趟比较的次数，第i趟比较len-i次 */
            
            NSInteger left = CMTimeGetSeconds(sortArr[j].start);
            NSInteger right = CMTimeGetSeconds(sortArr[j+1].start);
            if (left>right) {/* 相邻元素比较，若逆序则交换（升序为左大于右，降序反之） */
                
                [sortArr exchangeObjectAtIndex:j withObjectAtIndex:j+1];
            }
        }
    }
    return sortArr;
}

// 对要删除的数组内容根据 开始时间 有小到大进行排序
- (NSArray<FSLAVTimeRange *> *)quickSort:(NSArray<FSLAVTimeRange *> *)sortArr{
    
    NSMutableArray<FSLAVTimeRange *> * resultArr = [NSMutableArray arrayWithArray:sortArr];
    NSInteger first = 0;
    NSInteger last = sortArr.count-1;
    
    [self quickSort:resultArr withFirst:first withLast:last];
    return resultArr;
}

/**
 快速排序：将视频剪辑的时间片段数组，按升序的方式由小到大进行排序
 
 @param sortArr 时间片段数组
 @param first 首索引
 @param last  末索引
 */
- (void)quickSort:(NSMutableArray<FSLAVTimeRange *> *)sortArr withFirst:(NSInteger)first withLast:(NSInteger)last{
    if (first>=last) {// 递归结束条件
        return;
    }
    NSInteger i = first;
    NSInteger j = last;
    //标兵值(关键值)
    FSLAVTimeRange * keyTime = sortArr[i];
    //查询
    while (i<j) {
        
        // 从右边开始比较，比key大的数位置不变;
        // 从j开始向前搜索，即由后开始向前搜索(j--)，找到第一个小于key的值A[j]，将A[j]和A[i]的值交换；
        while (i<j && CMTimeCompare(sortArr[j].start, keyTime.start) != -1) {
            j--;
        }
        
        // 如果小于标兵就放到前面;只要出现一个比key小的数，将这个数放入左边i的位置
        sortArr[i] = sortArr[j];
        
        // 从左边开始比较，比key小的数位置不变
        // 从i开始向后搜索，即由前开始向后搜索(i++)，找到第一个大于key的A[i]，将A[i]和A[j]的值交换；
        while (i<j && CMTimeCompare(sortArr[i].start, keyTime.start)!=1) {
            i++;
        }
        //如果大于标兵就放到后面,只要出现一个比key大的数，将这个数放入右边j的位置
        sortArr[j] = sortArr[i];
    }
    
    sortArr[i] = keyTime;
    
    // 左递归
    [self quickSort:sortArr withFirst:first withLast:i-1];
    // 右递归
    [self quickSort:sortArr withFirst:i+1 withLast:last];
}
/**
 设置回调通知，并委托协议
 
 @param status 回调的剪辑状态
 */
- (void)notifyStatus:(FSLAVClipStatus)status;
{
    if(self.clipAudio.clipStatus == status) return;
    self.clipAudio.clipStatus = status;
    
    FSLRunSynchronouslyOnMainQueue(^{
        if ([self.clipDelegate respondsToSelector:@selector(didClippingAudioStatusChanged:onAudioClip:)]) {
            [self.clipDelegate didClippingAudioStatusChanged:status onAudioClip:self];
        }
        
        if (status == FSLAVClipStatusCompleted) {
            if ([self.clipDelegate respondsToSelector:@selector(didClipedAudioResult:onAudioClip:)]) {
                [self.clipDelegate didClipedAudioResult:_clipAudio onAudioClip:self];
            }
            if ([self.clipDelegate respondsToSelector:@selector(didCompletedClipAudioOutputPath:onAudioClip:)]) {
                [self.clipDelegate didCompletedClipAudioOutputPath:_clipAudio.outputFilePath onAudioClip:self];
            }
            
        }
    });
}


// 重置裁剪状态
- (void)resetClipperOperation;
{
    if (_exporter.status == AVAssetExportSessionStatusExporting || _exporter.status == AVAssetExportSessionStatusWaiting) {
        fslLWarn(@"Conditions cannot be reset during operation.");
        if (_exporter) {
            [_exporter cancelExport];
        }
    }else{
        if (_exporter) {
            [_exporter cancelExport];
        }
        
        if (_clipComposition) {
            [[_clipComposition tracks] enumerateObjectsUsingBlock:^(AVMutableCompositionTrack * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
               
                [self->_clipComposition removeTrack:obj];
            }];
        }
        _exporter = nil;
        _clipComposition = nil;
    }
}

@end
