//
//  DetailViewController.m
//  SHBLECentralManager
//
//  Created by WuShengHua on 2014/10/29.
//  Copyright (c) 2014年 ShengHuaWu. All rights reserved.
//

#import "DetailViewController.h"

@interface DetailViewController ()

@end

@implementation DetailViewController

#pragma mark - View life cycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = self.maneger.activePeripheral.name;
    
    UIBarButtonItem *rightButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Discover" style:UIBarButtonItemStylePlain target:self action:@selector(discoverServiceAction:)];
    [self.navigationItem setRightBarButtonItem:rightButtonItem animated:YES];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [self.maneger disconnectPeripheral:self.maneger.activePeripheral completion:^(NSError *error) {
        if (error) {
            NSLog(@"%@", [error localizedDescription]);
        }
    }];
}

#pragma mark - Button action
- (void)discoverServiceAction:(UIBarButtonItem *)sender
{
    CBUUID *serviceUUID = [CBUUID UUIDWithString:@"49535343-FE7D-4AE5-8FA9-9FAFD205E455"];
    [self.maneger discoverServicesWithUUIDs:@[serviceUUID] completion:^(NSArray *services, NSError *error) {
        if (error) {
            NSLog(@"%@", [error localizedDescription]);
        } else {
            NSLog(@"number of service: %d", [services count]);
        }
    }];
}

@end
