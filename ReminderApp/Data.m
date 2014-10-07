//
//  Data.m
//  Reminder
//
//  Created by Elwin on 11/08/14.
//  Copyright (c) 2014 Elwin. All rights reserved.
//

#import "Data.h"

@implementation Data

+ (instancetype)sharedClass {
    static Data *shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[self alloc] init];
    });
    return shared;
}

#pragma mark - Data File managing

- (NSString *)dataFilePath {
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentsDirectory = paths[0];
	return [documentsDirectory stringByAppendingPathComponent:@"data.plist"];
}

- (NSString *)notificationsFilePath {
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentsDirectory = paths[0];
	return [documentsDirectory stringByAppendingPathComponent:@"notifications.plist"];
}

- (void)loadData {
	NSString *filePath = [self dataFilePath];
	if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
		self.items = [[NSMutableArray alloc] initWithContentsOfFile:filePath];
	} else {
		NSLog(@"No file found. New File created.");
		[[NSFileManager defaultManager] createFileAtPath:filePath contents:nil attributes:nil];
	}
}

- (void)saveData {
	NSString *filePath = [self dataFilePath];
	if ([self.items writeToFile:filePath atomically:YES]) {
	} else {
		NSLog(@"Error: Content could not be written to file");
	}
	
	UIApplication *application = [UIApplication sharedApplication];
	NSArray *localNotifications = [application scheduledLocalNotifications];
//	NSMutableArray *notificationsArray = [[NSMutableArray alloc] init];
	
	NSLog(@"--- Scheduled Notifications: ---");
	
	for (int i = 0; i < [localNotifications count]; i++) {
		UILocalNotification *notification = localNotifications[i];
		NSLog(@"%@\t(%@)", notification.alertBody, notification.fireDate);
//		NSDictionary *dictionary = @{@"description": notification.alertBody, @"time": notification.fireDate};
//		[notificationsArray addObject:dictionary];
	}
	
//	NSString *notificationFilePath = [self notificationsFilePath];
//	if ([notificationsArray writeToFile:notificationFilePath atomically:YES]) {
//	} else {
//		NSLog(@"Error: Content could not be written to file");
//	}
}

#pragma mark - Notification handling

- (void)scheduleNotificationForNextWeekday:(NSDictionary *)item {
	if ([self hasPermissionForNotifications] == 0) {
		return;
	}
	
	NSString *description = [item valueForKey:kDescriptionKey];
	NSDate *date = [item valueForKey:kTimeKey];
	NSDictionary *uniqueID = [item valueForKey:kUniqueID];
	NSArray *weekdays = [item valueForKey:kWeekdayKey];
	UIApplication *application = [UIApplication sharedApplication];
	
	for (int i = 0; i < [weekdays count]; i++) {
		if ([weekdays[i]  isEqualToNumber:[NSNumber numberWithBool:YES]]) {
			
			UILocalNotification *notification = [[UILocalNotification alloc] init];
			[notification setAlertBody:description];
			[notification setFireDate:[self getNextDateForWeekday:(i + 1) andDate:date]];
			[notification setTimeZone:[NSTimeZone localTimeZone]];
			[notification setUserInfo:uniqueID];
			[notification setCategory:categoryIdentifier];
			[notification setRepeatInterval:NSWeekCalendarUnit];
			
			// Should never apply, just for safety 
			if ([[notification alertBody] isEqualToString:@""]) {
				[notification setAlertBody:@"Reminder"];
			}
			
			[application scheduleLocalNotification:notification];
		}
	}
}

- (NSDate *)getNextDateForWeekday:(NSInteger)weekday andDate:(NSDate *)date {
	NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
	[gregorian setLocale:[NSLocale currentLocale]];
	NSDateComponents *components = [gregorian components:NSYearCalendarUnit | NSWeekOfYearCalendarUnit | NSWeekdayCalendarUnit | NSHourCalendarUnit | NSMinuteCalendarUnit fromDate:[NSDate date]];
	NSDateComponents *givenTime = [gregorian components:NSHourCalendarUnit | NSMinuteCalendarUnit fromDate:date];
	
	[components setWeekday:weekday];
	[components setHour:[givenTime hour]];
	[components setMinute:[givenTime minute]];
	
//	NSDate *requestedDate = [gregorian dateFromComponents:components];
	
//	// Check if date has already happened
//	if ([requestedDate compare:[NSDate date]] == NSOrderedAscending ) {
//		NSInteger weekOfYear = [components weekOfYear] + 1;
//		[components setWeekOfYear:weekOfYear];
//	}
	
	return [gregorian dateFromComponents:components];
}

- (void)removeNotificationForDictionary:(NSDictionary*)item {
	
	UIApplication *application = [UIApplication sharedApplication];
	NSArray *localNotifications = [application scheduledLocalNotifications];
	
	for (int i = 0; i < [localNotifications count]; i++) {
		UILocalNotification *notification = localNotifications[i];
		NSString *userInfo = [NSString stringWithFormat:@"%@", [notification.userInfo valueForKey:key]];
		NSString *uniqueID = [NSString stringWithFormat:@"%@", [[item valueForKey:kUniqueID] valueForKey:key]];
		
		if ([userInfo isEqualToString:uniqueID]) {
			[application cancelLocalNotification:notification];
		}
	}
}

