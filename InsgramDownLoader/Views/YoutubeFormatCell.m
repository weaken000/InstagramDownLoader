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
    }
    return self;
}

- (void)configTask:(WKDownLoadTask *)task {
    _formatLabel.text = task.desc;
}

- (void)click_download {
    [self.delegate formatCellDidClickDownload:self];
}

@end
