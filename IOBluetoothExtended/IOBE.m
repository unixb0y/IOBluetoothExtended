//
//  IOBE.m
//  IOBluetoothExtended
//
//  Created by Davide Toldo on 19.09.19.
//  Copyright © 2019 Davide Toldo. All rights reserved.
//

#import "IOBE.h"
#import "HCIDelegate.h"

@implementation IOBE

- (id) initWith:(NSString *)inject and:(NSString*)snoop {
    if (self = [super init]) {
        self->controller = IOBluetoothHostController.defaultController;
        self->delegate = [[HCIDelegate alloc] initWith:inject and:snoop];
        self->controller.delegate = self->delegate;
    }
    return self;
}

- (void) shutdown {
    [self->delegate shutdown];
}

@end
