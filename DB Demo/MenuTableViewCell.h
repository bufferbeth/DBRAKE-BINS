//
//  MenuTableViewCell.h
//  DB Demo
//
//  Created by John Hewlin on 12/15/20.
//  Copyright © 2020 MiLife Solution. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface MenuTableViewCell : UITableViewCell

@property (nonatomic, retain) IBOutlet UIImageView *menuItemImageView;
@property (nonatomic, retain) IBOutlet UILabel *menuItemLabel;

@end

NS_ASSUME_NONNULL_END
