//
//  JMMasterViewController.m
//  Solstice Mobile Contacts
//
//  Created by Jack Miller on 3/4/14.
//  Copyright (c) 2014 Jack Miller. All rights reserved.
//

#import "JMMasterViewController.h"

#import "JMDetailViewController.h"

@interface JMMasterViewController () {
    NSMutableArray *_objects;
    NSMutableArray *contacts;
    NSMutableDictionary *imageDownloadsInProgress;
}

- (void)loadContacts;

- (void)failedLoadingContacts:(NSError *)error;
- (void)retrievedContactData:(NSData *)data;

@end

@implementation JMMasterViewController

- (void)awakeFromNib
{
    [super awakeFromNib];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    imageDownloadsInProgress = [NSMutableDictionary dictionary];
    
    // Load the contacts
    [self loadContacts];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    
    // Stop all image downloads
    NSArray *allDownloads = [imageDownloadsInProgress allValues];
    [allDownloads makeObjectsPerformSelector:@selector(cancelDownload)];
    
    [imageDownloadsInProgress removeAllObjects];
}

#pragma mark - Contacts

// Downloads the contact data from the internet
- (void)loadContacts
{
    NSURL *url = [NSURL URLWithString:@"https://solstice.applauncher.com/external/contacts.json"];
    
    [NSURLConnection sendAsynchronousRequest:[NSURLRequest requestWithURL:url]
                                       queue:[[NSOperationQueue alloc] init]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                               
                               if (connectionError) {
                                   [self failedLoadingContacts:connectionError];
                               }
                               
                               else {
                                   [self retrievedContactData:data];
                               }
                               
                           }];
}

- (void)failedLoadingContacts:(NSError *)error
{
#warning Not implemented!
}

// Handles the contact data recieved from the url
- (void)retrievedContactData:(NSData *)data
{
    NSError *error = nil;
    
    // Initialize contacts as a new/empty array.
    contacts = [NSMutableArray new];
    
    // Parse json data
    NSArray *contactsData = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
    
    // Load contact data into an array of contact objects
    for (NSDictionary *contactDict in contactsData) {
        
        JMContact *aContact = [JMContact new];
        [aContact setEmployeeId:[[contactDict valueForKey:@"employeeId"] integerValue]];
        [aContact setName:[contactDict valueForKey:@"name"]];
        [aContact setCompany:[contactDict valueForKey:@"company"]];
        [aContact setDetailsURL:[NSURL URLWithString:[contactDict valueForKey:@"detailsURL"]]];
        [aContact setSmallImageURL:[NSURL URLWithString:[contactDict valueForKey:@"smallImageURL"]]];
        [aContact setPhones:(NSDictionary *)[contactDict valueForKey:@"phone"]];
        [aContact setBirthday:[NSDate dateWithTimeIntervalSince1970:(NSTimeInterval)[[contactDict valueForKey:@"birthday"] doubleValue]]];
        
        // Add aContact to the list of contacts
        [contacts addObject:aContact];
    }
    
#warning Should alphabatize contacts here.
    // Reload table view to show contacts
    [self.tableView reloadData];
}

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return contacts.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ContactCell" forIndexPath:indexPath];
    
    // Fill cell with contact info
    
    JMContact *contact = [contacts objectAtIndex:indexPath.row];
    cell.textLabel.text = [contact name];
    
    // The default phone number is mobile.  If the mobile number does not exist,
    // the first phone number available that is not blank is used.
    NSString *mobilePhoneNumber = [contact.phones objectForKey:@"mobile"];
    
    // No mobile phone number
    if (mobilePhoneNumber == nil || [mobilePhoneNumber isEqual:@""]) {
        
        // Loop through the phone number values to find a non-empty one.
        for (NSString *phoneNumber in [contact.phones allValues]) {
            if (!(mobilePhoneNumber == nil) || !([mobilePhoneNumber isEqual:@""])) {
                cell.detailTextLabel.text = phoneNumber;
            }
        }
    }
    else {
        // Contact has a mobile phone number
        cell.detailTextLabel.text = mobilePhoneNumber;
    }
    
    // Handle loading contact image
    if (contact.smallImage != nil) {
        
        // If the user is not scrolling, load contact image
        if (self.tableView.dragging == NO && self.tableView.decelerating == NO) {
            
        }
        
        cell.imageView.image = [UIImage imageNamed:@"ContactPlaceholder.png"];
    }
    else {
        
    }

    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return NO;
}

// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return NO;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"showContactInfo"]) {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        JMContact *selectedContact = [contacts objectAtIndex:indexPath.row];
        [[segue destinationViewController] setDetailItem:selectedContact];
    }
}

#pragma mark - Loading Images

- (void)startImageDownload:(JMContact *)contact forIndexPath:(NSIndexPath *)indexPath
{
    JMLazyImageLoader *imageLoader = [imageDownloadsInProgress objectForKey:indexPath];
    if (imageLoader == nil)
    {
        
    }
}

@end
