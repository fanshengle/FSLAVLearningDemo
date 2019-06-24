//
//  FSLAVFileManager.m
//  FSLAVComponent
//
//  Created by tutu on 2019/6/21.
//  Copyright © 2019 tutu. All rights reserved.
//

#import "FSLAVFileManager.h"

/**
 *  文件管理类
 */
@implementation FSLAVFileManager

/**
 *  返回Document目录的路径
 *
 *  @return Document目录的路径
 */
+ (NSString *)DocumentsPath;
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    return [paths objectAtIndex:0];
}

/**
 *  返回Library目录的路径
 *
 *  @return Library目录的路径
 */
+ (NSString *)LibraryPath;
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
    return [paths objectAtIndex:0];
}

/**
 *  返回Cache目录的路径
 *
 *  @return Cache目录的路径
 */
+ (NSString *)CachePath;
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    return [paths objectAtIndex:0];
}

/**
 生成指定文件后缀带有日期的字符串，避免了文件名重复
 
 @param suffixFormat 文件后缀名
 @return  指定后缀带有日期的字符串
 */
+ (NSString *)pathAppendDefaultDatePath:(NSString *)suffixFormat;
{
    return [self pathAppendDateFormat:@"HHmmss" stringFormat:@"" suffixFormat:suffixFormat];
}

/**
 生成指定文件后缀带有日期的字符串，避免了文件名重复
 
 @param dateFormat 日期的显示格式
 @param suffixFormat 文件后缀名
 @return  指定后缀带有日期的字符串
 */
+ (NSString *)pathAppendDateFormat:(NSString *)dateFormat suffixFormat:(NSString *)suffixFormat;
{
    return [self pathAppendDateFormat:dateFormat stringFormat:@"" suffixFormat:suffixFormat];
}

/**
 生成指定文件后缀带有日期的字符串，避免了文件名重复
 
 @param dateFormat 日期的显示格式
 @param stringFormat 拼接文件字符串
 @param suffixFormat 文件后缀名
 @return  指定后缀带有日期的字符串
 */
+ (NSString *)pathAppendDateFormat:(NSString *)dateFormat stringFormat:(NSString *)stringFormat suffixFormat:(NSString *)suffixFormat;
{
    NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
    NSDateFormatter * formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:dateFormat];
    NSDate * NowDate = [NSDate dateWithTimeIntervalSince1970:now];
    NSString * timeStr = [formatter stringFromDate:NowDate];
    NSString *fileName = [NSString stringWithFormat:@"%@%@.%@",stringFormat,timeStr,suffixFormat];
    
    return fileName;
}

/**
 *  本地目录下文件夹的路径
 *
 *  @param basicPath 根路径
 *  @param dirName   目录名称
 *
 *  @return 本地目录下文件夹的路径
 */
+ (NSString *)dirPathAtBasicPath:(NSString *)basicPath WithDirName:(NSString *)dirName;
{
    NSMutableString *currentPath = [NSMutableString stringWithString:basicPath];
    
    NSArray *paths = [currentPath componentsSeparatedByString:@"/"];
    if (![[paths objectAtIndex:([paths count] - 1)] isEqualToString:@""]) {
        [currentPath appendString:@"/"];
    }
    
    if (dirName && ![dirName isEqualToString:@""]) {
        [currentPath appendFormat:@"%@/",dirName];
    }
    
    return currentPath;
}

/**
 *  本地目录下文件的路径
 *
 *  @param basicPath 根路径
 *  @param fileName  文件名
 *
 *  @return 本地目录下文件的路径
 */
+ (NSString *)filePathAtBasicPath:(NSString *)basicPath WithFileName:(NSString *)fileName;
{
    NSMutableString *currentPath = [NSMutableString stringWithString:basicPath];
    
    NSArray *paths = [currentPath componentsSeparatedByString:@"/"];
    if (![[paths objectAtIndex:([paths count] - 1)] isEqualToString:@""]) {
        [currentPath appendString:@"/"];
    }
    
    if (fileName && ![fileName isEqualToString:@""]) {
        [currentPath appendFormat:@"%@",fileName];
    }
    
    return currentPath;
}

/**
 *  在Documents文件夹下的路径
 *
 *  @param dirPath  根路径
 *  @param filePath 文件名
 *
 *  @return 本地目录下文件的路径
 */
+ (NSString *)pathInDocumentsWithDirPath:(NSString *)dirPath filePath:(NSString *)filePath;
{
    NSMutableString *basePath = (NSMutableString *)[self dirPathAtBasicPath:[self DocumentsPath] WithDirName:dirPath];
    
    if (filePath && ![filePath isEqualToString:@""]) {
        return [basePath stringByAppendingPathComponent:filePath];
    } else {
        return basePath;
    }
}

/**
 *  在Library文件夹下的路径
 *
 *  @param dirPath  根路径
 *  @param filePath 文件名
 *
 *  @return 本地目录下文件的路径
 */
