//
//  FSLAVH264VideoEcoder.h
//  FSLAVComponent
//
//  Created by tutu on 2019/6/21.
//  Copyright © 2019 tutu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FSLAVH264VideoEncoderInterface.h"

NS_ASSUME_NONNULL_BEGIN

/**
 硬编码：视频编码器
 */
@interface FSLAVH264VideoEncoder : NSObject<FSLAVH264VideoEncoderInterface>
{
    FSLAVH264VideoConfiguration *_configuration;
}
/**
 视频配置项
 */
@property (nonatomic, strong , readonly) FSLAVH264VideoConfiguration *configuration;

/**
 代理
 */
@property (nonatomic, weak) id<FSLAVH264VideoEncoderDelegate> encodeDelegate;

@end

NS_ASSUME_NONNULL_END
