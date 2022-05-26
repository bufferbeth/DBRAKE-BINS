//
//  FirmwareUpdateObject.m
//  CMONSTER
//
//  Created by John Hewlin on 12/23/14.
//  Copyright (c) 2014 JL MARINE. All rights reserved.
//

#import "FirmwareUpdateObject.h"
#import "AppDelegate.h"
#import "BLEManager.h"



enum {
    FIRMWARE_UPDATE_STATE_IDLE,
    FIRMWARE_UPDATE_STATE_REFLASH_COMMAND_SENT,
    FIRMWARE_UPDATE_STATE_SENDING_DATA,
    FIRMWARE_UPDATE_STATE_SENDING_EOT,
    FIRMWARE_UPDATE_STATE_END_SESSION,
    FIRMWARE_UPDATE_STATE_COMPLETE,
    FIRMWARE_UPDATE_STATE_END_OF_DOWNLOAD
};

@interface FirmwareUpdateObject ()
{
    NSInteger   firmwareUpdateState;
    NSInteger   typeOfUpdate;
    NSString    *fileName;
    BLEPeripheral *updatePeripheral;
    
    NSInteger   packSequenceNumber;
    
    NSTimer *reFlashDelayTimer;

    NSInteger endOfTransmissionCount;
    
    UIAlertView *bleTypeAlertView;
    
// AlertViewDeprecated.
//    UIAlertView *noSleepAlertView;
// AlertViewDeprecated.


}

@property (nonatomic, retain) NSMutableData *txData;
@property (nonatomic, readwrite) NSInteger  sendDataIndex;
@property (nonatomic, readwrite) BOOL       txComplete;
@property (nonatomic, readwrite) BOOL       txSuccessful;

//@property (nonatomic, retain) NSTimer *recoveryTimer;

//#define DEBUG_VERSION_DOWNLOAD 1

@end // interface


@implementation FirmwareUpdateObject

-(id)init {
    
    firmwareUpdateState = FIRMWARE_UPDATE_STATE_IDLE;
    self.firmwareData = [[NSMutableData alloc] init];
    return self;
}

/**
 *************************************
 *  Update the Power Pole's firmware
 *  @params blePeripheral for Power Pole,
 */
- (void) updateFirmwareForDevice:(BLEPeripheral *)blePeripheral updateType:(NSInteger)updateType {
    typeOfUpdate = updateType;
    updatePeripheral = blePeripheral;
    
    switch (updateType) {
        case FIRMWARE_UPDATE_BRAKE_FIRMWARE: {
            blePeripheral.commandString = cmdDownloadBrakeString;
        }
            break;
            
        case FIRMWARE_UPDATE_REMOTE_FIRMWARE: {
            blePeripheral.commandString = cmdDownloadRemoteString;
            //blePeripheral.commandString = cmdDownloadBrakeString;
        }
            break;
            
        default:
            break;
    }
    
    switch (firmwareUpdateState) {
        case FIRMWARE_UPDATE_STATE_IDLE:
        {
            // firmwareData is setup in DetailViewController.
            //NSString *filePath = [self getFilePath:updateType];

            UIAlertController* noSleepAlertController = [UIAlertController alertControllerWithTitle:@"! Warning !" message:@"Do Not Put Your Phone Into Sleep Mode During Download.\nThis App disables the Auto-Lock while downloading new firmware." preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
            }];
            UIAlertAction* okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
                
                self.m_HUD = [[MBProgressHUD alloc] initWithView:self.presentingViewController.navigationController.view];
                NSString *progressString = [NSString stringWithFormat:@"%li of %li", (long)self.firmwareSendDataIndex, (unsigned long)[self.firmwareData length]];
                self.m_HUD.labelText = [NSString stringWithFormat: @"Updating... %@", progressString];
                self.m_HUD.minSize = CGSizeMake(135.0f, 135.0f);
                [self.presentingViewController.navigationController.view addSubview:self.m_HUD];
                [self.m_HUD show:YES];

                packSequenceNumber = 0x00;
                //if ( [[BLEManager sharedService] sendCommandToDevice:updatePeripheral.peripheral cmdString:cmdDownloadBrakeString] == TRUE) {
                    [self sendFirstBlock];
                    firmwareUpdateState = FIRMWARE_UPDATE_STATE_REFLASH_COMMAND_SENT;
                //}
                //else {
                    //[[NSNotificationCenter defaultCenter] postNotificationName:FIRMWARE_UPDATE_ABORTED object:nil userInfo:nil];
                //}
            }];

            [noSleepAlertController addAction:cancelAction];
            [noSleepAlertController addAction:okAction];
            [self.presentingViewController presentViewController:noSleepAlertController animated:YES completion:nil];
        }
            break;
        
        case FIRMWARE_UPDATE_STATE_SENDING_EOT:
        {
            [self.m_HUD hide:YES];
        }
            break;
            
            
        default:
            break;
    }
}





