//
//  DetailViewController.m
//  DB Demo
//
//  Created by John Hewlin on 3/9/17.
//  Copyright © 2017 MiLife Solution. All rights reserved.
//

#import "DetailViewController.h"
#import "bleScannedDeviceTableViewCell.h"
#import "FirmwareUpdateObject.h"
#import "DiagnosticViewController.h"


@interface DetailViewController ()
{
    NSString    *fileName;
    NSString    *fileName2;

}
@property (nonatomic, retain) IBOutlet UITableView *detailTable;
@property (nonatomic, retain) IBOutlet UILabel *brakeVersionLabel;
@property (nonatomic, retain) IBOutlet UILabel *remoteVersionLabel;
@property (nonatomic, retain) IBOutlet UIButton *brakeVersionButton;
@property (nonatomic, retain) IBOutlet UIButton *remoteVersionButton;

@property (nonatomic, retain) IBOutlet UILabel *brakeFirmwareVersionAvailableLabel;
@property (nonatomic, retain) IBOutlet UIButton *brakeDownloadButton;
@property (nonatomic, retain) NSMutableData *firmwareData;


@property (nonatomic, retain) IBOutlet UILabel *brakeFirmwareVersionAvailableLabel2;
@property (nonatomic, retain) IBOutlet UIButton *remoteDownloadButton;
@property (nonatomic, retain) NSMutableData *firmwareData2;

@property (strong, nonatomic) FirmwareUpdateObject *firmwareUpdate;

@property (strong, nonatomic) IBOutlet UIView *enterSerailNumberView;
@property (strong, nonatomic) IBOutlet UIView *downloadBrakeVersionView;
@property (strong, nonatomic) IBOutlet UIView *downloadRemoteVersionView;

@property (strong, nonatomic) IBOutlet UIButton *checkForNewVersionsButton;
@property (nonatomic, retain) IBOutlet UITextField *serialNumberTextField;
@property (strong, nonatomic) IBOutlet UIButton *doneButton;


@end

@implementation DetailViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateForPeripheralConnected:) name:@"PeripheralConnected" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateForPeripheralDisconnected:) name:@"PeripheralDisconnected" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateForBrakeVersionRequest:) name:@"ReplyReceivedForBrakeVersion" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(processFirmwareDownloadReply) name:@"ReplyReceivedForBrakeDownload" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(processFirmwareDownloadReply) name:@"ReplyReceivedForRemoteDownload" object:nil];

    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(processFirmwareDownloadComplete) name:@"FirmwareDownLoadComplete" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(processFirmwareDownloadWaitingForReset) name:@"FirmwareDownloadWaitingForReset" object:nil];

    
    NSURL* url = [[NSBundle mainBundle] URLForResource:@"sw042-01_10" withExtension:@"bin"];
    self.firmwareData = [[NSData dataWithContentsOfURL:url] mutableCopy];
    fileName = @"sw042-01_10";
    self.brakeFirmwareVersionAvailableLabel.text = fileName;

    url = [[NSBundle mainBundle] URLForResource:@"sw052-01_10" withExtension:@"bin"];
    self.firmwareData2 = [[NSData dataWithContentsOfURL:url] mutableCopy];
    fileName2 = @"sw052-01_10";
    self.brakeFirmwareVersionAvailableLabel2.text = fileName2;
    
    [[UIApplication sharedApplication] setIdleTimerDisabled:TRUE];

    [self updateButtons];
    
    self.firmwareUpdate = [[FirmwareUpdateObject alloc] init];
    self.firmwareUpdate.presentingViewController = self;
    
    self.enterSerailNumberView.hidden = TRUE;
    self.checkForNewVersionsButton.enabled = FALSE;
    self.checkForNewVersionsButton.hidden = TRUE;
    
    self.downloadBrakeVersionView.hidden = TRUE;
    self.downloadRemoteVersionView.hidden = TRUE;

}

-(void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:TRUE];
    //[[BLEManager sharedService].centralManager cancelPeripheralConnection:self.blePeripheral.peripheral];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


// Diagnostics Button
-(IBAction)diagnosticButonTouched:(id)sender {
    DiagnosticViewController *diagnosticVC = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"DiagnosticViewController"];
    diagnosticVC.blePeripheral = self.blePeripheral;
    [[BLEManager sharedService] stopScan];
    [self.navigationController pushViewController:diagnosticVC animated:TRUE];

    
}




