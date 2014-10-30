//
//  MainViewController.m
//  SHBLECentralManager
//
//  Created by WuShengHua on 2014/10/29.
//  Copyright (c) 2014年 ShengHuaWu. All rights reserved.
//

#import "MainViewController.h"
#import "SHBLECentralManager.h"
#import "DetailViewController.h"

NSString *const PeripherialCellIdentifier = @"PeripherialCellIdentifier";

@interface MainViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, weak) UITableView *tableView;
@property (nonatomic, strong) SHBLECentralManager *manager;
@property (nonatomic, strong) NSMutableArray *discoverPeripherals;

@end

@implementation MainViewController

#pragma mark - View life cycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = @"BLE Central";
    
    self.navigationController.navigationBar.translucent = NO;
    
    UIBarButtonItem *rightButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Scan" style:UIBarButtonItemStylePlain target:self action:@selector(scanAction:)];
    [self.navigationItem setRightBarButtonItem:rightButtonItem animated:YES];
    
    self.manager = [SHBLECentralManager sharedManager];
    self.discoverPeripherals = [NSMutableArray array];
    
    UITableView *tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    tableView.translatesAutoresizingMaskIntoConstraints = NO;
    [tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:PeripherialCellIdentifier];
    tableView.dataSource = self;
    tableView.delegate = self;
    [self.view addSubview:tableView];
    self.tableView = tableView;
    
    [self.view setNeedsUpdateConstraints];
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
- (void)scanAction:(UIBarButtonItem *)sender
{
    [self.manager startScanForPeripheralsWithServicesUUIDs:nil completion:^(CBPeripheral *peripheral, NSDictionary *advertisementData, NSNumber *RSSI, NSError *error) {
        if (error) {
            NSLog(@"%@", [error localizedDescription]);
        } else {
            [self.discoverPeripherals addObject:peripheral];
            [self.tableView reloadData];
        }
    }];
}

#pragma mark - Table view data source
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.discoverPeripherals count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:PeripherialCellIdentifier forIndexPath:indexPath];
    
    CBPeripheral *peripheral = self.discoverPeripherals[indexPath.row];
    cell.textLabel.text = peripheral.name;
    
    return cell;
}

#pragma mark - Table view delegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    [self.manager stopScan];
    
    CBPeripheral *peripheral = self.discoverPeripherals[indexPath.row];
    [self.manager connectPeriperal:peripheral completion:^(CBPeripheral *peripheral, NSError *error) {
        if (error) {
            NSLog(@"%@", [error localizedDescription]);
        } else {
            DetailViewController *detailVC = [[DetailViewController alloc] init];
            [self.navigationController pushViewController:detailVC animated:YES];
        }
    }];
}

@end
