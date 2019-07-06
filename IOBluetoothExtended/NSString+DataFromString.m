//
//  NSString+DataFromString.m
//  btobjctest
//
//  Created by Davide Toldo on 06.07.19.
//  Copyright © 2019 Davide Toldo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NSString+DataFromString.h"

@implementation NSString(DataFromString)

- (NSData *)dataFromHexString {
    const char *chars = [self UTF8String];
    unsigned long i = 0, len = self.length;
    
    NSMutableData *data = [NSMutableData dataWithCapacity:len / 2];
    char byteChars[3] = {'\0','\0','\0'};
    unsigned long wholeByte;
    
    while (i < len) {
        byteChars[0] = chars[i++];
        byteChars[1] = chars[i++];
        wholeByte = strtoul(byteChars, NULL, 16);
        [data appendBytes:&wholeByte length:1];
    }
    
    return data;
}

@end
