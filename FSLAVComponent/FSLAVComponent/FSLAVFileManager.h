//
//  FSLAVFileManager.h
//  FSLAVComponent
//
//  Created by tutu on 2019/6/21.
//  Copyright © 2019 tutu. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface FSLAVFileManager : NSObject
/**
 *  返回Document目录的路径
 *
 *  @return Document目录的路径
 */
+ (NSString *)DocumentsPath;

/**
 *  返回Library目录的路径
 *
 *  @return Library目录的路径
 */
+ (NSString *)LibraryPath;


/**
 *  返回Cache目录的路径
 *
 *  @return Cache目录的路径
 */
+ (NSString *)CachePath;

/**
 生成指定文件后缀带有日期的字符串，避免了文件名重复
 
 @param suffixFormat 文件后缀名
 @return  指定后缀带有日期的字符串
 */
+ (NSString *)pathAppendDefaultDatePath:(NSString *)suffixFormat;

/**
 生成指定文件后缀带有日期的字符串，避免了文件名重复
 
 @param dateFormat 日期的显示格式
 @param suffixFormat 文件后缀名
 @return  指定后缀带有日期的字符串
 */
+ (NSString *)pathAppendDateFormat:(NSString *)dateFormat suffixFormat:(NSString *)suffixFormat;

/**
 生成指定文件后缀带有日期的字符串，避免了文件名重复
 
 @param dateFormat 日期的显示格式
 @param stringFormat 拼接文件字符串
 @param suffixFormat 文件后缀名
 @return  指定后缀带有日期的字符串
 */
+ (NSString *)pathAppendDateFormat:(NSString *)dateFormat stringFormat:(NSString *)stringFormat suffixFormat:(NSString *)suffixFormat;

/**
 *  本地目录下文件的路径
 *
 *  @param basicPath 根路径
 *  @param fileName  文件名
 *
 *  @return 本地目录下文件的路径
 */
+ (NSString *)filePathAtBasicPath:(NSString *)basicPath WithFileName:(NSString *)fileName;

/**
 *  在Documents文件夹下的路径
 *
 *  @param dirPath  根路径
 *  @param filePath 文件名
 *
 *  @return 本地目录下文件的路径
 */
+ (NSString *)pathInDocumentsWithDirPath:(NSString *)dirPath filePath:(NSString *)filePath;

/**
 *  在Library文件夹下的路径
 *
 *  @param dirPath  根路径
 *  @param filePath 文件名
 *
 *  @return 本地目录下文件的路径
 */
+ (NSString *)pathInLibraryWithDirPath:(NSString *)dirPath filePath:(NSString *)filePath;

/**
 *  在Cache文件夹下的路径
 *
 *  @param dirPath  根路径
 *  @param filePath 文件名
 *
 *  @return 本地目录下文件的路径
 */
+ (NSString *)pathInCacheWithDirPath:(NSString *)dirPath filePath:(NSString *)filePath;

/**
 *  检查路径是否指向文件
 *
 *  @param path 路径
 *
 *  @return 路径是否指向文件
 */
+ (BOOL)isExistFileAtPath:(NSString *)path;

/**
 *  检查路径是否指向文件夹
 *
 *  @param path 文件夹
 *
 *  @return 路径是否指向文件夹
 */
+ (BOOL)isExistDirAtPath:(NSString *)path;

/**
 *  检查本地路径下是否存在某个文件
 *
 *  @param fileName 文件名
 *  @param path     路径
 *
 *  @return 本地路径下是否存在某个文件
 */
+ (BOOL)isExistFile:(NSString *)fileName AtPath:(NSString *)path;

/**
 *  检查本地路径下是否存在某个文件夹
 *
 *  @param dirName 文件夹
 *  @param path    路径
 *
 *  @return 本地路径下是否存在某个文件夹
 */
+ (BOOL)isExistDir:(NSString *)dirName AtPath:(NSString *)path;

/**
 *  当前路径对应的那一级目录下，除文件夹之外的文件的大小
 *
 *  @param path 目录路径
 *
 *  @return 当前路径对应的那一级目录下，除文件夹之外的文件的大小
 */
+ (unsigned long long)fileSizeWithInDirectFolderAtPath:(NSString *)path;

/**
 *  某个路径下所有文件的大小
 *
 *  @param path 目录路径
 *
 *  @return 某个路径下所有文件的大小
 */
+ (unsigned long long)totalFilesSizeAtPath:(NSString *)path;

/**
 *  检查是否文件夹大小到达上限
 *
 *  @param paths      目录路径列表
 *  @param upperLimit 上限数 (单位:Byte)
 *
 *  @return 是否文件夹大小到达上限
 */
+ (BOOL)isArriveUpperLimitAtPaths:(NSArray *)paths WithUpperLimitByByte:(unsigned long long)upperLimit;

/**
 *  检查是否文件夹大小到达上限
 *
 *  @param paths      目录路径列表
 *  @param upperLimit 上限数 (单位:KByte)
 *
 *  @return 是否文件夹大小到达上限
 */
+ (BOOL)isArriveUpperLimitAtPaths:(NSArray *)paths WithUpperLimitByKByte:(unsigned long long)upperLimit;

/**
 *  检查是否文件夹大小到达上限
 *
 *  @param paths      目录路径列表
 *  @param upperLimit 上限数 (单位:MByte)
 *
 *  @return 是否文件夹大小到达上限
 */
+ (BOOL)isArriveUpperLimitAtPaths:(NSArray *)paths WithUpperLimitByMByte:(unsigned long long)upperLimit;

/**
 
 创建文件名文件路径
 
 @param filePath 带文件名的路径，最后一级为文件名
 @return 返回文件路径
 */
+ (NSString *)createFilePath:(NSString *)filePath;

/**
 *  在本地添加文件夹
 *
 *  @param path 路径
 *
 *  @return 本地添加文件夹路径
 */
+ (NSString *)createDir:(NSString *)path;

/**
 *  在本地目录下添加文件夹
 *
 *  @param dirName 文件夹
 *  @param path    路径
 *
 *  @return 本地添加文件夹路径
 */
+ (NSString *)createDir:(NSString *)dirName AtPath:(NSString *)path;

/**
 *  在本地删除路径
 *
 *  @param path 路径
 *
 *  @return 是否被删除
 */
+ (BOOL)deletePath:(NSString *)path;

/**
 *  在本地删除路径
 *
 *  @param paths 路径列表
 */
+ (BOOL)deletePaths:(NSArray *)paths;

/**
 清除该路径文件目录下的所有缓存数据
 
 @param path 文件目录
 @return 清除是否成功
 */
+ (BOOL)deleteCacheOnFilePath:(NSString *)path;

/**
 *  移动文件位置
 *
 *  @param path   源路径
 *  @param toPath 移动路径
 *
 *  @return 是否移动成功
 */
+ (BOOL)movePath:(NSString *)path toPath:(NSString *)toPath;


/**
 获取手机可用空间（单位：字节）
 
 @return 当前可用空间
 */
+ (float)fileSystemFreeSize;
@end

NS_ASSUME_NONNULL_END
