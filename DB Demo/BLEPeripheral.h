//
//  BLEPeripheral.h
//  DB Demo
//
//  Created by John Hewlin on 3/8/17.
//  Copyright © 2017 MiLife Solution. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>





@interface BLEPeripheral : NSObject

@property (retain) CBPeripheral *peripheral;
@property (retain) NSString *deviceName;
@property (retain) NSNumber *rssiValue;
@property (retain) NSString *userName;


/*
 * When a Peripheral is discovered, the System assigns it a UUID.
 * By Saving this with the BLE Peripheral Object, we can use this to retrieve the specific Peripheral.
 */
@property (retain) NSUUID *identifier;


/**
 Communication timer in seconds.  This is for Advertising.
 */
@property (nonatomic, weak) NSTimer *communicationTimerTimeout;


@property (nonatomic, weak) NSTimer *communicationResponseTimeout;
@property NSInteger communicationRetryCount;

/**
 * BLE Service and Characteristic for Communication.
 *
 */
@property (nonatomic, retain) CBService * dataSendService;
@property (nonatomic, retain) CBCharacteristic * dataSendCharacteristic;
@property CBCharacteristicWriteType characteristicWriteType;


/*
 * Data Container for sending data to a Peripheral.
 */
@property (nonatomic, retain) NSMutableData *transmitData;
@property (nonatomic, readwrite) NSInteger  sendDataIndex;
@property (nonatomic, readwrite) BOOL       txComplete;
@property (nonatomic, readwrite) BOOL       txSuccessful;



/*
 * Data Container to accumulate data received from a Peripheral
 */
@property (nonatomic, retain) NSMutableData *replyData;

@property (nonatomic, retain) NSString *commandString;
@property (nonatomic, retain) NSMutableString *replyString;


/**
 * blePeripheral state for the Application Layer Protocol
 */
typedef enum {
    blePeripheralStateUnknown,
    blePeripheralStateConnected,
    BLEPeripheralStateFirmwareDownload,
    blePeripheralStateSendingData,

}BLEPeripheralState;

@property BLEPeripheralState blePeripheralState;



typedef enum {
    blePeripheralCommunicationStateUnknown,
    blePeripheralCommunicationStateIdle,
    blePeripheralCommunicationStateRequestPending,
    
}BLEPeripheralCommunicationState;


@property BLEPeripheralCommunicationState blePeripheralCommunicationState;

@property (nonatomic, retain) NSString *brakeVersionString;
@property (nonatomic, retain) NSString *remoteVersionString;


@end
