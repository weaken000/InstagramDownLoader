//
//  MissionCell.h
//  InsgramDownLoader
//
//  Created by mac on 2019/10/12.
//  Copyright © 2019 leke. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WKDownLoadTask.h"

NS_ASSUME_NONNULL_BEGIN
@class MissionCell;

@protocol MissionCellDelegate <NSObject>

@optional
- (void)missionCellDidClickCancel:(MissionCell *)cell;
- (void)missionCellDidClickAction:(MissionCell *)cell;

@end

@interface MissionCell : UITableViewCell

@property (nonatomic, weak) id<MissionCellDelegate> delegate;

- (void)configTask:(WKDownLoadTask *)task;

@end

NS_ASSUME_NONNULL_END
