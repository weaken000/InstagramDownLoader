//
//  WKDownLoadManager.m
//  InsgramDownLoader
//
//  Created by mac on 2019/11/7.
//  Copyright © 2019 leke. All rights reserved.
//

#import "WKDownLoadManager.h"
#import "WKDownLoadTask.h"
#import "ToastView.h"
#import <pthread.h>
#import "PhotosTool.h"
#import "VideoReCoderTool.h"

#define BACKSESSION_IDENTIFIER @"com.wk.insgramDownloader.backgroundSession"

@interface WKDownLoadManager()<NSURLSessionDownloadDelegate>
/// 所有任务
@property (nonatomic, strong) NSMutableArray<WKDownLoadTask *> *allTasks;
/// 下载中的任务
@property (nonatomic, strong) NSMutableArray<WKDownLoadTask *> *activeTasks;
/// 保存完成的任务
@property (nonatomic, strong) NSMutableArray<WKDownLoadTask *> *compeleteTasks;
/// 下载、保存失败的任务
@property (nonatomic, strong) NSMutableArray<WKDownLoadTask *> *errorTasks;

@property (nonatomic, strong) NSMutableDictionary<NSNumber *, WKDownLoadTask *> *tasksMap;

@property (nonatomic, assign) NSInteger activeCount;

@property (nonatomic, strong) NSRecursiveLock *lock;

@end

static WKDownLoadManager *_instance;

@implementation WKDownLoadManager

+ (instancetype)share {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[WKDownLoadManager alloc] init];
    });
    return _instance;
}

- (instancetype)init {
    if (self == [super init]) {
        
        _maxConcurrenceCount = 5;
        self.lock = [[NSRecursiveLock alloc] init];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillEnterFore) name:UIApplicationWillEnterForegroundNotification object:nil];
        
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:BACKSESSION_IDENTIFIER];
        _session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:[[NSOperationQueue alloc] init]];
        
        dispatch_async(dispatch_get_global_queue(0, DISPATCH_QUEUE_PRIORITY_DEFAULT), ^{
            [self readAllTask];
        });
    }
    return self;
}

#pragma mark - init
- (void)readAllTask {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:WK_TASK_PATH]) {
        NSArray *dirArray = [fileManager contentsOfDirectoryAtPath:WK_TASK_PATH error:nil];
        self.allTasks = [NSMutableArray arrayWithCapacity:dirArray.count];
        for (NSString *str in dirArray) {
            NSString *subPath = [WK_TASK_PATH stringByAppendingPathComponent:str];
            WKDownLoadTask *task = [NSKeyedUnarchiver unarchiveObjectWithFile:subPath];
            [self.allTasks addObject:task];
        }
    } else {
        [fileManager createDirectoryAtURL:[NSURL fileURLWithPath:WK_TASK_PATH] withIntermediateDirectories:YES attributes:nil error:nil];
    }
    if (!_allTasks) {
        _allTasks = [NSMutableArray array];
    }
    _tasksMap       = [NSMutableDictionary dictionary];
    _activeTasks    = [NSMutableArray array];
    _compeleteTasks = [NSMutableArray array];
    _errorTasks     = [NSMutableArray array];
    [self filterTasks];
}

- (void)filterTasks {
    
    for (WKDownLoadTask *task in self.allTasks) {
        if (task.status == WKTaskStatusFailure || task.status == WKTaskStatusSaveFailure) {//
            [self.errorTasks addObject:task];
        } else if (task.status == WKTaskStatusSaveFinish) {
            [self.compeleteTasks addObject:task];
        } else {
            [self.activeTasks addObject:task];
        }
    }
    
    /// 有可能在保存过程中应用奔溃，开启后重新下载
    for (WKDownLoadTask *task in self.errorTasks) {
        if (task.status == WKTaskStatusSaveFailure) {
            [self saveDataForTask:task];
        }
    }
    for (WKDownLoadTask *task in self.activeTasks) {
        if (task.status == WKTaskStatusFinished || task.status == WKTaskStatusSaveing) {
            [self saveDataForTask:task];
        }
    }
    
    __weak typeof(self) weakSelf = self;
    [_session getTasksWithCompletionHandler:^(NSArray<NSURLSessionDataTask *> * _Nonnull dataTasks, NSArray<NSURLSessionUploadTask *> * _Nonnull uploadTasks, NSArray<NSURLSessionDownloadTask *> * _Nonnull downloadTasks) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        for (NSURLSessionDownloadTask *task in downloadTasks) {
            WKDownLoadTask *loadTask = [strongSelf findTaskByUrl:task.originalRequest.URL.absoluteString];
            if (!loadTask) {
                continue;
            }
            loadTask.task = task;
            if (task.state == NSURLSessionTaskStateRunning) {
                loadTask.status = WKTaskStatusLoading;
                [strongSelf.tasksMap setObject:loadTask forKey:@(task.taskIdentifier)];
            } else if (task.state == NSURLSessionTaskStateSuspended) {
                loadTask.status = WKTaskStatusSuspend;
                [strongSelf.tasksMap setObject:loadTask forKey:@(task.taskIdentifier)];
            } else if (task.state == NSURLSessionTaskStateCanceling) {
                loadTask.error = @"任务被取消";
                loadTask.status = WKTaskStatusFailure;
                if (![strongSelf.errorTasks containsObject:loadTask]) {
                    [strongSelf.errorTasks addObject:loadTask];
                }
                if ([strongSelf.activeTasks containsObject:loadTask]) {
                    [strongSelf.activeTasks removeObject:loadTask];
                }
            } else {
                loadTask.error = @"后台下载失败";
                loadTask.status = WKTaskStatusFailure;
                if (![strongSelf.errorTasks containsObject:loadTask]) {
                    [strongSelf.errorTasks addObject:loadTask];
                }
                if ([strongSelf.activeTasks containsObject:loadTask]) {
                    [strongSelf.activeTasks removeObject:loadTask];
                }
            }
        }
        
        [strongSelf toggleDelegateInMainthread];
    }];
}

