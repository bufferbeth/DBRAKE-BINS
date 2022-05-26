//
//  AddADeviceViewController.m
//  DB Demo
//
//  Created by John Hewlin on 1/4/21.
//  Copyright © 2021 MiLife Solution. All rights reserved.
//

#import "AddADeviceViewController.h"
#import "bleScannedDeviceTableViewCell.h"
#import "BLEManager.h"

@interface AddADeviceViewController ()

@property (nonatomic, retain) IBOutlet UITableView *devicesTable;
@property (nonatomic, retain) IBOutlet UIButton *scanButton;

@end

@implementation AddADeviceViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.scanButton.layer.cornerRadius = 5;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateForNewPeripheral:) name:@"NewPeripheralDiscovered" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateForPeripheralTimeout:) name:@"PeripheralStoppedAdvertising" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateForPeripheralConnected:) name:@"PeripheralConnected" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateForPeripheralDisconnected:) name:@"PeripheralDisconnected" object:nil];

}


- (void)viewWillDisappear:(BOOL)animated
{
    // Don't keep it going while we're not showing.
    [[BLEManager sharedService] stopScan];
    NSLog(@"Scanning stopped");
    
    [super viewWillDisappear:animated];
}

-(void)updateForNewPeripheral:(NSNotification*)notification {
    
    if ([BLEManager sharedService].isScanning) {
        [self.scanButton setSelected:TRUE];
    }
    else {
        [self.scanButton setSelected:FALSE];
    }

    NSMutableArray *peripheralIDsArray = [[NSMutableArray alloc] init];
    for (BLEPeripheral *blePeripheral in [[BLEManager sharedService] peripheralsArray]) {
        [peripheralIDsArray addObject:blePeripheral.peripheral.identifier];
    }
    // Get all peripherals
    NSArray *peripheralsArray = [[BLEManager sharedService].centralManager retrievePeripheralsWithIdentifiers:peripheralIDsArray];
    for (BLEPeripheral *blePeripheral in [[BLEManager sharedService] peripheralsArray]) {
        //NSLog(@"%@", blePeripheral.peripheral.name);
        // BMC
        if ([blePeripheral.peripheral.name hasPrefix:@"Dual"]) {
            continue;
        }
        if ([peripheralsArray containsObject:blePeripheral.peripheral]) {
            
            // Add devices to Unassigned Array if not in a Boat.
        }
    }
    [self.devicesTable reloadData];
    
}



-(void)updateForPeripheralConnected:(NSNotification*)notification {
    [self.devicesTable reloadData];
    
}


-(void)updateForPeripheralDisconnected:(NSNotification*)notification {
    [self.devicesTable reloadData];
    
}


-(void)updateForPeripheralTimeout:(NSNotification*)notification {
    [self.devicesTable reloadData];

}

-(IBAction)touchedStartScanningButton:(id)sender {
    if ([BLEManager sharedService].isScanning) {
        [[BLEManager sharedService] stopScan];
        [sender setSelected:FALSE];
    }
    else {
        [sender setSelected:TRUE];
        [[BLEManager sharedService] startScan];

    }
    [[[BLEManager sharedService] peripheralsArray] removeAllObjects];
    [self.devicesTable reloadData];

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
    //return 1;
    return [[BLEManager sharedService].peripheralsArray count];
}



- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    // NSLog(@"Section: %ld    Row: %ld", (long)indexPath.section, (long)indexPath.row);    
    bleScannedDeviceTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"DeviceCell" forIndexPath:indexPath];

    BLEPeripheral *blePeripheral = [[BLEManager sharedService].peripheralsArray objectAtIndex:indexPath.row];
    
    cell.bleNameLabel.text = blePeripheral.peripheral.name;
    cell.bleIdLabel.text = [blePeripheral.peripheral.identifier UUIDString];
    cell.bleRSSILabel.text = [NSString stringWithFormat:@"%ld", (long)[blePeripheral.rssiValue integerValue]];

    if (blePeripheral.peripheral.state == CBPeripheralStateConnected) {
        [cell.connectButton setSelected:TRUE];
    }
    else {
        [cell.connectButton setSelected:FALSE];

    }
    return cell;


}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
