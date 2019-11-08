//
//  PhotosTool.h
//  InsgramDownLoader
//
//  Created by mac on 2019/10/30.
//  Copyright © 2019 leke. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Photos/Photos.h>

NS_ASSUME_NONNULL_BEGIN

@interface PhotosTool : NSObject

+ (instancetype)share;

- (void)saveVideo:(NSURL *)videoFile compeled:(void(^)(NSString *_Nullable error))completed;
- (void)saveYoutube:(NSURL *)youtube compeled:(void(^)(NSString *_Nullable error))completed;
- (void)saveImage:(UIImage *)image compeled:(void(^)(NSString *_Nullable error))completed;
@end

NS_ASSUME_NONNULL_END
