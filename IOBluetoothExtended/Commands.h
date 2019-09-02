//
//  Commands.h
//  IOBluetoothExtended
//
//  Created by Davide Toldo on 06.07.19.
//  Copyright © 2019 Davide Toldo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <IOBluetooth/IOBluetooth.h>
#import "IOBluetoothHostController.h"

#ifndef Commands_h
#define Commands_h

@interface HCIDelegate: NSObject

@property (nonatomic, assign) unsigned short waitingFor;
+ (void) setWaitingFor:(unsigned short)arg1;

@end

@interface Commands: NSObject

+ (void) readConnectionAcceptTimeout;
+ (void) readLocalVersionInformation;
+ (void) readBDAddr;

+ (void) sendArbitraryCommand:(long long)arg1;
+ (NSArray *) sendArbitraryCommand4:(uint8_t [])arg1 len:(uint8_t)arg2;

+ (void) setDelegate:(HCIDelegate*)arg1 of:(IOBluetoothHostController*)arg2;

@end

#endif /* Commands_h */
