//
//  BLEManager.m
//  DB Demo
//
//  Created by John Hewlin on 3/8/17.
//  Copyright © 2017 MiLife Solution. All rights reserved.
//

#import "BLEManager.h"


static BLEManager *bleManager;

@implementation BLEManager
@synthesize centralManager;



/**
 *************************************
 */
+ (BLEManager *)sharedBLEManager {
    if( bleManager == nil ) {
        @synchronized(self) {
            bleManager = [[BLEManager alloc] init];
            assert(bleManager != nil);
        }
    }
    return bleManager;
}

// Would not retain instance of 'central Manager'.
- (BLEManager *)initSharedServiceWithDelegate:(id)delegate {
    if( bleManager == nil )
    {
        if (bleManager == nil) {
            @synchronized (self) {
                bleManager = [[BLEManager alloc] init];
                centralManager = [CBCentralManager alloc];
                centralManager = [centralManager initWithDelegate:self queue:nil];
                bleManager.peripheralsArray = [[NSMutableArray alloc] init];
                //bleManager.knownPeripheralNames = [[ NSArray alloc] initWithObjects:@"Power Pole", @"Micro Anchor", nil];
                //bleManager.comminucationMode = COMM_MODE_NORMAL;
                assert(bleManager != nil);
            }
        }
    }
    return bleManager;
}



/**
 *************************************
 */
- (id)init {
    self = [super init];
    if (self) {
        // Custom initialization
        centralManager = [CBCentralManager alloc];
        centralManager = [centralManager initWithDelegate:self queue:nil];
        self.peripheralsArray = [[NSMutableArray alloc] init];
        //self.knownPeripheralNames = [[ NSArray alloc] initWithObjects:@"Power Pole", @"Micro Anchor", nil];
        //self.comminucationMode = COMM_MODE_NORMAL;
        
        //self.deviceInfoCommandStrings = [NSArray arrayWithObjects:cmdFirmwareVersionString, cmdBootLoaderVersionString, cmdConfigTable0String, cmdConfigTable1String, cmdConfigTable2String, cmdConfigTable3String, cmdEndOfConfigData, nil];
        //self.deviceHydroInfoCommandStrings = [NSArray arrayWithObjects:cmdFirmwareVersionString, cmdBootLoaderVersionString, cmdConfigTable0String, cmdConfigTable1String, cmdConfigTable2String, cmdConfigTable3String, cmdEndOfConfigData, nil];
        
    }
    return self;
}

/**
 *************************************
 */
+ (BLEManager *)sharedService {
    
    if (bleManager == nil) {
        NSLog(@"ERROR: must call initSharedServiceWithDelegate: first.");
    }
    return bleManager;
 }


/**
 *************************************
 */
- (void)stopScan {
    [self.centralManager stopScan];
    self.isScanning = NO;
}


/**
 *************************************
 */
- (void)startScan {
    //Setting CBCentralManagerScanOptionAllowDuplicatesKey to YES will allow for repeated updates of the RSSI via advertising.
    NSDictionary *options = @{ CBCentralManagerScanOptionAllowDuplicatesKey: @YES };
    if (self.centralManager.state == CBCentralManagerStatePoweredOn ) {
        [self.centralManager scanForPeripheralsWithServices:nil options:options];
        self.isScanning = YES;
        
        NSLog(@"Scanning started");

    }
}

#pragma mark - Central Methods



/** centralManagerDidUpdateState is a required protocol method.
 *  Usually, you'd check for other states to make sure the current device supports LE, is powered on, etc.
 *  In this instance, we're just using it to wait for CBCentralManagerStatePoweredOn, which indicates
 *  the Central is ready to be used.
 */
- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    if (central.state != CBCentralManagerStatePoweredOn) {
        // In a real app, you'd deal with all the states correctly
        return;
    }
    
    // The state must be CBCentralManagerStatePoweredOn...
    
    // ... so start scanning
    //[self scan];
    
}



/** This callback comes whenever a peripheral that is advertising the TRANSFER_SERVICE_UUID is discovered.
 *  We check the RSSI, to make sure it's close enough that we're interested in it, and if it is,
 *  we start the connection process
 */
- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
    // Reject any where the value is above reasonable range
    if (RSSI.integerValue > -15) {
        return;
    }
    
    // Reject if the signal strength is too low to be close enough (Close is around -22dB)
    //    if (RSSI.integerValue < -35) {
    //        return;
    //    }
    NSString *BLMnameString = [advertisementData valueForKey:CBAdvertisementDataLocalNameKey];

    if (![peripheral.name containsString:@"BM71"] && ![BLMnameString containsString:@"BM71"]) {
//        NSLog(@"Advertising Name = %@", BLMnameString);
//        NSString *UUIDString = [advertisementData valueForKey:CBAdvertisementDataServiceUUIDsKey];
//        NSLog(@"UUID String = %@", UUIDString);
        if (peripheral.name == NULL)
            return;
    }
    
    NSString *nameString = [advertisementData valueForKey:CBAdvertisementDataLocalNameKey];
    NSLog(@"Advertising Name = %@", nameString);
    NSLog(@"Discovered %@ at %@", peripheral.name, RSSI);
    
    //if ([nameString hasPrefix:@"BM71"]) {
        BLEPeripheral *blePerpiheral = [self bleManagerAddPeripheral:peripheral advertisementData:advertisementData RSSI:RSSI];
        blePerpiheral.blePeripheralCommunicationState = blePeripheralCommunicationStateIdle;

        //if ( blePerpiheral!= nil) {
        NSDictionary* infoDict = @{@"blePeripheral":blePerpiheral};
        [[NSNotificationCenter defaultCenter] postNotificationName:@"NewPeripheralDiscovered" object:nil userInfo:infoDict];
        //}
        
        peripheral.delegate = self;
    //}
}


/** If the connection fails for whatever reason, we need to deal with it.
 */
- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    NSLog(@"Failed to connect to %@. (%@)", peripheral, [error localizedDescription]);
    [self cleanup];
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    NSLog(@"Disconnect: %@", peripheral.name);
    NSLog(@" ");
    
    NSDictionary* infoDict = @{@"peripheral":peripheral};
    [[NSNotificationCenter defaultCenter] postNotificationName:@"PeripheralDisconnected" object:nil userInfo:infoDict];

}




/** We've connected to the peripheral, now we need to discover the services and characteristics to find the 'transfer' characteristic.
 */
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    NSLog(@"Peripheral Connected");
    
    // Stop scanning
    [self.centralManager stopScan];
    NSLog(@"Scanning stopped");
    
    // Clear the data that we may already have
    //[self.data setLength:0];
    NSDictionary* infoDict = @{@"peripheral":peripheral};
    [[NSNotificationCenter defaultCenter] postNotificationName:@"PeripheralConnected" object:nil userInfo:infoDict];

    // Make sure we get the discovery callbacks
    peripheral.delegate = self;
    
    // Search only for services that match our UUID
    //[peripheral discoverServices:@[[CBUUID UUIDWithString:TRANSFER_SERVICE_UUID]]];
    [peripheral discoverServices:nil];
    
}


/** The Transfer Service was discovered
 
 - (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
 {
 if (error) {
 NSLog(@"Error discovering services: %@", [error localizedDescription]);
 [self cleanup];
 return;
 }
 
 // Discover the characteristic we want...
 
 // Loop through the newly filled peripheral.services array, just in case there's more than one.
 for (CBService *service in peripheral.services) {
 [peripheral discoverCharacteristics:@[[CBUUID UUIDWithString:TRANSFER_CHARACTERISTIC_UUID]] forService:service];
 }
 }
 */

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {
    if (error) {
        NSLog(@"Error discovering services: %@", [error localizedDescription]);
        [self cleanup];
        return;
    }
    for(CBService *service in peripheral.services) {
        //        NSLog(@"Device Name: %@", peripheral.name);
        NSLog(@"Service UUID: %@", service.UUID);
        [peripheral discoverCharacteristics:nil forService:service];
    }
    //NSLog(@" ");
}


    
/** The Transfer characteristic was discovered.
 *  Once this has been found, we want to subscribe to it, which lets the peripheral know we want the data it contains
 */
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error {
    // Deal with errors (if any)
    if (error) {
        NSLog(@"Error discovering characteristics: %@", [error localizedDescription]);
        [self cleanup];
        return;
    }
    
    BLEPeripheral *blePeripheral = [self findBLEPeripheralForCBPeripheral:peripheral];

    // Again, we loop through the array, just in case.
    for (CBCharacteristic *characteristic in service.characteristics) {
        NSLog(@"\n");
        [peripheral setNotifyValue:YES forCharacteristic:characteristic];
        NSLog(@"Service-Characteristic = %@-%@", service.UUID, characteristic);

        
        // MICROCHIP

        if ([service.UUID isEqual:[CBUUID UUIDWithString:UUIDSTR_ISSC_PROPRIETARY_SERVICE]]) {
            //if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:UUIDSTR_ISSC_NEW]]) {
            if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:UUIDSTR_ISSC_TRANS_TX]]) {
                
                blePeripheral.dataSendService = service;
                blePeripheral.dataSendCharacteristic = characteristic;
                //blePeripheral.characteristicWriteType = CBCharacteristicWriteWithoutResponse;
                blePeripheral.characteristicWriteType = CBCharacteristicWriteWithResponse;
                
                blePeripheral.blePeripheralCommunicationState = blePeripheralCommunicationStateIdle;
                blePeripheral.communicationRetryCount = 0;

                // Early Test Code.
                //[self sendCommandToDevice:blePeripheral.peripheral cmdString:cmdBrakeVersionString];
            }
        }
      
    }
    
    // Once this is complete, we just need to wait for the data to come in.
}

