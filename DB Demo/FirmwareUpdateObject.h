//
//  FirmwareUpdateObject.h
//  CMONSTER
//
//  Created by John Hewlin on 12/23/14.
//  Copyright (c) 2014 JL MARINE. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MBProgressHUD.h"
#import "BLEPeripheral.h"


// Firmware Update Types
enum
{
    FIRMWARE_UPDATE_UNDEFINED,
    FIRMWARE_UPDATE_BRAKE_FIRMWARE,
    FIRMWARE_UPDATE_REMOTE_FIRMWARE,
    FIRMWARE_UPDATE_TEST_FIRMWARE,
    
};


// Block Completions Types.
typedef void (^FirmwareUpdateManagerResultBlock)(NSInteger result);



enum ControlCharacters
{
    SOH = 0x01,
    STX = 0x02,
    EOT = 0x04,
    ACK = 0x06,
    NAK = 0x15,
    CAN = 0x18
};


#define FIRMWARE_UPDATE_COMPLETE @"FirmwareUpdateComplete"
#define FIRMWARE_UPDATE_ABORTED @"FirmwareUpdateAborted"


@interface FirmwareUpdateObject : NSObject


@property (nonatomic, retain) NSTimer *recoveryTimer;

@property (nonatomic, readwrite) NSInteger  firmwareSendDataIndex;
@property (nonatomic, retain) NSMutableData *firmwareData;
@property (nonatomic, readwrite) BOOL       firmwareTXComplete;

// AlertViewDeprecated.
@property (nonatomic, retain) MBProgressHUD* m_HUD;
@property (nonatomic, retain) UIViewController *presentingViewController;

// AlertViewDeprecated.


/**
 *  Update the Power Pole's firmware
 *  @params blePeripheral for Power Pole,
 */
- (void) updateFirmwareForDevice:(BLEPeripheral *)blePeripheral updateType:(NSInteger)updateType;

- (void)processFirmwareDownloadReply;
- (void)processNextChunkOfCurrentBlock;
- (void)endOfDownLoad;
- (void)abortDownload;

- (void)processDeviceDisconnect;

@end
