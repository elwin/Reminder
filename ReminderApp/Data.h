//
//  Data.h
//  Reminder
//
//  Created by Elwin on 11/08/14.
//  Copyright (c) 2014 Elwin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

// Constants
static NSString * const kDescriptionKey = @"description";
static NSString * const kUniqueID = @"uniqueID";
static NSString * const key = @"key";
static NSString * const kTimeKey = @"time";
static NSString * const kWeekdayKey = @"weekday";
static NSString * const kActiveKey = @"active";

static NSString * const repeatCategoryIdentifier = @"REPEAT_CATEGORY";

@interface Data : NSObject

@property (strong, nonatomic) NSString *logFilePath;
@property (strong, nonatomic) NSMutableArray *items;
+ (instancetype)sharedClass;
- (void)loadData;
- (void)saveData;
- (NSString *)dataFilePath;
- (NSMutableDictionary *)getNewItem;

- (void)scheduleNotificationForDictionary:(NSDictionary *)item;
- (void)removeNotificationForDictionary:(NSDictionary*)item;
- (void)requestPermission;
- (void)rescheduleAllNotifications;

- (NSString *)getWeekdaysFromArray:(NSArray *)weekdays;
- (void)moveItemAtIndex:(NSInteger)from toIndex:(NSInteger)to;

@end
