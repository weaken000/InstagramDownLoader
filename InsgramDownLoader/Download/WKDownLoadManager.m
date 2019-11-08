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

#define BACKSESSION_IDENTIFIER @"com.wk.backgroundSession"

@interface WKDownLoadManager()<NSURLSessionDownloadDelegate>
/// 下载中的任务
@property (nonatomic, strong) NSMutableArray<WKDownLoadTask *> *activeTasks;
/// 下载完成的任务
@property (nonatomic, strong) NSMutableArray<WKDownLoadTask *> *compeleteTasks;
/// 下载失败的任务
@property (nonatomic, strong) NSMutableArray<WKDownLoadTask *> *errorTasks;

@property (nonatomic, strong) NSMutableDictionary<NSNumber *, WKDownLoadTask *> *tasksMap;

@property (nonatomic, assign) NSInteger activeCount;

@end

static WKDownLoadManager *_instance;
pthread_mutex_t mutex;

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
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:BACKSESSION_IDENTIFIER];
        config.sessionSendsLaunchEvents = YES;
        config.discretionary = YES;
        _session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:[NSOperationQueue mainQueue]];
        
        _maxConcurrenceCount = 5;
        _tasksMap = [NSMutableDictionary dictionary];
        _activeTasks = [NSMutableArray array];
        _compeleteTasks = [NSMutableArray array];
        _errorTasks = [NSMutableArray array];
        pthread_mutex_init(&mutex,NULL);
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillEnterFore) name:UIApplicationWillEnterForegroundNotification object:nil];
    }
    return self;
}

- (void)setUrls:(NSArray<NSString *> *)urls {
    _urls = urls;
    [self clear];
    if ([self.delegate respondsToSelector:@selector(downloadManagerDidUpdateTask:)]) {
        [self.delegate downloadManagerDidUpdateTask:self];
    }
    
    //创建下载列表
    [self setupDownloadTasks];
}

#pragma mark -
- (void)setupDownloadTasks {
    for (int i = 0; i < _urls.count; i++) {
        if ([_urls[i] isKindOfClass:[NSNull class]]) {
            continue;
        }
        NSString *url = _urls[i];
        if (self.type == WKDownLoadTypeIns) {
            //下载ins素材
            if ([url rangeOfString:@"&dl=1"].location != NSNotFound) {
                url = [url substringToIndex:url.length-5];
            }
            NSURLSessionDownloadTask *task = [_session downloadTaskWithURL:[NSURL URLWithString:url]];
            WKDownLoadTask *model = [[WKDownLoadTask alloc] init];
            model.task = task;
            model.url = url;
            model.desc = [url containsString:@".jpg?"] ? @"instagram图片" : @"instagram视频";
            [self wk_addTask:model];
            if ([self.delegate respondsToSelector:@selector(downloadManagerDidUpdateTask:)]) {
                [self.delegate downloadManagerDidUpdateTask:self];
            }
        } else {
            //下载youtube视频
            __weak typeof(self) weakSelf = self;
            [self getdownLoaderUrl:url maxRetry:10 complete:^(NSDictionary * _Nullable videoDict, NSString * _Nullable error) {
                if (error) {
                    WKDownLoadTask *model = [[WKDownLoadTask alloc] init];
                    model.error = error;
                    model.url = url;
                    model.status = WKTaskStatusLoading;
                    [self.errorTasks addObject:model];
                } else {
                    NSArray *formats = videoDict[@"formats"];
                    for (int j = 0; j < formats.count; j++) {
                        NSDictionary *format = formats[j];
                        NSString *fileSize   = [NSString stringWithFormat:@"%.2fM", [format[@"filesize"] integerValue] / 1024.0 / 1024.0];
                        NSString *type       = format[@"ext"];//文件类型
                        NSString *height     = format[@"height"];
                        NSString *acodec     = [format[@"acodec"] isEqualToString:@"none"]?@"无声":@"有声";
                        NSString *url        = format[@"url"];
                        
                        WKDownLoadTask *task = [[WKDownLoadTask alloc] init];
                        task.url = url;
                        task.desc = [NSString stringWithFormat:@"%@ | %@ | %@ | %@", height, type, fileSize, acodec];
                        task.status = WKTaskStatusWait;
                        [weakSelf.activeTasks addObject:task];
                    }
                }
                if ([weakSelf.delegate respondsToSelector:@selector(downloadManagerDidUpdateTask:)]) {
                    [weakSelf.delegate downloadManagerDidUpdateTask:weakSelf];
                }
            }];
        }
    }
}

#pragma mark - Task Action
- (void)wk_addTask:(WKDownLoadTask *)task {
    pthread_mutex_lock(&mutex);
    if (![self.activeTasks containsObject:task]) {
        [self.activeTasks addObject:task];
    }
    if (![self.tasksMap.allValues containsObject:task]) {
        [self.tasksMap setObject:task forKey:@(task.task.taskIdentifier)];
    }
    if (self.activeCount < self.maxConcurrenceCount) {//未达到临界值，立即下载
        self.activeCount += 1;
        task.status = WKTaskStatusLoading;
        [task.task resume];
    } else {
        task.status = WKTaskStatusWait;
    }
    if ([self.delegate respondsToSelector:@selector(downloadManagerDidUpdateTask:)]) {
        [self.delegate downloadManagerDidUpdateTask:self];
    }
    pthread_mutex_unlock(&mutex);
}

