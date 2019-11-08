//
//  AppDelegate.m
//  InsgramDownLoader
//
//  Created by mac on 2019/10/12.
//  Copyright © 2019 leke. All rights reserved.
//

#import "AppDelegate.h"
#import "WKDownLoadManager.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    (void)[WKDownLoadManager share];
    return YES;
}

// 后台所有任务下载完成
- (void)application:(UIApplication *)application handleEventsForBackgroundURLSession:(NSString *)identifier completionHandler:(void (^)(void))completionHandler {
    if ([identifier isEqualToString:[WKDownLoadManager share].session.configuration.identifier]) {
        [WKDownLoadManager share].completionHandler = completionHandler;
    }
}


@end
