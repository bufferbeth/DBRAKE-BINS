//
//  DiagnosticViewController.h
//  DB Demo
//
//  Created by John Hewlin on 11/9/20.
//  Copyright © 2020 MiLife Solution. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BLEManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface DiagnosticViewController : UIViewController

@property (nonatomic, retain) BLEPeripheral *blePeripheral;

@end

NS_ASSUME_NONNULL_END
