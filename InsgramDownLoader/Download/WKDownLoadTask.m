//
//  WKDownLoadTask.m
//  InsgramDownLoader
//
//  Created by mac on 2019/11/7.
//  Copyright © 2019 leke. All rights reserved.
//

#import "WKDownLoadTask.h"
#import <CommonCrypto/CommonDigest.h>
#import "WKDownLoadManager.h"

@interface WKDownLoadTask()

@end

@implementation WKDownLoadTask

- (void)clear {
    if (_filePath && [[NSFileManager defaultManager] fileExistsAtPath:_filePath]) {
        [[NSFileManager defaultManager] removeItemAtPath:_filePath error:nil];
    }
    if (_task && _task.state != NSURLSessionTaskStateCanceling) {
        [_task cancel];
    }
    _task = nil;
    
    [[NSFileManager defaultManager] removeItemAtPath:[WK_TASK_PATH stringByAppendingPathComponent:[WKDownLoadTask md5:self.url]] error:nil];
}

- (void)save {
    BOOL success = [NSKeyedArchiver archiveRootObject:self toFile:[WK_TASK_PATH stringByAppendingPathComponent:[WKDownLoadTask md5:self.url]]];
    NSLog(@"task保存本地结果：%d %@", success, self.url);
}

- (void)setProgress:(double)progress {
    _progress = progress;
    if (self.update) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.update(self);
        });
    }
}

- (void)setStatus:(WKTaskStatus)status {
    _status = status;
    if (self.update) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.update(self);
        });
    }
    dispatch_async(dispatch_get_global_queue(0, DISPATCH_QUEUE_PRIORITY_DEFAULT), ^{
        [self save];
    });
}

#pragma mark - NSCoding
- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeInteger:_status forKey:@"status"];
    [coder encodeInteger:_mediaType forKey:@"mediaType"];
    [coder encodeObject:_url forKey:@"url"];
    [coder encodeObject:_desc forKey:@"desc"];
    [coder encodeDouble:_progress forKey:@"progress"];
    [coder encodeObject:_filePath forKey:@"filePath"];
    [coder encodeObject:_resumeData forKey:@"resumeData"];
    [coder encodeObject:_error forKey:@"error"];
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    if (self == [super init]) {
        _status = [coder decodeIntegerForKey:@"status"];
        _mediaType = [coder decodeIntegerForKey:@"mediaType"];
        _progress = [coder decodeDoubleForKey:@"progress"];
        _url = [coder decodeObjectForKey:@"url"];
        _desc = [coder decodeObjectForKey:@"desc"];
        _filePath = [coder decodeObjectForKey:@"filePath"];
        _error = [coder decodeObjectForKey:@"error"];
        _resumeData = [coder decodeObjectForKey:@"resumeData"];
    }
    return self;
}

+ (NSString *)md5:(NSString *)string {
    const char *cStr = [string UTF8String];
    unsigned char digest[CC_MD5_DIGEST_LENGTH];
    CC_MD5(cStr, (CC_LONG)strlen(cStr), digest);
    NSMutableString *result = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for (int i = 0; i < CC_MD5_DIGEST_LENGTH; i++) {
        [result appendFormat:@"%02X", digest[i]];
    }
    return result;
}

@end
