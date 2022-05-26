//
//  ViewController.m
//  DB Demo
//
//  Created by John Hewlin on 2/20/17.
//  Copyright © 2017 MiLife Solution. All rights reserved.
//

#import "ViewController.h"
#import "BLEManager.h"
#import "bleScannedDeviceTableViewCell.h"
#import "DetailViewController.h"


@interface ViewController ()

@property (nonatomic, retain) IBOutlet UITableView *devicesTable;
@property (nonatomic, retain) CBPeripheral  *newlyDiscoveredPeripheral;
@property (nonatomic, retain) IBOutlet UIButton *scanButton;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateForNewPeripheral:) name:@"NewPeripheralDiscovered" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateForPeripheralTimeout:) name:@"PeripheralStoppedAdvertising" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateForPeripheralConnected:) name:@"PeripheralConnected" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateForPeripheralDisconnected:) name:@"PeripheralDisconnected" object:nil];
}


-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:true];
    [[[BLEManager sharedService] peripheralsArray] removeAllObjects];
    [self.devicesTable reloadData];
    
    if ([BLEManager sharedService].isScanning) {
        [self.scanButton setSelected:TRUE];
    }
    else {
        [self.scanButton setSelected:FALSE];
    }

}


- (void)viewWillDisappear:(BOOL)animated
{
    // Don't keep it going while we're not showing.
    [[BLEManager sharedService] stopScan];
    NSLog(@"Scanning stopped");
    
    [super viewWillDisappear:animated];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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

-(void)updateForPeripheralConnected:(NSNotification*)notification {
    [self.devicesTable reloadData];
    
}


-(void)updateForPeripheralDisconnected:(NSNotification*)notification {
    [self.devicesTable reloadData];
    
}


-(void)updateForPeripheralTimeout:(NSNotification*)notification {
    [self.devicesTable reloadData];

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

- (IBAction)connectButtonTouched:(id)sender {
    // Determine which Boat Connect Button was touched.
    CGPoint buttonPosition = [sender convertPoint:CGPointZero toView:self.devicesTable];
    NSIndexPath *indexPath = [self.devicesTable indexPathForRowAtPoint:buttonPosition];

    BLEPeripheral *blePeripheral = [[[BLEManager sharedService] peripheralsArray] objectAtIndex:indexPath.row];
    
    if (blePeripheral.peripheral.state == CBPeripheralStateDisconnected) {
        [[BLEManager sharedService].centralManager connectPeripheral:blePeripheral.peripheral options:nil];
    }
    else {
        [[BLEManager sharedService].centralManager cancelPeripheralConnection:blePeripheral.peripheral];

    }
    
    NSLog(@"%@", blePeripheral);
    
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


-(void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    DetailViewController *detailVC = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"DetailViewController"];
    detailVC.blePeripheral = [[BLEManager sharedService].peripheralsArray objectAtIndex:indexPath.row];
    [tableView deselectRowAtIndexPath:indexPath animated:TRUE];
    [self.navigationController pushViewController:detailVC animated:TRUE];
}


@end
