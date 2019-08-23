//
//  TrimmerMaskView+Util.m
//  VideoTrimmerExp
//
//  Created by tutu on 2018/9/5.
//  Copyright © 2018年 tutu. All rights reserved.
//

#import "TrimmerMaskView+Util.h"

@implementation TrimmerMaskView (Util)

- (TrimmerTimeLocation)locationWithTouchControl:(UIView *)touchControl {
    TrimmerTimeLocation location = TrimmerTimeLocationUnknown;
    if (touchControl == self.leftThumb) {
        location = TrimmerTimeLocationLeft;
    } else if (touchControl == self.rightThumb) {
        location = TrimmerTimeLocationRight;
    }
    return location;
}

@end
