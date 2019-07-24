//
//  FSLAVMediaOptions.h
//  FSLAVComponent
//
//  Created by tutu on 2019/7/21.
//  Copyright © 2019 tutu. All rights reserved.
//

#import "FSLAVOptions.h"

NS_ASSUME_NONNULL_BEGIN

/**
 媒体资源类型：视频、音频
  */
typedef NS_ENUM(NSInteger,FSLAVMediaType)
{
    FSLAVMediaTypeVideo,
    FSLAVMediaTypeAudio
};

/**
 媒体资源音视频处理（剪辑、编辑、分离、合成等）的核心配置
 */
@interface FSLAVMediaOptions : FSLAVOptions

// 输入的媒体（音视频）路径
@property (nonatomic, strong) NSString *inputMediaPath;

//媒体类型
@property (nonatomic, assign) FSLAVMediaType meidaType;

// 是否保留视频原音，默认 YES，保留视频原音
@property (nonatomic, assign) BOOL enableVideoSound;


// 媒体音视频素材的总时长
@property (nonatomic,assign,getter=mediaDuration) NSTimeInterval mediaDuration;


@end

NS_ASSUME_NONNULL_END
