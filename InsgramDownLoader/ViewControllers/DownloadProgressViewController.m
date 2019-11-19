//
//  DownloadProgressViewController.m
//  InsgramDownLoader
//
//  Created by mac on 2019/10/17.
//  Copyright © 2019 leke. All rights reserved.
//

#import "DownloadProgressViewController.h"
#import "WKDownLoadManager.h"
#import "MissionCell.h"

@interface DownloadProgressViewController ()
<UITableViewDelegate,
UITableViewDataSource,
WKDownLoadManagerDelegate
>

@property (nonatomic, strong) UITableView *tableView;

@end

@implementation DownloadProgressViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    _tableView.rowHeight = 50;
    _tableView.separatorInset = UIEdgeInsetsZero;
    [_tableView registerClass:[MissionCell class] forCellReuseIdentifier:@"activeCell"];
    [_tableView registerClass:[MissionCell class] forCellReuseIdentifier:@"completeCell"];
    [_tableView registerClass:[MissionCell class] forCellReuseIdentifier:@"errorCell"];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    [self.view addSubview:_tableView];
    
    [WKDownLoadManager share].delegate = self;
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    [button setTitle:@"清空已下载" forState:UIControlStateNormal];
    [button addTarget:self action:@selector(click_clear) forControlEvents:UIControlEventTouchUpInside];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:button];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    _tableView.frame = self.view.bounds;
}

- (void)click_clear {
    [[WKDownLoadManager share] clear];
}

#pragma mark - WKDownLoadManagerDelegate
- (void)downloadManagerDidUpdateTask:(WKDownLoadManager *)manager {
    [self.tableView reloadData];
}

#pragma mark - UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return [WKDownLoadManager share].activeTasks.count;
    }
    if (section == 1) {
        return [WKDownLoadManager share].compeleteTasks.count;
    }
    return [WKDownLoadManager share].errorTasks.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    MissionCell *cell;
    WKDownLoadManager *manager = [WKDownLoadManager share];
    if (indexPath.section == 0 && manager.activeTasks.count > 0) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"activeCell"];
        [cell configTask:manager.activeTasks[indexPath.row]];
    }
    if (indexPath.section == 1 && manager.compeleteTasks.count > 0) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"completeCell"];
        [cell configTask:manager.compeleteTasks[indexPath.row]];
    }
    if (indexPath.section == 2 && manager.errorTasks.count > 0) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"errorCell"];
        [cell configTask:manager.errorTasks[indexPath.row]];
    }
//    cell.delegate = self;
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return @"下载中";
    }
    if (section == 1) {
        return @"已完成";
    }
    return @"失败";
}



@end