/*
 
  On Mon, Dec 30, 2019 at 1:11 PM Elizabeth Horton <elizabeth.horton@buffer.net> wrote:
 Russell,
 Do you have the serial numbers that we need to handle and the path they should handle??

 The below is the logic I have given hewlin… please check:
 01_08  would go to 01_37

 01_12 would go to 01_37

 01_31 would go to 01_37

 01_37 and any larger than 01_37 … (ie. 01_38 etc. stay with 01_xx) files

 01_29 check serial number to decide if gets sent the 01_37 or 02_04

 All others to 02_XX.

 All 02_xx stay on 02_xx.



 For testing I created the following bins for testing the iphone app.

 Sw042-01_37 *** newest file for 01-xx path

 Sw042-01_12
 Sw042-02_04 ** newest file for 02_xx path
 Sw042-01_10
 Sw042-01_08
 Sw042-01_31
 Sw042-01_29

 Hi Elizabeth,

 01_XX is Patriot 3 software branch
 01_29 check serial number to decide if gets sent the 01_37 or 02_04  (165020-166280 go to 01_XX)
 ****01_31 and any larger than 01_31 … (ie. 01_31, 01_37, 01_38 etc. stay with 01_xx) files


 02_XX is Patriot II software branch
 01_29 all other serial numbers go to 02_XX
 ****All other versions to 02_XX   (ie 00_88 through 01_12)
 ****All 02_xx stay on 02_xx
  
 Russell
 
 
 NOTE:  01_30 is NOT covered....

 */
 
-(IBAction) checkForNewVersionButtonTouched:(id)sender {
    
    NSLog(@"Brake Version - %@", self.blePeripheral.brakeVersionString);
    
    // Test Code
    //if ([self.blePeripheral.brakeVersionString containsString:@"01.10"]) {
    // Test Code
    if ([self.blePeripheral.brakeVersionString containsString:@"01.29"]) {
        self.enterSerailNumberView.hidden = FALSE;
        self.doneButton.enabled = FALSE;
    }
    
    // Test code
//    else if ([self.blePeripheral.brakeVersionString containsString:@"02.04"]) {
//        NSURL* url = [[NSBundle mainBundle] URLForResource:@"sw042-01_29" withExtension:@"bin"];  //OR the latest 01.xx
//        self.firmwareUpdate.firmwareData = [[NSData dataWithContentsOfURL:url] mutableCopy];
//        self.firmwareData = [[NSData dataWithContentsOfURL:url] mutableCopy];
//        fileName = @"sw042-01_29";
//        self.brakeFirmwareVersionAvailableLabel.text = fileName;
//        self.enterSerailNumberView.hidden = TRUE;
//
//        self.downloadBrakeVersionView.hidden = FALSE;
//
//    }
    // Test code
    
    
    else if ([self.blePeripheral.brakeVersionString containsString:@"01.3"]) {
        
        NSURL* url = [[NSBundle mainBundle] URLForResource:@"sw042-01_37" withExtension:@"bin"];  //OR the latest 01.xx
        self.firmwareUpdate.firmwareData = [[NSData dataWithContentsOfURL:url] mutableCopy];
        self.firmwareData = [[NSData dataWithContentsOfURL:url] mutableCopy];
        fileName = @"sw042-01_37";
        self.brakeFirmwareVersionAvailableLabel.text = fileName;
        self.enterSerailNumberView.hidden = TRUE;
        self.downloadBrakeVersionView.hidden = FALSE;
    

    }
    else if ([self.blePeripheral.brakeVersionString containsString:@"00."] || [self.blePeripheral.brakeVersionString containsString:@"01.0"] || [self.blePeripheral.brakeVersionString containsString:@"01.10"] || [self.blePeripheral.brakeVersionString containsString:@"01.11"] || [self.blePeripheral.brakeVersionString containsString:@"01.12"] || [self.blePeripheral.brakeVersionString containsString:@"02"]) {
        
        NSURL* url = [[NSBundle mainBundle] URLForResource:@"sw042-02_04" withExtension:@"bin"];  //OR  the latest 02.xx
        self.firmwareUpdate.firmwareData = [[NSData dataWithContentsOfURL:url] mutableCopy];
        self.firmwareData = [[NSData dataWithContentsOfURL:url] mutableCopy];
        fileName = @"sw042-02_04";
        self.brakeFirmwareVersionAvailableLabel.text = fileName;
        self.enterSerailNumberView.hidden = TRUE;
        self.downloadBrakeVersionView.hidden = FALSE;

    }

    
}


-(IBAction) cancelButtonTouched:(id)sender {
    self.enterSerailNumberView.hidden = TRUE;
    [self.serialNumberTextField resignFirstResponder];
}


