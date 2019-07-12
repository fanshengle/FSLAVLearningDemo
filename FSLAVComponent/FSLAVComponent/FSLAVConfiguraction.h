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
    FSLAVRecordStateLessMinRecordTime, //小于最小录制时间
    FSLAVRecordStateMoreMaxRecorTime,  //大于等于最大录制时间
    FSLAVRecordStatePause,             //暂停录制
    FSLAVRecordStateFinish,            //结束录制
    FSLAVRecordStateFailed,            //录制失败
    FSLAVRecordStateUnKnow             //录制时，发生未知原因
};

//文件在沙盒中的位置类型
typedef NS_ENUM(NSInteger, FSLAVSandboxDirType) {
    
    FSLAVSandboxDirDocuments,
    FSLAVSandboxDirLibrary,
    FSLAVSandboxDirCache
};

/**
 音视频录制的基础配置类
 */
@interface FSLAVConfiguraction : NSObject
/**定义实例变量*/
{
    
    NSString *_outputFileName;
    NSString *_saveSuffixFormat;
    NSURL *_savePathURL;
    NSString *_savePathURLStr;
    NSURL *_exportRandomURL;
    NSString *_exportRandomURLStr;
    BOOL _isAutomaticStop;
    NSUInteger _maxRecordDelay;
    NSTimeInterval _recordTimeLength;
}

/**定义属性变量*/

/**
 文件保存在沙盒哪个路径下
 */
@property (nonatomic, assign) FSLAVSandboxDirType sandboxDirType;

/**
 保存到本地FSLAVSandboxDirType下的文件路径名称
 */
@property (nonatomic,strong) NSString *outputFileName;

/**
 保存到本地FSLAVSandboxDirType下的音视频文件格式：如：mp4、mov、aac、caf
 */
@property (nonatomic,strong) NSString *saveSuffixFormat;

/**
 保存到本地FSLAVSandboxDirType下的音视频文件URL路径
 */
@property (nonatomic,strong,readonly) NSURL *savePathURL;

/**
 保存到本地FSLAVSandboxDirType下的音视频文件Str路径
 */
@property (nonatomic,strong,readonly) NSString *savePathURLStr;

/**
 导出保存文件对应文件夹路径下的文件随机URL
 */
@property (nonatomic,strong,readonly) NSURL *exportRandomURL;

/**
 导出保存文件对应文件夹路径下的文件随机URLStr
 */
@property (nonatomic,strong,readonly) NSString *exportRandomURLStr;

/**
 是否开启自动停止录制,默认是no
 */
@property (nonatomic, assign) BOOL isAutomaticStop;


/**
 自动停止录制的最小录制时间，默认3s,
 */
@property (nonatomic, assign) NSUInteger minRecordDelay;

/**
 自动停止录制的最大录制时间，默认0s,可以一直录制
 */
@property (nonatomic, assign) NSUInteger maxRecordDelay;

/**
 当前的录制音视频的总时长
 */
@property (nonatomic, assign) NSTimeInterval recordTimeLength;


/**
 是否开启音频声波定时器,默认开启
 */
@property (nonatomic, assign) BOOL isAcousticTimer;



/**
 获取数据操作的本地路径
 
 @return 文件保存的本地目录
 */
- (NSString *)createSaveDatePath;

/**
 导出创建的本地文件路径中的随机文件URLStr
 
 @return 文件URLStr
 */
- (NSString *)exportSaveDatePath;

/**
 清除缓存
 
 @return  返回清除缓存结果
 */
- (BOOL)clearCacheData;

@end

NS_ASSUME_NONNULL_END
