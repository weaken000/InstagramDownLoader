
//
//  VideoReCoderTool.m
//  InsgramDownLoader
//
//  Created by mac on 2019/10/29.
//  Copyright © 2019 leke. All rights reserved.
//

#import "VideoReCoderTool.h"
#import <AVFoundation/AVFoundation.h>
#import <Accelerate/Accelerate.h>

@interface VideoReCoderTool()

@property (nonatomic, strong) dispatch_queue_t mainSerializationQueue;
@property (nonatomic, strong) dispatch_queue_t rwAudioSerializationQueue;
@property (nonatomic, strong) dispatch_queue_t rwVideoSerializationQueue;
@property (nonatomic, strong) dispatch_group_t dispatchGroup;

@property (nonatomic, strong) AVAsset *asset;
@property (nonatomic, strong) AVAssetReader *assetReader;
@property (nonatomic, strong) AVAssetWriter *assetWriter;
@property (nonatomic, strong) AVAssetReaderTrackOutput *assetReaderAudioOutput;
@property (nonatomic, strong) AVAssetReaderTrackOutput *assetReaderVideoOutput;
@property (nonatomic, strong) AVAssetWriterInput *assetWriterAudioInput;
@property (nonatomic, strong) AVAssetWriterInput *assetWriterVideoInput;


@property (nonatomic, assign) BOOL audioFinished;
@property (nonatomic, assign) BOOL videoFinished;
@property (nonatomic, strong) NSURL *outputURL;

@property (nonatomic,   copy) void (^ completed)(BOOL success, NSURL *_Nullable path);
 
@end

@implementation VideoReCoderTool {
//    CGFloat _videoH;
//    CGFloat _videoW;
}


