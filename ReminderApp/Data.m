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

/*!
 * @brief Returns the singleton app instance.
 */
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

/*!
 * @brief Loads the content of the data.plist file and writes it into the newly allocated mutable array "items". In case the file does not exists a new one is created.
 */
- (void)loadData {
	NSString *filePath = [self dataFilePath];
	if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
		self.items = [[NSMutableArray alloc] initWithContentsOfFile:filePath];
	} else {
		NSLog(@"No file found. New File created.");
		[[NSFileManager defaultManager] createFileAtPath:filePath contents:nil attributes:nil];
	}
}


/*!
 * @brief Stores the content of the array "items" into the file data.plist.
 */
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

/*!
 * @brief Schedules a notification with the given NSDictionary. Does not notify the User if notification permission is not given.
 * @param item NSDictionary with various values to create a Notification, namely if active or not (boolean), description (NSString), fire date (NSDate), unique ID (NSDictionary) and active weekdays (NSArray with booleans).
 * @warning Dictionary has to use the keys given in the "Data" headerfile!
 */
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
	// Requests for permission, if denied function returns
	
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

	// Schedule Notification for specific weekday
	for (int i = 0; i < [weekdays count]; i++) {
		if ([weekdays[i] isEqualToNumber:[NSNumber numberWithBool:YES]]) {
			
			[notification setAlertBody:alertBody];
			NSDate *fireDate = [self getNextDateForWeekday:i + 1 andDate:date];
			[notification setFireDate:fireDate];
			[notification setUserInfo:uniqueID];
			[notification setTimeZone:[NSTimeZone localTimeZone]];
			[notification setCategory:repeatCategoryIdentifier];
			[notification setRepeatInterval:NSWeekCalendarUnit];
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

/*!
 * @brief Scans through all the scheduled notifications and searches for the given uniqueID and removes all associated Notifications.
 * @param item NSDictionary, important is the uniqueID.
 */
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

/*!
 * @brief If permission was not given yet it asks for and registeres Category with "Repeat"-Action for identifier repeatCategoryIdentifier.
 */
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

/*!
 * @brief Creates an instance of NSMutableArray with default values: "New Reminder" as description, current time and weekday, and a randomly generated uniqueID. The reminder is turned on by default.
 * @return An instance of NSMutableDictionary with preset values.
 */
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

/*!
 * @brief Creates a String with all active weekdays, preceeded by "Every". In case no weekday is active, it returns "Never". When all weekdays are active, it returns "Everyday". Otherwise the weekdays, which are shortened when there is more than one.
 * @param weekdays An array with booleans, where index 0 corresponds to Sunday and index 6 to Saturday.
 * @return An Instance of NSString, with a description of the active weekdays.
 */
- (NSString *)weekdayString:(NSArray *)weekdays {
	
	NSMutableArray *activeWeekdays = [[NSMutableArray alloc] init];
	NSInteger activeDays = 0;
	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	
	// Check how many Days are active
	for (int i = 0; i < [weekdays count]; i++) {
		if ([weekdays[i] boolValue]) {
			activeDays++;
		}
	}
	
	// Prepare String / Date Format accordingly to number of active Days
	if (activeDays == 0) {
		return @"Never";
	} else if (activeDays == 1) {
		[dateFormatter setDateFormat:@"EEEE"];
	} else if (activeDays == 7) {
		return @"Everyday";
	} else {
		[dateFormatter setDateFormat:@"EE"];
	}
	
	// Add Weekday to String
	for (int i = 0; i < [weekdays count]; i++) {
		if ([weekdays[i] boolValue]) {
			NSDate *date = [self getNextDateForWeekday:(i + 1) andDate:[NSDate date]];
			[activeWeekdays addObject:[dateFormatter stringFromDate:date]];
		}
	}
	
	NSMutableString *weekdaysString = [[NSMutableString alloc] initWithString:@"every "];
	
	for (int i = 0; i < [activeWeekdays count] - 1; i++) {
		[weekdaysString appendFormat:@"%@, ", activeWeekdays[i]];
	}
	
	NSUInteger i = [activeWeekdays count] - 1;
	[weekdaysString appendString:activeWeekdays[i]];
	
	return weekdaysString;
}

/*!
 * @brief Creates a String with all active weekdays. In case no weekday is active, it returns "Never". When all weekdays are active, it returns "Everyday". Otherwise it the weekdays, which are shortened when there is more than one.
 * @param weekdays An array with booleans, where index 0 corresponds to Sunday and index 6 to Saturday.
 * @return An Instance of NSString, with a description of the active weekdays.
 */
- (NSString *)weekdayStringPlain:(NSArray *)weekdays {
	NSMutableArray *activeWeekdays = [[NSMutableArray alloc] init];
	NSInteger activeDays = 0;
	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	[dateFormatter setDateFormat:@"EE"];
	
	if ([weekdays count] != 7) {
		NSLog(@"Warning: Array with weekdays contains more or less than 7 booleans!");
	}
	
	// Check how many Days are active
	for (int i = 0; i < [weekdays count]; i++) {
		if ([weekdays[i] boolValue]) {
			activeDays++;
		}
	}
	
	// Prepare String / Date Format accordingly to number of active Days
	if (activeDays == 0) {
		return @"Never";
	} else if (activeDays == 1) {
		[dateFormatter setDateFormat:@"EEEE"];
	} else if (activeDays == 7) {
		return @"Everyday";
	} else {
		[dateFormatter setDateFormat:@"EE"];
	}
	
	// Add Weekday to String
	for (int i = 0; i < [weekdays count]; i++) {
		if ([weekdays[i] boolValue]) {
			NSDate *date = [self getNextDateForWeekday:(i + 1) andDate:[NSDate date]];
			[activeWeekdays addObject:[dateFormatter stringFromDate:date]];
		}
	}
	
	NSMutableString *weekdaysString = [[NSMutableString alloc] init];
	
	for (int i = 0; i < [activeWeekdays count] - 1; i++) {
		[weekdaysString appendFormat:@"%@, ", activeWeekdays[i]];
	}
	
	NSUInteger i = [activeWeekdays count] - 1;
	[weekdaysString appendString:activeWeekdays[i]];
	
	return weekdaysString;
}

/*!
 * @brief Moves the item in the array "items" from to the given indexnumber. Calles the method saveData after succesful movement.
 * @param from NSInteger with the original location of the item
 * @param to NSInteger with the desired indexnumber.
 */
- (void)moveItemAtIndex:(NSInteger)from toIndex:(NSInteger)to {
	if ((from || to) >= [self.items count]) {
		NSLog(@"Index is out of bounds... from: %i to: %i items count: %i", from, to, [self.items count]);
	}
	
	id item = self.items[from];
	[self.items removeObjectAtIndex:from];
	[self.items insertObject:item atIndex:to];
	
	[self saveData];
}

@end
