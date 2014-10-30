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
@property (nonatomic, copy) SHBLECentralManagerReadValueForCharacteristicCompletion readValueForCharacteristicCompletion;
@property (nonatomic, copy) SHBLECentralManagerWriteValueForCharacteristicCompletion writeValueForCharacteristicCompletion;

@end

@implementation SHBLECentralManager

#pragma mark - Designated initializer
- (instancetype)init
{
    self = [super init];
    if (self) {
        
    }
    return self;
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
    self.connectCompletion = completion;
    
    [self.centralManager connectPeripheral:peripheral options:nil];
}

- (void)disconnectPeripheral:(CBPeripheral *)peripheral completion:(SHBLECentralManagerDisconnectCompletion)completion
{
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

- (void)readValueForCharacteristic:(CBCharacteristic *)characteristic completion:(SHBLECentralManagerReadValueForCharacteristicCompletion)completion
{
    self.readValueForCharacteristicCompletion = completion;
    
    [self.activePeripheral readValueForCharacteristic:characteristic];
}

- (void)writeValue:(NSData *)value forCharacteristic:(CBCharacteristic *)characteristic completion:(SHBLECentralManagerWriteValueForCharacteristicCompletion)completion
{
    self.writeValueForCharacteristicCompletion = completion;
    
    [self.activePeripheral writeValue:value forCharacteristic:characteristic type:CBCharacteristicWriteWithResponse];
}

- (void)subscribeValueForCharacteristic:(CBCharacteristic *)characteristic
{
    if (!characteristic.isNotifying) {
        [self.activePeripheral setNotifyValue:YES forCharacteristic:characteristic];
    }
}

- (void)unsubscribeValueForCharacteric:(CBCharacteristic *)characteristic
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
        // TODO: Error handling
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            NSError *error = [NSError errorWithDomain:@"SHBLECentralManager" code:100 userInfo:@{NSLocalizedDescriptionKey: @"Cannot start to scan"}];
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
    // TODO: Error handling
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        if (self.connectCompletion) self.connectCompletion(nil, error);
    }];
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    self.activePeripheral.delegate = nil;
    self.activePeripheral = nil;
    
    // TODO: Error handling
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        if (self.disconnectionCompletion) self.disconnectionCompletion(error);
    }];
}

#pragma mark - Peripheral Delegate
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    if (error) {
        // TODO: Error handling
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
        // TODO: Error handling
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
    if (characteristic.isNotifying) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            if (error) {
                [[NSNotificationCenter defaultCenter] postNotificationName:SHBLECentralManagerErrorNotification object:error];
            } else {
                [[NSNotificationCenter defaultCenter] postNotificationName:SHBLECentralManagerValueDidChangeNotification object:characteristic.value];
            }
        }];
    } else {
        // Read
        // TODO: Error handling
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            if (self.readValueForCharacteristicCompletion) self.readValueForCharacteristicCompletion(characteristic.value, error);
        }];
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    // TODO: Error handling
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        if (self.writeValueForCharacteristicCompletion) self.writeValueForCharacteristicCompletion(error);
    }];
}

@end
