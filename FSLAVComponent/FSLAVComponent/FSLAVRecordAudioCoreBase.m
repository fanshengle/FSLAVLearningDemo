//
//  FSLAVRecordAudioCoreBase.m
//  FSLAVComponent
//
//  Created by tutu on 2019/6/21.
//  Copyright © 2019 tutu. All rights reserved.
//

#import "FSLAVRecordAudioCoreBase.h"

@implementation FSLAVRecordAudioCoreBase
- (instancetype)init
{
    self = [super init];
    if (self) {
        
        _outputFileName = @"audioFile";
        _saveSuffixFormat = @"caf";
    }
    return self;
}
@end
