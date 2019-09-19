//
//  Commands.m
//  IOBluetoothExtended
//
//  Created by Davide Toldo on 06.07.19.
//  Copyright © 2019 Davide Toldo. All rights reserved.
//

#import "Commands.h"
#import "IOBluetoothExtended/IOBluetoothExtended-Swift.h"

@implementation Commands

+ (void) readConnectionAcceptTimeout {
    // Read Connection Accept Timeout manually
    BluetoothHCIRequestID request = 0;
    char *output = malloc(255);
    size_t outputSize = sizeof(output);

    int error = BluetoothHCIRequestCreate(&request, 1000, nil, 0);

    NSLog(@"Created request: %u", request);

    if (error) {
        BluetoothHCIRequestDelete(request);
        printf("Couldn't create error: %08x\n", error);
    }

    size_t commandSize = 8;
    uint8 * command = malloc(commandSize); // 0x0c15
    command[0] = 0x15;
    command[1] = 0x0C;
    command[2] = 0;

    error = _BluetoothHCISendRawCommand(request, command, 3, &output, outputSize);

    if (error) {
        BluetoothHCIRequestDelete(request);
        printf("Send HCI command Error: %08x\n", error);
    }

    sleep(0x1);
    BluetoothHCIRequestDelete(request);
    NSLog(@"BluetoothHCIReadConnectionAcceptTimeout %d", output);
}

+ (void) readLocalVersionInformation {
    // 0x1001 : "COMND Read_Local_Version_Information"
    BluetoothHCIRequestID request = 0;
    char *output = malloc(255);
    size_t outputSize = sizeof(output);

    int error = BluetoothHCIRequestCreate(&request, 1000, nil, 0);

    NSLog(@"Created request: %u", request);

    if (error) {
        BluetoothHCIRequestDelete(request);
        printf("Couldn't create error: %08x\n", error);
    }

    size_t commandSize = 8;
    uint8 * command = malloc(commandSize); // 0x1001
    command[0] = 0x01;
    command[1] = 0x10;
    command[2] = 0;

    error = _BluetoothHCISendRawCommand(request, command, 3, &output, outputSize);

    if (error) {
        BluetoothHCIRequestDelete(request);
        printf("Send HCI command Error: %08x\n", error);
    }

    sleep(0x1);
    BluetoothHCIRequestDelete(request);
    NSLog(@"Local Version Information: %x", output);
}

+ (void) readBDAddr {
    // 0x1009 : "COMND Read_BD_ADDR"
    BluetoothHCIRequestID request = 0;
    uint8 output[8];
    size_t outputSize = sizeof(output);

    int error = BluetoothHCIRequestCreate(&request, 1000, nil, 0);
    //    NSLog(@"Created request: %u", request);

    if (error) {
        BluetoothHCIRequestDelete(request);
        printf("Couldn't create error: %08x\n", error);
    }

    size_t commandSize = 8;
    uint8 * command = malloc(commandSize); // 0x1009
    command[0] = 0x09;
    command[1] = 0x10;

    error = _BluetoothHCISendRawCommand(request, command, 3, &output, outputSize);

    if (error) {
        BluetoothHCIRequestDelete(request);
        printf("Send HCI command Error: %08x\n", error);
    }

    sleep(0x1);
    BluetoothHCIRequestDelete(request);

    NSLog(@"Input: %02X %02X %02X %02X %02X %02X %02X %02X", command[0], command[1], command[2], command[3], command[4], command[5], command[6], command[7]);
    NSLog(@"Return: %02X %02X %02X %02X %02X %02X %02X %02X", output[0], output[1], output[2], output[3], output[4], output[5], output[6], output[7]);
}

+ (void) sendArbitraryCommand:(long long)arg1 {
    NSData *data = [NSData dataWithBytes:&arg1 length:sizeof(arg1)];
    uint8 *command = malloc(8);
    memcpy(command, [data bytes], 8);
    NSLog(@"Input: %02X %02X %02X %02X %02X %02X %02X %02X", command[0], command[1], command[2], command[3], command[4], command[5], command[6], command[7]);
    
    BluetoothHCIRequestID request = 0;
    uint8 output[8];
    size_t outputSize = sizeof(output);
    
    int error = BluetoothHCIRequestCreate(&request, 1000, nil, 0);
    if (error) {
        BluetoothHCIRequestDelete(request);
        printf("Couldn't create error: %08x\n", error);
    }
    
    error = _BluetoothHCISendRawCommand(request, command, 3, &output, outputSize);
    
    if (error) {
        BluetoothHCIRequestDelete(request);
        printf("Send HCI command Error: %08x\n", error);
    }
    
    sleep(0x1);
    BluetoothHCIRequestDelete(request);
    NSLog(@"Return: %02X %02X %02X %02X %02X %02X %02X %02X", output[0], output[1], output[2], output[3], output[4], output[5], output[6], output[7]);
}

+ (NSArray *) sendArbitraryCommand4:(uint8_t [])arg1 len:(uint8_t)arg2 {
    NSData *data = [NSData dataWithBytes:arg1 length:arg2];
    uint8_t *command = calloc(arg2, sizeof(uint8_t));
    memcpy(command, [data bytes], arg2);

    BluetoothHCIRequestID request = 0;
    static uint8_t* output[255];
    size_t outputSize = sizeof(output);
    
    int error = BluetoothHCIRequestCreate(&request, 1000, nil, 0);
    if (error) {
        BluetoothHCIRequestDelete(request);
        printf("Couldn't create error: %08x\n", error);
    }
    
    size_t commandSize = 3;
    if (arg2 > 2) {
        commandSize += command[2];
    }
    error = _BluetoothHCISendRawCommand(request, command, commandSize, &output, outputSize);
    
    if (error) {
        BluetoothHCIRequestDelete(request);
        printf("Send HCI command Error: %08x\n", error);
    }
    
    sleep(0x1);
    BluetoothHCIRequestDelete(request);

    uint8_t *result = calloc(255, sizeof(uint8_t));
    memcpy(result, output, 255);

    NSMutableArray *nsarr = [[NSMutableArray alloc] init];
    for (int i = 0; i < 255; i++) {
        [nsarr addObject:[NSNumber numberWithUnsignedChar:result[i]]];
    }

    return nsarr;
}

+ (void) setDelegate:(HCIDelegate*)arg1 of:(IOBluetoothHostController*)arg2 {
    arg2.delegate = arg1;
}

@end

@implementation HCIDelegate

Boolean exit_requested = false;

- (id) initWith:(NSString *)inject and:(NSString*)snoop {
    if (self = [super init]) {
        self.inject = inject;
        self.snoop = snoop;
        self.hostname = @"127.0.0.1";
        [self initServer];
    }
    return self;
}

+ (void) setWaitingFor:(unsigned short)arg1 {
    self.waitingFor = arg1;
}

+ (void) setHostname:(NSString *)hostname {
    self.hostname = hostname;
}

+ (void) setInject:(NSString *)port {
    self.inject = port;
}

+ (void) setSnoop:(NSString *)port {
    self.snoop = port;
}

- (void) shutdown {
    exit_requested = true;
}

@end
