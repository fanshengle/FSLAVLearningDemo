//
//  FSLAVOptions.h
//  FSLAVComponent
//
//  Created by tutu on 2019/6/26.
//  Copyright © 2019 tutu. All rights reserved.
//

#import "FSLAVOptions.h"

@implementation FSLAVOptions

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self setConfig];
    }
    return self;
}

#pragma mark -- getter
- (FSLAVMediaOutputFileType)outputFileType{
    if (!_outputFileType) {
        
        switch (_meidaType) {
            case FSLAVMediaTypeAudio:
                _outputFileType = FSLAVAudioOutputFileTypeM4A;
                break;
            default:
                _outputFileType = FSLAVVideoOutputFileTypeQuickTimeMovie;
                break;
        }
    }
    return _outputFileType;
}

- (AVFileType)appOutputFileType{
    if (!_appOutputFileType) {
        
        switch (_outputFileType) {
            case FSLAVVideoOutputFileTypeQuickTimeMovie:
                _appOutputFileType = AVFileTypeQuickTimeMovie;
                break;
            case FSLAVVideoOutputFileTypeMPEG4:
                _appOutputFileType = AVFileTypeMPEG4;
                break;
            case FSLAVAudioOutputFileTypeM4A:
                _appOutputFileType = AVFileTypeAppleM4A;
                break;
            case FSLAVMediaOutputFileTypeM4V:
                _appOutputFileType = AVFileTypeAppleM4V;
                break;
            default:
                _appOutputFileType = AVFileTypeAppleM4V;
                break;
        }
    }
    return _appOutputFileType;
}

- (NSString *)saveSuffixFormat{
    
    if (!_saveSuffixFormat) {
        
        switch (self.outputFileType) {
            case FSLAVVideoOutputFileTypeQuickTimeMovie:
                _saveSuffixFormat = @"mov";
                break;
            case FSLAVVideoOutputFileTypeMPEG4:
                _saveSuffixFormat = @"mp4";
                break;
            case FSLAVAudioOutputFileTypeM4A:
                _saveSuffixFormat = @"m4a";
                break;
            case FSLAVMediaOutputFileTypeM4V:
                _saveSuffixFormat = @"m4v";
                break;
            default:
                _saveSuffixFormat = @"m4v";
                break;
        }
    }
    return _saveSuffixFormat;
}

- (NSURL *)outputFileURL{
    if (!_outputFileURL) {
        
        _outputFileURL = [NSURL fileURLWithPath:self.outputFilePath];
    }
    return _outputFileURL;
}

- (NSString *)outputFilePath{
    if (!_outputFilePath) {
        _outputFilePath = [self createSaveDatePath];
    }
    return _outputFilePath;
}

- (NSURL *)exportRandomFileURL{
    if (!_exportRandomFileURL) {
        
        _exportRandomFileURL = [NSURL fileURLWithPath:self.exportRandomFilePath];
    }
    return _exportRandomFileURL;
}

- (NSString *)exportRandomFilePath{
    if (!_exportRandomFilePath) {
        _exportRandomFilePath = [self exportSaveDatePath];
    }
    return _exportRandomFilePath;
}

/**
 创建数据操作的本地文件路径
 
 @return 文件保存的本地目录
 */
- (NSString *)createSaveDatePath;
{
//    [self clearCacheData];
    
    NSString *filePath = [FSLAVFileManager pathAppendDefaultDatePath:self.saveSuffixFormat];
    NSString *datePath = @"";
    
    switch (_sandboxDirType) {
            
        case FSLAVSandboxDirDocuments:
            datePath = [FSLAVFileManager pathInDocumentsWithDirPath:self.outputFileName filePath:filePath];
            break;
        case FSLAVSandboxDirLibrary:
            datePath = [FSLAVFileManager pathInLibraryWithDirPath:self.outputFileName filePath:filePath];
            break;
        case FSLAVSandboxDirCache:
            datePath = [FSLAVFileManager pathInCacheWithDirPath:self.outputFileName filePath:filePath];
            break;
        default:
            break;
    }
    if (_enableCreateFilePath) {//创建文件路径，其中的没有的文件夹也一并创建了
        
        [FSLAVFileManager createFilePath:datePath];
    }else{//只创建文件路径中的文件夹路径
        
        [FSLAVFileManager createDir:[FSLAVFileManager pathInCacheWithDirPath:self.outputFileName filePath:@""]];
    }

    return datePath;
}

/**
 导出创建的本地文件路径中的随机文件URLStr

 @return 文件URLStr
 */
- (NSString *)exportSaveDatePath;
{
    NSString *filePath = @"";
    
    switch (_sandboxDirType) {
            
        case FSLAVSandboxDirDocuments:
            filePath = [FSLAVFileManager filePathAtBasicPath:[FSLAVFileManager DocumentsPath] WithFileName:self.outputFileName];
            break;
        case FSLAVSandboxDirLibrary:
            filePath = [FSLAVFileManager filePathAtBasicPath:[FSLAVFileManager LibraryPath] WithFileName:self.outputFileName];
            break;
        case FSLAVSandboxDirCache:
            filePath = [FSLAVFileManager filePathAtBasicPath:[FSLAVFileManager CachePath] WithFileName:self.outputFileName];
            break;
        default:
            break;
    }
    return [FSLAVFileManager getRandomFilePathOnDirPath:filePath];;
}


/**
 清除当前路径文件
 */
- (BOOL)clearOutputFilePath;
{
    
    if (!_outputFilePath) return NO;
    
    [FSLAVFileManager deletePath:_outputFilePath];
    _outputFilePath = nil;
    _outputFileURL = nil;
    return YES;
}

/**
 清除缓存
 
 @return  返回清除缓存结果
 */
- (BOOL)clearCacheData;
{
    BOOL isClear = NO;
    
    //文件夹路径是否存在
    if ([FSLAVFileManager isExistDirAtPath:self.outputFileName]) return isClear;
    
    switch (_sandboxDirType) {
            
        case FSLAVSandboxDirDocuments:
            isClear = [FSLAVFileManager deleteCacheOnFilePath:[FSLAVFileManager filePathAtBasicPath:[FSLAVFileManager DocumentsPath] WithFileName:self.outputFileName]];
            break;
        case FSLAVSandboxDirLibrary:
            isClear = [FSLAVFileManager deleteCacheOnFilePath:[FSLAVFileManager filePathAtBasicPath:[FSLAVFileManager LibraryPath] WithFileName:self.outputFileName]];
            break;
        case FSLAVSandboxDirCache:
            isClear = [FSLAVFileManager deleteCacheOnFilePath:[FSLAVFileManager filePathAtBasicPath:[FSLAVFileManager CachePath] WithFileName:self.outputFileName]];
            break;
        default:
            break;
    }
    _outputFileURL = nil;
    _outputFilePath = nil;
    return isClear;
}

/**
 设置默认参数配置
 */
- (void)setConfig;
{
    
//    _outputFileType = FSLAVMediaOutputFileTypeM4V;
    _sandboxDirType = FSLAVSandboxDirCache;
    _enableCreateFilePath = YES;
    _outputFileName = @"fslComponentTimeFile";
}


@end
