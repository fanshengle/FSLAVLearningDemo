//
//  FSLAVCompositionCoreBase.m
//  FSLAVComponent
//
//  Created by tutu on 2019/8/9.
//  Copyright © 2019 tutu. All rights reserved.
//

#import "FSLAVCompositionCoreBase.h"

@implementation FSLAVCompositionCoreBase


/**
 调整视频方向
 
 @param videoTrack 加入到 composition 的合成轨道
 @param assetVideoTrack 要添加的视频轨道
 @return 视频合成的转换layer
 */
- (AVMutableVideoCompositionLayerInstruction *)adjustVideoOrientationWith:(AVMutableCompositionTrack *)videoTrack assetTrack:(AVAssetTrack *)assetVideoTrack;
{
    UIImageOrientation videoOrientation = UIImageOrientationUp;
    BOOL isAssetPortrait = NO;
    CGAffineTransform transform = assetVideoTrack.preferredTransform;
    
    CGFloat translationX = 0;
    CGFloat translationY = 0;
    CGFloat radio = 0;
    CGFloat videoWidth = renderSize.width;
    CGFloat videoHeight = renderSize.height;
    if (transform.a == 0 && transform.b == 1.0 && transform.c == -1.0 && transform.d == 0) {
        videoOrientation = UIImageOrientationRight;
        isAssetPortrait = YES;
        translationX = videoWidth * (videoHeight/videoWidth);
        translationY = 0;
        radio = M_PI_2;
    }else if (transform.a == 0 && transform.b == -1.0 && transform.c == 1.0 && transform.d == 0){
        videoOrientation = UIImageOrientationLeft;
        isAssetPortrait = YES;
        translationX = 0;
        translationY = videoHeight * (videoWidth/videoHeight);
        radio = M_PI_2*3;
    }else if (transform.a == -1.0 && transform.b == 0 && transform.c == 0 && transform.d == -1.0){
        videoOrientation = UIImageOrientationDown;
        translationX = videoWidth;
        translationY = videoHeight;
        radio = M_PI;
    }else{
        videoOrientation = UIImageOrientationUp;
        translationX = 0;
        translationY = 0;
        radio = 0;
    }
    
    CGAffineTransform rotation = CGAffineTransformMakeRotation(radio);
    CGAffineTransform translateToCenter = CGAffineTransformMakeTranslation(translationX, translationY);
    CGAffineTransform mixedTransform = CGAffineTransformConcat(rotation, translateToCenter);
    
    if (isAssetPortrait) {
        //交换宽高
        CGSize tempSize = renderSize;
        renderSize = CGSizeMake(tempSize.height, tempSize.width);
    }
    // 调整视频方向
    AVMutableVideoCompositionLayerInstruction * layerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoTrack];
    [layerInstruction setTransform:mixedTransform atTime:kCMTimeZero];
    
    return layerInstruction;
}

@end