-(NSString *)getFilePath:(NSInteger)updateType {
    
    switch (updateType) {
        case FIRMWARE_UPDATE_BRAKE_FIRMWARE: {
            NSURL* url = [[NSBundle mainBundle] URLForResource:@"sw042-01_10" withExtension:@"bin"];
            self.firmwareData = [[NSData dataWithContentsOfURL:url] mutableCopy];
            fileName = @"sw042-01_10";
        }
            break;
        
        case FIRMWARE_UPDATE_REMOTE_FIRMWARE: {
            NSURL* url = [[NSBundle mainBundle] URLForResource:@"sw052-01_10" withExtension:@"bin"];
            self.firmwareData = [[NSData dataWithContentsOfURL:url] mutableCopy];
            fileName = @"sw052-01_10";
        }
            break;

        default:
            break;
    }
    NSString *applicationDocumentsDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    return [NSString stringWithFormat: @"%@/%@", applicationDocumentsDir, fileName];;
}



-(void)sendFirstBlock
{
    [reFlashDelayTimer invalidate];
    
    
    // Build the command packet
    NSString *startChar = @"#";
    
    NSMutableData *packetData = [[NSMutableData alloc] initWithCapacity:1024];
    [packetData appendData:[startChar dataUsingEncoding:NSStringEncodingConversionAllowLossy]];
    
    
    NSString *commandChars;
    switch (typeOfUpdate) {
        case FIRMWARE_UPDATE_BRAKE_FIRMWARE: {
            commandChars = cmdDownloadBrakeString;
        }
            break;
        case FIRMWARE_UPDATE_REMOTE_FIRMWARE: {
            commandChars = cmdDownloadRemoteString;
            //commandChars = cmdDownloadBrakeString;
        }
            break;
        default:
            break;
    }

    
    
    NSData *commandCharsData = [commandChars dataUsingEncoding:NSUTF8StringEncoding];
    
    NSString *terminateChar = @"\r";
    NSData *terminateCharData = [terminateChar dataUsingEncoding:NSUTF8StringEncoding];
    
    
    NSMutableData *lengthData = [[NSMutableData alloc] initWithCapacity:4];
    NSMutableData *cmdData = [[NSMutableData alloc] initWithCapacity:1024];
    
    NSInteger packetLength1;
    NSInteger packetLength2;


    // Create the first Block with the FileName.
    packetLength1 = 0x00;
    packetLength2 = 0x18;
    [lengthData appendBytes:&packetLength1 length:1];
    [lengthData appendBytes:&packetLength2 length:1];
    
    
    // Add to the command data.
    NSInteger packetNumber = 0x00;
    [cmdData appendBytes:&packetNumber length:1];
    
    //NSURL* url = [[NSBundle mainBundle] URLForResource:@"sw042-00_87" withExtension:@"bin"];
    NSData *firmwareData = self.firmwareData;
    
    NSLog(@"Firmware Data Length - %lu", (unsigned long)[firmwareData length]);
    // NSLog(@"Firmware Data - %@", firmwareData);
    
    // AppLength
    NSRange appLengthHighByteRange = {8,1};
    NSRange appLengtMidByteRange = {9,1};
    NSRange appLengthLowByteRange = {10,1};
    NSRange appLengthLowestByteRange = {11,1};
    [cmdData appendData:[firmwareData subdataWithRange:appLengthHighByteRange]];
    [cmdData appendData:[firmwareData subdataWithRange:appLengtMidByteRange]];
    [cmdData appendData:[firmwareData subdataWithRange:appLengthLowByteRange]];
    [cmdData appendData:[firmwareData subdataWithRange:appLengthLowestByteRange]];
    
    // checksum
    NSRange checksumHighByteRange = {4,1};
    NSRange checksumMidByteRange = {5,1};
    NSRange checksumLowByteRange = {6,1};
    NSRange checksumLowestByteRange = {7,1};
    [cmdData appendData:[firmwareData subdataWithRange:checksumHighByteRange]];
    [cmdData appendData:[firmwareData subdataWithRange:checksumMidByteRange]];
    [cmdData appendData:[firmwareData subdataWithRange:checksumLowByteRange]];
    [cmdData appendData:[firmwareData subdataWithRange:checksumLowestByteRange]];
    
    // checksum offset
    NSRange checksumOffsetHighByteRange = {44,1};
    NSRange checksumOffsetMidByteRange = {45,1};
    NSRange checksumOffsetLowByteRange = {46,1};
    NSRange checksumOffsetLowestByteRange = {47,1};
    [cmdData appendData:[firmwareData subdataWithRange:checksumOffsetHighByteRange]];
    [cmdData appendData:[firmwareData subdataWithRange:checksumOffsetMidByteRange]];
    [cmdData appendData:[firmwareData subdataWithRange:checksumOffsetLowByteRange]];
    [cmdData appendData:[firmwareData subdataWithRange:checksumOffsetLowestByteRange]];
    
    // version
    NSRange versionHighByteRange = {12,1};
    NSRange versionMidByteRange = {13,1};
    NSRange versionLowByteRange = {14,1};
    NSRange versionLowestByteRange = {15,1};
    [cmdData appendData:[firmwareData subdataWithRange:versionHighByteRange]];
    [cmdData appendData:[firmwareData subdataWithRange:versionMidByteRange]];
    [cmdData appendData:[firmwareData subdataWithRange:versionLowByteRange]];
    [cmdData appendData:[firmwareData subdataWithRange:versionLowestByteRange]];
    
    // Number of Packets
    NSInteger numberOfPackets = ([firmwareData length] / 512) + 1;
    [cmdData appendBytes:&numberOfPackets length:1];
    
    // Add the data pieces to the command packet
    [packetData appendData:lengthData];
    [packetData appendData:commandCharsData];
    [packetData appendData:cmdData];
    [packetData appendData:terminateCharData];
    
    NSData *chunk = [NSData dataWithBytes:packetData.bytes length:packetData.length];
    NSLog(@"Chunk Data- %@", chunk);

    updatePeripheral.transmitData = [[[NSMutableData alloc] initWithData:packetData] mutableCopy];
    updatePeripheral.blePeripheralState = blePeripheralStateSendingData;
    updatePeripheral.sendDataIndex = 0;
    updatePeripheral.txComplete = FALSE;
    updatePeripheral.txSuccessful = FALSE;
    
    self.firmwareSendDataIndex = 0;
    firmwareUpdateState = FIRMWARE_UPDATE_STATE_SENDING_DATA;
    [[BLEManager sharedBLEManager] sendData:updatePeripheral];
/*
    if (updatePeripheral.peripheral.state == CBPeripheralStateConnected) {
        
        // The 'dataSendCharacteristic' is set during the discovery of Services and Characteristics, after Connection is established.
        CBCharacteristic *theCharacteristic = updatePeripheral.dataSendCharacteristic;
        if (theCharacteristic && updatePeripheral.peripheral.state == CBPeripheralStateConnected) {
            
            [updatePeripheral.peripheral writeValue:chunk forCharacteristic:theCharacteristic type:updatePeripheral.characteristicWriteType];
            updatePeripheral.blePeripheralCommunicationState = blePeripheralCommunicationStateRequestPending;
            
            // Start a timer for the response if not running
//            if (![updatePeripheral.communicationResponseTimeout isValid]) {
//                updatePeripheral.communicationResponseTimeout = [NSTimer scheduledTimerWithTimeInterval:2 target:self selector:@selector(communicationResponseTimeOut:) userInfo:blePeripheral repeats:NO];
//            }
            
            //return TRUE;
        }
    }
*/


}



