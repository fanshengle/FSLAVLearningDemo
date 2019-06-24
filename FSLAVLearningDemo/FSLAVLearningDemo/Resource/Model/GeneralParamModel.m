//
//  GeneralPramaModel.m
//  TuTuSDKTestDemo
//
//  Created by tutu on 2019/4/30.
//  Copyright © 2019 tutu. All rights reserved.
//

#import "GeneralParamModel.h"

@implementation GeneralParamModel

/* 数组中存储模型数据，需要说明数组中存储的模型数据类型 */
/* 实现该方法，说明数组中存储的模型数据类型 */
+ (NSDictionary <NSString * , NSString *> *)mj_objectClassInArray{
    
    return @{ @"itemArr" : @"GeneralParamItemModel",
              };
}

@end
