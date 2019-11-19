//
//  WKDownLoadTask.h
//  InsgramDownLoader
//
//  Created by mac on 2019/11/7.
//  Copyright © 2019 leke. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, WKTaskStatus) {
    WKTaskStatusWait,      //等待开始
    WKTaskStatusLoading,   //下载中
    WKTaskStatusSuspend,   //暂停
    WKTaskStatusFinished,  //完成
    WKTaskStatusFailure,   //下载失败
    
    WKTaskStatusCoding,    //编码中
    
    WKTaskStatusSaveing,    //保存中
    WKTaskStatusSaveFinish, //保存完成
    WKTaskStatusSaveFailure //保存失败
};

typedef NS_ENUM(NSUInteger, WKMediaType) {
    WKMediaTypeInstagramImage,
    WKMediaTypeInstagramVideo,
    WKMediaTypeYoutubeVideo,
};

@interface WKDownLoadTask : NSObject<NSCoding>

@property (nonatomic, strong, nullable) NSURLSessionDownloadTask *task;
@property (nonatomic,   copy, nullable) NSString *url;
@property (nonatomic,   copy, nullable) NSString *error;
@property (nonatomic,   copy, nullable) NSString *desc;
@property (nonatomic,   copy, nullable) NSString *filePath;
@property (nonatomic, strong, nullable) NSData   *resumeData;
@property (nonatomic, assign) double       progress;
@property (nonatomic, assign) WKTaskStatus status;
@property (nonatomic, assign) WKMediaType  mediaType;

@property (nonatomic,   copy, nullable) void (^ update)(WKDownLoadTask *task);

- (void)clear;

- (void)save;

@end

NS_ASSUME_NONNULL_END
