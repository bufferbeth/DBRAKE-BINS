//
//  SettingsViewController.m
//  DB Demo
//
//  Created by John Hewlin on 12/18/20.
//  Copyright © 2020 MiLife Solution. All rights reserved.
//

#import "SettingsViewController.h"
#import "MenuTableViewCell.h"
#import <sys/utsname.h>
#import "ControlViewController.h"


@interface SettingsViewController ()

@property (nonatomic, retain) IBOutlet UITableView *settingsTable;
@property (nonatomic, retain) IBOutlet UIImageView *settingsImageView;
@property (nonatomic, retain) IBOutlet UIView *bottomMenuView;
@property (nonatomic, retain) IBOutlet UIImageView *bottomMenuImageView;

@property BOOL phoneIs6;
@property BOOL phoneIs7or8;

@end

@implementation SettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.phoneIs6 = FALSE;
    self.settingsImageView.layer.cornerRadius = 5;
    self.bottomMenuView.layer.cornerRadius = 5;
    [self initialSetUpForBottomMenu];
    self.bottomMenuImageView.layer.cornerRadius = 5;
}


-(void)initialSetUpForBottomMenu {
 
    NSString* model = [[UIDevice currentDevice] model];
    
    NSLog (@"%@", model);
    
    struct utsname systemInfo;
    uname(&systemInfo);

    NSString* deviceModel = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
    
    NSLog (@"%@", deviceModel   );
    
    if ([deviceModel containsString:@"10,3"] || [deviceModel containsString:@"10,6"] || [deviceModel containsString:@"11"] || [deviceModel containsString:@"12"] || [deviceModel containsString:@"13"] )  {

        CGRect menuImageViewframe = self.settingsImageView.frame;
        menuImageViewframe.origin.y +=20;
        self.settingsImageView.frame = menuImageViewframe;
        
        CGRect menuTableFrame = self.settingsTable.frame;
        menuTableFrame.origin.y = menuImageViewframe.origin.y + menuImageViewframe.size.height -10;
        self.settingsTable.frame = menuTableFrame;
        
        CGRect screenFrame = self.view.frame;
        CGRect bottomMenuImageViewFrame = self.bottomMenuView.frame;
        bottomMenuImageViewFrame.origin.y = screenFrame.size.height - bottomMenuImageViewFrame.size.height - 100;
        self.bottomMenuView.frame = bottomMenuImageViewFrame;
    }
    else if ([deviceModel containsString:@"7,2"] ){
        self.phoneIs6 = TRUE;
    }
    else if ([deviceModel containsString:@"10,4"] ){
        self.phoneIs7or8 = TRUE;
    }
}


#pragma mark - Table view data source

/**
 *************************************
 */

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.phoneIs6)
        return 80;
    else if (self.phoneIs7or8)
        return 80;
    else
        return 100;
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}


/**
 *************************************
 */
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 5;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    // NSLog(@"Section: %ld    Row: %ld", (long)indexPath.section, (long)indexPath.row);
    MenuTableViewCell *menuItemCell = [tableView dequeueReusableCellWithIdentifier:@"menuItemCell" forIndexPath:indexPath];
    
    switch (indexPath.row) {
        case 0:
            menuItemCell.menuItemImageView.image= [UIImage imageNamed:@"SettingsForce"];
            break;
        case 1:
            menuItemCell.menuItemImageView.image = [UIImage imageNamed:@"SettingsSensitivity"];
            break;
        case 2:
            menuItemCell.menuItemImageView.image = [UIImage imageNamed:@"SettingsMaxForce"];
            break;
        case 3:
            menuItemCell.menuItemImageView.image = [UIImage imageNamed:@"SettingsBackLight"];
            break;
        case 4:
            menuItemCell.menuItemImageView.image = [UIImage imageNamed:@"SettingsResetAll"];
            break;

        default:
            break;
    }
    menuItemCell.menuItemImageView.layer.cornerRadius = 5;
    return menuItemCell;
    
}


-(IBAction)showMenuView:(id)sender {
    [self.navigationController popToRootViewControllerAnimated:TRUE];
}

-(IBAction)showControlHomerView:(id)sender {
    if (self.transitionFromMenuScreen) {
        UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"Main" bundle: nil];

        ControlViewController *deviceControlViewController = (ControlViewController *)[mainStoryboard
                                                              instantiateViewControllerWithIdentifier: @"ControlViewController"];
        [self.navigationController pushViewController:(ControlViewController *)deviceControlViewController  animated:TRUE];
    }
    else {
        [self.navigationController popViewControllerAnimated:TRUE];
    }
}



/*
#pragma mark - Navigation
*/
// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}


@end
