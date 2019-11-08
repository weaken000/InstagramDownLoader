//
//  ToastView.h
//  InsgramDownLoader
//
//  Created by mac on 2019/10/12.
//  Copyright © 2019 leke. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ToastView : UIView

+ (void)showLoading;

+ (void)hiddenLoading;

+ (void)showMessage:(nullable NSString *)message;

@end

NS_ASSUME_NONNULL_END
