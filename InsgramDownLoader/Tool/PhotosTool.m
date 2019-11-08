//
//  PhotosTool.m
//  InsgramDownLoader
//
//  Created by mac on 2019/10/30.
//  Copyright © 2019 leke. All rights reserved.
//

#import "PhotosTool.h"

@implementation PhotosTool {
    PHAssetCollection *_videoAsset;
    PHAssetCollection *_photoAsset;
    PHAssetCollection *_youtubeAsset;
}

+ (instancetype)share {
    static PhotosTool *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[PhotosTool alloc] init];
    });
    return instance;
}

- (instancetype)init {
    if (self == [super init]) {
        [self createAsset];
    }
    return self;
}

- (void)createAsset {
    
    NSString *videoName   = @"ins video";
    NSString *photoName   = @"ins photo";
    NSString *youtubeName = @"Youtube video";

    //2 获取与 APP 同名的自定义相册
    PHFetchResult<PHAssetCollection *> *collections = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeAlbumRegular options:nil];
    for (PHAssetCollection *collection in collections) {
        if ([collection.localizedTitle isEqualToString:videoName]) {
            _videoAsset = collection;
        }
        if ([collection.localizedTitle isEqualToString:photoName]) {
            _photoAsset = collection;
        }
        if ([collection.localizedTitle isEqualToString:youtubeName]) {
            _youtubeAsset = collection;
        }
    }
    
    if (_videoAsset && _photoAsset && _youtubeAsset) {
        return;
    }

    //说明没有找到，需要创建
    NSError *error = nil;
    __block NSString *videoID = nil; //用来获取创建好的相册
    __block NSString *photoID = nil; //用来获取创建好的相册
    __block NSString *youtubeID = nil; //用来获取创建好的相册

    [[PHPhotoLibrary sharedPhotoLibrary] performChangesAndWait:^{
        //发起了创建新相册的请求，并拿到ID，当前并没有创建成功，待创建成功后，通过 ID 来获取创建好的自定义相册
        if (!self->_photoAsset) {
            PHAssetCollectionChangeRequest *photoRequest = [PHAssetCollectionChangeRequest creationRequestForAssetCollectionWithTitle:photoName];
            photoID = photoRequest.placeholderForCreatedAssetCollection.localIdentifier;
        }
        if (!self->_videoAsset) {
            PHAssetCollectionChangeRequest *videoRequest = [PHAssetCollectionChangeRequest creationRequestForAssetCollectionWithTitle:videoName];
            videoID = videoRequest.placeholderForCreatedAssetCollection.localIdentifier;
        }
        if (!self->_youtubeAsset) {
            PHAssetCollectionChangeRequest *youtubeRequest = [PHAssetCollectionChangeRequest creationRequestForAssetCollectionWithTitle:youtubeName];
            youtubeID = youtubeRequest.placeholderForCreatedAssetCollection.localIdentifier;
        }
    } error:&error];
    
    if (!error) {
        if (videoID) {
            _videoAsset = [PHAssetCollection fetchAssetCollectionsWithLocalIdentifiers:@[videoID] options:nil].firstObject;
        }
        if (photoID) {
            _photoAsset = [PHAssetCollection fetchAssetCollectionsWithLocalIdentifiers:@[photoID] options:nil].firstObject;
        }
        if (youtubeID) {
            _youtubeAsset = [PHAssetCollection fetchAssetCollectionsWithLocalIdentifiers:@[youtubeID] options:nil].firstObject;
        }
    }
}

- (void)saveImage:(UIImage *)image compeled:(void (^)(NSString * _Nullable))completed {
    NSError *error;
    
    __block NSString *createdAssetID = nil;
    [[PHPhotoLibrary sharedPhotoLibrary] performChangesAndWait:^{
        createdAssetID = [PHAssetChangeRequest          creationRequestForAssetFromImage:image].placeholderForCreatedAsset.localIdentifier;
    } error:&error];

    if (error) {
        completed(@"保存失败");
        return;
    }
    
    PHFetchResult<PHAsset *> *assets = [PHAsset fetchAssetsWithLocalIdentifiers:@[createdAssetID] options:nil];
    [[PHPhotoLibrary sharedPhotoLibrary] performChangesAndWait:^{
        PHAssetCollectionChangeRequest *collectionChangeRequest = [PHAssetCollectionChangeRequest changeRequestForAssetCollection:self->_photoAsset];
        [collectionChangeRequest insertAssets:assets atIndexes:[NSIndexSet indexSetWithIndex:0]];
    } error:&error];
    completed(nil);
}

- (void)saveVideo:(NSURL *)videoFile compeled:(void (^)(NSString * _Nullable))completed {
    NSError *error;
    
    __block NSString *createdAssetID = nil;
    [[PHPhotoLibrary sharedPhotoLibrary] performChangesAndWait:^{
        createdAssetID = [PHAssetChangeRequest          creationRequestForAssetFromVideoAtFileURL:videoFile].placeholderForCreatedAsset.localIdentifier;
    } error:&error];

    if (error) {
        completed(@"保存失败");
        return;
    }
    
    PHFetchResult<PHAsset *> *assets = [PHAsset fetchAssetsWithLocalIdentifiers:@[createdAssetID] options:nil];
    [[PHPhotoLibrary sharedPhotoLibrary] performChangesAndWait:^{
        PHAssetCollectionChangeRequest *collectionChangeRequest = [PHAssetCollectionChangeRequest changeRequestForAssetCollection:self->_videoAsset];
        [collectionChangeRequest insertAssets:assets atIndexes:[NSIndexSet indexSetWithIndex:0]];
    } error:&error];
    completed(nil);
}

- (void)saveYoutube:(NSURL *)youtube compeled:(void (^)(NSString * _Nullable))completed {
    NSError *error;
    
    __block NSString *createdAssetID = nil;
    [[PHPhotoLibrary sharedPhotoLibrary] performChangesAndWait:^{
        createdAssetID = [PHAssetChangeRequest          creationRequestForAssetFromVideoAtFileURL:youtube].placeholderForCreatedAsset.localIdentifier;
    } error:&error];

    if (error) {
        completed(@"保存失败");
        return;
    }
    
    PHFetchResult<PHAsset *> *assets = [PHAsset fetchAssetsWithLocalIdentifiers:@[createdAssetID] options:nil];
    [[PHPhotoLibrary sharedPhotoLibrary] performChangesAndWait:^{
        PHAssetCollectionChangeRequest *collectionChangeRequest = [PHAssetCollectionChangeRequest changeRequestForAssetCollection:self->_youtubeAsset];
        [collectionChangeRequest insertAssets:assets atIndexes:[NSIndexSet indexSetWithIndex:0]];
    } error:&error];
    completed(nil);
}

@end
