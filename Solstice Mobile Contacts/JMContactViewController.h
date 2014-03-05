//
//  JMContactViewController.h
//  Solstice Mobile Contacts
//
//  Created by Jack Miller on 3/4/14.
//  Copyright (c) 2014 Jack Miller. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "JMContact.h"
#import "JMLazyImageLoader.h"

@interface JMContactViewController : UITableViewController

// Contact being displayed.
@property (strong, nonatomic) JMContact *contact;

@end