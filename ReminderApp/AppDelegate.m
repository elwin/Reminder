//
//  AppDelegate.m
//  Reminder
//
//  Created by Elwin on 11/08/14.
//  Copyright (c) 2014 Elwin. All rights reserved.
//

#import "AppDelegate.h"
#import "Data.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{	
    return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
	// Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
	// If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
	// Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
	// Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
	// Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (void)application:(UIApplication *)application handleActionWithIdentifier:(NSString *)identifier forLocalNotification:(UILocalNotification *)notification completionHandler:(void (^)())completionHandler {

	NSTimeInterval timeInterval = 60 * 5; // 5 Minutes

	NSString *alertBody = notification.alertBody;
	NSDate *fireDate = [NSDate dateWithTimeIntervalSinceNow:timeInterval];
	NSDictionary *userInfo = notification.userInfo;
	
	UILocalNotification *repeatNotification = [[UILocalNotification alloc] init];
	[repeatNotification setAlertBody:alertBody];
	[repeatNotification setFireDate:fireDate];
	[repeatNotification setUserInfo:userInfo];
	[repeatNotification setCategory:categoryIdentifier];
	
	[application scheduleLocalNotification:repeatNotification];
	
	completionHandler();
}

@end
