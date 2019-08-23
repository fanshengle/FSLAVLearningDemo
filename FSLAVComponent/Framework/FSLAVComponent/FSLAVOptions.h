//
//  FSLAVOptions.h
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

//文件在沙盒中的位置类型
typedef NS_ENUM(NSInteger, FSLAVSandboxDirType) {
    
    FSLAVSandboxDirDocuments,
    FSLAVSandboxDirLibrary,
    FSLAVSandboxDirCache
};
/**
 导出的视频文件类型
 */
typedef NS_ENUM(NSInteger,FSLAVMediaOutputFileType)
{
    /**音视频苹果通用格式,安卓平台需要另外转换*/
    FSLAVMediaOutputFileTypeM4V,
    /**视频导出文件格式*/
    /** MOV */
    FSLAVVideoOutputFileTypeQuickTimeMovie,
    
    /** MP4 */
    FSLAVVideoOutputFileTypeMPEG4,
    
    /**音频导出文件格式*/
    FSLAVAudioOutputFileTypeM4A
};

/**
 媒体资源类型：视频、音频
 */
typedef NS_ENUM(NSInteger,FSLAVMediaType)
{
    FSLAVMediaTypeAudio,
    FSLAVMediaTypeVideo
};
/**
 音视频的基础配置类
 */
@interface FSLAVOptions : NSObject
/**定义实例变量*/
{
    FSLAVSandboxDirType _sandboxDirType;
    FSLAVMediaType _meidaType;
    FSLAVMediaOutputFileType _outputFileType;
    AVFileType _appOutputFileType;
    
    BOOL _enableCreateFilePath;
    NSString *_outputFileName;
    NSString *_saveSuffixFormat;
    NSURL *_outputFileURL;
    NSString *_outputFilePath;
    NSURL *_exportRandomFileURL;
    NSString *_exportRandomFilePath;
   
}

/**定义属性变量*/

/**
 文件保存在沙盒哪个路径下
 */
@property (nonatomic,assign) FSLAVSandboxDirType sandboxDirType;

/**
 媒体类型
 */
@property (nonatomic, assign) FSLAVMediaType meidaType;

/**
 输出的文件格式视频： FSLAVMediaOutputFileTypeQuickTimeMovie 或 FSLAVMediaOutputFileTypeMPEG4
 音频：FSLAVAudioOutputFileTypeM4A
 通用：FSLAVMediaOutputFileTypeM4V
 */
@property (nonatomic, assign) FSLAVMediaOutputFileType outputFileType;

/**
 传给苹果export导出素材的导出文件类型
 */
@property (nonatomic, assign,readonly) AVFileType appOutputFileType;

/**
 是否创建文件路径，与文件夹路径不同，文件夹路径是必须创建的
 文件路径是非必须创建的，有的导出音视频资源到该路径下，并不需要创建文件路径。
 举例：多音轨混合中导出混合音轨就不需要创建文件路径。
 默认为YES
 */
@property (nonatomic,assign) BOOL enableCreateFilePath;

/**
 保存到本地FSLAVSandboxDirType下的路径文件夹名称
 */
@property (nonatomic,strong) NSString *outputFileName;

/**
 保存到本地FSLAVSandboxDirType下的音视频文件或数据格式：如：mp4、mov、aac、caf
 */
@property (nonatomic,strong) NSString *saveSuffixFormat;

/**
 保存到本地FSLAVSandboxDirType下的音视频文件URL路径
 */
@property (nonatomic,strong) NSURL *outputFileURL;

/**
 保存到本地FSLAVSandboxDirType下的音视频文件Str路径
 */
@property (nonatomic,strong) NSString *outputFilePath;

/**
 导出保存文件对应文件夹路径下的文件随机URL
 */
@property (nonatomic,strong,readonly) NSURL *exportRandomFileURL;

/**
 导出保存文件对应文件夹路径下的文件随机URLStr
 */
@property (nonatomic,strong,readonly) NSString *exportRandomFilePath;

/**
 初始化/或直接init初始化一样
 
 @return FSLAVOptions
 */
+ (instancetype)defaultOptions;

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
 清除当前路径文件
 @return  返回清除结果
 */
- (BOOL)clearOutputFilePath;

/**
 清除缓存
 @return  返回清除缓存结果
 */
- (BOOL)clearCacheData;

/**
 设置默认参数配置
 */
- (void)setConfig;


@end

NS_ASSUME_NONNULL_END
