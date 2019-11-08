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

@interface WKDownLoadTask : NSObject

@property (nonatomic, strong) NSURLSessionDownloadTask *task;
@property (nonatomic, assign) WKTaskStatus status;
@property (nonatomic,   copy) NSString *url;
@property (nonatomic,   copy) NSString *error;
@property (nonatomic,   copy) NSString *desc;
@property (nonatomic,   copy) NSString *filePath;
@property (nonatomic, assign) double progress;

@property (nonatomic,   copy, nullable) void (^ update)(WKDownLoadTask *task);

- (void)clear;

@end

NS_ASSUME_NONNULL_END
