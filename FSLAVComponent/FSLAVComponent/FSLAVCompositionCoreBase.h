//
//  FSLAVCompositionCoreBase.h
//  FSLAVComponent
//
//  Created by tutu on 2019/8/9.
//  Copyright © 2019 tutu. All rights reserved.
//

#import "FSLAVCoreBase.h"
#import "FSLAVAssetExportSession.h"

NS_ASSUME_NONNULL_BEGIN

/**
 媒体资源创建新组合编辑环境的基类，可处理音视频：合成、剪辑、变速、分段等操作
 */
@interface FSLAVCompositionCoreBase : FSLAVCoreBase
{
    
    FSLAVAssetExportSession *_exporter;
    // 混合的composition
    AVMutableComposition   *_mixComposition;
    // 媒体 asset
    AVURLAsset *_mediaAsset;
}

@property (nonatomic, strong, readonly) FSLAVAssetExportSession *exporter;

@property (nonatomic, strong, readonly) AVMutableComposition *mixComposition;

@property (nonatomic, strong, readonly) AVURLAsset *mediaAsset;


/**
 调整视频方向
 
 @param videoTrack 加入到 composition 的合成轨道
 @param assetVideoTrack 要添加的视频轨道
 @return 视频合成的转换layer
 */
- (AVMutableVideoCompositionLayerInstruction *)adjustVideoOrientationWith:(AVMutableCompositionTrack *)videoTrack assetTrack:(AVAssetTrack *)assetVideoTrack;

@end

NS_ASSUME_NONNULL_END
