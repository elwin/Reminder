//
//  Data.m
//  Reminder
//
//  Created by Elwin on 11/08/14.
//  Copyright (c) 2014 Elwin. All rights reserved.
//

#import "Data.h"
#import "Master.h"

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

// Returns the File Path of the File with the User-created Notifications
- (NSString *)dataFilePath {
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentsDirectory = paths[0];
	return [documentsDirectory stringByAppendingPathComponent:@"data.plist"];
}

// Loads the File and writes its content to an array
- (void)loadData {
	NSString *filePath = [self dataFilePath];
	if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
		self.items = [[NSMutableArray alloc] initWithContentsOfFile:filePath];
	} else {
		NSLog(@"No file found. New File created.");
		[[NSFileManager defaultManager] createFileAtPath:filePath contents:nil attributes:nil];
	}
}

// Writes the content of the array to a file and saves it
- (void)saveData {
	NSString *filePath = [self dataFilePath];
	if ([self.items writeToFile:filePath atomically:YES]) {
	} else {
		NSLog(@"Error: Content could not be written to file");
	}
	
	// Prints all the scheduled Notifications the console
	UIApplication *application = [UIApplication sharedApplication];
	NSArray *localNotifications = [application scheduledLocalNotifications];
	
	NSLog(@"--- Scheduled Notifications: ---");
	for (int i = 0; i < [localNotifications count]; i++) {
		UILocalNotification *notification = localNotifications[i];
		NSLog(@"%@\t(%@)", notification.alertBody, notification.fireDate);
	}
}

#pragma mark - Notification handling

// Takes up a Dictionary which containts various informations
// to schedule a notification
- (void)scheduleNotificationForDictionary:(NSDictionary *)item {
	BOOL active = [[item valueForKey:kActiveKey] boolValue];
	if (!active) {
		return;
	}
	
	UIDevice *device = [UIDevice currentDevice];
	double iOSVersion = [device.systemVersion doubleValue];
	UIApplication *application	= [UIApplication sharedApplication];
	UIUserNotificationSettings *userNotificationSettings = [application currentUserNotificationSettings];
	
	// iOS 8 requires a permission from the User to schedule Notifications
	if (iOSVersion >= 8) {
		[self requestPermission];
		if (!([userNotificationSettings types] & UIUserNotificationTypeAlert)) {
			NSLog(@"Permission denied");
			return;
		}
	}
	
	NSString *alertBody			= [item valueForKey:kDescriptionKey];
	NSDate *date				= [item valueForKey:kTimeKey];
	NSDictionary *uniqueID		= [item valueForKey:kUniqueID];
	NSArray *weekdays			= [item valueForKey:kWeekdayKey];
	UILocalNotification *notification = [[UILocalNotification alloc] init];

	// Schedule Notification if specific weekday is enabled
	for (int i = 0; i < [weekdays count]; i++) {
		if ([weekdays[i] isEqualToNumber:[NSNumber numberWithBool:YES]]) {
			
			[notification setAlertBody:alertBody];
			NSDate *fireDate = [self getNextDateForWeekday:i + 1 andDate:date];
			[notification setFireDate:fireDate];
			[notification setUserInfo:uniqueID];
			[notification setTimeZone:[NSTimeZone localTimeZone]];
			[notification setCategory:repeatCategoryIdentifier];
			[notification setRepeatInterval:NSWeekdayCalendarUnit];
			if ([userNotificationSettings types] & UIUserNotificationTypeSound) {
				[notification setSoundName:UILocalNotificationDefaultSoundName];
			}
			[application scheduleLocalNotification:notification];
		}
	}
}

// Returns a date for a given weekday and given time
- (NSDate *)getNextDateForWeekday:(NSInteger)weekday andDate:(NSDate *)date {
	NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
	[gregorian setLocale:[NSLocale currentLocale]];
	NSDateComponents *components = [gregorian components:NSCalendarUnitYear | NSCalendarUnitWeekOfYear | NSCalendarUnitWeekday | NSCalendarUnitHour | NSCalendarUnitMinute fromDate:[NSDate date]];
	NSDateComponents *givenTime = [gregorian components:NSCalendarUnitHour | NSCalendarUnitMinute fromDate:date];
	
	[components setWeekday:weekday];
	[components setHour:[givenTime hour]];
	[components setMinute:[givenTime minute]];
	
	return [gregorian dateFromComponents:components];
}

// Takes up a Dictionary to remove all related notifications
- (void)removeNotificationForDictionary:(NSDictionary*)item {
	
	UIApplication *application = [UIApplication sharedApplication];
	NSArray *localNotifications = [application scheduledLocalNotifications];
	int numberOfDeletions = 0;
	
	for (int i = 0; i < [localNotifications count]; i++) {
		UILocalNotification *notification = localNotifications[i];
		NSString *userInfo = [NSString stringWithFormat:@"%@", [notification.userInfo valueForKey:key]];
		NSString *uniqueID = [NSString stringWithFormat:@"%@", [[item valueForKey:kUniqueID] valueForKey:key]];
		
		if ([userInfo isEqualToString:uniqueID]) {
			[application cancelLocalNotification:notification];
			numberOfDeletions++;
		}
	}
	
	NSLog(@"%i Notifications removed.", numberOfDeletions);
}

// Removes all scheduled Notifications, then reschedules them all
- (void)rescheduleAllNotifications {
	UIApplication *application = [UIApplication sharedApplication];
	[application cancelAllLocalNotifications];
	
	for (int i = 0; i < [self.items count]; i++) {
		[self scheduleNotificationForDictionary:self.items[i]];
	}
}

// Asks the User for permission to send Notifications
- (void)requestPermission {
	UIMutableUserNotificationAction *repeatAction = [[UIMutableUserNotificationAction alloc] init];
	[repeatAction setIdentifier:@"REPEAT_ACTION"];
	[repeatAction setDestructive:NO];
	[repeatAction setTitle:@"Repeat"];
	[repeatAction setActivationMode:UIUserNotificationActivationModeBackground];
	[repeatAction setAuthenticationRequired:NO];
	
	UIMutableUserNotificationCategory *repeatCategory = [[UIMutableUserNotificationCategory alloc] init];
	[repeatCategory setIdentifier:repeatCategoryIdentifier];
	[repeatCategory setActions:@[repeatAction] forContext:UIUserNotificationActionContextDefault];
	NSSet *categories = [NSSet setWithObject:repeatCategory];
	
	UIUserNotificationSettings *notificationSettings = [UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert | UIUserNotificationTypeSound categories:categories];
	UIApplication *application = [UIApplication sharedApplication];
	[application registerUserNotificationSettings:notificationSettings];
}

# pragma mark - Items handling

// Creates a new Dictionary which contains preset information
// for a reminder, i.e. current time & current weekday
- (NSMutableDictionary *)getNewItem {
	NSString *description = @"New Reminder";
	
	// Unique String is used to identify scheduled notifications
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

// Used to reorder the items on the Master-view
- (void)moveItemAtIndex:(NSInteger)from toIndex:(NSInteger)to {
	id item = self.items[from];
	[self.items removeObjectAtIndex:from];
	[self.items insertObject:item atIndex:to];
	
	[self saveData];
}

@end
