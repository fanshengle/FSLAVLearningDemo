//
//  GeneralGetDataManager.m
//  TuTuSDKTestDemo
//
//  Created by tutu on 2019/4/30.
//  Copyright © 2019 tutu. All rights reserved.
//

#import "GeneralGetDataManager.h"

@implementation GeneralGetDataManager

/**
 获取参数选项
 
 @param Key 本地配置标题的json索引key
 @return 配置标题的数组
 */
+ (NSMutableArray <GeneralParamItemModel *> *)getConfigOptionWithKey:(NSString *)Key{
    return [self returnConfigOptionArrWithKey:Key];
}

/**
 公共方法：通过索引key值，获取本地json的数组数据
 
 @param optionKey 获取到json索引key
 @return 返回配置标题数组
 */
+ (NSMutableArray *)returnConfigOptionArrWithKey:(NSString *)optionKey{
    
    NSString *path = [[NSBundle mainBundle] pathForResource:optionKey ofType:@"json"];
    NSString *optionListStr = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
//    NSData *optionListData = [optionListStr dataUsingEncoding:NSUTF8StringEncoding];
//    NSDictionary *optionListDic = [NSJSONSerialization JSONObjectWithData:optionListData options:NSJSONReadingMutableContainers error:nil];
    NSDictionary *optionListDic = [optionListStr mj_JSONObject];
    return [self returnConfigOptionArrWithOptionListDic:optionListDic];
}

/**
 公共方法：便利数组，将dic转model，存储到配置数组中

 @param optionDic 获取到json中dic数据
 @return 返回配置标题数组
 */
+ (NSMutableArray *)returnConfigOptionArrWithOptionListDic:(NSDictionary *)optionDic{
    
    NSMutableArray *configOptionArr = [NSMutableArray array];
    NSArray *paramTitleArr = optionDic[@"functionTitle"];
    for (NSDictionary *dic in paramTitleArr) {
        GeneralParamModel *model = [GeneralParamModel mj_objectWithKeyValues:dic];
        [configOptionArr addObject:model];
    }
    return configOptionArr;
}

@end
