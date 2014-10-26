//
//  Weekdays.m
//  Reminder
//
//  Created by Elwin on 12/08/14.
//  Copyright (c) 2014 Elwin. All rights reserved.
//

#import "Weekdays.h"
#import "Data.h"
#import "DetailView.h"

static NSString *reuseIdentifier = @"weekdayCell";

@interface Weekdays () {
	NSArray *weekdaysLabel;
}

@end

@implementation Weekdays

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	weekdaysLabel = @[@"Sunday", @"Monday", @"Tuesday", @"Wednesday", @"Thursday", @"Friday", @"Saturay"];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

// Stores Information in DetailView Controller when it is dismissed
- (void)viewWillDisappear:(BOOL)animated {
	DetailView *detail = [[DetailView alloc] init];
	[detail.itemDictionary setValue:self.weekdays forKey:kWeekdayKey];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [weekdaysLabel count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier forIndexPath:indexPath];
    
	cell.textLabel.text = weekdaysLabel[indexPath.row];
	if ([self.weekdays[indexPath.row] boolValue]) {
		cell.accessoryType = UITableViewCellAccessoryCheckmark;
	}
	
    return cell;
}

// Enable or Disable Checkmark, changes in the public array
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
	if (cell.accessoryType == UITableViewCellAccessoryCheckmark) {
		cell.accessoryType = UITableViewCellAccessoryNone;
		self.weekdays[indexPath.row] = [NSNumber numberWithBool:NO];
	} else if (cell.accessoryType == UITableViewCellAccessoryNone) {
		cell.accessoryType = UITableViewCellAccessoryCheckmark;
		self.weekdays[indexPath.row] = [NSNumber numberWithBool:YES];
	}
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