- (void)scheduleMissingNotifications {
	for (int i = 0; i < [self.items count]; i++) {
		NSDictionary *item = self.items[i];
		if (![self notificationDoesExist:item]) {
			[self scheduleNotificationForNextWeekday:item];
		}
	}
}

- (BOOL)notificationDoesExist:(NSDictionary *)item {
	BOOL active = [[item valueForKey:kActiveKey] boolValue];
	NSArray *weekdays = [item valueForKey:kWeekdayKey];
	NSString *uniqueID = [[item valueForKey:kUniqueID] valueForKey:key];
	if (active) {
		for (int j = 0; j < [weekdays count]; j++) {
			BOOL currentDayActive = [weekdays[j] boolValue];
			if (currentDayActive) {
				if ([self foundNotificationWithUniqueID:uniqueID]) {
					return YES;
				}
			}
		} return NO;
	} else return YES;
}

- (BOOL)foundNotificationWithUniqueID:(NSString *)uniqueID {
	NSArray *notificationItems = [[UIApplication sharedApplication] scheduledLocalNotifications];
	for (int i = 0; i < [notificationItems count]; i++) {
		UILocalNotification *notificationItem = notificationItems[i];
		NSString *userInfo = [notificationItem.userInfo valueForKey:key];
		
		if ([userInfo isEqualToString:uniqueID]) {
			return YES;
		}
	}
	
	return NO;
}

- (BOOL)hasPermissionForNotifications {
	UIDevice *device = [UIDevice currentDevice];
	double iOSVersion = [device.systemVersion doubleValue];
	
	if (iOSVersion >= 8) {
		UIApplication *application = [UIApplication sharedApplication];
		UIUserNotificationSettings *currentNotificationSettings = [application currentUserNotificationSettings];
		if ([currentNotificationSettings types] == UIUserNotificationTypeAlert) {
			return YES;
		}
		
		UIMutableUserNotificationAction *repeatAction = [[UIMutableUserNotificationAction alloc] init];
		[repeatAction setIdentifier:@"REPEAT_ACTION"];
		[repeatAction setDestructive:NO];
		[repeatAction setTitle:@"Repeat"];
		[repeatAction setActivationMode:UIUserNotificationActivationModeBackground];
		[repeatAction setAuthenticationRequired:NO];
		
		UIMutableUserNotificationCategory *repeatCategory = [[UIMutableUserNotificationCategory alloc] init];
		[repeatCategory setIdentifier:categoryIdentifier];
		[repeatCategory setActions:@[repeatAction] forContext:UIUserNotificationActionContextDefault];
		NSSet *categories = [NSSet setWithObject:repeatCategory];
		
		UIUserNotificationSettings *notificationSettings = [UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert categories:categories];
		[application registerUserNotificationSettings:notificationSettings];
		
		if ([currentNotificationSettings types] == UIUserNotificationTypeAlert) {
			return YES;
		} else return NO;
	} else return YES;
}

# pragma mark - Items handling

- (NSMutableDictionary *)getNewItem {
	NSString *description = @"New Reminder";
	NSString *globallyUniqueString = [[NSProcessInfo processInfo] globallyUniqueString];
	NSDictionary *uniqueID = @{key: globallyUniqueString};
	NSDate *date = [NSDate date];
	NSMutableArray *weekdays = [[NSMutableArray alloc] init];
	for (int i = 0; i < 7; i++) {
		[weekdays addObject:[NSNumber numberWithBool:NO]]; }
	NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
	NSDateComponents *components = [gregorian components:NSWeekdayCalendarUnit fromDate:[NSDate date]];
	weekdays[[components weekday] - 1] = [NSNumber numberWithBool:YES];
	NSNumber *active = [NSNumber numberWithBool:YES];
	
	return [[NSMutableDictionary alloc] initWithObjectsAndKeys:description, kDescriptionKey, uniqueID, kUniqueID, date, kTimeKey, weekdays, kWeekdayKey, active, kActiveKey, nil];
}

- (NSString *)getWeekdaysFromArray:(NSArray *)weekdays {
	NSMutableArray *stringArray = [[NSMutableArray alloc] init];
	NSArray *weekdaysShort = @[@"Sun", @"Mon", @"Tue", @"Wed", @"Thu", @"Fri", @"Sat"];
	NSArray *weekdaysLong = @[@"Sunday", @"Monday", @"Tuesday", @"Wednesday", @"Thursday", @"Friday", @"Saturay"];
	
	for (int i = 0; i < 7; i++) {
		if ([weekdays[i] boolValue]) {
			[stringArray addObject:weekdaysShort[i]];
		}
	}
	if ([stringArray count] == 0) {
		return @"Never";
	} else if ([stringArray count] == 7) {
		return @"Everyday";
	} else if ([stringArray count] == 1) {
		for (int i = 0; i < 7; i++) {
			if ([weekdays[i] boolValue]) {
				return weekdaysLong[i];
			}
		}
	}
	
	NSMutableString *string = [[NSMutableString alloc] init];
	for (int i = 0; i < ([stringArray count] - 1 ); i++) {
		[string appendString:stringArray[i]];
		[string appendString:@", "];
	} [string appendString:stringArray[[stringArray count] - 1]];
	
	return string;
}

- (void)moveItemAtIndex:(NSInteger)from toIndex:(NSInteger)to {
	id item = self.items[from];
	[self.items removeObjectAtIndex:from];
	[self.items insertObject:item atIndex:to];
	
	[self saveData];
}

@end
