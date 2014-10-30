//
//  SHBLECentralManager.m
//  SHBLECentralManager
//
//  Created by WuShengHua on 2014/10/29.
//  Copyright (c) 2014年 ShengHuaWu. All rights reserved.
//

#import "SHBLECentralManager.h"

NSString *const SHBLECentralManagerValueDidChangeNotification = @"SHBLECentralManagerValueDidChangeNotification";
NSString *const SHBLECentralManagerErrorNotification = @"SHBLECentralManagerErrorNotification";

@interface SHBLECentralManager () <CBCentralManagerDelegate, CBPeripheralDelegate>

@property (nonatomic, strong) CBCentralManager *centralManager;
@property (nonatomic, strong, readwrite) CBPeripheral *activePeripheral;
@property (nonatomic, strong) NSArray *serviceUUIDs;
@property (nonatomic, strong) NSArray *characteristicUUIDs;
@property (nonatomic, copy) SHBLECentralManagerScanCompletion scanCompletion;
@property (nonatomic, copy) SHBLECentralManagerConnectCompletion connectCompletion;
@property (nonatomic, copy) SHBLECentralManagerDisconnectCompletion disconnectionCompletion;
@property (nonatomic, copy) SHBLECentralManagerDiscoverServicesCompletion discoverServicesCompletion;
@property (nonatomic, copy) SHBLECentralManagerDiscoverCharacteristicsCompletion discoverCharacteristicsCompletion;
@property (nonatomic, copy) SHBLECentralManagerReadValueCompletion readValueCompletion;
@property (nonatomic, copy) SHBLECentralManagerWriteValueCompletion writeValueCompletion;

@end

@implementation SHBLECentralManager

#pragma mark - Shared instance
+ (instancetype)sharedManager
{
    static SHBLECentralManager *instance = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        instance = [[SHBLECentralManager alloc] init];
    });
    return instance;
}

#pragma mark - Public method
- (void)startScanForPeripheralsWithServicesUUIDs:(NSArray *)serviceUUIDs completion:(SHBLECentralManagerScanCompletion)completion
{
    self.serviceUUIDs = serviceUUIDs;
    self.scanCompletion = completion;
    
    dispatch_queue_t bluetoothQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    self.centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:bluetoothQueue options:nil];
}

- (void)stopScan
{
    [self.centralManager stopScan];
    self.scanCompletion = nil;
}

- (void)connectPeriperal:(CBPeripheral *)peripheral completion:(SHBLECentralManagerConnectCompletion)completion
{
    if (peripheral.state != CBPeripheralStateDisconnected) return;
    
    self.connectCompletion = completion;
    
    [self.centralManager connectPeripheral:peripheral options:nil];
}

- (void)disconnectPeripheral:(CBPeripheral *)peripheral completion:(SHBLECentralManagerDisconnectCompletion)completion
{
    if (peripheral.state != CBPeripheralStateConnected) return;
    
    self.disconnectionCompletion = completion;
    
    [self.centralManager cancelPeripheralConnection:peripheral];
    self.connectCompletion = nil;
}

- (void)discoverServicesWithUUIDs:(NSArray *)serviceUUIDs completion:(SHBLECentralManagerDiscoverServicesCompletion)completion
{
    self.serviceUUIDs = serviceUUIDs;
    self.discoverServicesCompletion = completion;
    
    [self.activePeripheral discoverServices:self.serviceUUIDs];
}

- (void)discoverCharacteristicsWithUUIDs:(NSArray *)characteristicUUIDs forService:(CBService *)service completion:(SHBLECentralManagerDiscoverCharacteristicsCompletion)completion
{
    self.characteristicUUIDs = characteristicUUIDs;
    self.discoverCharacteristicsCompletion = completion;
    
    [self.activePeripheral discoverCharacteristics:self.characteristicUUIDs forService:service];
}

