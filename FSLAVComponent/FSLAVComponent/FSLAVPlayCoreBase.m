//
//  FSLAVPlayCoreBase.m
//  FSLAVComponent
//
//  Created by tutu on 2019/6/21.
//  Copyright © 2019 tutu. All rights reserved.
//

#import "FSLAVPlayCoreBase.h"

static FSLAVPlayCoreBase *player = nil;

@implementation FSLAVPlayCoreBase

- (instancetype)init
{
    self = [super init];
    if (self) {
        
        [self setAudioSession];
    }
    return self;
}

/**
 初始化播放源url的播放起
 
 @param url 播放源
 @return 播放器
 */
- (instancetype)initWithURL:(NSString *)url{
    if (self = [self init]) {
        
        _currentURLStr = url;
        _currentURL = [self retrieveURL:url];
    }
    return self;
}

#pragma mark -- public set
- (void)setSessionCategory:(AVAudioSessionCategory)sessionCategory{
    
    [[AVAudioSession sharedInstance] setCategory:sessionCategory error:nil];
    //[[AVAudioSession sharedInstance] setCategory: AVAudioSessionCategorySoloAmbient error: nil];
    [[AVAudioSession sharedInstance] setActive:YES error:nil];
}

- (void)setCurrentURLStr:(NSString *)currentURLStr{
    _currentURLStr = currentURLStr;
    //设置urlStr时将url也替换掉
    _currentURL = [self retrieveURL:_currentURLStr];
}

/**
 激活Session控制当前的使用场景
 */
- (void)setAudioSession{
    
    //[[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
    [[AVAudioSession sharedInstance] setCategory: AVAudioSessionCategorySoloAmbient error: nil];
    [[AVAudioSession sharedInstance] setActive:YES error:nil];
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

/**
 播放
 */
- (void)play;
{
    
}

/**
 暂停
 */
- (void)pause;
{
    
}

/**
 停止
 */
- (void)stop;
{
    
}

/**
 创建播放定时器
 */
- (void)addPlayTimer;
{
    if (!_playTimer) {
        /**三种g方式解决NSTimer的循环引用*/
        //step1：
        //FSLProxy *proxy = [FSLProxy proxyWithTarget:self];
        //step2：
        FSLForwordProxy *proxy = [FSLForwordProxy proxyWithTarget:self];
        _playTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:proxy selector:@selector(playTimeAction) userInfo:nil repeats:YES];
        
        //step3:
        //__weak typeof(self) weakself = self;
        //_playTimer = [NSTimer block_TimerWithTimeInterval:1.0 block:^{
        //    [weakself playTimeAction];
        //} repeats:YES];
    }
}

/**
 播放定时事件
 */
- (void)playTimeAction;
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(didChangedPlayCurrentTimeLength:)]) {
        [self.delegate didChangedPlayCurrentTimeLength:_currentTimeLength];
    }
}


/**
 移除播放定时器
 */
- (void)removePlayTimer;
{
    
    [_playTimer invalidate];
    _playTimer = nil;
}

- (void)dealloc{
    
    NSLog(@"音频播放器被释放了");
    [self removePlayTimer];
}
@end