-(IBAction) doneButtonTouched:(id)sender {

    NSString *enteredSerialNumber;
    if ([self.serialNumberTextField.text length] == 5) {
        enteredSerialNumber = @"0";
        enteredSerialNumber = [enteredSerialNumber stringByAppendingString:self.serialNumberTextField.text];
    }
    else {
        enteredSerialNumber = self.serialNumberTextField.text;
    }
    
    NSInteger serialNumber = [enteredSerialNumber integerValue];
    NSLog(@"entered Serail Number - %@", enteredSerialNumber);
    NSLog(@"serial Number integerValue - %li", serialNumber);
    
    [self.serialNumberTextField resignFirstResponder];
    
    self.enterSerailNumberView.hidden = TRUE;
    
    if (serialNumber >=165020  && serialNumber <=166280) {
        NSURL* url = [[NSBundle mainBundle] URLForResource:@"sw042-01_37" withExtension:@"bin"];  //OR  the latest 02.xx
        self.firmwareUpdate.firmwareData = [[NSData dataWithContentsOfURL:url] mutableCopy];
        self.firmwareData = [[NSData dataWithContentsOfURL:url] mutableCopy];
        fileName = @"sw042-01_37";
        self.brakeFirmwareVersionAvailableLabel.text = fileName;
        self.downloadBrakeVersionView.hidden = FALSE;
    }
    else {
        NSURL* url = [[NSBundle mainBundle] URLForResource:@"sw042-02_04" withExtension:@"bin"];  //OR  the latest 02.xx
        self.firmwareUpdate.firmwareData = [[NSData dataWithContentsOfURL:url] mutableCopy];
        self.firmwareData = [[NSData dataWithContentsOfURL:url] mutableCopy];
        fileName = @"sw042-02_04";
        self.brakeFirmwareVersionAvailableLabel.text = fileName;
        self.downloadBrakeVersionView.hidden = FALSE;

    }

}


- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    //[self.saveEditButton setSelected:TRUE];
    //self.defaultBoatSwitch.enabled = FALSE;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    
    if (range.location > 0 || [string length] > 0) {
        //[self.saveEditButton setSelected:TRUE];
        //[self.saveEditButton setEnabled:TRUE];
    }
    else {
       // [self.saveEditButton setSelected:TRUE];
       // [self.saveEditButton setEnabled:FALSE];
    }
    if ([textField.text length] >= 5) {
        self.doneButton.enabled = TRUE;
    }
    if ([textField.text length] >= 6 && range.location >=6) {
        return FALSE;
    }
    return TRUE;
}


-(void)updateButtons {
    
    if (self.blePeripheral.peripheral.state != CBPeripheralStateConnected) {
        self.brakeVersionButton.enabled = FALSE;
        self.remoteVersionButton.enabled = FALSE;
        self.brakeDownloadButton.enabled = FALSE;
        self.remoteDownloadButton.enabled = FALSE;
    }
    else {
        if (self.blePeripheral.blePeripheralCommunicationState == blePeripheralCommunicationStateIdle) {
            self.brakeVersionButton.enabled = TRUE;
            self.remoteVersionButton.enabled = TRUE;
            self.brakeDownloadButton.enabled = TRUE;
            self.remoteDownloadButton.enabled = TRUE;
        }

    }
}

-(void)updateForPeripheralConnected:(NSNotification*)notification {
    [self updateButtons];
    [self.detailTable reloadData];
}


-(void)updateForPeripheralDisconnected:(NSNotification*)notification {
    [self updateButtons];
    self.brakeVersionLabel.text = @"??";
    self.remoteVersionLabel.text = @"??";
    [[BLEManager sharedService] startScan];
    [self.firmwareUpdate.m_HUD hide:TRUE];
    if (self.firmwareUpdate.firmwareTXComplete == TRUE ) {
        [self.navigationController popViewControllerAnimated:TRUE];
    }

    [self.detailTable reloadData];
}

-(void)updateForBrakeVersionRequest:(NSNotification*)notification {
    [self updateButtons];
    
    if ([self.blePeripheral.brakeVersionString length]) {
        self.brakeVersionLabel.text = self.blePeripheral.brakeVersionString;
        self.checkForNewVersionsButton.enabled = TRUE;
        self.checkForNewVersionsButton.hidden = FALSE;


    }
    if ([self.blePeripheral.remoteVersionString length]) {
        self.remoteVersionLabel.text = self.blePeripheral.remoteVersionString;
    }

    
}


