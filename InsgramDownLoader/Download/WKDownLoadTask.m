//
//  WKDownLoadTask.m
//  InsgramDownLoader
//
//  Created by mac on 2019/11/7.
//  Copyright © 2019 leke. All rights reserved.
//

#import "WKDownLoadTask.h"

@implementation WKDownLoadTask

- (void)clear {
    if (_filePath && [[NSFileManager defaultManager] fileExistsAtPath:_filePath]) {
        [[NSFileManager defaultManager] removeItemAtPath:_filePath error:nil];
    }
    if (_task && _task.state != NSURLSessionTaskStateCanceling) {
        [_task cancel];
    }
    _task = nil;
}

- (void)setProgress:(double)progress {
    _progress = progress;
    if (self.update) {
        self.update(self);
    }
}

- (void)setStatus:(WKTaskStatus)status {
    _status = status;
    if (self.update) {
        self.update(self);
    }
}

@end
