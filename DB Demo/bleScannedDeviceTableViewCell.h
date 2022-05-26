//
//  bleScannedDeviceTableViewCell.h
//  DB Demo
//
//  Created by John Hewlin on 3/8/17.
//  Copyright © 2017 MiLife Solution. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface bleScannedDeviceTableViewCell : UITableViewCell

@property (nonatomic, retain) IBOutlet UILabel *bleNameLabel;
@property (nonatomic, retain) IBOutlet UILabel *bleIdLabel;
@property (nonatomic, retain) IBOutlet UILabel *bleRSSILabel;
@property (nonatomic, retain) IBOutlet UIButton *connectButton;
@end
