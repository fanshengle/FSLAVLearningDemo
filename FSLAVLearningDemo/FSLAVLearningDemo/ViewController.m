//
//  ViewController.m
//  FSLAVLearningDemo
//
//  Created by tutu on 2019/6/4.
//  Copyright © 2019 tutu. All rights reserved.
//

#import "ViewController.h"
#import "GeneralGetDataManager.h"
#import "AudioRecordViewController.h"
#import "FSLAudioEncoderViewController.h"
#import "VideoRecorViewController.h"
#import "HWCutMusicViewController.h"
#import "FSLH264VideoViewController.h"
#import "FSLAVPlayerViewController.h"
#import "FSLAVAudioMixViewController.h"
#import "FSLAVAudioClipperViewController.h"
#import "FSLAVAudioPitchRecordViewController.h"

@interface ViewController ()<UITableViewDataSource,UITableViewDelegate>

@property (nonatomic,strong) UITableView *tableView;

/**
 图像组件功能列表选项数组
 */
@property (nonatomic,strong) NSArray *optionArr;
@end

@implementation ViewController



- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.isShowBackBtn = NO;
    self.navTitle = @"音视频学习";
    
    _optionArr = [GeneralGetDataManager getConfigOptionWithKey:@"FunctionList"];
    [self tableView];
}

- (UITableView *)tableView{
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, NMNavbarHeight, NMScreenWidth, NMScreenHeight - NMNavbarHeight) style:UITableViewStyleGrouped];
        _tableView.delegate = self;
        _tableView.dataSource = self;
        _tableView.backgroundColor = [UIColor blackColor];
        _tableView.showsVerticalScrollIndicator = NO;
        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        _tableView.tableHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, NMScreenWidth, 0.01)];
        _tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, NMScreenWidth, 0.01)];
        [self.view addSubview:_tableView];
    }
    return _tableView;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return _optionArr.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    
    if(_optionArr.count <= section) return 0;
    GeneralParamModel *model = _optionArr[section];
    return model.itemArr.count;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    
    
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, NMScreenWidth, 40)];
    GeneralParamModel *model = _optionArr[section];
    UILabel *titleLab0 = [headerView viewWithTag:1000 + section];
    if (!titleLab0) {
        
        UILabel *titleLab = [[UILabel alloc] init];
        titleLab.font = [UIFont systemFontOfSize:16];
        titleLab.textColor = [UIColor whiteColor];
        titleLab.tag = 1000 + section;
        titleLab.text = model.title;
        [headerView addSubview:titleLab];
        [titleLab mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(headerView.mas_left).offset(20);
            make.centerY.equalTo(headerView.mas_centerY);
        }];
    }else{
        
        
        UILabel *titleLab = [headerView viewWithTag:1000];
        titleLab.text = model.title;
    }
    
    return headerView;
}
- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section{
    UIView *footerView = [[UIView alloc] initWithFrame:CGRectZero];
    return footerView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section{
    return 0.01;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    return 40.0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 44.0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    static NSString *itentify = @"cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:itentify];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:itentify];
        cell.contentView.backgroundColor = [UIColor blackColor];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    if (_optionArr.count <= indexPath.section) return nil;
    GeneralParamModel *model = _optionArr[indexPath.section];
    if(model.itemArr.count <= indexPath.item) return nil;
    GeneralParamItemModel *itemM = model.itemArr[indexPath.row];
    cell.textLabel.text = itemM.itemName;
    cell.textLabel.textColor = [UIColor whiteColor];
    cell.textLabel.font = [UIFont systemFontOfSize:15];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSInteger section = indexPath.section;
    NSInteger row = indexPath.row;
    if (section == 0) {
        switch (row) {
            case 0:
            {
                AudioRecordViewController *vc = [[AudioRecordViewController alloc] init];
                [self.navigationController pushViewController:vc animated:YES];
            }
                
                break;
            case 1:
            {
                HWCutMusicViewController *vc = [[HWCutMusicViewController alloc] init];
                [self.navigationController pushViewController:vc animated:YES];
            }
                break;
            case 2:
            {
                AudioRecordViewController *vc = [[AudioRecordViewController alloc] init];
                [self.navigationController pushViewController:vc animated:YES];
            }
            case 3:
            {
                FSLAudioEncoderViewController *vc = [[FSLAudioEncoderViewController alloc] init];
                [self.navigationController pushViewController:vc animated:YES];
            }
                break;
            case 4:
            {

                [self performSegueWithIdentifier:@"FSLAVAudioMixViewController" sender:nil];
            }
                break;
            case 5:
            {
                [self performSegueWithIdentifier:@"FSLAVAudioClipperViewController" sender:nil];
            }
                break;
            case 6:
            {
                [self performSegueWithIdentifier:@"FSLAVAudioPitchRecordViewController" sender:nil];
            }
                break;
            default:
                break;
        }
    }else if (section == 1){
        
        switch (row) {
            case 0:
            {
                VideoRecorViewController *vc = [[VideoRecorViewController alloc] init];
                [self.navigationController pushViewController:vc animated:YES];
            }
                
                break;
            case 1:
            {
                HWCutMusicViewController *vc = [[HWCutMusicViewController alloc] init];
                [self.navigationController pushViewController:vc animated:YES];
            }
                break;
            case 2:
            {
                FSLH264VideoViewController *vc = [[FSLH264VideoViewController alloc] init];
                [self.navigationController pushViewController:vc animated:YES];
            }
            case 3:
            {
                FSLAVPlayerViewController *vc = [[FSLAVPlayerViewController alloc] init];
                [self.navigationController pushViewController:vc animated:YES];
            }
                break;
            
            default:
                break;
        }
    }
   
}
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    NSLog(@"可以在这里做一些页面跳转属性传值的操作");
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
