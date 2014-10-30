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
 *
 *  If you subscribe one characteristic, this class will post a notifictaion when the value changes.
 *  The object of this notification contains the value of the characteristic.
 *  If an error occurs, this class will post another notification and the object of this notification contains the error.
 */

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

extern NSString *const SHBLECentralManagerValueDidChangeNotification;
extern NSString *const SHBLECentralManagerErrorNotification;

typedef void (^SHBLECentralManagerScanCompletion) (CBPeripheral *peripheral, NSDictionary *advertisementData, NSNumber *RSSI, NSError *error);
typedef void (^SHBLECentralManagerConnectCompletion) (CBPeripheral *peripheral, NSError *error);
typedef void (^SHBLECentralManagerDisconnectCompletion) (NSError *error);
typedef void (^SHBLECentralManagerDiscoverServicesCompletion) (NSArray *services, NSError *error);
typedef void (^SHBLECentralManagerDiscoverCharacteristicsCompletion) (NSArray *characterisics, NSError *error);
typedef void (^SHBLECentralManagerReadValueForCharacteristicCompletion) (NSData *value, NSError *error);
typedef void (^SHBLECentralManagerWriteValueForCharacteristicCompletion) (NSError *error);

@interface SHBLECentralManager : NSObject

@property (nonatomic, strong, readonly) CBPeripheral *activePeripheral;

- (void)startScanForPeripheralsWithServicesUUIDs:(NSArray *)serviceUUIDs completion:(SHBLECentralManagerScanCompletion)completion;
- (void)stopScan;

- (void)connectPeriperal:(CBPeripheral *)peripheral completion:(SHBLECentralManagerConnectCompletion)completion;
- (void)disconnectPeripheral:(CBPeripheral *)peripheral completion:(SHBLECentralManagerDisconnectCompletion)completion;

- (void)discoverServicesWithUUIDs:(NSArray *)serviceUUIDs completion:(SHBLECentralManagerDiscoverServicesCompletion)completion;
- (void)discoverCharacteristicsWithUUIDs:(NSArray *)characteristicUUIDs forService:(CBService *)service completion:(SHBLECentralManagerDiscoverCharacteristicsCompletion)completion;

- (void)readValueForCharacteristic:(CBCharacteristic *)characteristic completion:(SHBLECentralManagerReadValueForCharacteristicCompletion)completion;
- (void)writeValue:(NSData *)value forCharacteristic:(CBCharacteristic *)characteristic completion:(SHBLECentralManagerWriteValueForCharacteristicCompletion)completion;

- (void)subscribeValueForCharacteristic:(CBCharacteristic *)characteristic;
- (void)unsubscribeValueForCharacteric:(CBCharacteristic *)characteristic;

@end
