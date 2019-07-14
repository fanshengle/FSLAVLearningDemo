//
//  FSLAVConfiguraction.m
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
        [self resetConfig];
    }
    return self;
}

- (NSURL *)savePathURL{
    if (!_savePathURL) {
        
        _savePathURL = [NSURL fileURLWithPath:self.savePathURLStr];
    }
    return _savePathURL;
}

- (NSString *)savePathURLStr{
    if (!_savePathURLStr) {
        _savePathURLStr = [self createSaveDatePath];
    }
    return _savePathURLStr;
}

- (NSURL *)exportRandomURL{
    if (!_exportRandomURL) {
        
        _exportRandomURL = [NSURL fileURLWithPath:self.exportRandomURLStr];
    }
    return _exportRandomURL;
}

- (NSString *)exportRandomURLStr{
    if (!_exportRandomURLStr) {
        _exportRandomURLStr = [self exportSaveDatePath];
    }
    return _exportRandomURLStr;
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
 清除缓存
 
 @return  返回清除缓存结果
 */
- (BOOL)clearCacheData;
{
    BOOL isClear = NO;
    
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
    _savePathURL = nil;
    _savePathURLStr = nil;
    return isClear;
}

/**
 重置默认参数配置
 */
- (void)resetConfig;
{
    _sandboxDirType = FSLAVSandboxDirCache;
    _enableCreateFilePath = YES;
}
@end
