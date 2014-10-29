//
//  AppDelegate.m
//  SHBLECentralManager
//
//  Created by WuShengHua on 2014/10/29.
//  Copyright (c) 2014年 ShengHuaWu. All rights reserved.
//

#import "AppDelegate.h"
#import "MainViewController.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    CGRect frame = [UIScreen mainScreen].bounds;
    self.window = [[UIWindow alloc] initWithFrame:frame];
    self.window.backgroundColor = [UIColor whiteColor];
    MainViewController *mainVC = [[MainViewController alloc] init];
    UINavigationController *navigation = [[UINavigationController alloc] initWithRootViewController:mainVC];
    self.window.rootViewController = navigation;
    
    [self.window makeKeyAndVisible];
    
    return YES;
}

@end
