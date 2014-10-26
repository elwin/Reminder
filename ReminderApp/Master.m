//
//  Master.m
//  Reminder
//
//  Created by Elwin on 11/08/14.
//  Copyright (c) 2014 Elwin. All rights reserved.
//

#import "Master.h"
#import "Cells.h"
#import "Data.h"
#import "DetailView.h"

static NSString *reuseIdentifier = @"masterCell";
static NSString *segue = @"Segue";

@interface Master ()

@end

@implementation Master

- (void)viewDidLoad
{
    [super viewDidLoad];
	[self firstRunWithNewBuild];
	
	Data *data = [Data sharedClass];
	[data loadData];
	[data rescheduleAllNotifications];
	
	// Prepare TableView & TableViewCells
	// Tag referes to Storyboard
	UITableView *tableView = (id)[self.view viewWithTag:1];
	UINib *nib = [UINib nibWithNibName:@"CustomCell" bundle:nil];
	[tableView registerNib:nib forCellReuseIdentifier:reuseIdentifier];
	
	[tableView setRowHeight:98];
	[tableView setBackgroundColor:[UIColor colorWithWhite:0.1 alpha:1]];
	[tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
	
	// Creates + Button, which creates a new object and invokes transition to DetailView
	UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(insertNewObject)];
	self.navigationItem.rightBarButtonItem = addButton;
	self.navigationItem.leftBarButtonItem = self.editButtonItem;
	
	// Calls applicationWillResignActive when application closes
	UIApplication *application = [UIApplication sharedApplication];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillResignActive:) name:UIApplicationWillResignActiveNotification object:application];
	
	[self printAllScheduledNotifications];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

// Logs all scheduled Notifications, for Debugging-Purposes
- (void)printAllScheduledNotifications {
	NSArray *Notifications = [[UIApplication sharedApplication] scheduledLocalNotifications];
	for (int i = 0; i < [Notifications count]; i++) {
		UILocalNotification *localNotification = Notifications[i];
		NSString *description = localNotification.alertBody;
		NSDate *fireDate = localNotification.fireDate;
		NSUInteger repeatInterval = localNotification.repeatInterval;
		NSString *uniqueID = [localNotification.userInfo valueForKey:key];
		
		NSLog(@"%@", description);
		NSLog(@"%@", fireDate);
		if (repeatInterval != NSWeekCalendarUnit) {
			NSLog(@"%lu", (unsigned long)repeatInterval);
		}
		NSLog(@"%@\n", uniqueID);
	}
}

// Compares current Build Number to the Build Number stored in NSUserDefaulsts
// If Build Number is outdated or not stored the current one is stored
- (void)firstRunWithNewBuild {
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	float buildVersion = [[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"] floatValue];
	
	if (![userDefaults valueForKey:@"version"]) {
		// First time the App has been started
		[userDefaults setFloat:buildVersion forKey:@"version"];
		
	} else if ([[NSUserDefaults standardUserDefaults] floatForKey:@"version"] == buildVersion) {
		// Same Build version
	} else {
		// New Build version
		[userDefaults setFloat:buildVersion forKey:@"version"];
	}
	
	NSLog(@"Current Build Number: %@", [userDefaults valueForKey:@"version"]);

}

// Saves the Data to the File, called when Application closes
- (void)applicationWillResignActive:(NSNotification *)notification {
	Data *data = [Data sharedClass];
	[data saveData];
}

// Reloads all Cells when View appears
// Called when App is opened or before transition from DetailView
- (void)viewWillAppear:(BOOL)animated {
	[self.tableView reloadData];
}

// Creates a new Object which is inserted on top
// Calles DetailView Controller with created Object
- (void)insertNewObject {
	Data *data = [Data sharedClass];
	if (!data.items) {
		data.items = [[NSMutableArray alloc] init];
	}
	[data.items insertObject:[data getNewItem] atIndex:0];
	[self performSegueWithIdentifier:segue sender:self];
	
	NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
	[self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
}

#pragma mark - Table view data source

// Determines the Sections; When Single / Recurring Reminders use two Sections
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

// Returns the number of Rows
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	Data *data = [Data sharedClass];
    return [data.items count];
}

// Populates the Cell with information; Date String Handling should be rewritten
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	Cells *cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier forIndexPath:indexPath];
    
	Data *data = [Data sharedClass];
	cell.descriptionLabel.text = [data.items[indexPath.row] valueForKey:kDescriptionKey];
	
	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	[dateFormatter setDateFormat:@"HH:mm"];
	NSDate *date = [data.items[indexPath.row] valueForKey:kTimeKey];
//	NSMutableString *detailedString = [[NSMutableString alloc] initWithString:[dateFormatter stringFromDate:date]];
//	NSString *tempString = [data getWeekdaysFromArray:[data.items[indexPath.row] valueForKey:kWeekdayKey]];
//	
//	// Checks for different cases when String is Empty / Everyday active
//	if ([tempString isEqualToString:@"Never"]) {
//	} else if ([tempString isEqualToString:@"Everyday"]) {
//		[detailedString appendString:@", Everyday"];
//	} else {
//		[detailedString appendString:@", every "];
//		[detailedString appendString:tempString];
//	}
//	cell.detailedDescriptionLabel.text = detailedString;
	
	NSArray *activeWeekdays = [data.items[indexPath.row] valueForKey:kWeekdayKey];
	NSMutableString *timeString = [[NSMutableString alloc] initWithString:[dateFormatter stringFromDate:date]];
	[timeString appendString:@", "];
	[timeString appendString:[data weekdayString:activeWeekdays]];
	
	cell.detailedDescriptionLabel.text = timeString;
	
	cell.tag = indexPath.row;
	cell.currentStateSwitch.on = [[data.items[indexPath.row] valueForKey:kActiveKey] boolValue];
	
    return cell;
}

// Further customization of the Cell
// Adds action when Switch changed
- (void)tableView:(UITableView *)tableView willDisplayCell:(Cells *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
	[cell setBackgroundView:[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Background.png"]]];
	[cell.currentStateSwitch setTintColor:[UIColor colorWithWhite:1.0 alpha:0.9]];
	[cell.currentStateSwitch setOnTintColor:[UIColor colorWithWhite:1.0 alpha:0.5]];
	[cell.currentStateSwitch addTarget:cell action:@selector(switchDidChange) forControlEvents:UIControlEventValueChanged];
}

// Performs Segue when Cell tapped
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[self performSegueWithIdentifier:@"Segue" sender:self];
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

// Allow editing (remove cells)
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
		Data *data = [Data sharedClass];
		[data removeNotificationForDictionary:data.items[indexPath.row]];
		[data.items removeObjectAtIndex:indexPath.row];
		[tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
	} else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }
}

// When in Editing Mode, no Object can be added
- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
	[super setEditing:editing animated:YES];
	
	if (editing) {
		[self.navigationItem.rightBarButtonItem setEnabled:NO];
	} else {
		[self.navigationItem.rightBarButtonItem setEnabled:YES];
	}
}

// Override to support rearranging the table view.
// Currently turned off, as willTransitionToState: works not properly
//- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
//	Data *data = [Data sharedClass];
//	[data moveItemAtIndex:fromIndexPath.row toIndex:toIndexPath.row];
//}

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

#pragma mark - Navigation

// Passes IndexPath when Segue is called
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	DetailView *detail = [segue destinationViewController];
	detail.indexPath = [self.tableView indexPathForSelectedRow];

}

@end