/**
 *************************************
 *
 Send Command to Power Pole Device
 @param string matching Command
 @return
 */
#define replyDataMaxSize    250


- (BOOL)sendCommandToDevice:(CBPeripheral *)peripheralDevice cmdString:(NSString *)cmdString {
    
    BLEPeripheral *blePeripheral = [self findBLEPeripheralForCBPeripheral:peripheralDevice];
    
    if (blePeripheral.blePeripheralCommunicationState == blePeripheralCommunicationStateIdle || blePeripheral.blePeripheralCommunicationState == blePeripheralCommunicationStateUnknown) {
        blePeripheral.commandString = cmdString;
        
        // Initialize the Reply Data Container.
        blePeripheral.replyData = [NSMutableData dataWithCapacity:replyDataMaxSize];
        
        // Build the command packet
        NSString *startChar = @"#";
        
        NSMutableData *packetData = [[NSMutableData alloc] initWithCapacity:1024];
        [packetData appendData:[startChar dataUsingEncoding:NSStringEncodingConversionAllowLossy]];

        
        NSString *commandChars = cmdString;
        NSData *commandCharsData = [commandChars dataUsingEncoding:NSUTF8StringEncoding];
        
        NSString *terminateChar = @"\r";
        NSData *terminateCharData = [terminateChar dataUsingEncoding:NSUTF8StringEncoding];


        NSMutableData *lengthData = [[NSMutableData alloc] initWithCapacity:4];
        NSMutableData *cmdData = [[NSMutableData alloc] initWithCapacity:1024];
        
        NSInteger packetLength1;
        NSInteger packetLength2;

        // For the different Commands, add relevant data.
        if ([cmdString isEqualToString:cmdBrakeVersionString] || [cmdString isEqualToString:cmdRemoteVersionString]) {
            // There is no command data
            packetLength1 = 0x00;
            packetLength2 = 0x06;
            [lengthData appendBytes:&packetLength1 length:1];
            [lengthData appendBytes:&packetLength2 length:1];
        }
        else if ([cmdString isEqualToString:cmdDownloadBrakeString]){
            
            /*
            NSLog(@"Download Brake Version - Test No Response Timeout");
            // Test Code.
            // blePeripheral.commandString = @"";
            blePeripheral.blePeripheralCommunicationState = blePeripheralCommunicationStateRequestPending;
            // Start a timer for the response.
            if (![blePeripheral.communicationResponseTimeout isValid]) {
                blePeripheral.communicationResponseTimeout = [NSTimer scheduledTimerWithTimeInterval:2 target:self selector:@selector(communicationResponseTimeOut:) userInfo:blePeripheral repeats:NO];
            }
            return TRUE;
             
             2017-03-20 15:27:25.866 DB Demo[1696:1730185] Firmware Data Length - 81896
             2017-03-20 15:27:38.184 DB Demo[1696:1730185] Firmware Data - <efcdab89 aefd0103 e83f0100 20870000 06000000 53000000 57000000 30000000 34000000 32000000 70000000 98badcfe 00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000 00000000
             
             aefd0103 – checksum of the .bin 0x0301fdae
             e83f0100 – length  = 0x00013f8e = 81,806 decimal
             20870000 – this is the firmware version 0x00008720 = version 00.87”space”
             
             The file checksum state is not right. But the checksum ing is done right after the 0xfedcba98 delimiter

             Comment Packet Data - <23001844 4200e83f 0100aefd 010398ba dcfe2087 0000a00d>
            */
            
            packetLength1 = 0x00;
            packetLength2 = 0x18;
            [lengthData appendBytes:&packetLength1 length:1];
            [lengthData appendBytes:&packetLength2 length:1];
            
            
            // Add to the command data.
            NSInteger packetNumber = 0x00;
            [cmdData appendBytes:&packetNumber length:1];
            
            NSURL* url = [[NSBundle mainBundle] URLForResource:@"sw042-00_87" withExtension:@"bin"];
            NSData *firmwareData = [[NSData dataWithContentsOfURL:url] mutableCopy];

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
            
        }
        else if ([cmdString isEqualToString:cmdDownloadRemoteString]){
            
            packetLength1 = 0x00;
            packetLength2 = 0x18;
            [lengthData appendBytes:&packetLength1 length:1];
            [lengthData appendBytes:&packetLength2 length:1];
            
            
            // Add to the command data.
            NSInteger packetNumber = 0x00;
            [cmdData appendBytes:&packetNumber length:1];
            
            NSURL* url = [[NSBundle mainBundle] URLForResource:@"sw042-00_87" withExtension:@"bin"];
            NSData *firmwareData = [[NSData dataWithContentsOfURL:url] mutableCopy];
            
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

        }
        
        // Add the data pieces to the command packet
        [packetData appendData:lengthData];
        [packetData appendData:commandCharsData];
        [packetData appendData:cmdData];
        [packetData appendData:terminateCharData];
        
        NSLog(@"Packet Data - %@", packetData);
        
        NSData *chunk = [NSData dataWithBytes:packetData.bytes length:packetData.length];
        NSLog(@"Chunk Data- %@", chunk);
        
/*
        NSInteger packetSize1 = 0x00;
        NSInteger packetSize2 = 0x06;
        NSLog(@"Command Char Data- %@", commandCharsData);
        // Create the first Block with the FileName.
        NSMutableData *firstBlockData = [[NSMutableData alloc] initWithCapacity:1024];
        [firstBlockData appendData:[startChar dataUsingEncoding:NSStringEncodingConversionAllowLossy]];
        [firstBlockData appendBytes:&packetSize1 length:1];
        [firstBlockData appendBytes:&packetSize2 length:1];
        //[firstBlockData appendBytes:(__bridge const void * _Nonnull)(commandCharsData) length:[commandCharsData length]];
        [firstBlockData appendData:[commandChars dataUsingEncoding:NSStringEncodingConversionAllowLossy]];
        [firstBlockData appendData:[terminateChar dataUsingEncoding:NSStringEncodingConversionAllowLossy]];
        NSLog(@"Command Data- %@", firstBlockData);
        NSData *chunk = [NSData dataWithBytes:firstBlockData.bytes length:firstBlockData.length];
        NSLog(@"Chunk Data- %@", chunk);
*/
        
        if (peripheralDevice.state == CBPeripheralStateConnected) {
            
            // The 'dataSendCharacteristic' is set during the discovery of Services and Characteristics, after Connection is established.
            CBCharacteristic *theCharacteristic = blePeripheral.dataSendCharacteristic;
            if (theCharacteristic && peripheralDevice.state == CBPeripheralStateConnected) {
                
                [peripheralDevice writeValue:chunk forCharacteristic:theCharacteristic type:blePeripheral.characteristicWriteType];
                blePeripheral.blePeripheralCommunicationState = blePeripheralCommunicationStateRequestPending;
                
                // Start a timer for the response if not running
                if (![blePeripheral.communicationResponseTimeout isValid]) {
                    blePeripheral.communicationResponseTimeout = [NSTimer scheduledTimerWithTimeInterval:2 target:self selector:@selector(communicationResponseTimeOut:) userInfo:blePeripheral repeats:NO];
                }
 
                return TRUE;
            }
        }
        else {
            blePeripheral.commandString = @"";
            return FALSE;
        }
    }
    return FALSE;
}