- (WKDownLoadTask * _Nullable)findTaskByUrl:(NSString *)url {
    for (WKDownLoadTask *task in self.allTasks) {
        if ([task.url isEqualToString:url]) {
            return task;
        }
    }
    return nil;
}

- (void)safe:(void(^)(void))block {
    [self.lock lock];
    void (^ copy)(void) = [block copy];
    copy();
    copy = nil;
    [self.lock unlock];
}

- (void)toggleDelegateInMainthread {
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.delegate respondsToSelector:@selector(downloadManagerDidUpdateTask:)]) {
            [self.delegate downloadManagerDidUpdateTask:self];
        }
    });
}

#pragma mark - Task Action
/// 添加下载任务(创建sessionTask)
- (void)addTask:(WKDownLoadTask *)task {
    if (!task) return;
    [self safe:^{
        if (![self.activeTasks containsObject:task]) {
            [self.activeTasks addObject:task];
        }
        if (self.activeCount < self.maxConcurrenceCount) {//未达到临界值，立即下载
            self.activeCount += 1;
            task.task = [self.session downloadTaskWithURL:[NSURL URLWithString:task.url]];
            [self.tasksMap setObject:task forKey:@(task.task.taskIdentifier)];
            task.status = WKTaskStatusLoading;
            [task.task resume];
        } else {
            task.status = WKTaskStatusWait;
        }
        if ([self.delegate respondsToSelector:@selector(downloadManagerDidUpdateTask:)]) {
            [self.delegate downloadManagerDidUpdateTask:self];
        }
    }];
}
/// 添加多个下载任务(创建sessionTask)
- (void)addTasks:(NSArray<WKDownLoadTask *> *)tasks {
    [self safe:^{
        for (WKDownLoadTask *task in tasks) {
            if (![self.activeTasks containsObject:task]) {
                [self.activeTasks addObject:task];
            }
            if (self.activeCount < self.maxConcurrenceCount) {//未达到临界值，立即下载
                self.activeCount += 1;
                task.task = [self.session downloadTaskWithURL:[NSURL URLWithString:task.url]];
                [self.tasksMap setObject:task forKey:@(task.task.taskIdentifier)];
                task.status = WKTaskStatusLoading;
                [task.task resume];
            } else {
                task.status = WKTaskStatusWait;
            }
        }
        if ([self.delegate respondsToSelector:@selector(downloadManagerDidUpdateTask:)]) {
            [self.delegate downloadManagerDidUpdateTask:self];
        }
    }];
    
}
/// 暂停任务
- (void)suspendTask:(WKDownLoadTask *)task {
    if (!task) return;

    [self safe:^{
        if (task.status == WKTaskStatusLoading) {
            [task.task cancelByProducingResumeData:^(NSData * _Nullable resumeData) {
                [self.tasksMap removeObjectForKey:@(task.task.taskIdentifier)];
                task.resumeData = resumeData;
                task.task = nil;
                self.activeCount -= 1;
                task.status = WKTaskStatusSuspend;
            }];
        }
    }];
}
/// 继续任务(暂停状态继续下载，下载失败重新下载，保存失败重新保存，其他状态不处理)
- (void)resumeTask:(WKDownLoadTask *)task {
    if (!task) return;
    
    [self safe:^{
        //暂停中，继续下载
        if (task.status == WKTaskStatusSuspend || task.status == WKTaskStatusWait) {
            NSURLSessionDownloadTask *downloadTask;
            if (task.resumeData) {
                downloadTask = [self.session downloadTaskWithResumeData:task.resumeData];
                task.resumeData = nil;
            } else {
                downloadTask = [self.session downloadTaskWithURL:[NSURL URLWithString:task.url]];
            }
            task.task = downloadTask;
            task.status = WKTaskStatusLoading;
            [self.tasksMap setObject:task forKey:@(downloadTask.taskIdentifier)];
            [task.task resume];
            if (self.activeCount == self.maxConcurrenceCount) {
                for (WKDownLoadTask *tmp in self.activeTasks) {
                    if (tmp.status == WKTaskStatusLoading) {
                        [self suspendTask:tmp];
                        self.activeCount -= 1;
                        break;
                    }
                }
            }
            self.activeCount += 1;
            return;
        }
        
        //下载失败，重新下载
        if (task.status == WKTaskStatusFailure) {
            task.error = nil;
            task.progress = 0;
            [self.errorTasks removeObject:task];
            [self addTask:task];
            if ([self.delegate respondsToSelector:@selector(downloadManagerDidUpdateTask:)]) {
                [self.delegate downloadManagerDidUpdateTask:self];
            }
            return;
        }
        
        //保存失败，重新保存
        if (task.status == WKTaskStatusSaveFailure) {
            [self.errorTasks removeObject:task];
            [self.activeTasks addObject:task];
            if ([self.delegate respondsToSelector:@selector(downloadManagerDidUpdateTask:)]) {
                [self.delegate downloadManagerDidUpdateTask:self];
            }
            
            [self saveDataForTask:task];
        }
        
    }];
}

