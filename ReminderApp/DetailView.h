//
//  DetailView.h
//  Reminder
//
//  Created by Elwin on 12/08/14.
//  Copyright (c) 2014 Elwin. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DetailView : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (strong, nonatomic) NSIndexPath *indexPath;
@property (strong, nonatomic) NSMutableDictionary *itemDictionary;

@end
