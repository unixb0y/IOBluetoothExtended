//
//  Commands.h
//  IOBluetoothExtended
//
//  Created by Davide Toldo on 06.07.19.
//  Copyright © 2019 Davide Toldo. All rights reserved.
//

#ifndef Commands_h
#define Commands_h

@interface Commands: NSObject

+ (void) readConnectionAcceptTimeout;
+ (void) readLocalVersionInformation;
+ (void) readBDAddr;

+ (void) sendArbitraryCommand:(long long)arg1;

@end

#endif /* Commands_h */
