//
//  Cells.h
//  Reminder
//
//  Created by Elwin on 11/08/14.
//  Copyright (c) 2014 Elwin. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface Cells : UITableViewCell

@property (strong, nonatomic) IBOutlet UISwitch *currentStateSwitch;
@property (strong, nonatomic) IBOutlet UILabel *descriptionLabel;
@property (strong, nonatomic) IBOutlet UILabel *detailedDescriptionLabel;
- (void)switchDidChange;

@end
