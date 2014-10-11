//
//  DetailView.m
//  Reminder
//
//  Created by Elwin on 12/08/14.
//  Copyright (c) 2014 Elwin. All rights reserved.
//

#import "DetailView.h"
#import "Data.h"
#import "Weekdays.h"

static NSString *reuseIdentifier = @"detailCell";

@interface DetailView ()

@property (strong, nonatomic) IBOutlet UIDatePicker *timePicker;
@property (strong, nonatomic) IBOutlet UITableView *detailTableView;
@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) UITextField *textField;

@end

@implementation DetailView

- (void)viewDidLoad
{
    [super viewDidLoad];
	self.view.backgroundColor = self.detailTableView.backgroundColor;
	
	Data *data = [Data sharedClass];
	self.itemDictionary = [[NSMutableDictionary alloc] init];
	self.itemDictionary = data.items[self.indexPath.row];
	self.navigationItem.title = [self.itemDictionary valueForKey:kDescriptionKey];
	self.timePicker.date = [self.itemDictionary valueForKey:kTimeKey];
	self.timePicker.backgroundColor = [UIColor whiteColor];
	[data requestPermission];
	
//	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWasShown:) name:UIKeyboardDidShowNotification object:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated {
	NSIndexPath *indexPath = [NSIndexPath indexPathForRow:1 inSection:0];
	[self.detailTableView reloadRowsAtIndexPaths:[NSArray arrayWithObjects:indexPath, nil] withRowAnimation:UITableViewRowAnimationNone];
}

- (void)viewWillDisappear:(BOOL)animated {
	if ([self.navigationController.viewControllers indexOfObject:self]==NSNotFound) {
		Data *data = [Data sharedClass];
		if (![self.textField.text isEqual: @""]) {
			[self.itemDictionary setValue:self.textField.text forKey:kDescriptionKey];
		}
		
		NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
		[gregorian setLocale:[NSLocale currentLocale]];
		NSDateComponents *components = [gregorian components:NSYearCalendarUnit | NSDayCalendarUnit | NSHourCalendarUnit | NSMinuteCalendarUnit fromDate:self.timePicker.date];
		NSDate *date = [gregorian dateFromComponents:components];
		[self.itemDictionary setValue:date forKey:kTimeKey];
		[data.items replaceObjectAtIndex:self.indexPath.row withObject:self.itemDictionary];
		
		[data removeNotificationForDictionary:data.items[self.indexPath.row]];
		BOOL active = [[data.items[self.indexPath.row] valueForKey:kActiveKey] boolValue];
		if (active) {
			[data scheduleNotificationForDictionary:data.items[self.indexPath.row]];
		}
	}
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return 2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier forIndexPath:indexPath];
    Data *data = [Data sharedClass];
	
	if (indexPath.row == 0) {
		cell.detailTextLabel.hidden = true;
		CGFloat width = self.view.frame.size.width - 145 - 15;
		self.textField = [[UITextField alloc] initWithFrame:CGRectMake(145, 0, width, 44)];
		self.textField.textAlignment = NSTextAlignmentRight;
		self.textField.textColor = cell.detailTextLabel.textColor;
		self.textField.adjustsFontSizeToFitWidth = true;
		self.textField.placeholder = [self.itemDictionary valueForKey:kDescriptionKey];
		self.textField.returnKeyType = UIReturnKeyDone;
//		[self.textField addTarget:self action:@selector(scrollToTextField:) forControlEvents:UIControlEventEditingDidBegin];
		[self.textField addTarget:self action:@selector(dismissKeyboard) forControlEvents:UIControlEventEditingDidEndOnExit];
		[cell addSubview:self.textField];
		cell.accessoryType = UITableViewCellAccessoryNone;
	} else if (indexPath.row == 1) {
		cell.textLabel.text = @"Repeat:";
		cell.detailTextLabel.text = [data getWeekdaysFromArray:[self.itemDictionary valueForKey:kWeekdayKey]];
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		cell.detailTextLabel.adjustsFontSizeToFitWidth = true;
	}
	
    return cell;
}

// Actually dismisses Keyboard for some unknown reason...
- (void)dismissKeyboard {
}

//- (IBAction)scrollToTextField:(id)sender {
//}

//- (void)keyboardWasShown:(NSNotification *)notification {
//	NSDictionary *keyboardDictionary = [notification userInfo];
//	CGRect keyboardSize = [[keyboardDictionary objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue];
//	UIEdgeInsets insets = UIEdgeInsetsMake(0, 0, keyboardSize.size.height, 0);
//	self.tableView.contentInset = insets
//	[self.tableView setScrollIndicatorInsets:insets];
//}


- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	if (indexPath.row == 0) {
		return nil;
	} else return indexPath;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	Weekdays *weekdayView = [segue destinationViewController];
	Data *data = [Data sharedClass];
	weekdayView.weekdays = [[NSMutableArray alloc] init];
	weekdayView.weekdays = [data.items[self.indexPath.row] valueForKey:kWeekdayKey];
}

@end
