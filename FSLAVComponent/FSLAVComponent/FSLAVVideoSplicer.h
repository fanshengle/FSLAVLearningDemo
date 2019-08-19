//
//  FSLAVVideoSplicer.h
//  FSLAVComponent
//
//  Created by TuSDK on 2019/8/15.
//  Copyright © 2019 tutu. All rights reserved.
//

#import "FSLAVCoreBase.h"
#import "FSLAVVideoSplicerOptions.h"

NS_ASSUME_NONNULL_BEGIN

@protocol FSLAVVideoSplicerDelegate;

/**
 视频拼接工具
 
 功能 (建议拼接的视频的方向与分辨率尽量一致)
 1、将多个视频的片段进行拼接
 
 */
@interface FSLAVVideoSplicer : FSLAVCoreBase

// 代理设置
@property (nonatomic, weak) id<FSLAVVideoSplicerDelegate> spliceDelegate;

// 设置拼接参数options，如：视频输出路径、视频的总时长等
@property (nonatomic,strong) FSLAVVideoSplicerOptions  *spliceOptions;

// 需要进行合并的视频，合并顺序按照数组顺序
@property (nonatomic, strong) NSArray<FSLAVVideoSplicerOptions *> *videos;

/**
 初始化视频拼接器，用init初始化也可以，需要另外配置videos
 
 @param spliceOptions 拼接多视频的配置项
 @return FSLAVVideoSplicer
 */
- (instancetype)initWithSplicerOptions:(FSLAVVideoSplicerOptions *)spliceOptions;

/**
 初始化视频拼接器，用init初始化也可以，需要另外配置videos
 
 @param videos 多视频
 @return FSLAVVideoSplicer
 */
- (instancetype)initWithSplicerVideos:(NSArray <FSLAVVideoSplicerOptions *> *)videos;

/**
 * 开始合并视频操作
 */
- (void)startSplicing;

/**
 * 开始合并视频操作 block回调
 */
- (void)startSplicingWithCompletionHandler:(void (^ _Nullable)(NSString *filePath, FSLAVSpliceStatus status))handler;

/**
 * 取消合并操作
 */
- (void)cancelSplicing;

@end


#pragma mark - protocol FSLAVVideoSplicerDelegate

/**
 视频拼接代理
 */
@protocol FSLAVVideoSplicerDelegate <NSObject>

@optional

/**
 状态通知代理
 
 @param status 一个/多个视频拼接状态
 @param videoSplicer 视频拼接器
 */- (void)didSplicingVideoStatusChanged:(FSLAVSpliceStatus)status onVideoSplice:(FSLAVVideoSplicer *)videoSplicer;


/**
 所有的拼接结果通知代理
 
 @param result 剪辑结果（如：包括地址输出）
 @param videoSplicer 视频拼接器
 */- (void)didSplicedVideoResult:(FSLAVVideoSplicerOptions *)result onVideoSplice:(FSLAVVideoSplicer *)videoSplicer;

/**
 拼接完成:结果回调
 @param filePath 拼接结果文件路径
 @param videoSplicer 视频拼接器
 */
- (void)didCompletedSpliceVideoOutputFilePath:(NSString *)filePath onVideoSplice:(FSLAVVideoSplicer *)videoSplicer;

/**
 多视频拼接进度通知代理
 
 @param progress 剪辑进度
 @param videoSplicer 视频拼接器
 */
- (void)didSplicingVideoProgressChanged:(CGFloat)progress onVideoSplice:(FSLAVVideoSplicer *)videoSplicer;

/**
 拼接完成：拼接的媒体总时间回调
 @param mediaTotalTime 音视频的总时长
 @param videoSplicer 视频拼接器
 */
- (void)didCompletedSpliceMediaTotalTime:(NSTimeInterval)mediaTotalTime onVideoSplice:(FSLAVVideoSplicer *)videoSplicer;

@end

NS_ASSUME_NONNULL_END