- (IBAction)connectButtonTouched:(id)sender {
//    CGPoint buttonPosition = [sender convertPoint:CGPointZero toView:self.devicesTable];
//    NSIndexPath *indexPath = [self.detailTable indexPathForRowAtPoint:buttonPosition];
    
//    BLEPeripheral *blePeripheral = [[[BLEManager sharedService] peripheralsArray] objectAtIndex:indexPath.row];
    
    if (self.blePeripheral.peripheral.state == CBPeripheralStateDisconnected) {
        [[BLEManager sharedService].centralManager connectPeripheral:self.blePeripheral.peripheral options:nil];
    }
    else {
        [[BLEManager sharedService].centralManager cancelPeripheralConnection:self.blePeripheral.peripheral];
    }
    //NSLog(@"%@", self.blePeripheral);
}



-(IBAction)brakeVersionRequestButtonTouched:(id)sender {
    if (self.blePeripheral.peripheral.state == CBPeripheralStateConnected) {
        self.brakeVersionLabel.text = @"??";
        
        [[BLEManager sharedService] sendCommandToDevice:self.blePeripheral.peripheral cmdString:cmdBrakeVersionString];
        [self updateButtons];
    }
}


-(IBAction)remoteVersionRequestButtonTouched:(id)sender {
    if (self.blePeripheral.peripheral.state == CBPeripheralStateConnected) {
        self.remoteVersionLabel.text = @"??";
        [[BLEManager sharedService] sendCommandToDevice:self.blePeripheral.peripheral cmdString:cmdRemoteVersionString];
        
        [self updateButtons];
    }
}


-(IBAction)brakeUpdateVersionButtonTouched:(id)sender {
    if (self.blePeripheral.peripheral.state == CBPeripheralStateConnected) {
        
        //[[BLEManager sharedService] sendCommandToDevice:self.blePeripheral.peripheral cmdString:cmdDownloadBrakeString];
        [self.firmwareUpdate updateFirmwareForDevice:self.blePeripheral updateType:FIRMWARE_UPDATE_BRAKE_FIRMWARE];
        [self updateButtons];
    }
}



-(IBAction)remoteUpdateVersionButtonTouched:(id)sender {
  
    if (self.blePeripheral.peripheral.state == CBPeripheralStateConnected) {
        
        //[[BLEManager sharedService] sendCommandToDevice:self.blePeripheral.peripheral cmdString:cmdDownloadBrakeString];
        [self.firmwareUpdate updateFirmwareForDevice:self.blePeripheral updateType:FIRMWARE_UPDATE_REMOTE_FIRMWARE];
        [self updateButtons];
    }

}

/**
 *************************************
 */
-(void)processFirmwareDownloadReply {
    [self.firmwareUpdate processFirmwareDownloadReply];
    float sentBytes = (float)self.firmwareUpdate.firmwareSendDataIndex;
    float totalBytes = (float)[self.firmwareUpdate.firmwareData length];
    NSString *progressString = [NSString stringWithFormat:@"%li of %li", (long)self.firmwareUpdate.firmwareSendDataIndex, (unsigned long)[self.firmwareUpdate.firmwareData length]];
    
    float percentDone = (sentBytes / totalBytes ) * 100;
    NSString *percentChar = @"%";
    NSString *betterProgressString = [NSString stringWithFormat:@"%2.0f %@", percentDone, percentChar];
    
    // AlertViewDeprecated.
    self.firmwareUpdate.m_HUD.labelText = [NSString stringWithFormat: @"Updating... %@ (%@)", progressString, betterProgressString];
    // AlertViewDeprecated.
    
    if (self.firmwareUpdate.firmwareTXComplete == TRUE ) {
        self.firmwareUpdate.m_HUD.labelText = @"Waiting for Reset...";
    }
}

-(void)processFirmwareDownloadComplete {

    NSLog(@"Detail View - Firmwaredownload Complete");
    [self.navigationController popViewControllerAnimated:TRUE];
}


-(void)processFirmwareDownloadWaitingForReset {
    self.firmwareUpdate.m_HUD.labelText = @"Waiting for Reset";
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
    return 1;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    //if (indexPath.row == 0) {
        // NSLog(@"Section: %ld    Row: %ld", (long)indexPath.section, (long)indexPath.row);
        bleScannedDeviceTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"DeviceCell" forIndexPath:indexPath];
        
        cell.bleNameLabel.text = self.blePeripheral.peripheral.name;
        cell.bleIdLabel.text = [self.blePeripheral.peripheral.identifier UUIDString];
        cell.bleRSSILabel.text = [NSString stringWithFormat:@"%ld", (long)[self.blePeripheral.rssiValue integerValue]];
        
        if (self.blePeripheral.peripheral.state == CBPeripheralStateConnected) {
            [cell.connectButton setSelected:TRUE];
        }
        else {
            [cell.connectButton setSelected:FALSE];
            
        }
        return cell;
    //}
    
 //   if (indexPath.row == 1) {
 //   }
    
}


-(void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
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