/**
 *************************************
 * Sends the next amount of data to the Peripheral
 */
- (BOOL)sendData:(BLEPeripheral *)blePeripheral {
    
    if (blePeripheral.peripheral.state == CBPeripheralStateConnected  && blePeripheral.blePeripheralCommunicationState == blePeripheralCommunicationStateIdle) {
        
        if (blePeripheral.dataSendCharacteristic != nil) {
            NSInteger amountToSend = blePeripheral.transmitData.length - blePeripheral.sendDataIndex;
            
/*
            if (blePeripheral.bleHardWareType == bleHardwareTypeSTMicro) {
                // Cannot be longer than 20 bytes for the ST Micro.
                if (amountToSend > 20) {
                    amountToSend = 20;
                }
                //                if (amountToSend > 100) {
                //                    amountToSend = 100;
                //                }
                
            }
            else if (blePeripheral.bleHardWareType == bleHardwareTypeMicrochip) {
                // Cannot be longer than ?? bytes for the Microchip.
                // TODO
                // Check if Microchip will accept more.
                if (amountToSend > 100) {
                    amountToSend = 100;
                }
                //                if (amountToSend > 20) {
                //                    amountToSend = 20;
                //                }
            }
*/
            if (amountToSend > 120) {
                amountToSend = 120;
            }
            
            // Initialize the Reply Data Container.
            blePeripheral.replyData = [NSMutableData dataWithCapacity:replyDataMaxSize];
            
            // Copy out the data we want
            NSData *chunk = [NSData dataWithBytes:blePeripheral.transmitData.bytes+blePeripheral.sendDataIndex length:amountToSend];
            
            NSString *stringFromData = [[NSString alloc] initWithData:chunk encoding:NSUTF8StringEncoding];
            NSLog(@"Sent: %@", stringFromData);
            
            // It did send, so update our index
            blePeripheral.sendDataIndex += amountToSend;
            NSLog(@"SendDataIndex: %ld", (long)blePeripheral.sendDataIndex);
            
            // Was it the last one?
            if (blePeripheral.sendDataIndex >= blePeripheral.transmitData.length) {
                blePeripheral.txComplete = TRUE;
            }
            //if (blePeripheral.bleHardWareType == bleHardwareTypeMicrochip) {
                //[blePeripheral.peripheral writeValue:chunk forCharacteristic:blePeripheral.dataSendCharacteristic type:CBCharacteristicWriteWithResponse];
                //                [blePeripheral.peripheral writeValue:chunk forCharacteristic:blePeripheral.dataSendCharacteristic type:blePeripheral.characteristicWriteType];
                //                blePeripheral.communicationTimerTimeout = [NSTimer scheduledTimerWithTimeInterval:0.01 target:self selector:@selector(firmwareDownloadTimer:) userInfo:blePeripheral repeats:YES];
                //                [[NSRunLoop mainRunLoop] addTimer:blePeripheral.communicationTimerTimeout forMode:NSRunLoopCommonModes];
            //}
           // else {
                [blePeripheral.peripheral writeValue:chunk forCharacteristic:blePeripheral.dataSendCharacteristic type:blePeripheral.characteristicWriteType];
           // }
            return TRUE;
        }
    }
    return FALSE;
}




