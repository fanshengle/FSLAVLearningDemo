//
//  FSLAVAudioEncoder.h
//  FSLAVComponent
//
//  Created by tutu on 2019/7/2.
//  Copyright © 2019 tutu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FSLAVAACAudioEncoderInterface.h"

NS_ASSUME_NONNULL_BEGIN

@interface FSLAVAACAudioEncoder : NSObject<FSLAVAACAudioEncoderInterface>
{
    FSLAVAACAudioConfiguration *_configuration;
}

@property (nonatomic,strong,readonly) FSLAVAACAudioConfiguration *configuration;

@property (nonatomic,weak) id<FSLAVAACAudioEncoderDelegate> encoderDelegate;

@end

NS_ASSUME_NONNULL_END
