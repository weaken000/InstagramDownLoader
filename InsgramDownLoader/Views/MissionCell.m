//
//  MissionCell.m
//  InsgramDownLoader
//
//  Created by mac on 2019/10/12.
//  Copyright © 2019 leke. All rights reserved.
//

#import "MissionCell.h"

@implementation MissionCell {
    UILabel     *_descLab;
    UILabel     *_stateLab;
    UIButton    *_actionButton;
    CAShapeLayer *_progressLayer;
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self == [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        [self setupSubview];
    }
    return self;
}

- (void)setupSubview {
    CGSize size = CGSizeMake([UIScreen mainScreen].bounds.size.width, 50);
    
    _actionButton = [[UIButton alloc] initWithFrame:CGRectMake(size.width-80, 10, 70, 30)];
    _actionButton.layer.cornerRadius = 5;
    _actionButton.layer.borderColor = [UIColor greenColor].CGColor;
    _actionButton.layer.borderWidth = 1.0;
    _actionButton.titleLabel.font = [UIFont systemFontOfSize:12.0];
    [_actionButton setTitleColor:[UIColor greenColor] forState:UIControlStateNormal];
    [self.contentView addSubview:_actionButton];
    
    _descLab = [[UILabel alloc] initWithFrame:CGRectMake(16, 5, CGRectGetMinX(_actionButton.frame) - 26, 20)];
    _descLab.font = [UIFont systemFontOfSize:12];
    _descLab.textColor = [UIColor whiteColor];
    [self.contentView addSubview:_descLab];
    
    _stateLab = [[UILabel alloc] initWithFrame:CGRectMake(16, CGRectGetMaxY(_descLab.frame) + 5, CGRectGetMinX(_actionButton.frame) - 26, 20)];
    _stateLab.font = [UIFont systemFontOfSize:12];
    _stateLab.textColor = [UIColor whiteColor];
    [self.contentView addSubview:_stateLab];
    
    _progressLayer = [CAShapeLayer layer];
    UIBezierPath *path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointMake(0, 1.5)];
    [path addLineToPoint:CGPointMake(size.width, 1.5)];
    _progressLayer.path = path.CGPath;
    _progressLayer.strokeColor = [UIColor greenColor].CGColor;
    _progressLayer.lineWidth = 3;
    _progressLayer.frame = CGRectMake(0, size.height-3, size.width, 3);
    _progressLayer.strokeEnd = 0.5;
    _progressLayer.cornerRadius = 1.5;
    [self.contentView.layer addSublayer:_progressLayer];
}

- (void)configTask:(WKDownLoadTask *)task {
    [self updateByTask:task];
    __weak typeof(self) weakSelf = self;
    task.update = ^(WKDownLoadTask * _Nonnull task) {
        [weakSelf updateByTask:task];
    };
}

- (void)updateByTask:(WKDownLoadTask *)task {
    _descLab.text = task.desc;
    if (!task.task) {
        _progressLayer.strokeEnd = 0;
        [_actionButton setTitle:@"下载" forState:UIControlStateNormal];
        return;
    }
    if (task.status == WKTaskStatusWait) {
        [_actionButton setTitle:@"开始下载" forState:UIControlStateNormal];
    } else if (task.status == WKTaskStatusLoading) {
        [_actionButton setTitle:@"暂停" forState:UIControlStateNormal];
    } else if (task.status == WKTaskStatusSuspend) {
        [_actionButton setTitle:@"继续下载" forState:UIControlStateNormal];
    } else if (task.status == WKTaskStatusFinished) {
        [_actionButton setTitle:@"等待保存" forState:UIControlStateNormal];
    } else if (task.status == WKTaskStatusFailure) {
        _descLab.text = task.error;
        [_actionButton setTitle:@"重新下载" forState:UIControlStateNormal];
    } else if (task.status == WKTaskStatusSaveing) {
        [_actionButton setTitle:@"保存中" forState:UIControlStateNormal];
    } else if (task.status == WKTaskStatusSaveFinish) {
        [_actionButton setTitle:@"保存完成" forState:UIControlStateNormal];
    } else if (task.status == WKTaskStatusCoding) {
        [_actionButton setTitle:@"编码中" forState:UIControlStateNormal];
    } else {
        _descLab.text = task.error;
        [_actionButton setTitle:@"重新保存" forState:UIControlStateNormal];
    }
    _progressLayer.strokeEnd = task.progress;
}

@end
