//
//  FSLMediaAssetInfo.m
//  FSLAVComponent
//
//  Created by tutu on 2019/7/15.
//  Copyright © 2019 tutu. All rights reserved.
//

#import "FSLMediaAssetInfo.h"

@implementation FSLMediaAssetInfo

/**
 根据 AVAsset 初始化 FSLMediaAssetInfo
 
 @param asset 资产信息
 @return FSLMediaAssetInfo
 */
- (instancetype)initWithAsset:(AVAsset *)asset;
{
    if (self = [super init]) {
        
    }
    return self;
}

/**
 异步加载视频信息
 
 @param asset AVAsset
 */
- (void)loadSynchronouslyForAssetInfo:(AVAsset *)asset;
{
    
}
@end
