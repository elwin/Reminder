
//
//  Cells.m
//  Reminder
//
//  Created by Elwin on 11/08/14.
//  Copyright (c) 2014 Elwin. All rights reserved.
//

#import "Cells.h"
#import <QuartzCore/QuartzCore.h>
#import "Master.h"
#import "Data.h"

@interface Cells ()

@end

@implementation Cells

// Called when Items are enabled / disabled, schedules or removes Notifications
- (void)switchDidChange {
	Data *data = [Data sharedClass];
	if (self.currentStateSwitch.isOn) {
		[data.items[self.tag] setValue:[NSNumber numberWithBool:YES] forKey:kActiveKey];
		[data scheduleNotificationForDictionary:data.items[self.tag]];
	} else if (!self.currentStateSwitch.isOn) {
		[data.items[self.tag] setValue:[NSNumber numberWithBool:NO] forKey:kActiveKey];
		[data removeNotificationForDictionary:data.items[self.tag]];
	}
}

// Called to make Switch disappear when in Editing Mode
// Otherwise Switch would overlap text
- (void)willTransitionToState:(UITableViewCellStateMask)state {
	[super willTransitionToState:state];
	
	switch (state) {
		case UITableViewCellStateDefaultMask:
			[self.currentStateSwitch setHidden:NO];
			break;
		case UITableViewCellStateShowingDeleteConfirmationMask:
			break;
		case UITableViewCellStateShowingEditControlMask:
			[self.currentStateSwitch setHidden:YES];
			break;
		default:
			NSLog(@"Default");
	}
}

@end
