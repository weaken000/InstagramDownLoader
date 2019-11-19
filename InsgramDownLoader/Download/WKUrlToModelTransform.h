//
//  WKUrlToModelTransform.h
//  InsgramDownLoader
//
//  Created by mac on 2019/11/19.
//  Copyright © 2019 leke. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WKDownLoadTask.h"

NS_ASSUME_NONNULL_BEGIN

@interface WKUrlToModelTransform : NSObject

+ (void)transformYoutubeUrl:(NSString *)url complete:(void(^ _Nullable)(NSArray<WKDownLoadTask *> * _Nullable list, NSString * _Nullable error))complete;

+ (void)transformInstagramUrls:(NSArray<NSString *> *)urls complete:(void(^ _Nullable)(void))comeplete;



@end

NS_ASSUME_NONNULL_END
