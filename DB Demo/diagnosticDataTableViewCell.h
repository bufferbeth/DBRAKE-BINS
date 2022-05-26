//
//  diagnosticDataTableViewCell.h
//  DB Demo
//
//  Created by John Hewlin on 11/9/20.
//  Copyright © 2020 MiLife Solution. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface DiagnosticDataTableViewCell : UITableViewCell

@property (nonatomic, retain) IBOutlet UILabel *timeStampLabel;
@property (nonatomic, retain) IBOutlet UILabel *diagnosticDataLabel;

@end

NS_ASSUME_NONNULL_END
