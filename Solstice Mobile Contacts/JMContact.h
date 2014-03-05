//
//  JMContact.h
//  Solstice Mobile Contacts
//
//  Created by Jack Miller on 3/4/14.
//  Copyright (c) 2014 Jack Miller. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface JMContact : NSObject

@property (assign) NSInteger employeeId;
@property (assign) bool favorite;
@property (strong, nonatomic) NSString *name;
@property (strong, nonatomic) NSString *company;
@property (strong, nonatomic) NSDictionary *phones;
@property (strong, nonatomic) NSURL *smallImageURL;
@property (strong, nonatomic) NSURL *largeImageURL;
@property (strong, nonatomic) NSDate *birthday;
@property (strong, nonatomic) NSString *email;
@property (strong, nonatomic) NSString *website;
@property (strong, nonatomic) NSDictionary *address;
@property (strong, nonatomic) NSURL *detailsURL;

// These will be loaded as needed...
@property (strong, nonatomic) UIImage *smallImage;
@property (strong, nonatomic) UIImage *largeImage;

@property (assign) bool hasLoadedDetailInfo;

@end