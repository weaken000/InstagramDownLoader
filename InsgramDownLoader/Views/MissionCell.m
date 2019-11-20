//
//  MissionCell.m
//  InsgramDownLoader
//
//  Created by mac on 2019/10/12.
//  Copyright © 2019 leke. All rights reserved.
//

#import "MissionCell.h"
#import "ColorUtils.h"

@implementation MissionCell {
    UILabel      *_descLab;
    UILabel      *_stateLab;
    UIButton     *_actionButton;
    CAShapeLayer *_progressLayer;
    UIButton     *_cancelButton;
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self == [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        [self setupSubview];
        self.backgroundColor = [ColorUtils whiteColor];
    }
    return self;
}

- (void)setupSubview {
    CGSize size = CGSizeMake([UIScreen mainScreen].bounds.size.width, 50);
    
    _actionButton = [[UIButton alloc] initWithFrame:CGRectMake(size.width-80, 10, 70, 30)];
    _actionButton.layer.cornerRadius = 5;
    _actionButton.layer.borderColor = [ColorUtils mainColor].CGColor;
    _actionButton.layer.borderWidth = 1.0;
    _actionButton.titleLabel.font = [UIFont systemFontOfSize:12.0];
    [_actionButton setTitleColor:[ColorUtils mainColor] forState:UIControlStateNormal];
    [_actionButton addTarget:self action:@selector(click_button:) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:_actionButton];
    
    _cancelButton = [[UIButton alloc] initWithFrame:CGRectMake(CGRectGetMinX(_actionButton.frame) - 80, 10, 70, 30)];
    _cancelButton.layer.cornerRadius = 5;
    _cancelButton.layer.borderColor = [ColorUtils mainColor].CGColor;
    _cancelButton.layer.borderWidth = 1.0;
    _cancelButton.titleLabel.font = [UIFont systemFontOfSize:12.0];
    [_cancelButton setTitle:@"取消" forState:UIControlStateNormal];
    [_cancelButton setTitleColor:[ColorUtils mainColor] forState:UIControlStateNormal];
    [_cancelButton addTarget:self action:@selector(click_button:) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:_cancelButton];
    
    
    _descLab = [[UILabel alloc] initWithFrame:CGRectMake(5, 5, CGRectGetMinX(_cancelButton.frame) - 10, 20)];
    _descLab.font = [UIFont systemFontOfSize:14];
    _descLab.textColor = [ColorUtils blackColor];
    [self.contentView addSubview:_descLab];
    
    _stateLab = [[UILabel alloc] initWithFrame:CGRectMake(5, 25, CGRectGetMinX(_actionButton.frame) - 10, 20)];
    _stateLab.font = [UIFont systemFontOfSize:14];
    _stateLab.textColor = [ColorUtils blackColor];
    [self.contentView addSubview:_stateLab];
    
    _progressLayer = [CAShapeLayer layer];
    UIBezierPath *path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointMake(0, 1.5)];
    [path addLineToPoint:CGPointMake(size.width, 1.5)];
    _progressLayer.path = path.CGPath;
    _progressLayer.strokeColor = [ColorUtils mainColor].CGColor;
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
    _cancelButton.hidden = task.status != WKTaskStatusLoading;
    _progressLayer.strokeEnd = task.progress;
    _stateLab.text = @"";

    if (task.status == WKTaskStatusWait) {
        _cancelButton.hidden = NO;
        [_actionButton setTitle:@"开始下载" forState:UIControlStateNormal];
    } else if (task.status == WKTaskStatusLoading) {
        _cancelButton.hidden = NO;
        [_actionButton setTitle:@"暂停" forState:UIControlStateNormal];
    } else if (task.status == WKTaskStatusSuspend) {
        [_actionButton setTitle:@"继续下载" forState:UIControlStateNormal];
    } else if (task.status == WKTaskStatusFinished) {
        [_actionButton setTitle:@"等待保存" forState:UIControlStateNormal];
    } else if (task.status == WKTaskStatusFailure) {
        _stateLab.text = task.error;
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
}

- (void)click_button:(UIButton *)sender {
    if (sender == _cancelButton) {
        if ([self.delegate respondsToSelector:@selector(missionCellDidClickCancel:)]) {
            [self.delegate missionCellDidClickCancel:self];
        }
    } else {
        if ([self.delegate respondsToSelector:@selector(missionCellDidClickAction:)]) {
            [self.delegate missionCellDidClickAction:self];
        }
    }
}

@end