- (void)readValueForCharacteristic:(CBCharacteristic *)characteristic completion:(SHBLECentralManagerReadValueCompletion)completion
{
    self.readValueCompletion = completion;
    
    [self.activePeripheral readValueForCharacteristic:characteristic];
}

- (void)writeValue:(NSData *)value forCharacteristic:(CBCharacteristic *)characteristic completion:(SHBLECentralManagerWriteValueCompletion)completion
{
    self.writeValueCompletion = completion;
    
    [self.activePeripheral writeValue:value forCharacteristic:characteristic type:CBCharacteristicWriteWithResponse];
}

- (void)subscribeValueForCharacteristic:(CBCharacteristic *)characteristic
{
    if (!characteristic.isNotifying) {
        [self.activePeripheral setNotifyValue:YES forCharacteristic:characteristic];
    }
}

- (void)unsubscribeValueForCharacteristic:(CBCharacteristic *)characteristic
{
    if (characteristic.isNotifying) {
        [self.activePeripheral setNotifyValue:NO forCharacteristic:characteristic];
    }
}

#pragma mark - Central manager delegate
- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    if (central.state == CBCentralManagerStatePoweredOn) {
        [self.centralManager scanForPeripheralsWithServices:self.serviceUUIDs options:nil];
    } else {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            NSError *error = [NSError errorWithDomain:@"SHBLECentralManagerError" code:999 userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"Central manager state: %lu", (long unsigned)central.state]}];
            if (self.scanCompletion) self.scanCompletion(nil, nil, nil, error);
        }];
    }
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        if (self.scanCompletion) self.scanCompletion(peripheral, advertisementData, RSSI, nil);
    }];
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    self.activePeripheral = peripheral;
    self.activePeripheral.delegate = self;
    
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        if (self.connectCompletion) self.connectCompletion(peripheral, nil);
    }];
}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        if (self.connectCompletion) self.connectCompletion(nil, error);
    }];
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    self.activePeripheral.delegate = nil;
    self.activePeripheral = nil;
    
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        if (self.disconnectionCompletion) self.disconnectionCompletion(error);
    }];
}

#pragma mark - Peripheral Delegate
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    if (error) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            if (self.discoverServicesCompletion) self.discoverServicesCompletion(nil, error);
        }];
    } else {
        NSMutableArray *services = [NSMutableArray array];
        if ([self.serviceUUIDs count]) {
            for (CBService *service in peripheral.services) {
                if ([self.serviceUUIDs containsObject:service.UUID]) {
                    [services addObject:service];
                }
            }
        } else {
            [services addObjectsFromArray:peripheral.services];
        }
        
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            if (self.discoverServicesCompletion) self.discoverServicesCompletion([services copy], nil);
        }];
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    if (error) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            if (self.discoverCharacteristicsCompletion) self.discoverCharacteristicsCompletion(nil, error);
        }];
    } else {
        NSMutableArray *characteristics = [NSMutableArray array];
        if ([self.characteristicUUIDs count]) {
            for (CBCharacteristic *characteristic in service.characteristics) {
                if ([self.characteristicUUIDs containsObject:characteristic.UUID]) {
                    [characteristics addObject:characteristic];
                }
            }
        } else {
            [characteristics addObjectsFromArray:service.characteristics];
        }
        
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            if (self.discoverCharacteristicsCompletion) self.discoverCharacteristicsCompletion([characteristics copy], nil);
        }];
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    // Reading and subscribing both use this delegate method
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        if (characteristic.isNotifying) {
            if (error) {
                [[NSNotificationCenter defaultCenter] postNotificationName:SHBLECentralManagerErrorNotification object:error];
            } else {
                [[NSNotificationCenter defaultCenter] postNotificationName:SHBLECentralManagerValueDidChangeNotification object:characteristic.value];
            }
        } else {
            if (self.readValueCompletion) self.readValueCompletion(characteristic.value, error);
        }
    }];
}

- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        if (self.writeValueCompletion) self.writeValueCompletion(error);
    }];
}

@end