- (void)cancelTask:(WKDownLoadTask *)task {
    if (!task) return;

    [self safe:^{
        if (task.status == WKTaskStatusLoading) {
            [task clear];
            task.error = @"下载任务被取消";
            task.status = WKTaskStatusFailure;
            self.activeCount -= 1;
            [self.errorTasks addObject:task];
            [self.activeTasks removeObject:task];
            if ([self.delegate respondsToSelector:@selector(downloadManagerDidUpdateTask:)]) {
                [self.delegate downloadManagerDidUpdateTask:self];
            }
        }
    }];
}

- (void)startNextTask {
    [self safe:^{
        if (self.activeTasks.count > 0) {
            for (WKDownLoadTask *task in self.activeTasks) {
                if (task.status == WKTaskStatusWait || task.status == WKTaskStatusSuspend) {
                    [self addTask:task];
                    break;
                }
            }
        }
    }];
}

- (void)clear {
    for (WKDownLoadTask *task in self.compeleteTasks) {
        [task clear];
    }
    [self.allTasks removeObjectsInArray:self.compeleteTasks];
    [self.compeleteTasks removeAllObjects];
    
    for (WKDownLoadTask *task in self.errorTasks) {
        [task clear];
    }
    [self.allTasks removeObjectsInArray:self.errorTasks];
    [self.errorTasks removeAllObjects];
    [self toggleDelegateInMainthread];
}

#pragma mark - NSURLSessionDownloadDelegate
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(nullable NSError *)error {
    if (error) {
        WKDownLoadTask *model = [self.tasksMap objectForKey:@(task.taskIdentifier)];
        if (!model || [_errorTasks containsObject:model]) {
            return;
        }
        
        self.activeCount -= 1;
        model.error = error.localizedRecoverySuggestion;
        model.status = WKTaskStatusFailure;
        [self.activeTasks removeObject:model];
        [self.errorTasks addObject:model];
        [self startNextTask];
        [self toggleDelegateInMainthread];
    } else {
        WKDownLoadTask *model = [self.tasksMap objectForKey:@(task.taskIdentifier)];
        if (!model) {
            return;
        }
        
    }
}

// 写数据
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
    WKDownLoadTask *model = [self.tasksMap objectForKey:@(downloadTask.taskIdentifier)];
    model.progress = totalBytesWritten * 1.0 / totalBytesExpectedToWrite;
}

// 下载完成
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location {
    WKDownLoadTask *model = [self.tasksMap objectForKey:@(downloadTask.taskIdentifier)];
    if (!model) {
        return;
    }
    self.activeCount -= 1;
    [self startNextTask];
    
    model.filePath = location.path;
    model.status = WKTaskStatusFinished;
    
    //从tmp文件夹移到cache的沙盒文件夹
    NSError *error;
    NSString *cache = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
    NSString *dir = [cache stringByAppendingPathComponent:@"com.cache.lk"];
    if (![[NSFileManager defaultManager] isExecutableFileAtPath:dir]) {
        [[NSFileManager defaultManager] createDirectoryAtURL:[NSURL fileURLWithPath:dir] withIntermediateDirectories:YES attributes:nil error:nil];
    }
    NSString *cachePath = [dir stringByAppendingPathComponent:downloadTask.response.suggestedFilename];
    if ([[NSFileManager defaultManager] fileExistsAtPath:cachePath]) {
        [[NSFileManager defaultManager] removeItemAtPath:cachePath error:nil];
    }

    [[NSFileManager defaultManager] moveItemAtURL:location toURL:[NSURL fileURLWithPath:cachePath] error:&error];
   
    if (error) {
        model.error = error.localizedRecoverySuggestion;
        model.status = WKTaskStatusSaveFailure;
        [self.activeTasks removeObject:model];
        [self.errorTasks addObject:model];
        [self toggleDelegateInMainthread];
    } else {
        model.filePath = cachePath;
        [self saveDataForTask:model];
    }
}

