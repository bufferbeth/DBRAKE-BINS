//
//  MenuViewController.m
//  DB Demo
//
//  Created by John Hewlin on 12/15/20.
//  Copyright © 2020 MiLife Solution. All rights reserved.
//

#import "MenuViewController.h"
#import "MenuTableViewCell.h"
#import <sys/utsname.h>
#import "ControlViewController.h"
#import "SettingsViewController.h"
#import "AddADeviceViewController.h"

@interface MenuViewController ()

@property (nonatomic, retain) IBOutlet UITableView *menuTable;
@property (nonatomic, retain) IBOutlet UIImageView *menuImageView;
@property (nonatomic, retain) IBOutlet UIView *bottomMenuView;
@property (nonatomic, retain) IBOutlet UIImageView *bottomMenuImageView;

@end

@implementation MenuViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.menuImageView.layer.cornerRadius = 5;
    self.bottomMenuView.layer.cornerRadius = 5;
    self.bottomMenuImageView.layer.cornerRadius = 5;
    [self initialSetUpForBottomMenu];
}


-(void)initialSetUpForBottomMenu {
 
    NSString* model = [[UIDevice currentDevice] model];
    
    NSLog (@"%@", model);
    
    struct utsname systemInfo;
    uname(&systemInfo);

    NSString* deviceModel = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
    
    NSLog (@"%@", deviceModel   );
    
    if ([deviceModel containsString:@"10,3"] || [deviceModel containsString:@"10,6"] || [deviceModel containsString:@"11"] || [deviceModel containsString:@"12"] || [deviceModel containsString:@"13"] )  {

        CGRect menuImageViewframe = self.menuImageView.frame;
        menuImageViewframe.origin.y +=20;
        self.menuImageView.frame = menuImageViewframe;
        
        CGRect menuTableFrame = self.menuTable.frame;
        menuTableFrame.origin.y = menuImageViewframe.origin.y + menuImageViewframe.size.height -10;
        self.menuTable.frame = menuTableFrame;
        
        CGRect screenFrame = self.view.frame;
        CGRect bottomMenuImageViewFrame = self.bottomMenuView.frame;
        bottomMenuImageViewFrame.origin.y = screenFrame.size.height - bottomMenuImageViewFrame.size.height - 100;
        self.bottomMenuView.frame = bottomMenuImageViewFrame;
    }
    else {
//        self.bottomMenuMoveUp = FALSE;
    }


}



#pragma mark - Table view data source

/**
 *************************************
 */
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}


/**
 *************************************
 */
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 4;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    // NSLog(@"Section: %ld    Row: %ld", (long)indexPath.section, (long)indexPath.row);
    MenuTableViewCell *menuItemCell = [tableView dequeueReusableCellWithIdentifier:@"menuItemCell" forIndexPath:indexPath];
    
    switch (indexPath.row) {
        case 0:
            //menuItemCell.menuItemLabel.text = @"MY DEVICES";
            menuItemCell.menuItemImageView.image= [UIImage imageNamed:@"MyDevices"];
            break;
        case 1:
            //menuItemCell.menuItemLabel.text = @"ADD A DEVICE";
            menuItemCell.menuItemImageView.image = [UIImage imageNamed:@"AddADevice"];
            break;
        case 2:
            //menuItemCell.menuItemLabel.text = @"SOFTWARE UPDATE";
            menuItemCell.menuItemImageView.image = [UIImage imageNamed:@"SoftwareUpdate"];
            break;
        case 3:
            //menuItemCell.menuItemLabel.text = @"SUPPORT";
            menuItemCell.menuItemImageView.image = [UIImage imageNamed:@"Support"];
            break;

        default:
            break;
    }
    menuItemCell.menuItemImageView.layer.cornerRadius = 5;
    return menuItemCell;
    
}

/**
 *************************************
 */
-(void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    AddADeviceViewController *addADeviceVC = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"AddADeviceViewController"];
    //detailVC.blePeripheral = [[BLEManager sharedService].peripheralsArray objectAtIndex:indexPath.row];
    [tableView deselectRowAtIndexPath:indexPath animated:TRUE];
    [self.navigationController pushViewController:addADeviceVC animated:TRUE];

}


/*
#pragma mark - Navigation
*/
// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    if ([segue.identifier isEqualToString:@"ControlHomeView"]) {
        ControlViewController *deviceControlViewController = segue.destinationViewController;
        deviceControlViewController.transitionFromMenuScreen = TRUE;
    }
    else if ([segue.identifier isEqualToString:@"SettingsView"]) {
        SettingsViewController *settingsViewController = segue.destinationViewController;
        settingsViewController.transitionFromMenuScreen = TRUE;
    }

}


@end
