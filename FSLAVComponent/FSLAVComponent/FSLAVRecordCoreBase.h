//
//  FSLAVCoreBase.h
//  FSLAVComponent
//
//  Created by tutu on 2019/6/21.
//  Copyright © 2019 tutu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FSLAVFileManager.h"

NS_ASSUME_NONNULL_BEGIN

/**
 音视频录制的基础类
 */
@interface FSLAVRecordCoreBase : NSObject
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

@end

NS_ASSUME_NONNULL_END