+ (instancetype)startWithURL:(NSURL *)url complete:(void (^)(BOOL, NSURL * _Nullable))complete {
    VideoReCoderTool *tool = [[VideoReCoderTool alloc] init];
    
    NSString *cache=[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
    NSString *dir = [cache stringByAppendingPathComponent:@"com.cache.lk"];
    NSString *outPath = [dir stringByAppendingPathComponent:[[[url pathComponents].lastObject componentsSeparatedByString:@"."].firstObject stringByAppendingFormat:@"_recode.mp4"]];
    tool.outputURL = [NSURL fileURLWithPath:outPath];
    tool.asset = [AVAsset assetWithURL:url];
    tool.completed = [complete copy];
    [tool setupQueue];
    [tool readTracks];
    return tool;
}


- (void)setupQueue {
    NSString *serializationQueueDescription = [NSString stringWithFormat:@"%@ serialization queue", self];
    // Create the main serialization queue.
    self.mainSerializationQueue = dispatch_queue_create([serializationQueueDescription UTF8String], NULL);
    
    NSString *rwAudioSerializationQueueDescription = [NSString stringWithFormat:@"%@ rw audio serialization queue", self];
    // Create the serialization queue to use for reading and writing the audio data.
    self.rwAudioSerializationQueue = dispatch_queue_create([rwAudioSerializationQueueDescription UTF8String], NULL);
    
    NSString *rwVideoSerializationQueueDescription = [NSString stringWithFormat:@"%@ rw video serialization queue", self];
    // Create the serialization queue to use for reading and writing the video data.
    self.rwVideoSerializationQueue = dispatch_queue_create([rwVideoSerializationQueueDescription UTF8String], NULL);
}

- (void)readTracks {
    [self.asset loadValuesAsynchronouslyForKeys:@[@"tracks"] completionHandler:^{
         dispatch_async(self.mainSerializationQueue, ^{
             BOOL success = YES;
             NSError *localError = nil;
             success = ([self.asset statusOfValueForKey:@"tracks" error:&localError] == AVKeyValueStatusLoaded);
             if (success) {
                  NSFileManager *fm = [NSFileManager defaultManager];
                  NSString *localOutputPath = [self.outputURL path];
                  if ([fm fileExistsAtPath:localOutputPath])
                       success = [fm removeItemAtPath:localOutputPath error:&localError];
             }
             if (!success) {
                 self.completed(NO, nil);
                 return;
             }
             success = [self setupAssetReaderAndAssetWriter:&localError];
             if (!success) {
                 self.completed(NO, nil);
                 return;
             }
             success = [self startAssetReaderAndWriter:&localError];
             if (!success) {
                 self.completed(NO, nil);
                 return;
             }
         });
    }];
}

- (BOOL)setupAssetReaderAndAssetWriter:(NSError **)outError {
    self.assetReader = [[AVAssetReader alloc] initWithAsset:self.asset error:outError];
    BOOL success = (self.assetReader != nil);
    if (success) {
        self.assetWriter = [[AVAssetWriter alloc] initWithURL:self.outputURL fileType:AVFileTypeMPEG4 error:outError];
        success = (self.assetWriter != nil);
    }

    if (success) {
        AVAssetTrack *assetAudioTrack = nil, *assetVideoTrack = nil;
        NSArray *audioTracks = [self.asset tracksWithMediaType:AVMediaTypeAudio];
        if ([audioTracks count] > 0)
            assetAudioTrack = [audioTracks objectAtIndex:0];
        NSArray *videoTracks = [self.asset tracksWithMediaType:AVMediaTypeVideo];
        if ([videoTracks count] > 0)
            assetVideoTrack = [videoTracks objectAtIndex:0];

        if (assetAudioTrack) {
            NSDictionary *decompressionAudioSettings = @{ AVFormatIDKey : [NSNumber numberWithUnsignedInt:kAudioFormatLinearPCM] };
            self.assetReaderAudioOutput = [AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack:assetAudioTrack outputSettings:decompressionAudioSettings];
            [self.assetReader addOutput:self.assetReaderAudioOutput];
            AudioChannelLayout stereoChannelLayout = {
                .mChannelLayoutTag = kAudioChannelLayoutTag_Stereo,
                .mChannelBitmap = 0,
                .mNumberChannelDescriptions = 0
            };
            NSData *channelLayoutAsData = [NSData dataWithBytes:&stereoChannelLayout length:offsetof(AudioChannelLayout, mChannelDescriptions)];
            NSDictionary *compressionAudioSettings = @{
                AVFormatIDKey         : [NSNumber numberWithUnsignedInt:kAudioFormatMPEG4AAC],
                AVEncoderBitRateKey   : [NSNumber numberWithInteger:128000],
                AVSampleRateKey       : [NSNumber numberWithInteger:44100],
                AVChannelLayoutKey    : channelLayoutAsData,
                AVNumberOfChannelsKey : [NSNumber numberWithUnsignedInteger:2]
            };
            self.assetWriterAudioInput = [AVAssetWriterInput assetWriterInputWithMediaType:[assetAudioTrack mediaType] outputSettings:compressionAudioSettings];
            [self.assetWriter addInput:self.assetWriterAudioInput];
        }

        if (assetVideoTrack) {
            NSDictionary *decompressionVideoSettings = @{
                (id)kCVPixelBufferPixelFormatTypeKey : [NSNumber numberWithUnsignedInt:kCVPixelFormatType_422YpCbCr8],
                (id)kCVPixelBufferIOSurfacePropertiesKey : [NSDictionary dictionary]
            };
            
            self.assetReaderVideoOutput = [AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack:assetVideoTrack outputSettings:decompressionVideoSettings];
            [self.assetReader addOutput:self.assetReaderVideoOutput];
            
            CMFormatDescriptionRef formatDescription = NULL;
            NSArray *videoFormatDescriptions = [assetVideoTrack formatDescriptions];
            if ([videoFormatDescriptions count] > 0) {
                formatDescription = (__bridge CMFormatDescriptionRef)[videoFormatDescriptions objectAtIndex:0];
            }
            CGSize trackDimensions = {
                .width = 0.0,
                .height = 0.0,
            };
            if (formatDescription) {
                trackDimensions = CMVideoFormatDescriptionGetPresentationDimensions(formatDescription, false, false);
            } else {
                trackDimensions = [assetVideoTrack naturalSize];
            }
//            _videoW = trackDimensions.width;
//            _videoH = trackDimensions.height;
//
            NSDictionary *compressionSettings = nil;
            if (formatDescription) {
                NSDictionary *cleanAperture = nil;
                NSDictionary *pixelAspectRatio = nil;
                CFDictionaryRef cleanApertureFromCMFormatDescription = CMFormatDescriptionGetExtension(formatDescription, kCMFormatDescriptionExtension_CleanAperture);
                if (cleanApertureFromCMFormatDescription) {
                    cleanAperture = @{
                        AVVideoCleanApertureWidthKey            : (id)CFDictionaryGetValue(cleanApertureFromCMFormatDescription, kCMFormatDescriptionKey_CleanApertureWidth),
                        AVVideoCleanApertureHeightKey           : (id)CFDictionaryGetValue(cleanApertureFromCMFormatDescription, kCMFormatDescriptionKey_CleanApertureHeight),
                        AVVideoCleanApertureHorizontalOffsetKey : (id)CFDictionaryGetValue(cleanApertureFromCMFormatDescription, kCMFormatDescriptionKey_CleanApertureHorizontalOffset),
                        AVVideoCleanApertureVerticalOffsetKey   : (id)CFDictionaryGetValue(cleanApertureFromCMFormatDescription, kCMFormatDescriptionKey_CleanApertureVerticalOffset)
                    };
                }
                CFDictionaryRef pixelAspectRatioFromCMFormatDescription = CMFormatDescriptionGetExtension(formatDescription, kCMFormatDescriptionExtension_PixelAspectRatio);
                if (pixelAspectRatioFromCMFormatDescription) {
                    pixelAspectRatio = @{
                        AVVideoPixelAspectRatioHorizontalSpacingKey : (id)CFDictionaryGetValue(pixelAspectRatioFromCMFormatDescription, kCMFormatDescriptionKey_PixelAspectRatioHorizontalSpacing),
                        AVVideoPixelAspectRatioVerticalSpacingKey   : (id)CFDictionaryGetValue(pixelAspectRatioFromCMFormatDescription, kCMFormatDescriptionKey_PixelAspectRatioVerticalSpacing)
                    };
                }
                if (cleanAperture || pixelAspectRatio) {
                    NSMutableDictionary *mutableCompressionSettings = [NSMutableDictionary dictionary];
                    if (cleanAperture)
                        [mutableCompressionSettings setObject:cleanAperture forKey:AVVideoCleanApertureKey];
                    if (pixelAspectRatio)
                        [mutableCompressionSettings setObject:pixelAspectRatio forKey:AVVideoPixelAspectRatioKey];
                    
                    //压缩前原视频比特率
                    NSInteger kbps = assetVideoTrack.estimatedDataRate / 1024;
                    if (kbps == 1500) {
                        kbps = 1600;
                    } else {
                        kbps += 100;
                    }
                    //压缩前原视频帧率
                    NSInteger frameRate = [assetVideoTrack nominalFrameRate];
                    
                    [mutableCompressionSettings setObject:@(1500 * 1024) forKey:AVVideoAverageBitRateKey];//码率
                    [mutableCompressionSettings setObject:@(frameRate+5) forKey:AVVideoExpectedSourceFrameRateKey];//帧率
                    [mutableCompressionSettings setObject:AVVideoProfileLevelH264MainAutoLevel forKey:AVVideoProfileLevelKey];//画质水平
                    
                    compressionSettings = mutableCompressionSettings;
                }
            }
            NSMutableDictionary *videoSettings = @{
                AVVideoCodecKey  : AVVideoCodecH264,
                AVVideoWidthKey  : [NSNumber numberWithDouble:trackDimensions.width],
                AVVideoHeightKey : [NSNumber numberWithDouble:trackDimensions.height],
            }.mutableCopy;
            if (compressionSettings)
                [videoSettings setObject:compressionSettings forKey:AVVideoCompressionPropertiesKey];
            self.assetWriterVideoInput = [AVAssetWriterInput assetWriterInputWithMediaType:[assetVideoTrack mediaType] outputSettings:videoSettings];
            [self.assetWriter addInput:self.assetWriterVideoInput];
        }
    }
    return success;
}

- (BOOL)startAssetReaderAndWriter:(NSError **)outError {
     BOOL success = YES;
     success = [self.assetReader startReading];
     if (!success)
          *outError = [self.assetReader error];
     if (success)
     {
          success = [self.assetWriter startWriting];
          if (!success)
               *outError = [self.assetWriter error];
     }

     if (success)
     {
          self.dispatchGroup = dispatch_group_create();
          [self.assetWriter startSessionAtSourceTime:kCMTimeZero];
          self.audioFinished = NO;
          self.videoFinished = NO;

          if (self.assetWriterAudioInput)
          {
               dispatch_group_enter(self.dispatchGroup);
               [self.assetWriterAudioInput requestMediaDataWhenReadyOnQueue:self.rwAudioSerializationQueue usingBlock:^{
                    if (self.audioFinished)
                         return;
                    BOOL completedOrFailed = NO;
                    while ([self.assetWriterAudioInput isReadyForMoreMediaData] && !completedOrFailed) {
                         CMSampleBufferRef sampleBuffer = [self.assetReaderAudioOutput copyNextSampleBuffer];
                         if (sampleBuffer != NULL)
                         {
                              BOOL success = [self.assetWriterAudioInput appendSampleBuffer:sampleBuffer];
                              CFRelease(sampleBuffer);
                              sampleBuffer = NULL;
                              completedOrFailed = !success;
                         }
                         else
                         {
                              completedOrFailed = YES;
                         }
                    }
                    if (completedOrFailed) {
                         BOOL oldFinished = self.audioFinished;
                         self.audioFinished = YES;
                         if (oldFinished == NO)
                         {
                              [self.assetWriterAudioInput markAsFinished];
                         }
                         dispatch_group_leave(self.dispatchGroup);
                    }
               }];
          }

          if (self.assetWriterVideoInput)
          {
               dispatch_group_enter(self.dispatchGroup);
               [self.assetWriterVideoInput requestMediaDataWhenReadyOnQueue:self.rwVideoSerializationQueue usingBlock:^{
                    if (self.videoFinished)
                         return;
                    BOOL completedOrFailed = NO;
                    while ([self.assetWriterVideoInput isReadyForMoreMediaData] && !completedOrFailed)
                    {
                         CMSampleBufferRef sampleBuffer = [self.assetReaderVideoOutput copyNextSampleBuffer];
                         if (sampleBuffer != NULL)
                         {
                              BOOL success = [self.assetWriterVideoInput appendSampleBuffer:sampleBuffer];
                              CFRelease(sampleBuffer);
                              sampleBuffer = NULL;
                              completedOrFailed = !success;
                         }
                         else
                         {
                              completedOrFailed = YES;
                         }
                    }
                    if (completedOrFailed)
                    {
                         BOOL oldFinished = self.videoFinished;
                         self.videoFinished = YES;
                         if (oldFinished == NO)
                         {
                              [self.assetWriterVideoInput markAsFinished];
                         }
                         dispatch_group_leave(self.dispatchGroup);
                    }
               }];
          }
         
         
          dispatch_group_notify(self.dispatchGroup, self.mainSerializationQueue, ^{
              BOOL finalSuccess = YES;
              NSError *finalError = nil;
              
              if ([self.assetReader status] == AVAssetReaderStatusFailed) {
                   finalSuccess = NO;
                   finalError = [self.assetReader error];
              }
              if (finalSuccess) {
                   finalSuccess = [self.assetWriter finishWriting];
                   if (!finalSuccess)
                        finalError = [self.assetWriter error];
              }
              [self readingAndWritingDidFinishSuccessfully:finalSuccess withError:finalError];
          });
     }
     
     return success;
}

- (void)readingAndWritingDidFinishSuccessfully:(BOOL)success withError:(NSError *)error {
     if (!success)
     {
          [self.assetReader cancelReading];
          [self.assetWriter cancelWriting];
          dispatch_async(dispatch_get_main_queue(), ^{
              self.completed(NO, nil);
          });
     }
     else
     {
          self.videoFinished = NO;
          self.audioFinished = NO;
          dispatch_async(dispatch_get_main_queue(), ^{
               self.completed(YES, self.outputURL);
          });
     }
}

//- (void)cancel {
//     // Handle cancellation asynchronously, but serialize it with the main queue.
//     dispatch_async(self.mainSerializationQueue, ^{
//          // If we had audio data to reencode, we need to cancel the audio work.
//          if (self.assetWriterAudioInput)
//          {
//               // Handle cancellation asynchronously again, but this time serialize it with the audio queue.
//               dispatch_async(self.rwAudioSerializationQueue, ^{
//                    // Update the Boolean property indicating the task is complete and mark the input as finished if it hasn't already been marked as such.
//                    BOOL oldFinished = self.audioFinished;
//                    self.audioFinished = YES;
//                    if (oldFinished == NO)
//                    {
//                         [self.assetWriterAudioInput markAsFinished];
//                    }
//                    // Leave the dispatch group since the audio work is finished now.
//                    dispatch_group_leave(self.dispatchGroup);
//               });
//          }
//
//          if (self.assetWriterVideoInput)
//          {
//               // Handle cancellation asynchronously again, but this time serialize it with the video queue.
//               dispatch_async(self.rwVideoSerializationQueue, ^{
//                    // Update the Boolean property indicating the task is complete and mark the input as finished if it hasn't already been marked as such.
//                    BOOL oldFinished = self.videoFinished;
//                    self.videoFinished = YES;
//                    if (oldFinished == NO)
//                    {
//                         [self.assetWriterVideoInput markAsFinished];
//                    }
//                    // Leave the dispatch group, since the video work is finished now.
//                    dispatch_group_leave(self.dispatchGroup);
//               });
//          }
//          // Set the cancelled Boolean property to YES to cancel any work on the main queue as well.
//          self.cancelled = YES;
//     });
//}

//- (void)frameBuffer:(CMSampleBufferRef)sampleBuffer {
//    CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
//    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
//    CFAbsoluteTime elapsedTime, startTime = CFAbsoluteTimeGetCurrent();
//    unsigned char *data = (unsigned char *)CVPixelBufferGetBaseAddress(pixelBuffer);
//    size_t bufferHeight = CVPixelBufferGetHeight(pixelBuffer);
//    size_t bufferWidth = CVPixelBufferGetWidth(pixelBuffer);
//    NSInteger myDataLength = bufferWidth * bufferHeight * 4;
//    for (int i = 0; i < myDataLength; i+=4)
//    {
//            UInt8 r_pixel = data[i];
//            UInt8 g_pixel = data[i+1];
//            UInt8 b_pixel = data[i+2];
//            //Gray = R*0.299 + G*0.587 + B*0.114
//            int outputRed = (r_pixel * 0.299) + (g_pixel *0.587) + (b_pixel * 0.114);
//            int outputGreen = (r_pixel * 0.299) + (g_pixel *0.587) + (b_pixel * 0.114);
//            int outputBlue = (r_pixel * 0.299) + (g_pixel *0.587) + (b_pixel * 0.114);
//            if(outputRed>255)outputRed=255;
//            if(outputGreen>255)outputGreen=255;
//            if(outputBlue>255)outputBlue=255;
//            data[i] = outputRed;
//            data[i+1] = outputGreen;
//            data[i+2] = outputBlue;
//    }
//
//    elapsedTime = CFAbsoluteTimeGetCurrent() - startTime;
//    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
//}

//- (void)sizeFitBuffer:(CMSampleBufferRef)sampleBuffer {
//
//    int outWidth, outHeight;
//
//    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
//    CVPixelBufferLockBaseAddress(imageBuffer, 0);
//    void * baseAddress = CVPixelBufferGetBaseAddress(imageBuffer);
//    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
//
//
//    vImage_Buffer inBuff;
//    inBuff.height = _videoH;
//    inBuff.width = _videoW;
//    inBuff.rowBytes = bytesPerRow;
//
////    int startpos = cropY0 * bytesPerRow + 4 * cropX0;
//    int startpos = _videoH / 2 * bytesPerRow;
//    inBuff.data = baseAddress + startpos;
//
//    outWidth = _videoW;
//    outHeight = _videoH / 2;
//    unsigned char *outImg = (unsigned char *)malloc(4 * outWidth * outHeight);
//    vImage_Buffer outBuff = {outImg, outHeight, outWidth, 4 * outWidth};
//
//    vImage_Error err = vImageScale_ARGB8888(&inBuff, &outBuff, NULL, 0);
//    if (err != kvImageNoError) {
//        NSLog(@"发生了错误");
//    }
////    if (err != kvImageNoError) {
////
////    } else {
////        return sampleBuffer;
////    }
//}


@end
