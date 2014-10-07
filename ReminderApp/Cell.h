//
//  Cells.h
//  Reminder
//
//  Created by Elwin on 11/08/14.
//  Copyright (c) 2014 Elwin. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface Cells : UITableViewCell

@property (copy, nonatomic) NSString *description;
@property (copy, nonatomic) NSString *detailedDescription;
@property (strong, nonatomic) UISwitch *currentStateSwitch;
@property (strong, nonatomic) UILabel *descriptionLabel;
@property (strong, nonatomic) UILabel *detailedDescriptionLabel;

@end