- (void)processFirmwareDownloadReply {
    
    switch (firmwareUpdateState) {
        case FIRMWARE_UPDATE_STATE_REFLASH_COMMAND_SENT:
        case FIRMWARE_UPDATE_STATE_SENDING_DATA:
        {
            
            // Each time a Block is Sent start a 10s timer.  If no reply, abort download.
            [self.recoveryTimer invalidate];
            //self.recoveryTimer = [NSTimer timerWithTimeInterval:10 target:self selector:@selector(abortDownload) userInfo:nil repeats:NO];
            self.recoveryTimer = [NSTimer timerWithTimeInterval:600 target:self selector:@selector(abortDownload) userInfo:nil repeats:NO];
            [[NSRunLoop mainRunLoop] addTimer:self.recoveryTimer forMode:NSRunLoopCommonModes];
           
           if (packSequenceNumber == 0) {
               self.firmwareSendDataIndex = 0;
           }
           
           // Build the command packet
           NSString *startChar = @"#";
           
           
           NSString *cmdString = cmdDownloadBrakeString;
            
            switch (typeOfUpdate) {
                case FIRMWARE_UPDATE_BRAKE_FIRMWARE: {
                    cmdString = cmdDownloadBrakeString;
                }
                    break;
                    
                case FIRMWARE_UPDATE_REMOTE_FIRMWARE: {
                    cmdString = cmdDownloadRemoteString;
                    //blePeripheral.commandString = cmdDownloadBrakeString;
                }
                    break;
                    
                default:
                    break;
            }

            
            
            
           NSString *commandChars = cmdString;
           NSData *commandCharsData = [commandChars dataUsingEncoding:NSUTF8StringEncoding];
           
           NSString *terminateChar = @"\r";
           NSData *terminateCharData = [terminateChar dataUsingEncoding:NSUTF8StringEncoding];
           
           NSMutableData *lengthData = [[NSMutableData alloc] initWithCapacity:4];
           NSMutableData *cmdData = [[NSMutableData alloc] initWithCapacity:1024];

           NSInteger packetLength = 512+7;

           NSInteger packetLengthLowByte = packetLength & 0x000000FF;
           NSInteger packetLengthHighByte = (packetLength >> 8) & 0x000000FF;
           [lengthData appendBytes:&packetLengthHighByte length:1];
           [lengthData appendBytes:&packetLengthLowByte length:1];

           // Build the command data.
           packSequenceNumber++;
           [cmdData appendBytes:&packSequenceNumber length:1];
           
           // Get the next chunk of bytes from the file.
           // Copy out the data we want
           NSInteger amountToSend = self.firmwareData.length - self.firmwareSendDataIndex;
           
           if (amountToSend > 512) amountToSend = 512;

           NSMutableData *firmwareDataBytes = [[NSMutableData alloc] initWithBytes:self.firmwareData.bytes+self.firmwareSendDataIndex length:amountToSend];
           
           NSInteger fillData = 0xAA;
            if (amountToSend < 512) {
                while ([firmwareDataBytes length] < 512) {
                    [firmwareDataBytes appendBytes:&fillData length:1];
                }
                
            }
           [cmdData appendData:firmwareDataBytes];
           
           // Add the data pieces to the command packet
           NSMutableData *packetData = [[NSMutableData alloc] initWithCapacity:1024];
           [packetData appendData:[startChar dataUsingEncoding:NSStringEncodingConversionAllowLossy]];
           [packetData appendData:lengthData];
           [packetData appendData:commandCharsData];
           [packetData appendData:cmdData];
           [packetData appendData:terminateCharData];

            NSLog(@"Packet Data chunk of new firmware: %@", packetData);

            
            
            /*
             
             Packet Data chunk of new firmware: 
             <23020744 4201efcd ab89aefd 0103e83f 01002087 00000600 00005300 00005700 00003000 00003400 00003200 00007000 000098ba dcfe0000 00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000 00006879 00205d28 0100e128 01003528 01000000 00000000 00000000 00000000 00000000 00000000 00000000 0000e928 01000000 00000000 0000e928 0100e928 0100e928 0100e928 0100e928 0100e928 0100dd42 0000e928 0100e928 0100a90f 0100bd0f 0100d10f 0100e50f 0100f90f 01000d10 0100c957 0000dd57 0000f157 00000558 00001958 00002d58 00004158 00005558 00005d3c 0000e928 0100e928 0100e928 010010b5 064c2378 002b07d1 054b002b 02d00448 00e000bf 01232370 10bd7404 00200000 0000746b 010008b5 084b002b 03d00748 084900e0 00bf0748 0368002b 03d0064b 002b00d0 984708bd c0460000 0000746b 01007804 0020746b 01000d>
             
             */
            
            updatePeripheral.transmitData = [[[NSMutableData alloc] initWithData:packetData] mutableCopy];
            updatePeripheral.blePeripheralState = blePeripheralStateSendingData;
            updatePeripheral.sendDataIndex = 0;
            updatePeripheral.txComplete = FALSE;
            updatePeripheral.txSuccessful = FALSE;
            [[BLEManager sharedBLEManager] sendData:updatePeripheral];
            
            self.firmwareSendDataIndex += amountToSend;
            NSLog(@"FirmwareDataIndex: %ld", (long)self.firmwareSendDataIndex);
            
            if (self.firmwareSendDataIndex >= self.firmwareData.length) {
                self.firmwareTXComplete = TRUE;
                firmwareUpdateState = FIRMWARE_UPDATE_STATE_SENDING_EOT;
                endOfTransmissionCount = 0;
                //[self.m_HUD hide:YES]; // Now Hidden in Detail View Controller.
                NSDictionary* infoDict = @{@"peripheral":updatePeripheral};
                [[NSNotificationCenter defaultCenter] postNotificationName:@"FirmwareDownloadWaitingForReset" object:nil userInfo:infoDict];


            }

            
        }
            break;

        case FIRMWARE_UPDATE_STATE_SENDING_EOT:
        {
            NSLog(@"Firm Update Complete - reply received");
            NSDictionary* infoDict = @{@"peripheral":updatePeripheral};
            [[NSNotificationCenter defaultCenter] postNotificationName:@"FirmwareDownLoadComplete" object:nil userInfo:infoDict];

        }
            break;
            
        default:
            break;

    }
}



