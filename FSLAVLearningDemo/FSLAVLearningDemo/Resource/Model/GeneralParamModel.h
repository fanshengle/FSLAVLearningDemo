//
//  GeneralPramaModel.h
//  TuTuSDKTestDemo
//
//  Created by tutu on 2019/4/30.
//  Copyright © 2019 tutu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GeneralParamItemModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface GeneralParamModel : NSObject

/**
 *  组件配置的参数选项标题
 */
@property (nonatomic,strong) NSString *title;
/**
 *  组件配置的参数选项具体内容数组
 */
@property (nonatomic,strong) NSMutableArray<GeneralParamItemModel *> *itemArr;

@end

NS_ASSUME_NONNULL_END
