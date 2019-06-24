//
//  GeneralGetDataManager.h
//  TuTuSDKTestDemo
//
//  Created by tutu on 2019/4/30.
//  Copyright © 2019 tutu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GeneralParamModel.h"
#import "GeneralParamItemModel.h"
NS_ASSUME_NONNULL_BEGIN

@interface GeneralGetDataManager : NSObject

/**
 获取参数选项
 
 @param Key 本地配置标题的json索引key
 @return 配置标题的数组
 */
+ (NSMutableArray <GeneralParamItemModel *> *)getConfigOptionWithKey:(NSString *)Key;




@end

NS_ASSUME_NONNULL_END
