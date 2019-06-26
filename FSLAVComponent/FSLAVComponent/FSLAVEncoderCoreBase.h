//
//  FSLAVEcoderBase.h
//  FSLAVComponent
//
//  Created by tutu on 2019/6/21.
//  Copyright © 2019 tutu. All rights reserved.
//

#import "FSLAVRecordCoreBase.h"
#import <VideoToolbox/VideoToolbox.h>

NS_ASSUME_NONNULL_BEGIN

@interface FSLAVEncoderCoreBase : NSObject
{
    @protected
    /**编码线程*/
    dispatch_queue_t _encodeQueue;
    /**文件写入对象*/
    NSFileHandle *_fileHandle;
    /**文件写入对象*/
    FILE *_fileHandle2;
}


@property (nonatomic,strong,readonly) NSFileHandle *fileHandle;

@property (nonatomic,readonly) FILE *fileHandle2;

@end

NS_ASSUME_NONNULL_END
