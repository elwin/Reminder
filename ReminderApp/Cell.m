
//
//  Cells.m
//  Reminder
//
//  Created by Elwin on 11/08/14.
//  Copyright (c) 2014 Elwin. All rights reserved.
//

#import "Cell.h"
#import <QuartzCore/QuartzCore.h>
#import "Master.h"
#import "Data.h"

@interface Cells ()

@end

@implementation Cells

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
	self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
	if (self) {
		
		self.selectionStyle = UITableViewCellSelectionStyleDefault;
		
		// Setting Background Color
		self.backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Background.png"]];
		UIView *selectedBackgroundView = [[UIView alloc] init];
		selectedBackgroundView.backgroundColor = [UIColor colorWithRed:0.453 green:0.097 blue:0.735 alpha:1];
		self.selectedBackgroundView = selectedBackgroundView;
		
		// Initializing Description Label
		CGRect descriptionLabelRect = CGRectMake(25, 20, 220, 33);
		_descriptionLabel = [[UILabel alloc] initWithFrame:descriptionLabelRect];
		_descriptionLabel.textColor = [UIColor whiteColor];
		_descriptionLabel.font = [UIFont fontWithName:@"Avenir-Medium" size:24];
		[self.contentView addSubview:_descriptionLabel];
		
		// Initializing detailedDescription Label
		CGRect detailedDescriptionLabelRect = CGRectMake(25, 57, 220, 25);
		_detailedDescriptionLabel = [[UILabel alloc] initWithFrame:detailedDescriptionLabelRect];
		_detailedDescriptionLabel.textColor = [UIColor whiteColor];
		_detailedDescriptionLabel.font = [UIFont fontWithName:@"Avenir-Light" size:20];
		[self.contentView addSubview:_detailedDescriptionLabel];
		
		// Initializing currentStateSwitch
		CGRect currentStateSwitchRect = CGRectMake(250, 34, 0, 0);
		_currentStateSwitch = [[UISwitch alloc] initWithFrame:currentStateSwitchRect];
		_currentStateSwitch.TintColor = [UIColor colorWithWhite:1 alpha:0.9];
		_currentStateSwitch.onTintColor = [UIColor colorWithWhite:1 alpha:0.5];
		[_currentStateSwitch addTarget:self action:@selector(switchDidChange) forControlEvents:UIControlEventValueChanged];
		[self.contentView addSubview:_currentStateSwitch];
		
		self.currentStateSwitch.hidden = self.editing;
		
	}
	return self;
}

- (void)willTransitionToState:(UITableViewCellStateMask)state {
	[super willTransitionToState:state];
	
	switch (state) {
		case UITableViewCellStateShowingDeleteConfirmationMask:
			break;
		case UITableViewCellStateShowingEditControlMask:
			self.currentStateSwitch.hidden = true;
			break;
		case UITableViewCellStateDefaultMask:
			self.currentStateSwitch.hidden = false;
			break;
		default:
			break;
	}
}

- (void)switchDidChange {
	Data *data = [Data sharedClass];
	if (self.currentStateSwitch.isOn) {
		[data.items[self.tag] setValue:[NSNumber numberWithBool:YES] forKey:kActiveKey];
		[data scheduleNotificationForNextWeekday:data.items[self.tag]];
	} else if (!self.currentStateSwitch.isOn) {
		[data.items[self.tag] setValue:[NSNumber numberWithBool:NO] forKey:kActiveKey];
		[data removeNotificationForDictionary:data.items[self.tag]];
	}
}

- (void)setDescription:(NSString *)description {
	if (![description isEqualToString:self.description]) {
		self.description = [description copy];
		self.descriptionLabel.text = self.description;
	}
}

- (void)setDetailedDescription:(NSString *)detailedDescription {
	if (![detailedDescription isEqualToString:_detailedDescription]) {
		_detailedDescription = [detailedDescription copy];
		self.detailedDescriptionLabel.text = _detailedDescription;
	}
}

@end
