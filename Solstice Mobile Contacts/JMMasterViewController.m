//
//  JMMasterViewController.m
//  Solstice Mobile Contacts
//
//  Created by Jack Miller on 3/4/14.
//  Copyright (c) 2014 Jack Miller. All rights reserved.
//

#import "JMMasterViewController.h"
#import "JMContactViewController.h"

@interface JMMasterViewController ()

@property (nonatomic, strong) NSMutableArray *contacts;
@property (nonatomic, strong) NSMutableDictionary *imageDownloadsInProgress;

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
    
    // Initialize the properties
    self.contacts = [NSMutableArray new];
    self.imageDownloadsInProgress = [NSMutableDictionary dictionary];
    
    // Load the contacts
    [self loadContacts];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    
    // Stop all image downloads
    NSArray *allDownloads = [self.imageDownloadsInProgress allValues];
    [allDownloads makeObjectsPerformSelector:@selector(cancelDownload)];
    
    // Remove downloading images to free up memory
    [self.imageDownloadsInProgress removeAllObjects];
}

#pragma mark - Contacts

// Downloads the contact data from the internet
- (void)loadContacts
{
    NSURL *url = [NSURL URLWithString:@"https://solstice.applauncher.com/external/contacts.json"];
    
    // Asynchronously download contact data
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
    // Log the error and let the user know that something went wrong.
    NSLog(@"Error: %@", error);
    UIAlertView *errorAlert = [[UIAlertView alloc] initWithTitle:@"Oh No :(" message:@"Something went wrong..." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [errorAlert show];
}

// Handles the contact data recieved from the url
- (void)retrievedContactData:(NSData *)data
{
    NSError *error = nil;
    
    // Initialize contacts as a new/empty array.
    self.contacts = [NSMutableArray new];
    
    // Parse json data
    NSArray *contactsData = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
    
    // Load contact data into an array of contact objects
    for (NSDictionary *contactDict in contactsData) {
        
        // Populate data from dictionary
        JMContact *aContact = [JMContact new];
        [aContact setEmployeeId:[[contactDict valueForKey:@"employeeId"] integerValue]];
        [aContact setName:[contactDict valueForKey:@"name"]];
        [aContact setCompany:[contactDict valueForKey:@"company"]];
        [aContact setDetailsURL:[NSURL URLWithString:[contactDict valueForKey:@"detailsURL"]]];
        [aContact setSmallImageURL:[NSURL URLWithString:[contactDict valueForKey:@"smallImageURL"]]];
        [aContact setBirthday:[NSDate dateWithTimeIntervalSince1970:(NSTimeInterval)[[contactDict valueForKey:@"birthdate"] doubleValue]]];
        
        // Remove empty phone numbers
        NSMutableDictionary *phoneNumbers = [contactDict valueForKey:@"phone"];
        [phoneNumbers removeObjectsForKeys:[phoneNumbers allKeysForObject:@""]];
        [aContact setPhones:phoneNumbers];
        
        [aContact setHasLoadedDetailInfo:false];
        
        // Add aContact to the list of contacts
        [self.contacts addObject:aContact];
    }
    
    // Must tell table view to reload data on main thread.
    [self.tableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];
}

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.contacts.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"ContactCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    // Fill cell with contact info
    JMContact *contact = [self.contacts objectAtIndex:indexPath.row];
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
    if (contact.smallImage == nil) {
        
        // If the user is not scrolling, load contact image
        if (self.tableView.dragging == NO && self.tableView.decelerating == NO) {
            [self startImageDownload:contact forIndexPath:indexPath];
        }
        
        // Fill image view with placeholder until image is downloaded
        cell.imageView.image = [UIImage imageNamed:@"ContactPlaceholder.png"];
    }
    else {
        cell.imageView.image = contact.smallImage;
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
        JMContact *selectedContact = [self.contacts objectAtIndex:indexPath.row];
        [[segue destinationViewController] setContact:selectedContact];
    }
}

#pragma mark - Loading Images

- (void)startImageDownload:(JMContact *)contact forIndexPath:(NSIndexPath *)indexPath
{
    // Check if image is already being downloaded for cell.  If not, start it.
    JMLazyImageLoader *imageLoader = [self.imageDownloadsInProgress objectForKey:indexPath];
    if (imageLoader == nil)
    {
        imageLoader = [[JMLazyImageLoader alloc] init];
        [imageLoader setCompletionHandler:^(NSURL *url, UIImage *image) {
            // Fill cell image view with downloaded image.
            UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
            cell.imageView.image = image;
            contact.smallImage = image;
            
            [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            
            [self.imageDownloadsInProgress removeObjectForKey:indexPath];
            
        }];
        
        // Add object to dictionary of image downloaders
        [self.imageDownloadsInProgress setObject:imageLoader forKey:indexPath];
        
        // Start the download...
        [imageLoader startDownload:contact.smallImageURL];
    }
}

// Load images for row that are visible on the screen.
- (void)loadImagesForOnscreenRows
{
    if ([self.contacts count] > 0) {
        NSArray *visiblePaths = [self.tableView indexPathsForVisibleRows];
        for (NSIndexPath *indexPath in visiblePaths) {
            JMContact *contact = [self.contacts objectAtIndex:indexPath.row];
            // If the image is not downloaded, download it...
            if (!contact.smallImage) {
                [self startImageDownload:contact forIndexPath:indexPath];
            }
        }
    }
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    // Load images once the user is not dragging and the table is not decelerating.
    if (!decelerate)
	{
        [self loadImagesForOnscreenRows];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    [self loadImagesForOnscreenRows];
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    // Do nothing when an alertview is dismissed...
}

@end