/*
//    if (!updatePeripheral.txComplete) {
//        return;
    }
    switch (firmwareUpdateState) {
        
        case FIRMWARE_UPDATE_STATE_REFLASH_COMMAND_SENT:
        {
            [reFlashDelayTimer invalidate];
            [self.recoveryTimer invalidate];
            reFlashDelayTimer = [NSTimer timerWithTimeInterval:2 target:self selector:@selector(sendFirstBlock) userInfo:nil repeats:NO];
            [[NSRunLoop mainRunLoop] addTimer:reFlashDelayTimer forMode:NSRunLoopCommonModes];
            //[self sendFirstBlock];
        }
        break;
        
        case FIRMWARE_UPDATE_STATE_SENDING_DATA:
        {
            // Each time a Block is Sent start a 10s timer.  If no reply, abort download.
            [self.recoveryTimer invalidate];
            //self.recoveryTimer = [NSTimer timerWithTimeInterval:10 target:self selector:@selector(abortDownload) userInfo:nil repeats:NO];
            self.recoveryTimer = [NSTimer timerWithTimeInterval:600 target:self selector:@selector(abortDownload) userInfo:nil repeats:NO];

            [[NSRunLoop mainRunLoop] addTimer:self.recoveryTimer forMode:NSRunLoopCommonModes];

            NSMutableData *blockData = [[NSMutableData alloc] initWithCapacity:1024];
            
            packSequenceNumber++;
            NSInteger notPacketSequenceNumber = ~packSequenceNumber;
            NSInteger packetSize = STX;
            [blockData appendBytes:&packetSize length:1];
            [blockData appendBytes:&packSequenceNumber length:1];
            [blockData appendBytes:&notPacketSequenceNumber length:1];

//            NSString *dataBlockHeaderString = [NSString stringWithFormat:@"%d,%ld,%ld", STX, (long)packSequenceNumber, (long)~packSequenceNumber];
//            blockData = [[dataBlockHeaderString dataUsingEncoding:NSStringEncodingConversionAllowLossy] mutableCopy];

            NSInteger amountToSend = self.firmwareData.length - self.firmwareSendDataIndex;
            
            if (amountToSend > 1024) amountToSend = 1024;
            
            // Copy out the data we want
            NSData *chunk = [NSData dataWithBytes:self.firmwareData.bytes+self.firmwareSendDataIndex length:amountToSend];
            [blockData appendData:chunk];
            
            NSInteger fillData = 0xAA;
            while ([blockData length] < 1029) {
                [blockData appendBytes:&fillData length:1];
//
//                NSString *fill = [NSString stringWithFormat:@"%d",0x00];
//                [blockData appendData:[fill dataUsingEncoding:NSStringEncodingConversionAllowLossy]];
            }
            NSLog(@"Block Data%@", blockData);

//            self.txData = [[[NSMutableData alloc] initWithData:blockData] mutableCopy];
//            // Init status for this block.
//            self.sendDataIndex = 0;
//            self.txComplete = FALSE;
//            self.txSuccessful = FALSE;
//            [self sendData:updatePeripheral.peripheral];
            
            updatePeripheral.transmitData = [[[NSMutableData alloc] initWithData:blockData] mutableCopy];
            updatePeripheral.blePeripheralState = blePeripheralStateSendingData;
            updatePeripheral.sendDataIndex = 0;
            updatePeripheral.txComplete = FALSE;
            updatePeripheral.txSuccessful = FALSE;
            [[BLEManager sharedBLEManager] sendData:updatePeripheral];

            self.firmwareSendDataIndex += amountToSend;
            NSLog(@"FirmwareDataIndex: %ld", (long)self.firmwareSendDataIndex);

            if (self.firmwareSendDataIndex >= self.firmwareData.length) {
                self.firmwareTXComplete = TRUE;
                firmwareUpdateState = FIRMWARE_UPDATE_STATE_SENDING_EOT;
                endOfTransmissionCount = 0;
            }
        }
        break;
            
        case FIRMWARE_UPDATE_STATE_SENDING_EOT:
        {
            [self.recoveryTimer invalidate];
            //self.recoveryTimer = [NSTimer timerWithTimeInterval:10 target:self selector:@selector(abortDownload) userInfo:nil repeats:NO];
            self.recoveryTimer = [NSTimer timerWithTimeInterval:600 target:self selector:@selector(abortDownload) userInfo:nil repeats:NO];
            [[NSRunLoop mainRunLoop] addTimer:self.recoveryTimer forMode:NSRunLoopCommonModes];
            NSMutableData *blockData = [[NSMutableData alloc] initWithCapacity:1024];
            NSInteger endOfFileTransmission = EOT;
            [blockData appendBytes:&endOfFileTransmission length:1];
            NSLog(@"Block Data%@", blockData);
            
//            self.txData = [[[NSMutableData alloc] initWithData:blockData] mutableCopy];
//            // Init status for this block.
//            self.sendDataIndex = 0;
//            self.txComplete = FALSE;
//            self.txSuccessful = FALSE;
//            [self sendData:updatePeripheral.peripheral];
            
            updatePeripheral.transmitData = [[[NSMutableData alloc] initWithData:blockData] mutableCopy];
            updatePeripheral.blePeripheralState = blePeripheralStateSendingData;
            updatePeripheral.sendDataIndex = 0;
            updatePeripheral.txComplete = FALSE;
            updatePeripheral.txSuccessful = FALSE;
            [[BLEManager sharedBLEManager] sendData:updatePeripheral];
            
            if (++endOfTransmissionCount == 10) {
                firmwareUpdateState = FIRMWARE_UPDATE_STATE_END_SESSION;
            }
        }
        break;
            
        case FIRMWARE_UPDATE_STATE_END_SESSION:
        {
            [self.recoveryTimer invalidate];
            //self.recoveryTimer = [NSTimer timerWithTimeInterval:10 target:self selector:@selector(abortDownload) userInfo:nil repeats:NO];
            self.recoveryTimer = [NSTimer timerWithTimeInterval:600 target:self selector:@selector(abortDownload) userInfo:nil repeats:NO];
            [[NSRunLoop mainRunLoop] addTimer:self.recoveryTimer forMode:NSRunLoopCommonModes];
            NSMutableData *blockData = [[NSMutableData alloc] initWithCapacity:1024];
            packSequenceNumber=0;  // RESTART SEQUENCE NUMBER TO FIT STs Batardzied YModem implementation....
            NSInteger notPacketSequenceNumber = ~packSequenceNumber;
            NSInteger packetSize = SOH;
            [blockData appendBytes:&packetSize length:1];
            [blockData appendBytes:&packSequenceNumber length:1];
            [blockData appendBytes:&notPacketSequenceNumber length:1];

            NSInteger fillData = 0x00;
            while ([blockData length] < 133) {
                [blockData appendBytes:&fillData length:1];
            }
            NSLog(@"Block Data%@", blockData);
            
            
//            self.txData = [[[NSMutableData alloc] initWithData:blockData] mutableCopy];
//            // Init status for this block.
//            self.sendDataIndex = 0;
//            self.txComplete = FALSE;
//            self.txSuccessful = FALSE;
//            [self sendData:updatePeripheral.peripheral];
            
            updatePeripheral.transmitData = [[[NSMutableData alloc] initWithData:blockData] mutableCopy];
            updatePeripheral.blePeripheralState = blePeripheralStateSendingData;
            updatePeripheral.sendDataIndex = 0;
            updatePeripheral.txComplete = FALSE;
            updatePeripheral.txSuccessful = FALSE;
            [[BLEManager sharedBLEManager] sendData:updatePeripheral];

            
            firmwareUpdateState = FIRMWARE_UPDATE_STATE_COMPLETE;
        }
            
        case FIRMWARE_UPDATE_STATE_COMPLETE:
        {
            [self.recoveryTimer invalidate];
            self.recoveryTimer = [NSTimer timerWithTimeInterval:600 target:self selector:@selector(abortDownload) userInfo:nil repeats:NO];
            [[NSRunLoop mainRunLoop] addTimer:self.recoveryTimer forMode:NSRunLoopCommonModes];

            //[BLEManager sharedService].comminucationMode = COMM_MODE_NORMAL;
        }
        
        break;
            
        default:
        break;
    }
}
*/