- (void)communicationResponseTimeOut: (NSTimer *)timer {
    // Check which peripheral's timer has timed out.
    for(BLEPeripheral *blePeripheral in self.peripheralsArray) {
        if (blePeripheral == timer.userInfo ) {
            [blePeripheral.communicationResponseTimeout invalidate];
            if (blePeripheral.peripheral.state == CBPeripheralStateDisconnected) {
                // Re-connection will re-establish the commuication State.
                NSLog(@"Response Timeout-Disconnection: %@", blePeripheral.deviceName);
            }
            else {
                if (blePeripheral.communicationRetryCount++ >= 5) {
                    // Stop re-trying.
                    blePeripheral.communicationRetryCount = 0;
                    blePeripheral.blePeripheralCommunicationState = blePeripheralCommunicationStateIdle;
                    NSLog(@"Command Failed");
                }
                else {
                    // Retry the current command.
                    if ([blePeripheral.commandString length] != 0 && blePeripheral.blePeripheralCommunicationState == blePeripheralCommunicationStateRequestPending) {
                        blePeripheral.blePeripheralCommunicationState = blePeripheralCommunicationStateIdle;  // Do this to allow 'sendCommand' to re-send
                        [self sendCommandToDevice:blePeripheral.peripheral cmdString:blePeripheral.commandString];

                    }
                }
            }
        }
    }

}


/**
 *************************************
 * The 'writeValue' to the Mircochip does NOT allow use of 'writeWithResponse'.
 * The 'writeValue' to the ST REQUIRES the use of 'writeWithResponse', otherwise there will be NO response from the Applice Layer protocol.
 */
- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    
    BLEPeripheral *blePeripheral = [self findBLEPeripheralForCBPeripheral:peripheral];
    
    //NSLog(@"ACK REPLY RECEIVED - Service-Characteristic = %@-%@", characteristic.service.UUID, characteristic);

    // NSLog(@"Peripheral.senddataindex: %ld", (long)blePeripheral.sendDataIndex);
    if (error) {
        NSLog(@"Write to Characteristic Error: %@", [error localizedDescription]);
        return;
    }
    else {
        
        //        if (self.bleManager.comminucationMode == COMM_MODE_FW_DOWNLOAD) {
        //            [self.firmwareUpdate processNextChunkOfCurrentBlock];
        //            return;
        //        }
        //
        //
        if (blePeripheral.blePeripheralState == blePeripheralStateSendingData) {
            if (!blePeripheral.txComplete) {
                [self sendData:blePeripheral];
            }
        }
    }
    
    
}


- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    
    BLEPeripheral *blePeripheral = [self findBLEPeripheralForCBPeripheral:peripheral];
    NSLog(@"Reply bytes: %@", characteristic.value);

    // In Dbrake App protocol there are 00s in the data and thus string conversion is not advised.
    //
    //NSMutableString *stringFromData = [[NSMutableString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding];
    [blePeripheral.replyData appendData:characteristic.value];
    //[stringFromData replaceOccurrencesOfString:@"\n" withString:@"" options:0 range:NSMakeRange(0, [stringFromData length])];
    
    // Check for EoM.
    // Get last byte of received data and check for "\r"
    NSString *terminateChar = @"\r";
    NSData *terminateCharData = [terminateChar dataUsingEncoding:NSUTF8StringEncoding];
    NSData *lastByteData = [blePeripheral.replyData subdataWithRange:NSMakeRange([blePeripheral.replyData length]-1, 1)];
    
    if ([lastByteData isEqualToData:terminateCharData]) {
    //if ([stringFromData hasSuffix:@"\r"]) {
        
        NSMutableData *replyData = [[NSMutableData alloc] initWithCapacity:[blePeripheral.replyData length]];
        replyData = [blePeripheral.replyData mutableCopy];
        
        if ([replyData length] < 3) {
            NSLog(@"Invalid Data Packet");
            NSMutableDictionary* infoDict = [[NSMutableDictionary alloc] init];
            [infoDict setObject:peripheral forKey:@"peripheral"];
            [infoDict setObject:@"Invalid packet length < 3" forKey:@"PacketDataString"];
            [infoDict setObject:replyData forKey:@"ReplyData"];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"DiagnosticDataReceived" object:nil userInfo:infoDict];
            return;
        }
        
        // Length is bytes 2 & 3
        // NSInteger lenghtLowByte = [replyData]
        NSRange range = {1, 2};
        NSMutableData *receivedLengthData = [[characteristic.value subdataWithRange:range] mutableCopy];
        NSLog(@"Reply Data for Length: %@", receivedLengthData);
        
        NSRange highByteRange = {0, 1};
        NSData *lengthHighByte = [receivedLengthData subdataWithRange:highByteRange];
        unsigned char *highByte = (unsigned char *)[lengthHighByte bytes];
        int *hbyteptr = (int *)&highByte[0];
        int hbyte = hbyteptr[0];
        NSLog(@"Length High Byte: %li", (long)hbyte);

        NSRange lowByteRange = {1, 1};
        NSData *lengthLowByte = [receivedLengthData subdataWithRange:lowByteRange];
        unsigned char *lowByte = (unsigned char *)[lengthLowByte bytes];
        int *lbyteptr = (int *)&lowByte[0];
        int lbyte = lbyteptr[0];
        NSLog(@"Length Low Byte: %li", (long)lbyte);
        
        NSInteger length = (hbyte << 8) + lbyte;
        NSLog(@"Length: %li", (long)length);
        
        if ([replyData length] < length + 2) {
            NSLog(@"Invalid packet based on length");
            NSMutableDictionary* infoDict = [[NSMutableDictionary alloc] init];
            [infoDict setObject:peripheral forKey:@"peripheral"];
            [infoDict setObject:@"Invalid packet based on length" forKey:@"PacketDataString"];
            [infoDict setObject:replyData forKey:@"ReplyData"];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"DiagnosticDataReceived" object:nil userInfo:infoDict];
            return;
        }
        
        NSRange packetDataRange = {3, length-2};
        NSData *packetData = [replyData subdataWithRange:packetDataRange];
        NSLog(@"Packet Reply Data: %@", packetData);
        NSMutableString *replyDataString = [[NSMutableString alloc] initWithData:packetData encoding:NSUTF8StringEncoding];
        NSLog(@"Packet Reply String: %@", replyDataString);
        
        // Reply bytes: <23000962 7630302e 38380d>
        // Packet Reply Data: <62763030 2e3838>

        // Check for the Op Code.......
        NSRange opCodeRange = {3,2};
        NSData *opCodeData = [replyData subdataWithRange:opCodeRange];
        
        NSMutableData *compareData = [[NSMutableData alloc] initWithCapacity:2];
        NSInteger packetData1 = 0X62;
        NSInteger packetData2 = 0X74;
        //NSInteger packetData2 = 0X76; //- Test Code

        [compareData appendBytes:&packetData1 length:1];
        [compareData appendBytes:&packetData2 length:1];


        // Re-init the buffer.
        blePeripheral.replyData = [NSMutableData dataWithCapacity:replyDataMaxSize];
        [blePeripheral.communicationResponseTimeout invalidate];
        blePeripheral.communicationRetryCount = 0;
        blePeripheral.blePeripheralCommunicationState = blePeripheralCommunicationStateIdle;

        // IF Op Code is 0x6274 ("bt")
        if ([opCodeData isEqualToData:compareData]) {
            NSLog (@"OpCode Data: %@", opCodeData);
            NSMutableDictionary* infoDict = [[NSMutableDictionary alloc] init];
            [infoDict setObject:peripheral forKey:@"peripheral"];
            [infoDict setObject:replyDataString forKey:@"PacketDataString"];
            NSRange diagnosticDataRange = {0, length+2};
            NSData *diagnosticData = [replyData subdataWithRange:diagnosticDataRange];
            [infoDict setObject:diagnosticData forKey:@"ReplyData"];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"DiagnosticDataReceived" object:nil userInfo:infoDict];
        }
        else if ([blePeripheral.commandString isEqualToString:cmdBrakeVersionString]) {
            blePeripheral.brakeVersionString = [replyDataString mutableCopy];
            NSDictionary* infoDict = @{@"peripheral":peripheral};
            [[NSNotificationCenter defaultCenter] postNotificationName:@"ReplyReceivedForBrakeVersion" object:nil userInfo:infoDict];
        }
        else if ([blePeripheral.commandString isEqualToString:cmdRemoteVersionString]) {
            blePeripheral.remoteVersionString = [replyDataString mutableCopy];
            NSDictionary* infoDict = @{@"peripheral":peripheral};
            [[NSNotificationCenter defaultCenter] postNotificationName:@"ReplyReceivedForBrakeVersion" object:nil userInfo:infoDict];

        }
        else if ([blePeripheral.commandString isEqualToString:cmdDownloadBrakeString]) {
            // What's in the reply packet??
            // Reply bytes: <23000964 62303000 a0000d>
            // Packet Reply Data: <64623030 00a000>
            
            //NSString *ackChar = @"\r";
            //NSData *ackCharData = [ackChar dataUsingEncoding:NSUTF8StringEncoding];
            //NSData *ackByteData = [packetData subdataWithRange:NSMakeRange(0, 1)];
            
            ////if ([ackByteData isEqualToData:ackCharData]) {
                blePeripheral.blePeripheralState = BLEPeripheralStateFirmwareDownload;
                
                NSDictionary* infoDict = @{@"peripheral":peripheral};
                [[NSNotificationCenter defaultCenter] postNotificationName:@"ReplyReceivedForBrakeDownload" object:nil userInfo:infoDict];

                //[self sendNextFirmwareDownloadPacket:blePeripheral.peripheral];
            //}
        }
        else if ([blePeripheral.commandString isEqualToString:cmdDownloadRemoteString]) {
            blePeripheral.blePeripheralState = BLEPeripheralStateFirmwareDownload;
            
            NSDictionary* infoDict = @{@"peripheral":peripheral};
            [[NSNotificationCenter defaultCenter] postNotificationName:@"ReplyReceivedForRemoteDownload" object:nil userInfo:infoDict];

        }


    }
   
}