//后台或有任务下载完成
- (void)URLSessionDidFinishEventsForBackgroundURLSession:(NSURLSession *)session {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.completionHandler) {
            self.completionHandler();
        }
    });
}

#pragma mark -
- (void)saveDataForTask:(WKDownLoadTask *)task {
    __weak typeof(self) weakSelf = self;
    __weak typeof(task) weakTask = task;
    task.status = WKTaskStatusSaveing;
    if (task.mediaType == WKMediaTypeYoutubeVideo) {//保存youtube
        [[PhotosTool share] saveYoutube:[NSURL fileURLWithPath:task.filePath] compeled:^(NSString * _Nullable error) {
            [weakSelf.activeTasks removeObject:weakTask];
            if (error) {
                weakTask.error = error;
                weakTask.status = WKTaskStatusSaveFailure;
                [weakSelf.errorTasks addObject:weakTask];
            } else {
                weakTask.status = WKTaskStatusSaveFinish;
                [weakSelf.compeleteTasks addObject:weakTask];
            }
            [weakSelf toggleDelegateInMainthread];
        }];
    } else {
        if (task.mediaType == WKMediaTypeInstagramImage) {//保存图片
            NSData *data = [NSData dataWithContentsOfURL:[NSURL fileURLWithPath:task.filePath]];
            UIImage *image = [UIImage imageWithData:data];
            [[PhotosTool share] saveImage:image compeled:^(NSString * _Nullable error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (error) {
                        weakTask.error = error;
                        weakTask.status = WKTaskStatusSaveFailure;
                        [weakSelf.activeTasks removeObject:weakTask];
                        [weakSelf.errorTasks addObject:weakTask];
                    } else {
                        weakTask.status = WKTaskStatusSaveFinish;
                        [weakSelf.activeTasks removeObject:weakTask];
                        [weakSelf.compeleteTasks addObject:weakTask];
                    }
                    [weakSelf toggleDelegateInMainthread];
                });
            }];
        } else {//保存视频
            //是否开启编码
            BOOL isOpen = [[NSUserDefaults standardUserDefaults] boolForKey:@"com.wk.open"];
            if (isOpen) {
                task.status = WKTaskStatusCoding;
                //尝试进行编码
                NSURL *fromUrl = [NSURL fileURLWithPath:task.filePath];
                [VideoReCoderTool startWithURL:fromUrl complete:^(BOOL success, NSURL * _Nullable filePath) {
                    if (success) {//编码成功
                        weakTask.filePath = [filePath path];
                    }
                    [[PhotosTool share] saveVideo:[NSURL fileURLWithPath:weakTask.filePath] compeled:^(NSString * _Nullable error) {
                        if (error) {
                            weakTask.error = error;
                            weakTask.status = WKTaskStatusSaveFailure;
                            [weakSelf.activeTasks removeObject:weakTask];
                            [weakSelf.errorTasks addObject:weakTask];
                        } else {
                            weakTask.status = WKTaskStatusSaveFinish;
                            [weakSelf.activeTasks removeObject:weakTask];
                            [weakSelf.compeleteTasks addObject:weakTask];
                        }
                        [weakSelf toggleDelegateInMainthread];
                    }];
                }];
            } else {
                [[PhotosTool share] saveVideo:[NSURL fileURLWithPath:task.filePath] compeled:^(NSString * _Nullable error) {
                    if (error) {
                        weakTask.error = error;
                        weakTask.status = WKTaskStatusSaveFailure;
                        [weakSelf.activeTasks removeObject:weakTask];
                        [weakSelf.errorTasks addObject:weakTask];
                    } else {
                        weakTask.status = WKTaskStatusSaveFinish;
                        [weakSelf.activeTasks removeObject:weakTask];
                        [weakSelf.compeleteTasks addObject:weakTask];
                    }
                    [weakSelf toggleDelegateInMainthread];
                }];
            }
        }
    }
}

- (void)applicationWillEnterFore {
    [self toggleDelegateInMainthread];
}

@end
