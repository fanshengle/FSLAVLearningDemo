//
//  FSLAVRecordAudioCoreBase.h
//  FSLAVComponent
//
//  Created by tutu on 2019/6/21.
//  Copyright © 2019 tutu. All rights reserved.
//

#import "FSLAVRecordCoreBase.h"

NS_ASSUME_NONNULL_BEGIN
/**
 音频录制的基础类
 */
@interface FSLAVRecordAudioCoreBase : FSLAVRecordCoreBase

@property (nonatomic, assign) AVAudioSessionCategory sessionCategory;


#pragma mark -- 激活Session控制当前的使用场景
- (void)setAudioSession;

@end

NS_ASSUME_NONNULL_END
