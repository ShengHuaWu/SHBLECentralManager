//
//  NSString+SHBLEToData.m
//  SHBLECentralManager
//
//  Created by WuShengHua on 2014/10/30.
//  Copyright (c) 2014年 ShengHuaWu. All rights reserved.
//

#import "NSString+SHBLEToData.h"

@implementation NSString (SHBLEToData)

- (NSData *)dataFromHexString
{
    const char *chars = [self UTF8String];
    int i = 0, len = self.length;
    
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
