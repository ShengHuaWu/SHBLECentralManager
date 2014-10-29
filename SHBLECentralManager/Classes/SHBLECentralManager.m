//
//  SHBLECentralManager.m
//  SHBLECentralManager
//
//  Created by WuShengHua on 2014/10/29.
//  Copyright (c) 2014年 ShengHuaWu. All rights reserved.
//

#import "SHBLECentralManager.h"

@interface SHBLECentralManager () <CBCentralManagerDelegate, CBPeripheralDelegate>

@property (nonatomic, strong) CBCentralManager *centralManager;
@property (nonatomic, strong, readwrite) CBPeripheral *activePeripheral;
@property (nonatomic, strong) NSArray *serviceUUIDs;
@property (nonatomic, copy) SHBLECentralManagerScanCompletion scanCompletion;
@property (nonatomic, copy) SHBLECentralManagerConnectCompletion connectCompletion;
@property (nonatomic, copy) SHBLECentralManagerDisconnectCompletion disconnectionCompletion;
@property (nonatomic, copy) SHBLECentralManagerDiscoverServicesCompletion discoverServicesCompletion;

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
        for (CBService *service in peripheral.services) {
            if ([self.serviceUUIDs containsObject:service.UUID]) {
                [services addObject:service];
            }
        }
        
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            if (self.discoverServicesCompletion) self.discoverServicesCompletion([services copy], nil);
        }];
    }
}

@end
