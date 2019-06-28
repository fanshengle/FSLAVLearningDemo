//
//  FSLAVPlayerViewController.m
//  FSLAVLearningDemo
//
//  Created by tutu on 2019/6/27.
//  Copyright © 2019 tutu. All rights reserved.
//

#import "FSLAVPlayerViewController.h"
#import "ZQPlayerMaskView.h"

@interface FSLAVPlayerViewController ()<FSLAVPlayerDelegate>

/** 视频播放器*/
@property (nonatomic, strong) ZQPlayerMaskView *playerMaskView;


/** 音频播放器 */
@property (nonatomic, strong) FSLAVPlayer *audioPlayer;

@end


@implementation FSLAVPlayerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    // 视频播放
    _playerMaskView = [[ZQPlayerMaskView alloc] initWithFrame:CGRectMake(0, 100, self.view.frame.size.width, self.view.frame.size.width*0.56)];
    _playerMaskView.isWiFi = YES; // 是否允许自动加载，
    _playerMaskView.titleLab.text = @"标题";
    [self.view addSubview:_playerMaskView];
    
    // 网络视频
    NSString *videoUrl = @"https://vd3.bdstatic.com/mda-ihhf38w8vwr3xi5x/sc/mda-ihhf38w8vwr3xi5x.mp4?auth_key=1561606704-0-0-537a2138297a57e67cc2e34d07a7a137&bcevod_channel=searchbox_feed&pd=bjh&abtest=all";
    // 本地视频
    //    NSString *videoUrl = [[NSBundle mainBundle] pathForResource:@"abc" ofType:@"mp4"];
    [_playerMaskView playWithVideoUrl:videoUrl];
    
    [_playerMaskView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.view);
        make.top.equalTo(self.view).with.offset(100);
        make.height.equalTo(self->_playerMaskView.mas_width).multipliedBy(0.56);
    }];
}
#pragma mark - 屏幕旋转
//是否自动旋转,返回YES可以自动旋转
- (BOOL)shouldAutorotate {
    return YES;
}
//返回支持的方向
- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}
//这个是返回优先方向
- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    return UIInterfaceOrientationPortrait;
}
// 全屏需要重写方法
- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator  {
    UIDeviceOrientation orientation = [UIDevice currentDevice].orientation;
    if (orientation == UIDeviceOrientationPortrait || orientation
        == UIDeviceOrientationPortraitUpsideDown) {
        // 隐藏导航栏
        [self.navigationController setNavigationBarHidden:NO animated:YES];
        [_playerMaskView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.left.right.equalTo(self.view);
            make.top.equalTo(self.view).with.offset(100);;
            make.height.equalTo(self->_playerMaskView.mas_width).multipliedBy(0.56);
        }];
    }else {
        // 显示导航栏
        [self.navigationController setNavigationBarHidden:YES animated:YES];
        [_playerMaskView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self.view);
        }];
    }
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
}
/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
