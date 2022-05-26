//
//  DiagnosticViewController.m
//  DB Demo
//
//  Created by John Hewlin on 11/9/20.
//  Copyright © 2020 MiLife Solution. All rights reserved.
//

#import "DiagnosticViewController.h"
#import "BLEManager.h"
#import "diagnosticDataTableViewCell.h"

@interface DiagnosticViewController ()

@property (nonatomic, retain) IBOutlet UITableView *dataTable;
@property (nonatomic, retain) IBOutlet UIButton *startCaptureButton;

@property (atomic, strong) NSMutableArray *diagnosticDataArray;

@property (nonatomic, retain) IBOutlet UILabel *bleNameLabel;
@property (nonatomic, retain) IBOutlet UILabel *bleIdLabel;

@end

bool captureStarted;

@implementation DiagnosticViewController

/**
*************************************
*/
- (void)viewDidLoad {
    [super viewDidLoad];
    self.diagnosticDataArray = [[NSMutableArray alloc] initWithCapacity:25];
    captureStarted = FALSE;
    // Do any additional setup after loading the view.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateTableData:) name:@"DiagnosticDataReceived" object:nil];
    
    self.bleNameLabel.text = self.blePeripheral.peripheral.name;
    self.bleIdLabel.text = [self.blePeripheral.peripheral.identifier UUIDString];

}


/**
*************************************
*/
-(void)updateTableData:(NSNotification*)notification {
    
    if (!captureStarted)
        return;
    //BLEPeripheral *blePeripheral = notification.userInfo[@"blePeripheral"];
    NSString *diagnosticDataString = notification.userInfo[@"PacketDataString"];
    NSData *packetData = notification.userInfo[@"ReplyData"];

    [self.diagnosticDataArray addObject:packetData];
    
    if ([self.diagnosticDataArray count] > 20) {
        [self.diagnosticDataArray removeObjectAtIndex:0];
    }
    
//    if (packetData != nil) {
//        NSLog(@"Packet Reply Data: %@", packetData);
//        
//        // Convert Reply data to string representing raw data
//        // <23000962 7630312e 31300d> ==>> @"23 00 09 62 76 30 31 2e 31 30 0d
//        NSUInteger length = [packetData length];
//        NSData *data = packetData;
//        NSUInteger capacity = data.length * 2;
//        NSMutableString *sbuf = [NSMutableString stringWithCapacity:capacity];
//        const unsigned char *buf = data.bytes;
//        NSInteger i;
//        for (i=0; i<data.length; ++i) {
//            [sbuf appendFormat:@"%02lX", (unsigned long)buf[i]];
//        }
//        NSLog(@"Packet Reply String: %@", sbuf);
//         self.bleIdLabel.text = sbuf;
//    }
    [self.dataTable reloadData];
//    NSIndexPath *indexPath;
//    [self.dataTable scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionBottom animated:TRUE];

}

/**
*************************************
*/
-(IBAction)brakeVersionRequestButtonTouched:(id)sender {
    
//    if (captureStarted)
//    {
//        [sender setSelected:FALSE];
//    }
//    else {
//        [sender setSelected:TRUE];
//        
//    }
    captureStarted = !captureStarted;
    [sender setSelected:!captureStarted];

//    if (self.blePeripheral.peripheral.state == CBPeripheralStateConnected) {
//        [[BLEManager sharedService] sendCommandToDevice:self.blePeripheral.peripheral cmdString:cmdBrakeVersionString];
//    }
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
    return [self.diagnosticDataArray count];
}


/**
 *************************************
 */
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    // NSLog(@"Section: %ld    Row: %ld", (long)indexPath.section, (long)indexPath.row);
    
    DiagnosticDataTableViewCell *dataCell = [tableView dequeueReusableCellWithIdentifier:@"DataCell" forIndexPath:indexPath];
    
    NSData *packetData = [self.diagnosticDataArray objectAtIndex:indexPath.row];
    NSMutableString *replyDataString = [[NSMutableString alloc] initWithData:packetData encoding:NSUTF8StringEncoding];

    dataCell.diagnosticDataLabel.text = replyDataString;
    
    
    if (packetData != nil) {
        NSLog(@"Packet Reply Data: %@", packetData);
        
        // Convert Reply data to string representing raw data
        // <23000962 7630312e 31300d> ==>> @"23 00 09 62 76 30 31 2e 31 30 0d
        
        NSUInteger length = [packetData length];
        
        
        NSData *data = packetData;
        NSUInteger capacity = data.length * 2;
        NSMutableString *sbuf = [NSMutableString stringWithCapacity:capacity];
        const unsigned char *buf = data.bytes;
        NSInteger i;
        for (i=0; i<data.length; ++i) {
            [sbuf appendFormat:@"%02lX", (unsigned long)buf[i]];
        }
        NSLog(@"Packet Reply String: %@", sbuf);
        dataCell.timeStampLabel.text = [NSString stringWithFormat:@"%ld %@", (long)indexPath.row+1, sbuf];
    }
    
    
    // Test code
    //dataCell.diagnosticDataLabel.text = @"123456789 123456789 123456789123456789 123456789 123456789 123456789 123456789 123456789";
    //bleScannedDeviceTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"DeviceCell" forIndexPath:indexPath];
//
//    BLEPeripheral *blePeripheral = [[BLEManager sharedService].peripheralsArray objectAtIndex:indexPath.row];
//
//    cell.bleNameLabel.text = blePeripheral.peripheral.name;
//    cell.bleIdLabel.text = [blePeripheral.peripheral.identifier UUIDString];
//    cell.bleRSSILabel.text = [NSString stringWithFormat:@"%ld", (long)[blePeripheral.rssiValue integerValue]];
//
//    if (blePeripheral.peripheral.state == CBPeripheralStateConnected) {
//        [cell.connectButton setSelected:TRUE];
//    }
//    else {
//        [cell.connectButton setSelected:FALSE];
//
//    }
//    return cell;
    return dataCell;
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
