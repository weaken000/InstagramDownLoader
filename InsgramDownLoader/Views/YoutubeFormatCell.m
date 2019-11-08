//
//  YoutubeFormatCell.m
//  InsgramDownLoader
//
//  Created by mac on 2019/11/5.
//  Copyright © 2019 leke. All rights reserved.
//

#import "YoutubeFormatCell.h"

@implementation YoutubeFormatCell {
    UILabel  *_formatLabel;
    UIButton *_actionButton;
    CAShapeLayer *_progressLayer;
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self == [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        CGSize size = CGSizeMake([UIScreen mainScreen].bounds.size.width, 50);
        
        _actionButton = [[UIButton alloc] initWithFrame:CGRectMake(size.width-80, 10, 70, 30)];
        _actionButton.layer.cornerRadius = 5;
        _actionButton.layer.borderColor = [UIColor greenColor].CGColor;
        _actionButton.layer.borderWidth = 1.0;
        _actionButton.titleLabel.font = [UIFont systemFontOfSize:12.0];
        [_actionButton setTitleColor:[UIColor greenColor] forState:UIControlStateNormal];
        [_actionButton setTitle:@"下载" forState:UIControlStateNormal];
        [_actionButton addTarget:self action:@selector(click_download) forControlEvents:UIControlEventTouchUpInside];
        [self.contentView addSubview:_actionButton];
        
        _formatLabel = [[UILabel alloc] init];
        _formatLabel.font = [UIFont systemFontOfSize:14];
        _formatLabel.textColor = [UIColor whiteColor];
        [self.contentView addSubview:_formatLabel];
        _formatLabel.frame = CGRectMake(16, 0, size.width - 100, 50);
        
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
    return self;
}

//- (void)configWithFormat:(NSDictionary *)format {
//    NSString *fileSize = format[@"filesize"];
//    NSString *type = format[@"ext"];
//    NSString *video = format[@"height"];
//    NSString *acodec = format[@"acodec"];
//    double file = [fileSize integerValue] / 1024.0 / 1024.0;
//    _formatLabel.text = [NSString stringWithFormat:@"%@p %.2fM %@ %@", video, file, type, [acodec isEqualToString:@"none"]?@"无声":@"有声"];
//}
//
//- (void)configTask:(VideoTaskModel *)task {
//    if (!task) {
//        _progressLayer.strokeEnd = 0;
//        [_actionButton setTitle:@"下载" forState:UIControlStateNormal];
//        return;
//    }
//    if (task.status == TaskStatusWait) {
//        [_actionButton setTitle:@"开始下载" forState:UIControlStateNormal];
//    } else if (task.status == TaskStatusLoading) {
//        [_actionButton setTitle:@"暂停" forState:UIControlStateNormal];
//    } else if (task.status == TaskStatusSuspend) {
//        [_actionButton setTitle:@"继续下载" forState:UIControlStateNormal];
//    } else if (task.status == TaskStatusFinished) {
//        [_actionButton setTitle:@"等待保存" forState:UIControlStateNormal];
//    } else if (task.status == TaskStatusFailure) {
//        [_actionButton setTitle:@"重新下载" forState:UIControlStateNormal];
//    } else if (task.status == TaskStatusSaveing) {
//        [_actionButton setTitle:@"保存中" forState:UIControlStateNormal];
//    } else if (task.status == TaskStatusSaveFinish) {
//        [_actionButton setTitle:@"保存完成" forState:UIControlStateNormal];
//    } else if (task.status == TaskStatusCoding) {
//        [_actionButton setTitle:@"编码中" forState:UIControlStateNormal];
//    } else {
//        [_actionButton setTitle:@"重新保存" forState:UIControlStateNormal];
//    }
//    _progressLayer.strokeEnd = task.progress;
//}

- (void)configTask:(WKDownLoadTask *)task {
    [self updateByTask:task];
    __weak typeof(self) weakSelf = self;
    task.update = ^(WKDownLoadTask * _Nonnull task) {
        [weakSelf updateByTask:task];
    };
}

- (void)updateByTask:(WKDownLoadTask *)task {
    _formatLabel.text = task.desc;
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
        _formatLabel.text = task.error;
        [_actionButton setTitle:@"重新下载" forState:UIControlStateNormal];
    } else if (task.status == WKTaskStatusSaveing) {
        [_actionButton setTitle:@"保存中" forState:UIControlStateNormal];
    } else if (task.status == WKTaskStatusSaveFinish) {
        [_actionButton setTitle:@"保存完成" forState:UIControlStateNormal];
    } else if (task.status == WKTaskStatusCoding) {
        [_actionButton setTitle:@"编码中" forState:UIControlStateNormal];
    } else {
        _formatLabel.text = task.error;
        [_actionButton setTitle:@"重新保存" forState:UIControlStateNormal];
    }
    _progressLayer.strokeEnd = task.progress;
}

- (void)click_download {
    [self.delegate formatCellDidClickDownload:self];
}

@end
