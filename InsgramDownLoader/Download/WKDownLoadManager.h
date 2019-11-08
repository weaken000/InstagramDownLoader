//
//  WKDownLoadManager.h
//  InsgramDownLoader
//
//  Created by mac on 2019/11/7.
//  Copyright © 2019 leke. All rights reserved.
//

#import <Foundation/Foundation.h>

@class WKDownLoadTask;

NS_ASSUME_NONNULL_BEGIN

typedef enum : NSUInteger {
    WKDownLoadTypeIns,
    WKDownLoadTypeYoutube
} WKDownLoadType;

@class WKDownLoadManager;

@protocol WKDownLoadManagerDelegate <NSObject>

@optional
/// 下载任务变化(变化指的是3个任务数组的数量变化，并非具体某个任务状态的变化)
- (void)downloadManagerDidUpdateTask:(WKDownLoadManager *)manager;

@end

@interface WKDownLoadManager : NSObject

@property (nonatomic, strong, readonly) NSURLSession *session;

@property (nonatomic,   copy) void (^ completionHandler)(void);
/// 下载的地址
@property (nonatomic, strong) NSArray<NSString *> *urls;
/// 下载类型
@property (nonatomic, assign) WKDownLoadType type;
/// 下载中的任务
@property (nonatomic, strong, readonly) NSMutableArray<WKDownLoadTask *> *activeTasks;
/// 下载完成的任务
@property (nonatomic, strong, readonly) NSMutableArray<WKDownLoadTask *> *compeleteTasks;
/// 下载失败的任务
@property (nonatomic, strong, readonly) NSMutableArray<WKDownLoadTask *> *errorTasks;
/// 是否开启转码
@property (nonatomic, assign, getter=isEncode) BOOL encode;
/// 最大下载数量
@property (nonatomic, assign) NSInteger maxConcurrenceCount;

@property (nonatomic,   weak) id<WKDownLoadManagerDelegate> delegate;

+ (instancetype)share;

/// 暂停任务(只有在下载中时有效)
- (void)suspendTask:(WKDownLoadTask *)task;
/// 继续任务(暂停状态继续下载，下载失败重新下载，保存失败重新保存，其他状态不处理)
- (void)resumeTask:(WKDownLoadTask *)task;
/// 取消任务(只有在下载、转码有效，进入保存后无法停止)
- (void)cancelTask:(WKDownLoadTask *)task;

- (void)clear;

@end

NS_ASSUME_NONNULL_END
