//
//  FSLAVRecordVideoCoreBase.m
//  FSLAVComponent
//
//  Created by tutu on 2019/6/21.
//  Copyright © 2019 tutu. All rights reserved.
//

#import "FSLAVRecordVideoCoreBase.h"

@implementation FSLAVRecordVideoCoreBase

- (instancetype)init
{
    self = [super init];
    if (self) {
        _outputFileName = @"VideoFile";
        _saveSuffixFormat = @"mp4";
    }
    return self;
}


@end
