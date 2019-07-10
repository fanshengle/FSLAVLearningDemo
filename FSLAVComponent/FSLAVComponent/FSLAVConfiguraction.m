//
//  FSLAVConfiguraction.m
//  FSLAVComponent
//
//  Created by tutu on 2019/6/26.
//  Copyright © 2019 tutu. All rights reserved.
//

#import "FSLAVConfiguraction.h"

@implementation FSLAVConfiguraction

@synthesize savePathURL = _savePathURL;

- (instancetype)init
{
    self = [super init];
    if (self) {
        
        _isAutomaticStop = NO;
        _maxRecordDelay = 0;
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
        _savePathURLStr = [self getSaveDatePath];
    }
    return _savePathURLStr;
}


/**
 获取数据操作的本地路径
 
 @return 文件保存的本地目录
 */
- (NSString *)getSaveDatePath;
{
    NSString *filePath = [FSLAVFileManager pathAppendDefaultDatePath:self.saveSuffixFormat];
    NSString *datePath = [FSLAVFileManager pathInCacheWithDirPath:self.outputFileName filePath:filePath];
    [FSLAVFileManager createFilePath:datePath];

    return datePath;
}

//视频路径
- (NSString *)getPath
{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"YYYYMMdd"];
    NSString *dateStr = [formatter stringFromDate:[NSDate date]];
    
    NSString *path = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.mp4", dateStr]];
    
    return path;
}
/**
 清除缓存
 
 @return  返回清除缓存结果
 */
- (BOOL)clearCacheData;
{
    
    return [FSLAVFileManager deleteCacheOnFilePath:[FSLAVFileManager filePathAtBasicPath:[FSLAVFileManager CachePath] WithFileName:self.outputFileName]];
}

@end
