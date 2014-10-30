//
//  DetailViewController.m
//  SHBLECentralManager
//
//  Created by WuShengHua on 2014/10/29.
//  Copyright (c) 2014年 ShengHuaWu. All rights reserved.
//

#import "DetailViewController.h"
#import "NSString+SHBLEToData.h"

NSString *const CharacteristicCellIdentifier = @"CharacteristicCellIdentifier";

@interface DetailViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, weak) UITableView *tableView;
@property (nonatomic, strong) NSMutableArray *discoverCharacheristics;

@end

@implementation DetailViewController

#pragma mark - View life cycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = self.maneger.activePeripheral.name;
    
    UIBarButtonItem *rightButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Discover" style:UIBarButtonItemStylePlain target:self action:@selector(discoverServiceAction:)];
    [self.navigationItem setRightBarButtonItem:rightButtonItem animated:YES];
    
    self.discoverCharacheristics = [NSMutableArray array];
    
    UITableView *tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    tableView.translatesAutoresizingMaskIntoConstraints = NO;
    [tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:CharacteristicCellIdentifier];
    tableView.dataSource = self;
    tableView.delegate = self;
    [self.view addSubview:tableView];
    self.tableView = tableView;
    
    [self.view setNeedsUpdateConstraints];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    NSOperationQueue *mainQueue = [NSOperationQueue mainQueue];
    
    [center addObserverForName:SHBLECentralManagerValueDidChangeNotification object:nil queue:mainQueue usingBlock:^(NSNotification *note) {
        NSData *value = note.object;
        NSLog(@"value change: %@", [value description]);
    }];
    
    [center addObserverForName:SHBLECentralManagerErrorNotification object:nil queue:mainQueue usingBlock:^(NSNotification *note) {
        NSError *error = note.object;
        NSLog(@"%@", [error localizedDescription]);
    }];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    for (CBCharacteristic *characteristic in self.discoverCharacheristics) {
        [self.maneger unsubscribeValueForCharacteristic:characteristic];
    }
    
    [self.maneger disconnectPeripheral:self.maneger.activePeripheral completion:^(NSError *error) {
        if (error) {
            NSLog(@"%@", [error localizedDescription]);
        }
    }];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Constains
- (void)updateViewConstraints
{
    [super updateViewConstraints];
    
    NSDictionary *viewDict = @{@"tableView": self.tableView};
    
    NSArray *horizontalConstrains = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[tableView]|" options:NSLayoutFormatAlignAllLeft metrics:nil views:viewDict];
    NSArray *verticalContrains = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[tableView]|" options:NSLayoutFormatAlignAllTop metrics:nil views:viewDict];
    [self.view addConstraints:horizontalConstrains];
    [self.view addConstraints:verticalContrains];
}

#pragma mark - Button action
- (void)discoverServiceAction:(UIBarButtonItem *)sender
{
    CBUUID *serviceUUID = [CBUUID UUIDWithString:@"49535343-FE7D-4AE5-8FA9-9FAFD205E455"];
    
    DetailViewController *__weak weakSelf = self;
    [self.maneger discoverServicesWithUUIDs:@[serviceUUID] completion:^(NSArray *services, NSError *error) {
        if (error) {
            NSLog(@"%@", [error localizedDescription]);
        } else {
            for (CBService *service in services) {
                [weakSelf.maneger discoverCharacteristicsWithUUIDs:nil forService:service completion:^(NSArray *characterisics, NSError *error) {
                    if (error) {
                        NSLog(@"%@", [error localizedDescription]);
                    } else {
                        [self.discoverCharacheristics addObjectsFromArray:characterisics];
                        [self.tableView reloadData];
                    }
                }];
            }
        }
    }];
}

#pragma mark - Table view data source
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.discoverCharacheristics count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CharacteristicCellIdentifier forIndexPath:indexPath];
    
    CBCharacteristic *characteristic = self.discoverCharacheristics[indexPath.row];
    cell.textLabel.text = characteristic.UUID.UUIDString;
    
    return cell;
}

#pragma mark - Table view delegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    CBCharacteristic *characteristic = self.discoverCharacheristics[indexPath.row];
    if (characteristic.properties & CBCharacteristicPropertyNotify) {
        [self.maneger subscribeValueForCharacteristic:characteristic];
    } else if (characteristic.properties & CBCharacteristicPropertyWrite) {
        NSString *valueString = @"1002031003"; // 頭尾需要1002 1003
        [self.maneger writeValue:[valueString dataFromHexString] forCharacteristic:characteristic completion:^(NSError *error) {
            if (error) {
                NSLog(@"%@", [error localizedDescription]);
            }
        }];
    }
}

@end
