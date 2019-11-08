//
//  ToastView.m
//  InsgramDownLoader
//
//  Created by mac on 2019/10/12.
//  Copyright © 2019 leke. All rights reserved.
//

#import "ToastView.h"

static ToastView *_toast;

@implementation ToastView {
    UIView *_maskView;
    UIActivityIndicatorView *_loadView;
    UILabel *_label;
    CGFloat _paddingL;
    CGFloat _paddingT;
    CGFloat _maxW;
}

+ (void)showLoading {
    if (!_toast) {
        _toast = [[ToastView alloc] initWithFrame:[UIScreen mainScreen].bounds];
        [[UIApplication sharedApplication].keyWindow addSubview:_toast];
    }
    [_toast showLoading];
}

+ (void)showMessage:(NSString *)message {
    if (!message) return;

    if (!_toast) {
        _toast = [[ToastView alloc] initWithFrame:[UIScreen mainScreen].bounds];
        [[UIApplication sharedApplication].keyWindow addSubview:_toast];
    }
    [_toast show:message];
}

+ (void)hiddenLoading {
    [_toast dismiss];
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self == [super initWithFrame:frame]) {
        
        _maxW = frame.size.width * 0.5;
        _paddingT = 15;
        _paddingL = 15;
        
        _maskView = [[UIView alloc] init];
        _maskView.backgroundColor = [UIColor colorWithRed:89/255.0 green:89/255.0 blue:89/255.0 alpha:0.8];
        _maskView.layer.cornerRadius = 8;
        [self addSubview:_maskView];
        
        _label = [[UILabel alloc] init];
        _label.textColor = [UIColor whiteColor];
        _label.font = [UIFont systemFontOfSize:16.0];
        _label.textAlignment = NSTextAlignmentCenter;
        [_maskView addSubview:_label];
        
        _loadView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        _loadView.hidesWhenStopped = YES;
        [_maskView addSubview:_loadView];
    }
    return self;
}

- (void)show:(NSString *)message {
    [_loadView stopAnimating];
    NSMutableParagraphStyle* paragraphStyle = [[NSMutableParagraphStyle alloc]init];
    paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
    paragraphStyle.lineSpacing = 3;
    paragraphStyle.alignment = NSTextAlignmentCenter;
    NSDictionary *attributes = @{ NSFontAttributeName: [UIFont systemFontOfSize:16],
                                  NSParagraphStyleAttributeName: paragraphStyle.copy,
                                  NSForegroundColorAttributeName: [UIColor whiteColor]
    };
    
    NSAttributedString *att = [[NSAttributedString alloc] initWithString:message attributes:attributes];
    _label.attributedText = att;
    
    
    CGSize messageSize = [message boundingRectWithSize:CGSizeMake(_maxW, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading |NSStringDrawingTruncatesLastVisibleLine attributes:attributes context:nil].size;
    CGSize labelSize = CGSizeMake(messageSize.width + 2 * _paddingL, messageSize.height + 2 * _paddingT);
    CGRect frame = CGRectMake((self.frame.size.width-labelSize.width)/2, (self.frame.size.height-labelSize.height)/2, labelSize.width, labelSize.height);
    _maskView.frame = frame;
    _label.frame = CGRectMake(_paddingL, _paddingT, messageSize.width, messageSize.height);
    
    _label.hidden = NO;
    self.hidden = NO;
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(dismiss) object:nil];
    [self performSelector:@selector(dismiss) withObject:nil afterDelay:1.5];
}

- (void)showLoading {
    _label.hidden = YES;
    _maskView.frame = CGRectMake((self.bounds.size.width-50) / 2, (self.bounds.size.height-50)/2, 50, 50);
    _loadView.center = CGPointMake(25, 25);
    [_loadView startAnimating];
    self.hidden = NO;
}

- (void)dismiss {
    [_loadView stopAnimating];
    self.hidden = YES;
}

@end