-(void)sendNextFirmwareDownloadPacket:(CBPeripheral *)peripheralDevice {
    
}


/**
 *************************************
 */
/**
 Find BLE Peripheral instance matching CBPeripheral
 @param peripheral corresponding with CBPeripheral
 @return instance of BLEPeripheral
 */
- (BLEPeripheral *)findBLEPeripheralForCBPeripheral:(CBPeripheral *)peripheral {
    
    BLEPeripheral *blePeripheral = nil;
    
    for(BLEPeripheral *blePeripheral in self.peripheralsArray)
    {
        if (blePeripheral.peripheral == peripheral) {
            
            return blePeripheral;
        }
    }
    return blePeripheral;
}

/** Call this when things either go wrong, or you're done with the connection.
 *  This cancels any subscriptions if there are any, or straight disconnects if not.
 *  (didUpdateNotificationStateForCharacteristic will cancel the connection if a subscription is involved)
 */
- (void)cleanup
{
    // Don't do anything if we're not connected
    //    if (!self.discoveredPeripheral.isConnected) {
    //        return;
    //    }
    
    // See if we are subscribed to a characteristic on the peripheral
    //if (self.discoveredPeripheral.services != nil) {
        //for (CBService *service in self.discoveredPeripheral.services) {
            //if (service.characteristics != nil) {
                //for (CBCharacteristic *characteristic in service.characteristics) {
                    
                    /*
                     if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:TRANSFER_CHARACTERISTIC_UUID]]) {
                     if (characteristic.isNotifying) {
                     // It is notifying, so unsubscribe
                     [self.discoveredPeripheral setNotifyValue:NO forCharacteristic:characteristic];
                     
                     // And we're done.
                     return;
                     }
                     }
                     */
               // }
           //}
       // }
    //}
    
    // If we've got this far, we're connected, but we're not subscribed, so we just disconnect
    //[self.centralManager cancelPeripheralConnection:self.discoveredPeripheral];
}



