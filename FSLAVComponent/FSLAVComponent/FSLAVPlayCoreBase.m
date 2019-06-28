//
//  FSLAVPlayCoreBase.m
//  FSLAVComponent
//
//  Created by tutu on 2019/6/21.
//  Copyright © 2019 tutu. All rights reserved.
//

#import "FSLAVPlayCoreBase.h"

@implementation FSLAVPlayCoreBase
- (instancetype)init
{
    self = [super init];
    if (self) {
        
        [self setAudioSession];
    }
    return self;
}

#pragma mark -- public set
- (void)setSessionCategory:(AVAudioSessionCategory)sessionCategory{
    
    [[AVAudioSession sharedInstance] setCategory:sessionCategory error:nil];
    //[[AVAudioSession sharedInstance] setCategory: AVAudioSessionCategorySoloAmbient error: nil];
    [[AVAudioSession sharedInstance] setActive:YES error:nil];
}

#pragma mark -- 激活Session控制当前的使用场景
- (void)setAudioSession{
    
    //[[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
    [[AVAudioSession sharedInstance] setCategory: AVAudioSessionCategorySoloAmbient error: nil];
    [[AVAudioSession sharedInstance] setActive:YES error:nil];
}

/**
 初始化播放源url的播放起
 
 @param url 播放源
 @return 播放器
 */
- (instancetype)initWithURL:(NSString *)url{
    if (self = [super init]) {
        
        _currentURLStr = url;
        _currentURL = [self retrieveURL:url];
        [self setAudioSession];
    }
    return self;
}

/**
 检索url是网络、本地哪一种

 @param url url
 @return 返回相应的url
 */
- (NSURL *)retrieveURL:(NSString *)url{
    
    NSURL *videoUrl;
    if ([url containsString:@"http"] || [url containsString:@"https"]) {//网络url
        videoUrl = [self translateIllegalCharacterWtihUrlStr:url];
        //videoUrl = [NSURL URLWithString:url];
    }else {//本地url
        
        videoUrl = [NSURL fileURLWithPath:url];
    }
    return videoUrl;
}

//如果链接中存在中文或某些特殊字符，需要通过以下代码转译
- (NSURL *)translateIllegalCharacterWtihUrlStr:(NSString *)yourUrl{
    
    yourUrl = [yourUrl stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    //NSString *encodedString = [yourUrl stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSString *encodedString = [yourUrl stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    
    return [NSURL URLWithString:encodedString];
}

@end