+ (NSString *)pathInLibraryWithDirPath:(NSString *)dirPath filePath:(NSString *)filePath;
{
    NSMutableString *basePath = (NSMutableString *)[self dirPathAtBasicPath:[self LibraryPath] WithDirName:dirPath];
    
    if (filePath && ![filePath isEqualToString:@""]) {
        return [basePath stringByAppendingPathComponent:filePath];
    } else {
        return basePath;
    }
}

/**
 *  在Cache文件夹下的路径
 *
 *  @param dirPath  根路径
 *  @param filePath 文件名
 *
 *  @return 本地目录下文件的路径
 */
+ (NSString *)pathInCacheWithDirPath:(NSString *)dirPath filePath:(NSString *)filePath;
{
    NSMutableString *basePath = (NSMutableString *)[self dirPathAtBasicPath:[self CachePath] WithDirName:dirPath];
    
    if (filePath && ![filePath isEqualToString:@""]) {
        return [basePath stringByAppendingPathComponent:filePath];
    } else {
        return basePath;
    }
}

/**
 *  检查本地文件是否存在
 *
 *  @param filePath 文件路径
 *  @param isDir    是否为目录
 *
 *  @return 本地文件是否存在
 */
+ (BOOL)isFilePathExist:(NSString *)filePath isDir:(BOOL)isDir;
{
    if (filePath) {
        NSString *path = [NSString stringWithString:filePath];
        if (!path || path.length <= 0) {
            return NO;
        }
        
        NSFileManager *fileManager = [NSFileManager defaultManager];
        BOOL dir;
        if ([fileManager fileExistsAtPath:path isDirectory:&dir]) {
            if (dir == isDir) {
                return YES;
            } else {
                return NO;
            }
        } else {
            return NO;
        }
    } else {
        return NO;
    }
}

/**
 *  检查路径是否指向文件
 *
 *  @param path 路径
 *
 *  @return 路径是否指向文件
 */
+ (BOOL)isExistFileAtPath:(NSString *)path;
{
    return [self isFilePathExist:path isDir:NO];
}

/**
 *  检查路径是否指向文件夹
 *
 *  @param path 文件夹
 *
 *  @return 路径是否指向文件夹
 */
+ (BOOL)isExistDirAtPath:(NSString *)path;
{
    NSString *tempPath = [NSString stringWithString:path];
    return [self isFilePathExist:tempPath isDir:YES];
}

/**
 *  检查本地路径下是否存在某个文件
 *
 *  @param fileName 文件名
 *  @param path     路径
 *
 *  @return 本地路径下是否存在某个文件
 */
+ (BOOL)isExistFile:(NSString *)fileName AtPath:(NSString *)path;
{
    NSString *filePath = [NSString stringWithFormat:@"%@/%@", path, fileName];
    return [self isExistFileAtPath:filePath];
}

/**
 *  检查本地路径下是否存在某个文件夹
 *
 *  @param dirName 文件夹
 *  @param path    路径
 *
 *  @return 本地路径下是否存在某个文件夹
 */
+ (BOOL)isExistDir:(NSString *)dirName AtPath:(NSString *)path;
{
    NSString *dirPath = [NSString stringWithFormat:@"%@/%@", path, dirName];
    
    return [self isExistDirAtPath:dirPath];
}

/**
 *  当前路径对应的那一级目录下，除文件夹之外的文件的大小
 *
 *  @param path 目录路径
 *
 *  @return 当前路径对应的那一级目录下，除文件夹之外的文件的大小
 */
+ (unsigned long long)fileSizeWithInDirectFolderAtPath:(NSString *)path;
{
    unsigned long long size = 0;
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error;
    if ([self isExistFileAtPath:path]) {
        NSDictionary *fileAttributeDic = [fileManager attributesOfItemAtPath:path error:&error];
        size += fileAttributeDic.fileSize;
    } else if([self isExistDirAtPath:path]) {
        NSArray *array = [fileManager contentsOfDirectoryAtPath:path error:&error];
        for (NSString * component in array) {
            NSString *fullPath = [path stringByAppendingString:component];
            BOOL isDir;
            if ([fileManager fileExistsAtPath:fullPath isDirectory:&isDir] && !isDir) {
                NSDictionary *fileAttributeDic = [fileManager attributesOfItemAtPath:fullPath error:&error];
                size += fileAttributeDic.fileSize;
            }
        }
    }
    
    if (error) {
        
        NSAssert(YES, @"当前路径不存在");
    }
    return size;
}

/**
 *  某个路径下所有文件的大小
 *
 *  @param path 目录路径
 *
 *  @return 某个路径下所有文件的大小
 */
