//
//  SHBLECentralManager.h
//  SHBLECentralManager
//
//  Created by WuShengHua on 2014/10/29.
//  Copyright (c) 2014年 ShengHuaWu. All rights reserved.
//

/**
 *  This class wraps a central manager of the Core Bluetooth framework.
 *  All callback functions will be execute on the main queue.
 */

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

typedef void (^SHBLECentralManagerScanCompletion) (CBPeripheral *peripheral, NSDictionary *advertisementData, NSNumber *RSSI, NSError *error);
typedef void (^SHBLECentralManagerConnectCompletion) (CBPeripheral *peripheral, NSError *error);
typedef void (^SHBLECentralManagerDisconnectCompletion) (NSError *error);
typedef void (^SHBLECentralManagerDiscoverServicesCompletion) (NSArray *services, NSError *error);

@interface SHBLECentralManager : NSObject

@property (nonatomic, strong, readonly) CBPeripheral *activePeripheral;

- (void)startScanForPeripheralsWithServicesUUIDs:(NSArray *)serviceUUIDs completion:(SHBLECentralManagerScanCompletion)completion;
- (void)stopScan;

- (void)connectPeriperal:(CBPeripheral *)peripheral completion:(SHBLECentralManagerConnectCompletion)completion;
- (void)disconnectPeripheral:(CBPeripheral *)peripheral completion:(SHBLECentralManagerDisconnectCompletion)completion;

- (void)discoverServicesWithUUIDs:(NSArray *)serviceUUIDs completion:(SHBLECentralManagerDiscoverServicesCompletion)completion;

@end