/**
 *************************************
 */
/** @name
 *  Add peripheral to peripherals array if it does not exist.
 */
- (BLEPeripheral *) bleManagerAddPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
    for(BLEPeripheral *blePeripheral in self.peripheralsArray)
    {
        if (blePeripheral.peripheral == peripheral) {
            // Peripheral already exists.  Update the data received.
            blePeripheral.deviceName = [advertisementData valueForKey:CBAdvertisementDataLocalNameKey];
            blePeripheral.rssiValue = RSSI;
            if ([blePeripheral.communicationTimerTimeout isValid]) {
                [blePeripheral.communicationTimerTimeout invalidate];
            }
            // NSLog(@"blePeripheral.peripheral:%@", blePeripheral.peripheral);
            [blePeripheral.communicationTimerTimeout invalidate];
            blePeripheral.communicationTimerTimeout = [NSTimer scheduledTimerWithTimeInterval:30 target:self selector:@selector(communicationTimeOut:) userInfo:blePeripheral repeats:YES];
            [[NSRunLoop mainRunLoop] addTimer:blePeripheral.communicationTimerTimeout forMode:NSRunLoopCommonModes];
            return blePeripheral;
            //return nil;
        }
    }
    
    // Peripheral was not in the current devices array.
    BLEPeripheral *newPeripheral = [[BLEPeripheral alloc] init];
    newPeripheral.peripheral = peripheral;
    newPeripheral.deviceName = [advertisementData valueForKey:CBAdvertisementDataLocalNameKey];
    newPeripheral.rssiValue = RSSI;
    newPeripheral.identifier = peripheral.identifier;
    newPeripheral.communicationTimerTimeout = [NSTimer scheduledTimerWithTimeInterval:30 target:self selector:@selector(communicationTimeOut:) userInfo:newPeripheral repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:newPeripheral.communicationTimerTimeout forMode:NSRunLoopCommonModes];
    [self.peripheralsArray addObject:newPeripheral];
    return newPeripheral;
}

/**
 *************************************
 */
/**
 *  A peripheral Connection has timed out.
 *  When Advertising data is received from the Peripheral, the timer is restarted.
 *  The blePeripheral is removed from the 'peripheralsArray' if the timer times out.
 *  @param timer for peripheral
 */
- (void)communicationTimeOut: (NSTimer *)timer {
    // Check which peripheral's timer has timed out.
    for(BLEPeripheral *blePeripheral in self.peripheralsArray) {
        if (blePeripheral == timer.userInfo ) {
            // If it is connected, the 'disconnect' will handle this.
            // If it is not connected, and just advertising, remove it from self.peripheralsArray.
            if (blePeripheral.peripheral.state == CBPeripheralStateDisconnected) {
                NSLog(@"Timeout: %@", blePeripheral.deviceName);
                [self.peripheralsArray removeObject:blePeripheral];
                [[NSNotificationCenter defaultCenter] postNotificationName:@"PeripheralStoppedAdvertising" object:nil userInfo:timer.userInfo];
                break;
            }
            
            // TODO
            // Notify the current View Controller.... ??
        }
    }
}



@end
