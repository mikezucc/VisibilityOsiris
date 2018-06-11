//
//  AppDelegate.m
//  SCKLogTestApp
//
//  Created by Michael Zuccarino on 1/6/18.
//  Copyright © 2018 domino. All rights reserved.
//

#import "AppDelegate.h"

//@import VisibilityiOS;

//#import <VisibilityiOS/VisibilityiOS.h>

#import "VisibilitySocketLogger.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    NSString *thing = @"http://ec2-13-56-158-108.us-west-1.compute.amazonaws.com:3003/";
    [[SCKLogger shared] configureWithEndpoint:thing];
    [[SCKLogger shared] configureWithAPIKey:@"53ebd5ee9d045bbf1b1746ba1ee4bc4786dee9e687be83600938c6d07bb8"];
    
    SCKLog(@"%s %@",__FUNCTION__,self);
    
    return YES;
}


- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    SCKLog(@"%s %@",__FUNCTION__,self);
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    SCKLog(@"%s %@",__FUNCTION__,self);
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    SCKLog(@"%s %@",__FUNCTION__,self);
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    SCKLog(@"%s %@",__FUNCTION__,self);
}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    SCKLog(@"%s %@",__FUNCTION__,self);
}


@end
