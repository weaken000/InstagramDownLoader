//
//  YoutubeFormatCell.h
//  InsgramDownLoader
//
//  Created by mac on 2019/11/5.
//  Copyright © 2019 leke. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WKDownLoadTask.h"

NS_ASSUME_NONNULL_BEGIN

@class YoutubeFormatCell;
@protocol YoutubeFormatCellDelegate <NSObject>

- (void)formatCellDidClickDownload:(YoutubeFormatCell *)cell;

@end

@interface YoutubeFormatCell : UITableViewCell

@property (nonatomic, weak) id<YoutubeFormatCellDelegate> delegate;

- (void)configTask:(WKDownLoadTask *)task;

@end

NS_ASSUME_NONNULL_END
