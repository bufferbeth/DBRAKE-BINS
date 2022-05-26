//
//  ControlViewController.m
//  DB Demo
//
//  Created by John Hewlin on 12/18/20.
//  Copyright © 2020 MiLife Solution. All rights reserved.
//

#import "ControlViewController.h"
#import <sys/utsname.h>
#import "SettingsViewController.h"

@interface ControlViewController ()

@property (nonatomic, retain) IBOutlet UIImageView *menuImageView;
@property (nonatomic, retain) IBOutlet UIView *bottomMenuView;
@property (nonatomic, retain) IBOutlet UIImageView *breakAwayImageView;
@property (nonatomic, retain) IBOutlet UIView *forceView;
@property (nonatomic, retain) IBOutlet UIImageView *indicatorImageView;
@property (nonatomic, retain) IBOutlet UIImageView *brakeActiveImageView;
@property (nonatomic, retain) IBOutlet UIImageView *bottomMenuImageView;

@end

@implementation ControlViewController

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
    
    if ([deviceModel containsString:@"10,3"] || [deviceModel containsString:@"10,6"] || [deviceModel containsString:@"11"] || [deviceModel containsString:@"12"] || [deviceModel containsString:@"13"])  {

        CGRect menuImageViewframe = self.menuImageView.frame;
        menuImageViewframe.origin.y +=20;
        self.menuImageView.frame = menuImageViewframe;
           
        CGRect breakAwayImageViewFrame = self.breakAwayImageView.frame;
        breakAwayImageViewFrame.origin.y = menuImageViewframe.origin.y + menuImageViewframe.size.height - 10;
        self.breakAwayImageView.frame = breakAwayImageViewFrame;
        
        CGRect forceViewFrame = self.forceView.frame;
        forceViewFrame.origin.y =  breakAwayImageViewFrame.origin.y + breakAwayImageViewFrame.size.height -10;
        self.forceView.frame = forceViewFrame;
        
        CGRect indicatorImageViewFrame = self.indicatorImageView.frame;
        indicatorImageViewFrame.origin.y = forceViewFrame.origin.y + forceViewFrame.size.height;
        self.indicatorImageView.frame = indicatorImageViewFrame;
        
        CGRect brakeActiveImageViewFrame = self.brakeActiveImageView.frame;
        brakeActiveImageViewFrame.origin.y = indicatorImageViewFrame.origin.y + indicatorImageViewFrame.size.height;
        self.brakeActiveImageView.frame = brakeActiveImageViewFrame;

        CGRect screenFrame = self.view.frame;
        CGRect bottomMenuImageViewFrame = self.bottomMenuView.frame;
        bottomMenuImageViewFrame.origin.y = screenFrame.size.height - bottomMenuImageViewFrame.size.height - 100;
        self.bottomMenuView.frame = bottomMenuImageViewFrame;
    }
    else {
//        self.bottomMenuMoveUp = FALSE;
    }
}


-(IBAction)showMenuView:(id)sender {
    [self.navigationController popToRootViewControllerAnimated:TRUE];

}

-(IBAction)showSettingsView:(id)sender {
    if (self.transitionFromMenuScreen) {
        UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"Main" bundle: nil];

        SettingsViewController *settingsViewController = (SettingsViewController *)[mainStoryboard
                                                              instantiateViewControllerWithIdentifier: @"SettingsViewController"];
        [self.navigationController pushViewController:(SettingsViewController *)settingsViewController  animated:TRUE];
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