- (void)suspendTask:(WKDownLoadTask *)task {
    if (task.status == WKTaskStatusLoading) {
        pthread_mutex_lock(&mutex);
        self.activeCount -= 1;
        [task.task suspend];
        pthread_mutex_unlock(&mutex);
    }
}

//继续任务(暂停状态继续下载，下载失败重新下载，保存失败重新保存，其他状态不处理)
- (void)resumeTask:(WKDownLoadTask *)task {
    
    //等待开始下载，还没有初始化下载任务
    if (self.type == WKDownLoadTypeYoutube && task.status == WKTaskStatusWait) {
        NSURLSessionDownloadTask *downloadTask = [_session downloadTaskWithURL:[NSURL URLWithString:task.url]];
        task.task = downloadTask;
        [self wk_addTask:task];
        if ([self.delegate respondsToSelector:@selector(downloadManagerDidUpdateTask:)]) {
            [self.delegate downloadManagerDidUpdateTask:self];
        }
        return;
    }
    
    //暂停，继续下载
    if (task.status == WKTaskStatusSuspend) {
        pthread_mutex_lock(&mutex);
        //已经到达阈值，暂停活跃里正在下载的第一个
        if (self.activeCount == self.maxConcurrenceCount) {
            for (WKDownLoadTask *activeTask in self.activeTasks) {
                if (activeTask.status == WKTaskStatusLoading) {
                    [activeTask.task suspend];
                    activeTask.status = WKTaskStatusSuspend;
                    self.activeCount -= 1;
                    break;
                }
            }
        }
        self.activeCount = MIN(self.maxConcurrenceCount, (self.activeCount + 1));
        task.status = WKTaskStatusLoading;
        [task.task resume];
        pthread_mutex_unlock(&mutex);
        return;
    }
    
    //下载失败，重新下载
    if (task.status == WKTaskStatusFailure) {
        NSURLSessionDownloadTask *downloadTask = [_session downloadTaskWithURL:[NSURL URLWithString:task.url]];
        task.task = downloadTask;
        [self.errorTasks removeObject:task];
        [self wk_addTask:task];
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
        
        task.status = WKTaskStatusSaveing;
        [self saveDataForTask:task];
        return;
    }
    
}

- (void)cancelTask:(WKDownLoadTask *)task {
    
}

- (void)clear {
    //清除历史下载记录
    for (WKDownLoadTask *task in self.activeTasks) {
        [task clear];
    }
    [self.activeTasks removeAllObjects];
    
    for (WKDownLoadTask *task in self.compeleteTasks) {
        [task clear];
    }
    [self.compeleteTasks removeAllObjects];
    
    for (WKDownLoadTask *task in self.errorTasks) {
        [task clear];
    }
    [self.errorTasks removeAllObjects];
    
    [self.tasksMap removeAllObjects];
    self.activeCount = 0;
}

