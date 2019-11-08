//
//  VideoReCoderTool.h
//  InsgramDownLoader
//
//  Created by mac on 2019/10/29.
//  Copyright © 2019 leke. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface VideoReCoderTool : NSObject

+ (instancetype)startWithURL:(NSURL *)url complete:(void(^)(BOOL success, NSURL * _Nullable filePath))complete;

@end

NS_ASSUME_NONNULL_END
