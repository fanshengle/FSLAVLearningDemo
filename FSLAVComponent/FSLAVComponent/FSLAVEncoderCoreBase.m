//
//  FSLAVEcoderBase.m
//  FSLAVComponent
//
//  Created by tutu on 2019/6/21.
//  Copyright © 2019 tutu. All rights reserved.
//

#import "FSLAVEncoderCoreBase.h"

@implementation FSLAVEncoderCoreBase

- (instancetype)init
{
    self = [super init];
    if (self) {
        
       
    }
    return self;
}

#pragma mark -- 文件写入对象一
- (NSFileHandle *)fileHandle{
    if (!_fileHandle) {
        
        _fileHandle = [NSFileHandle fileHandleForWritingAtPath:[self getSaveDatePath]];
    }
    return _fileHandle;
}

#pragma mark -- 文件写入对象二
- (FILE *)fileHandle2{
    
    if (!_fileHandle2) {
        
        _fileHandle2 = fopen([[self getSaveDatePath] cStringUsingEncoding:NSUTF8StringEncoding], "wb");
    }
    return _fileHandle2;
}

/**
 获取数据操作的本地路径
 
 @return 文件保存的本地目录
 */
- (NSString *)getSaveDatePath{
    
    NSString *filePath = [FSLAVFileManager pathAppendDefaultDatePath:self.saveSuffixFormat];
    NSString *datePath = [FSLAVFileManager pathInCacheWithDirPath:self.outputFileName filePath:filePath];
    
    _savePathURL = [NSURL URLWithString:datePath];
    return datePath;
}

@end