#pragma mark - NSURLSessionDownloadDelegate

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(nullable NSError *)error {
    self.activeCount -= 1;
    if (error) {
        WKDownLoadTask *model = [self.tasksMap objectForKey:@(task.taskIdentifier)];
        if (!model) {
            return;
        }
        model.error = error.localizedRecoverySuggestion;
        model.status = WKTaskStatusFailure;
        [self.activeTasks removeObject:model];
        [self.errorTasks addObject:model];
        if ([self.delegate respondsToSelector:@selector(downloadManagerDidUpdateTask:)]) {
            [self.delegate downloadManagerDidUpdateTask:self];
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
    self.activeCount -= 1;
    WKDownLoadTask *model = [self.tasksMap objectForKey:@(downloadTask.taskIdentifier)];
    if (!model) {
        return;
    }
    model.status = WKTaskStatusSaveing;
    //当文件是视频格式时，需要从tmp文件夹移到其他的沙盒文件夹
    NSError *error;
    if (self.type == WKDownLoadTypeYoutube || ![model.url containsString:@"jpg?"]) {
        NSString *cache = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
        NSString *dir = [cache stringByAppendingPathComponent:@"com.cache.lk"];
        if (![[NSFileManager defaultManager] isExecutableFileAtPath:dir]) {
            [[NSFileManager defaultManager] createDirectoryAtURL:[NSURL fileURLWithPath:dir] withIntermediateDirectories:YES attributes:nil error:nil];
        }
        model.filePath = [dir stringByAppendingPathComponent:downloadTask.response.suggestedFilename];
        if ([[NSFileManager defaultManager] fileExistsAtPath:model.filePath]) {
            [[NSFileManager defaultManager] removeItemAtPath:model.filePath error:nil];
        }

        [[NSFileManager defaultManager] moveItemAtURL:location toURL:[NSURL fileURLWithPath:model.filePath] error:&error];
    } else {
        model.filePath = location.path;
    }
    
    if (error) {
        model.error = error.localizedRecoverySuggestion;
        model.status = WKTaskStatusSaveFailure;
        [self.activeTasks removeObject:model];
        [self.errorTasks addObject:model];
        if ([self.delegate respondsToSelector:@selector(downloadManagerDidUpdateTask:)]) {
            [self.delegate downloadManagerDidUpdateTask:self];
        }
    } else {
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
- (void)getdownLoaderUrl:(NSString *)yotubeUrl maxRetry:(NSUInteger)maxRetry complete:(void (^) (NSDictionary * _Nullable videoDict, NSString * _Nullable error))complete {
        
    NSURLComponents *youtubeCpm = [NSURLComponents componentsWithString:yotubeUrl];
    NSString *youtubeWatchKey;
    if ([youtubeCpm.host isEqualToString:@"youtu.be"]) {
        youtubeWatchKey = [youtubeCpm.path substringFromIndex:1];
    } else {
        if (!youtubeCpm.queryItems.count) {
            complete(nil, @"获取不到下载链接的key");
            return;
        }
        youtubeWatchKey = youtubeCpm.queryItems.firstObject.value;
    }
    [ToastView showLoading];
    NSString *referer = [NSString stringWithFormat:@"ttps://keepvid.pro/youtube/%@", youtubeWatchKey];
    NSDictionary *httpHeaders = @{@"Content-Type": @"application/json",
                                  @"Referer": referer,
                                  @"Host": @"v2api.keepvid.pro",
                                  @"Origin": @"https://keepvid.pro"
    };
    
    NSURLSession *session = [NSURLSession sharedSession];
    
    NSMutableURLRequest *jobReq = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:@"https://v2api.keepvid.pro/v1/job"]];
    jobReq.HTTPMethod = @"POST";
    [jobReq setAllHTTPHeaderFields:httpHeaders];
    NSDictionary *jobParam = @{@"params": @{@"video_url": yotubeUrl},
                               @"type": @"crawler"
    };
    jobReq.HTTPBody = [NSJSONSerialization dataWithJSONObject:jobParam options:NSJSONWritingFragmentsAllowed error:nil];
    
    NSURLSessionDataTask *jobTask = [session dataTaskWithRequest:jobReq completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (error) {
                complete(nil, @"获取jobId失败");
                return;
            }
            //获取到了jobid，获取正确的下载视频链接
            id res = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
            NSString *jobId = [[res objectForKey:@"data"] objectForKey:@"job_id"];
            NSString *type  = [[res objectForKey:@"data"] objectForKey:@"type"];

            if (jobId) {
                NSMutableURLRequest *dataReq = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://v2api.keepvid.pro/v1/check?type=%@&job_id=%@", type, jobId]]];
                dataReq.HTTPMethod = @"GET";
                [dataReq setAllHTTPHeaderFields:httpHeaders];
                NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:dataReq completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (error) {
                            complete(nil, @"获取视频下载列表失败");
                            return;
                        }
                        [ToastView hiddenLoading];
                        id res = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
                        NSLog(@"%@", res);
                        NSDictionary *data = [res objectForKey:@"data"];
                        if (!data) {
                            complete(nil, @"获取data失败");
                            return;
                        }
                        NSArray *formats = data[@"formats"];
                        if (!formats) {
                            if (maxRetry == 0) {
                                complete(nil, @"连续10次获取不到视频链接");
                            } else {
                                
                            }
                            [self getdownLoaderUrl:yotubeUrl maxRetry:maxRetry-1 complete:complete];
                        } else {
                            complete(data, nil);
                        }
                    });
                }];
                [dataTask resume];
            }
        });
    }];
    [jobTask resume];
}

- (void)saveDataForTask:(WKDownLoadTask *)task {
    __weak typeof(self) weakSelf = self;
    __weak typeof(task) weakTask = task;
    if (self.type == WKDownLoadTypeYoutube) {//保存youtube
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
            if ([weakSelf.delegate respondsToSelector:@selector(downloadManagerDidUpdateTask:)]) {
                [weakSelf.delegate downloadManagerDidUpdateTask:weakSelf];
            }
        }];
    } else {
        if ([task.url containsString:@"jpg?"]) {//保存图片
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
                    if ([weakSelf.delegate respondsToSelector:@selector(downloadManagerDidUpdateTask:)]) {
                        [weakSelf.delegate downloadManagerDidUpdateTask:weakSelf];
                    }
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
                        if ([weakSelf.delegate respondsToSelector:@selector(downloadManagerDidUpdateTask:)]) {
                            [weakSelf.delegate downloadManagerDidUpdateTask:weakSelf];
                        }
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
                    if ([weakSelf.delegate respondsToSelector:@selector(downloadManagerDidUpdateTask:)]) {
                        [weakSelf.delegate downloadManagerDidUpdateTask:weakSelf];
                    }
                }];
            }
        }
    }
}

- (void)applicationWillEnterFore {
    if ([self.delegate respondsToSelector:@selector(downloadManagerDidUpdateTask:)]) {
        [self.delegate downloadManagerDidUpdateTask:self];
    }
}

@end
