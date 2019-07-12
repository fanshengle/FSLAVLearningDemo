//
//  FSLAVRecodeOptions.m
//  FSLAVComponent
//
//  Created by tutu on 2019/7/12.
//  Copyright © 2019 tutu. All rights reserved.
//

#import "FSLAVRecoderOptions.h"

@implementation FSLAVRecoderOptions
- (instancetype)init
{
    self = [super init];
    if (self) {
        
        _isAutomaticStop = NO;
        _maxRecordDelay = 0;
    }
    return self;
}
@end
