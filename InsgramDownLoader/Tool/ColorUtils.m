//
//  ColorUtils.m
//  InsgramDownLoader
//
//  Created by mac on 2019/11/20.
//  Copyright © 2019 leke. All rights reserved.
//

#import "ColorUtils.h"

@implementation ColorUtils

+ (UIColor *)whiteColor {
    if (@available(iOS 13.0, *)) {
        return [UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull traitCollection) {
            if (traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
                return [UIColor colorWithRed:51/255.0 green:51/255.0 blue:51/255.0 alpha:1.0];
            } else {
                return [UIColor whiteColor];
            }
        }];
    } else {
        return [UIColor whiteColor];
    }
}

+ (UIColor *)blackColor {
    if (@available(iOS 13.0, *)) {
        return [UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull traitCollection) {
            if (traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
                return [UIColor whiteColor];
            } else {
                return [UIColor colorWithRed:51/255.0 green:51/255.0 blue:51/255.0 alpha:1.0];
            }
        }];
    } else {
        return [UIColor colorWithRed:51/255.0 green:51/255.0 blue:51/255.0 alpha:1.0];
    }
}

+ (UIColor *)mainColor {
    if (@available(iOS 13.0, *)) {
        return [UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull traitCollection) {
            return [UIColor greenColor];
        }];
    } else {
        return [UIColor greenColor];
    }
}

+ (UIColor *)grayColor {
    if (@available(iOS 13.0, *)) {
        return [UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull traitCollection) {
            return[UIColor colorWithWhite:0.5 alpha:1.0];
        }];
    } else {
        return [UIColor colorWithWhite:0.5 alpha:1.0];
    }
}


@end
