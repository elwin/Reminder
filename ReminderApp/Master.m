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
	UITableView *tableView = (id)[self.view viewWithTag:1];
	[tableView registerClass:[Cells class] forCellReuseIdentifier:reuseIdentifier];
	[tableView setRowHeight:98];
	[tableView setBackgroundColor:[UIColor colorWithWhite:0.1 alpha:1]];
	[tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
	
	
	UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(insertNewObject)];
	self.navigationItem.rightBarButtonItem = addButton;
	self.navigationItem.leftBarButtonItem = self.editButtonItem;
	
	UIApplication *application = [UIApplication sharedApplication];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillResignActive:) name:UIApplicationWillResignActiveNotification object:application];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

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
- (void)applicationWillResignActive:(NSNotification *)notification {
	Data *data = [Data sharedClass];
	[data saveData];
}

- (void)viewWillAppear:(BOOL)animated {
	[self.tableView reloadData];
}

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

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	Data *data = [Data sharedClass];
    return [data.items count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	Cells *cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier forIndexPath:indexPath];
    
	Data *data = [Data sharedClass];
	cell.descriptionLabel.text = [data.items[indexPath.row] valueForKey:kDescriptionKey];
	
	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	[dateFormatter setDateFormat:@"HH:mm"];
	NSDate *date = [data.items[indexPath.row] valueForKey:kTimeKey];
	NSMutableString *detailedString = [[NSMutableString alloc] initWithString:[dateFormatter stringFromDate:date]];
	NSString *tempString = [data getWeekdaysFromArray:[data.items[indexPath.row] valueForKey:kWeekdayKey]];
	
	if ([tempString isEqualToString:@"Never"]) {
		
	} else if ([tempString isEqualToString:@"Everyday"]) {
		[detailedString appendString:@", Everyday"];
	} else {
		[detailedString appendString:@", every "];
		[detailedString appendString:tempString];
	}
	cell.detailedDescription = detailedString;
	
	cell.tag = indexPath.row;
	cell.currentStateSwitch.on = [[data.items[indexPath.row] valueForKey:kActiveKey] boolValue];
	cell.currentStateSwitch.hidden = self.editing;
	
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[self performSegueWithIdentifier:@"Segue" sender:self];
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

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

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
	[super setEditing:editing animated:YES];
	
	if (editing) {
		[self.navigationItem.rightBarButtonItem setEnabled:NO];
	} else {
		[self.navigationItem.rightBarButtonItem setEnabled:YES];
	}
}

//// Override to support rearranging the table view.
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

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	DetailView *detail = [segue destinationViewController];
	detail.indexPath = [self.tableView indexPathForSelectedRow];
}

@end
