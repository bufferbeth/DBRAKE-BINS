//
//  DetailViewController.h
//  DB Demo
//
//  Created by John Hewlin on 3/9/17.
//  Copyright © 2017 MiLife Solution. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BLEManager.h"

@interface DetailViewController : UIViewController

@property (nonatomic, retain) BLEPeripheral *blePeripheral;
@end
