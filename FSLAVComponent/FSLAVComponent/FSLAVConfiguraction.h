//
//  FSLAVConfiguraction.h
//  FSLAVComponent
//
//  Created by tutu on 2019/6/26.
//  Copyright © 2019 tutu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

#import "FSLAVFileManager.h"
NS_ASSUME_NONNULL_BEGIN

//录制状态
typedef NS_ENUM(NSInteger, FSLAVRecordState) {
    FSLAVRecordStateReadyToRecord = 0, //开始录制
    FSLAVRecordStateRecording,         //正在录制
    FSLAVRecordStatePause,             //暂停录制
    FSLAVRecordStateFinish,            //结束录制
    FSLAVRecordStateFailed,            //录制失败
    FSLAVRecordStateUnKnow             //录制时，发生未知原因
};

/**
 音视频录制的基础类
 */
@interface FSLAVConfiguraction : NSObject
/**定义实例变量*/
{
    
    NSString *_outputFileName;
    NSString *_saveSuffixFormat;
    NSURL *_savePathURL;
    BOOL _isAutomaticStop;
    NSUInteger _maxRecordDelay;
    NSTimeInterval _recordTimeLength;
}

/**定义属性变量*/

/**
 保存到本地document下的文件路径名称
 */
@property (nonatomic,strong) NSString *outputFileName;

/**
 保存到本地document下的音视频文件格式：如：mp4、mov、aac、caf
 */
@property (nonatomic,strong) NSString *saveSuffixFormat;

/**
 保存到本地document下的音视频文件URL路径
 */
@property (nonatomic,strong,readonly) NSURL *savePathURL;

/**
 是否开启自动停止录制,默认是no
 */
@property (nonatomic, assign) BOOL isAutomaticStop;

/**
 自动停止录制的最大录制时间，默认0s,可以一直录制
 */
@property (nonatomic, assign) NSUInteger maxRecordDelay;

/**
 当前的录制音视频的总时长
 */
@property (nonatomic, assign) NSTimeInterval recordTimeLength;

/**
 获取数据操作的本地路径
 
 @return 文件保存的本地目录
 */
- (NSString *)getSaveDatePath;
/**
 清除缓存
 
 @return  返回清除缓存结果
 */
- (BOOL)clearCacheData;

@end

NS_ASSUME_NONNULL_END