- (void)processDeviceDisconnect {
    [self.recoveryTimer invalidate];
    if (firmwareUpdateState == FIRMWARE_UPDATE_STATE_COMPLETE) {
        [self endOfDownLoad];
    }
    else {
// AlertViewDeprecated.
        //[[NSNotificationCenter defaultCenter] postNotificationName:FIRMWARE_UPDATE_COMPLETE object:nil userInfo:nil];
        UIAlertController* downloadFailedAlertController = [UIAlertController alertControllerWithTitle:@"! Download Failed !" message:@"Reconnect From the Home Screen" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction* okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
            [[NSNotificationCenter defaultCenter] postNotificationName:FIRMWARE_UPDATE_COMPLETE object:nil userInfo:nil];
        }];
        [downloadFailedAlertController addAction:okAction];
        [self.presentingViewController presentViewController:downloadFailedAlertController animated:YES completion:nil];
// AlertViewDeprecated.
    }
}

- (void)endOfDownLoad {
    firmwareUpdateState = FIRMWARE_UPDATE_STATE_END_OF_DOWNLOAD;

    [self.recoveryTimer invalidate];
    // TODO test if YS YN received - This is done in didUpdateValueForCharacteristic() in BLE Manager.
// AlertViewDeprecated.
//    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"! Download Complete !" message:@"Device is Restarting\n\n Reconnect From the Home Screen" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
//    [alertView show];
    
    UIAlertController* endOfDownloadAlertController = [UIAlertController alertControllerWithTitle:@"! Download Complete !" message:@"Device is Restarting\n\n Reconnect From the Home Screen" preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction* okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
        [[BLEManager sharedService].centralManager cancelPeripheralConnection:updatePeripheral.peripheral];
        [[NSNotificationCenter defaultCenter] postNotificationName:FIRMWARE_UPDATE_COMPLETE object:nil userInfo:nil];
    }];
    [endOfDownloadAlertController addAction:okAction];
    [self.presentingViewController presentViewController:endOfDownloadAlertController animated:YES completion:nil];
