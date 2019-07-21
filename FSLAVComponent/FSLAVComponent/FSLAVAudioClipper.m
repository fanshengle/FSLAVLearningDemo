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
}

@end

@implementation FSLAVAudioClipper

#pragma mark - setter getter

- (void)setClipAudio:(FSLAVCliperAudioOptions *)clipAudio{
    _clipAudio = clipAudio;
    
}


#pragma mark -- init
/**
 初始化音频剪辑器，用init初始化也可以，clipAudio都得自行配置
 
 @param clipAudio 需要裁剪的音轨
 @return FSLAVAudioCliper
 */
- (instancetype)initWithCliperAudioOptions:(FSLAVCliperAudioOptions *)clipAudio;
{
    if (self = [super init]) {
        _clipAudio = clipAudio;
    }
    return self;
}

#pragma mark -- public methods
/**
 开始剪辑音轨，该方法的剪辑音轨结果没有block回调过程，结果可通过协议拿到
 */
- (void)startClippingAudio;
{
    id block = nil;
    [self startClippingAudioWithCompletion:block];
}

/**
 开始剪辑音轨，该方法的剪辑音轨结果有block回调，同时也可通过协议拿到
 */
- (void)startClippingAudioWithCompletion:(void (^)(NSURL*, FSLAVClipStatus))handler;
{

    if (!_clipAudio) {
        fslLError(@"have not set a valid audio track");
        [self notifyStatus:FSLAVClipStatusCancelled];
    }
    if (!_exporter) {
        //1.创建导出素材会话
        _exporter = [AVAssetExportSession exportSessionWithAsset:_clipAudio.audioAsset presetName:AVAssetExportPresetAppleM4A];
        //添加进度观察者
        [self addProgressObserver];
    }
    //2.导出剪辑音频到该路径下
    _exporter.outputURL = _clipAudio.outputFileURL;
    //3.设置导出音频的数据格式.m4a
    _exporter.outputFileType = AVFileTypeAppleM4A;
    //4.剪辑重点：设置剪辑的时间范围
    _exporter.timeRange = _clipAudio.atTimeRange.CMTimeRange;
    
    [self notifyStatus:FSLAVClipStatusClipping];
    
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
            handler(self->_exporter.outputURL,exportStatus);
        }
        
        [self resetClipperOperation];
    }];
}

/**
 取消剪辑操作
 */
- (void)cancelClipping;
{
    if (_exporter) {
        if (_exporter.status == AVAssetExportSessionStatusExporting || _exporter.status == AVAssetExportSessionStatusWaiting) {
            
            [_clipAudio clearOutputFilePath];
            [self notifyStatus:FSLAVClipStatusCancelled];
            [self resetClipperOperation];
        }
    }
}

#pragma mark -- private methods
/**
 增加进度观察者
 */
- (void)addProgressObserver{
    
    if (_exporter) {
        [_exporter addObserver:self forKeyPath:@"progress" options:NSKeyValueObservingOptionNew context:nil];
    }
}

/**
 移除进度观察者
 */
- (void)removeProgressObserver{
    if (_exporter) {
        [_exporter removeObserver:self forKeyPath:@"progress" context:nil];
    }
}

#pragma mark - FSLAVAssetExportSession progress
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context{
    
    if ([@"progress" isEqualToString:keyPath]){
        //progress
        id newValue = [change objectForKey:NSKeyValueChangeNewKey];
        CGFloat progerss = 0.9 + ( [newValue floatValue] / 10);
        [self notifyProgress:progerss];
    }
}
/**
 设置回调通知，并委托协议
 
 @param status 回调的剪辑状态
 */
- (void)notifyStatus:(FSLAVClipStatus)status;
{
    if (![NSThread isMainThread]) {
        dispatch_sync(dispatch_get_main_queue(), ^{
            if ([self.clipDelegate respondsToSelector:@selector(didClippingAudioStatusChanged:onAudioClip:)]) {
                [self.clipDelegate didClippingAudioStatusChanged:status onAudioClip:self];
            }
        });
    }else{
        if ([self.clipDelegate respondsToSelector:@selector(didClippingAudioStatusChanged:onAudioClip:)]) {
            [self.clipDelegate didClippingAudioStatusChanged:status onAudioClip:self];
        }
    }
    if (status == FSLAVClipStatusCompleted) {
        if ([self.clipDelegate respondsToSelector:@selector(didClipedAudioResult:onAudioClip:)]) {
            [self.clipDelegate didClipedAudioResult:_clipAudio onAudioClip:self];
        }
    }
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
        [self removeProgressObserver];
        _exporter = nil;
    }
}

/**
 通知分段时间片段合成进度
 
 @param progress 当前进度
 */
- (void)notifyProgress:(CGFloat)progress{
    
//    if ([self.compositionDelegate respondsToSelector:@selector(didCompositionMediaProgressChanged:progress:composition:)]) {
//        [self.compositionDelegate didCompositionMediaStatusChanged:progress composition:self];
//    }
}
/**
 销毁对象
 */
- (void)destory{
    [super destory];

    [self cancelClipping];
}
@end
