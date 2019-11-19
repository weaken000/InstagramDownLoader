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

@interface MissionCell : UITableViewCell

- (void)configTask:(WKDownLoadTask *)task;

@end

NS_ASSUME_NONNULL_END