// AlertViewDeprecated.

}

-(void)abortDownload {
    [self.recoveryTimer invalidate];
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"! Down Failure !" message:@"Restart Device and Restart Download" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alertView show];
}


- (void)processNextChunkOfCurrentBlock {
    
    if (!self.txComplete) {
        [self sendData:updatePeripheral.peripheral];
        return;
    }
}

/** Sends the next amount of data to the Peripheral
 */
- (void)sendData:(CBPeripheral *)selectedPeripheral
{
    // First up, check if we're meant to be sending an EOM
    if (selectedPeripheral.state == CBPeripheralStateConnected) {
        
        // TODO - Need to confirm with ST which Service will be used.
        //
        CBCharacteristic *theCharacteristic =  [((CBService *)[selectedPeripheral.services objectAtIndex:0]).characteristics objectAtIndex:0];
        
        // Make the next chunk
        // Work out how big it should be
        NSInteger amountToSend = self.txData.length - self.sendDataIndex;
        
        // Can't be longer than 20 bytes
        if (amountToSend > 20) amountToSend = 20;
        
        // Copy out the data we want
        NSData *chunk = [NSData dataWithBytes:self.txData.bytes+self.sendDataIndex length:amountToSend];
        
        // Send it
        if (theCharacteristic != nil)
            [selectedPeripheral writeValue:chunk forCharacteristic:theCharacteristic type:CBCharacteristicWriteWithResponse];
        
        
        NSString *stringFromData = [[NSString alloc] initWithData:chunk encoding:NSUTF8StringEncoding];
        NSLog(@"Sent: %@", stringFromData);
        
        // It did send, so update our index
        self.sendDataIndex += amountToSend;
        NSLog(@"SendDataIndex: %ld", (long)self.sendDataIndex);

        // Was it the last one?
        if (self.sendDataIndex >= self.txData.length) {
            
            self.txComplete = TRUE;
        }
    }
}


@end
