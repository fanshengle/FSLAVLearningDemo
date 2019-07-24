//
//  FSLAVCoreBase.h
//  FSLAVComponent
//
//  Created by tutu on 2019/7/21.
//  Copyright © 2019 tutu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FSLAVLog.h"

NS_ASSUME_NONNULL_BEGIN

@interface FSLAVCoreBase : NSObject


/**
 设置默认参数配置
 */
- (void)setConfig;

/**
 销毁对象，释放对象
 */
- (void)destory;


@end

NS_ASSUME_NONNULL_END
