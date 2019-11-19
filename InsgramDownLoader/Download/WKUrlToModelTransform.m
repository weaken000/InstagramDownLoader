//
//  WKUrlToModelTransform.m
//  InsgramDownLoader
//
//  Created by mac on 2019/11/19.
//  Copyright © 2019 leke. All rights reserved.
//

#import "WKUrlToModelTransform.h"
#import "WKDownLoadManager.h"

@implementation WKUrlToModelTransform

+ (void)transformYoutubeUrl:(NSString *)url complete:(void (^)(NSArray<WKDownLoadTask *> * _Nullable, NSString * _Nullable))complete {
    [self getdownLoaderUrl:url maxRetry:10 complete:^(NSDictionary * _Nullable videoDict, NSString * _Nullable error) {
        if (error) {
            complete(nil, error);
        } else {
            NSArray *formats = videoDict[@"formats"];
            NSMutableArray *result = [NSMutableArray arrayWithCapacity:formats.count];
            for (int j = 0; j < formats.count; j++) {
                NSDictionary *format = formats[j];
                NSString *fileSize   = [NSString stringWithFormat:@"%.2fM", [format[@"filesize"] integerValue] / 1024.0 / 1024.0];
                NSString *type       = format[@"ext"];//文件类型
                NSString *height     = format[@"height"];
                NSString *acodec     = [format[@"acodec"] isEqualToString:@"none"]?@"无声":@"有声";
                NSString *url        = format[@"url"];
                
                WKDownLoadTask *task = [[WKDownLoadTask alloc] init];
                task.url = url;
                task.mediaType = WKMediaTypeYoutubeVideo;
                task.desc = [NSString stringWithFormat:@"%@ | %@ | %@ | %@", height, type, fileSize, acodec];
                [result addObject:task];
            }
            complete(result, nil);
        }
    }];
}

/// 获取youtube下载链接
+ (void)getdownLoaderUrl:(NSString *)yotubeUrl maxRetry:(NSUInteger)maxRetry complete:(void (^) (NSDictionary * _Nullable videoDict, NSString * _Nullable error))complete {
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


+ (void)transformInstagramUrls:(NSArray<NSString *> *)urls complete:(void (^)(void))comeplete {
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:urls.count];
    for (int i = 0; i < urls.count; i++) {
        if ([urls[i] isKindOfClass:[NSNull class]]) {
            continue;
        }
        
        NSString *url = urls[i];
        if ([url rangeOfString:@"&dl=1"].location != NSNotFound) {
            url = [url substringToIndex:url.length-5];
        }
        WKDownLoadTask *model = [[WKDownLoadTask alloc] init];
        model.url = url;
        if ([url containsString:@".jpg"]) {
            model.desc = @"instagram图片";
            model.mediaType = WKMediaTypeInstagramImage;
        } else {
            model.desc = @"instagram视频";
            model.mediaType = WKMediaTypeInstagramVideo;
        }
        [result addObject:model];
    }
    [[WKDownLoadManager share] addTasks:result];
    comeplete();
}

@end
