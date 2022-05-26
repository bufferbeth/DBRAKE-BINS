//
//  BLEManager.h
//  DB Demo
//
//  Created by John Hewlin on 3/8/17.
//  Copyright © 2017 MiLife Solution. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import "BLEPeripheral.h"


#define UUIDSTR_ISSC_PROPRIETARY_SERVICE        @"49535343-FE7D-4AE5-8FA9-9FAFD205E455"
#define UUIDSTR_CONNECTION_PARAMETER_CHAR       @"49535343-6DAA-4D02-ABF6-19569ACA69FE"
#define UUIDSTR_ISSC_TRANS_TX                   @"49535343-1E4D-4BD9-BA61-23C647249616"
#define UUIDSTR_ISSC_TRANS_RX                   @"49535343-8841-43F4-A8D4-ECBE34729BB3"
#define UUIDSTR_ISSC_MP                         @"49535343-ACA3-481C-91EC-D85E28A60318"

#define UUIDSTR_ISSC_NEW                         @"49535343-4C8A-39B3-2F49-511CFF073B7E"



//#define cmdBrakeVersionString @"#06BV\r"
//#define cmdRemoteVersionString @"#06RV\r"
#define cmdBrakeVersionString @"BV"
#define cmdRemoteVersionString @"RV"
#define cmdDownloadBrakeString @"DB"
#define cmdDownloadRemoteString @"DR"




/**
 *
 *  Application CoreBluetooth Manager service for D-Brake.
 *  This class defines a singleton application service instance which manages access to
 *  the BLE devices via the CoreBluetooth API.
 *
 */
@interface BLEManager : NSObject <CBCentralManagerDelegate, CBPeripheralDelegate>


/**
 *  Return singleton instance.
 *  @return bleManager
 */
+ (BLEManager *)sharedBLEManager;
//+ (BLEManager *)initSharedServiceWithDelegate:(id)delegate;
- (BLEManager *)initSharedServiceWithDelegate:(id)delegate;


/**
 *  Return singleton instance.
 *  @return bleManager
 */
+ (BLEManager *)sharedService;


/**
 The CBCentralManager object.
 
 In typical practice, there is only one instance of CBCentralManager
 This class listens to CBCentralManagerDelegate messages sent by manager, which in turn forwards those messages to delegate.
 */
@property (nonatomic, retain) CBCentralManager *centralManager;


// Flag to determine if manager is scanning.
@property (atomic, assign) BOOL isScanning;

#pragma mark - Scan Methods
/** @name Scanning for Peripherals */
/**
 Start CoreBluetooth scan for peripherals. This method is to be overridden.
 
 The implementation of this method in a subclass must include the call to
 scanForPeripheralsWithServices:options:
 
 */
- (void)startScan;

/**
 Stop CoreBluetooth scan for peripherals.
 */
- (void)stopScan;



/**
 Array of Peripheral instances.
 
 This array holds all Peripheral instances discovered or retrieved by manager.
 */
@property (atomic, strong) NSMutableArray *peripheralsArray;



- (BOOL)sendCommandToDevice:(CBPeripheral *)peripheralDevice cmdString:(NSString *)cmdString;

// For Firmware Downloads.
- (BOOL)sendData:(BLEPeripheral *)blePeripheral;

@end