+ (unsigned long long)totalFilesSizeAtPath:(NSString *)path;
{
    unsigned long long size = 0;
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error;
    if ([self isExistFileAtPath:path]) {
        NSDictionary *fileAttributeDic = [fileManager attributesOfItemAtPath:path error:&error];
        size += fileAttributeDic.fileSize;
    } else if([self isExistDirAtPath:path]) {
        NSArray *array = [fileManager contentsOfDirectoryAtPath:path error:&error];
        for (NSString * component in array) {
            NSString *fullPath = [path stringByAppendingString:component];
            NSDictionary *fileAttributeDic = [fileManager attributesOfItemAtPath:fullPath error:&error];
            size += fileAttributeDic.fileSize;
        }
    }
    if (error) {
        
        NSAssert(YES, @"当前路径不存在");
    }
    return size;
}

/**
 *  检查是否文件夹大小到达上限
 *
 *  @param paths      目录路径列表
 *  @param upperLimit 上限数 (单位:Byte)
 *
 *  @return 是否文件夹大小到达上限
 */
+ (BOOL)isArriveUpperLimitAtPaths:(NSArray *)paths WithUpperLimitByByte:(unsigned long long)upperLimit;
{
    unsigned long long totalSize = 0;
    
    for (NSString *path in paths) {
        totalSize += [self totalFilesSizeAtPath:path];
    }
    
    if (totalSize >= upperLimit) {
        return YES;
    } else {
        return NO;
    }
}

/**
 *  检查是否文件夹大小到达上限
 *
 *  @param paths      目录路径列表
 *  @param upperLimit 上限数 (单位:KByte)
 *
 *  @return 是否文件夹大小到达上限
 */
+ (BOOL)isArriveUpperLimitAtPaths:(NSArray *)paths WithUpperLimitByKByte:(unsigned long long)upperLimit;
{
    return [self isArriveUpperLimitAtPaths:paths WithUpperLimitByByte:(1024 * upperLimit)];
}

/**
 *  检查是否文件夹大小到达上限
 *
 *  @param paths      目录路径列表
 *  @param upperLimit 上限数 (单位:MByte)
 *
 *  @return 是否文件夹大小到达上限
 */
+ (BOOL)isArriveUpperLimitAtPaths:(NSArray *)paths WithUpperLimitByMByte:(unsigned long long)upperLimit;
{
    return [self isArriveUpperLimitAtPaths:paths WithUpperLimitByKByte:(1024 * upperLimit)];
}

/**
 *  在本地添加文件夹
 *
 *  @param path 路径
 *
 *  @return 本地添加文件夹路径
 */
+ (NSString *)createDir:(NSString *)path;
{
    NSMutableString *currentPath = [[NSMutableString alloc] initWithString:path];
    
    NSArray *paths = [currentPath componentsSeparatedByString:@"/"];
    if (![[paths objectAtIndex:([paths count] - 1)] isEqualToString:@""]) {
        [currentPath appendString:@"/"];
    }
    
    if (![self isFilePathExist:currentPath isDir:YES]) {
        if ([[NSFileManager defaultManager] createDirectoryAtPath:currentPath withIntermediateDirectories:YES attributes:nil error:nil]) {
            return currentPath;
        } else {
            return nil;
        }
    } else {
        return currentPath;
    }
}

/**
 *  在本地目录下添加文件夹
 *
 *  @param dirName 文件夹
 *  @param path    路径
 *
 *  @return 本地添加文件夹路径
 */
+ (NSString *)createDir:(NSString *)dirName AtPath:(NSString *)path;
{
    NSString *currentPath = [self dirPathAtBasicPath:path WithDirName:dirName];
    if (currentPath) {
        return [self createDir:currentPath];
    } else {
        return path;
    }
}

/**
 *  在本地删除路径
 *
 *  @param path 路径
 *
 *  @return 是否被删除
 */
+ (BOOL)deletePath:(NSString *)path;
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (path && [fileManager fileExistsAtPath:path]) {
        return [fileManager removeItemAtPath:path error:nil];
    } else {
        return NO;
    }
}

/**
 *  在本地删除路径
 *
 *  @param paths 路径列表
 */
+ (void)deletePaths:(NSArray *)paths;
{
    if (paths && paths.count > 0) {
        for (NSString *path in paths) {
            [self deletePath:path];
        }
    }
}

/**
 *  移动文件位置
 *
 *  @param path   源路径
 *  @param toPath 移动路径
 *
 *  @return 是否移动成功
 */
+ (BOOL)movePath:(NSString *)path toPath:(NSString *)toPath;
{
    if (!path || !toPath) return NO;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    return [fileManager moveItemAtPath:path toPath:toPath error:nil];
}


/**
 获取手机可用空间（单位：字节）
 
 @return 当前可用空间
 */
+ (float)fileSystemFreeSize;
{
    NSError *error = nil;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSDictionary *dictionary = [[NSFileManager defaultManager] attributesOfFileSystemForPath:[paths lastObject] error: &error];
    if (dictionary)
    {
        NSNumber *freeSizeNumber = [dictionary objectForKey:NSFileSystemFreeSize];
        
        return [freeSizeNumber floatValue] ;
        
    }
    
    return 0.0f;
}

@end
