//
//  JMContactViewController.m
//  Solstice Mobile Contacts
//
//  Created by Jack Miller on 3/4/14.
//  Copyright (c) 2014 Jack Miller. All rights reserved.
//

#import "JMContactViewController.h"

@interface JMContactViewController ()

- (void)loadAdditonalContactInfo;

@property (nonatomic, strong) JMLazyImageLoader *imageLoader;
@property (nonatomic, strong) NSIndexPath *selectedIndexPath;

@end

@implementation JMContactViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setContact:(JMContact *)newContact
{
    if(_contact != newContact) {
        _contact = newContact;
        
        // Once the contact is set, start downloading addtional data.
        [self loadAdditonalContactInfo];
    }
}

- (void)loadAdditonalContactInfo
{
    // Only download data if contact exists and the additional info hasn't already been downloaded.
    if (self.contact && !self.contact.hasLoadedDetailInfo) {
        [NSURLConnection sendAsynchronousRequest:[NSURLRequest requestWithURL:self.contact.detailsURL]
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
}

// Log and prompt the user of error
- (void)failedLoadingContacts:(NSError *)error
{
    NSLog(@"Error: %@", error);
    UIAlertView *errorAlert = [[UIAlertView alloc] initWithTitle:@"Oh No :(" message:@"Something went wrong..." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [errorAlert show];
}

// Process the data downloaded
- (void)retrievedContactData:(NSData *)data
{
    NSError *error = nil;
    NSDictionary *contactData = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
    
    // Make sure contacts have same employee id
    if (self.contact.employeeId == [[contactData valueForKey:@"employeeId"] integerValue]) {
        self.contact.favorite = [[contactData valueForKey:@"favorite"] boolValue];
        self.contact.email = [contactData valueForKey:@"email"];
        self.contact.website = [contactData valueForKey:@"website"];
        self.contact.address = [contactData valueForKey:@"address"];
        self.contact.largeImageURL = [NSURL URLWithString:[contactData valueForKey:@"largeImageURL"]];
        
        self.contact.hasLoadedDetailInfo = true;
        
        // Reload the table view on the main thread.  This does not work on other threads.
        [self.tableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if (self.contact.hasLoadedDetailInfo) {
        return 6;
    }
    else {
        // Show only the loading cell
        return 1;
    }
    
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (self.contact.hasLoadedDetailInfo) {
        switch (section) {
            case 0:
                return 1;
                break;
                
            case 1:
                return [[self.contact.phones allValues] count];
                
            case 2:
                return 1;
                
            case 3:
                return 1;
                
            case 4:
                return 1;
                
            case 5:
                return 1;
                
            default:
                return 0;
                break;
        }
    }
    else {
        // Show only the loading cell
        return 1;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (section == 0) {
        // Hide the header cell above the first cell containing the image, name, and company
        return 0.1f;
    }
    else {
        return 32.0f;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.contact.hasLoadedDetailInfo) {
        switch (indexPath.section) {
                // Header cell (with name, image, and company)
            case 0:
                return 120.0f;
                break;
                
                // Address cell
            case 3:
                return 66.0f;
                
            default:
                return 44.0f;
                break;
        }
    }
    else {
        // Loading cell height
        return 80.0f;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    switch (section) {
        case 0:
            return @"";
            break;
            
        case 1:
            return @"Phone";
            break;
            
        case 2:
            return @"Email";
            break;
            
        case 3:
            return @"Address";
            
        case 4:
            return @"Website";
            
        case 5:
            return @"Birthday";
            
        default:
            return @"";
            break;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    UITableViewCell *cell;
    
    if (self.contact.hasLoadedDetailInfo) {
        
        // Header Cell
        if (indexPath.section == 0 && indexPath.row == 0) {
            cell = [tableView dequeueReusableCellWithIdentifier:@"HeaderCell" forIndexPath:indexPath];
            
            UILabel *nameLabel = (UILabel *)[cell viewWithTag:101];
            nameLabel.text = self.contact.name;
            
            UILabel *companyLabel = (UILabel *)[cell viewWithTag:102];
            companyLabel.text = self.contact.company;
            
            UIImageView *contactImageView = (UIImageView *)[cell viewWithTag:100];
            if (self.contact.largeImage == nil) {
                contactImageView.image = [UIImage imageNamed:@"ContactPlaceholder.png"];
                
                // Lazy load larger image.
                self.imageLoader = [[JMLazyImageLoader alloc] init];
                
                // Create weak reference to self to use inside code block...
                __weak typeof(self) weakSelf = self;
                
                [self.imageLoader setCompletionHandler:^(NSURL *url, UIImage *image) {
                    weakSelf.contact.largeImage = image;
                    contactImageView.image = image;
                    
                    // Must be done on main thread otherwise it won't work properly.
                    [weakSelf.tableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:YES];
                }];
                
                [self.imageLoader startDownload:self.contact.largeImageURL];
                
            }
            else {
                contactImageView.image = self.contact.largeImage;
            }
            
            // Round the corners and add a border to image view
            contactImageView.layer.cornerRadius = 10.0f;
            contactImageView.layer.masksToBounds = YES;
            contactImageView.layer.borderColor = [UIColor blackColor].CGColor;
            contactImageView.layer.borderWidth = 3.0f;
            
            UIImageView *favoriteImageView = (UIImageView *)[cell viewWithTag:103];
            favoriteImageView.image = [UIImage imageNamed:@"Favorite.png"];
            favoriteImageView.hidden = !self.contact.favorite;
            
        }
        
        // Phone numbers
        else if (indexPath.section == 1) {
            cell = [tableView dequeueReusableCellWithIdentifier:@"InfoCell" forIndexPath:indexPath];
            cell.textLabel.text = [[self.contact.phones allKeys] objectAtIndex:indexPath.row];
            cell.detailTextLabel.text = [[self.contact.phones allValues] objectAtIndex:indexPath.row];
        }
        
        // Email address
        else if (indexPath.section == 2) {
            cell = [tableView dequeueReusableCellWithIdentifier:@"InfoCell" forIndexPath:indexPath];
            cell.textLabel.text = @"";
            cell.detailTextLabel.text = self.contact.email;
        }
        
        // Address
        else if (indexPath.section == 3) {
            
            cell = [tableView dequeueReusableCellWithIdentifier:@"InfoCell" forIndexPath:indexPath];
            cell.textLabel.text = @"";
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%@\n%@ %@ %@\n%@", [self.contact.address valueForKey:@"street"], [self.contact.address valueForKey:@"city"], [self.contact.address valueForKey:@"state"], [self.contact.address valueForKey:@"zip"], [self.contact.address valueForKey:@"country"]];
            
            cell.detailTextLabel.numberOfLines = 3;
            cell.detailTextLabel.lineBreakMode = NSLineBreakByWordWrapping;
        }
        
        // Website
        else if (indexPath.section == 4) {
            cell = [tableView dequeueReusableCellWithIdentifier:@"InfoCell" forIndexPath:indexPath];
            cell.textLabel.text = @"";
            cell.detailTextLabel.text = self.contact.website;
        }
        
        // Birthday
        else if (indexPath.section == 5) {
            cell = [tableView dequeueReusableCellWithIdentifier:@"InfoCell" forIndexPath:indexPath];
            cell.textLabel.text = @"";
            
            NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
            
            // Long style format is like March 4, 2014
            [dateFormat setDateStyle:NSDateFormatterLongStyle];
            
            cell.detailTextLabel.text = [dateFormat stringFromDate:self.contact.birthday];
        }
        
    }
    
    else {
        // Show the loading cell.
        cell = [tableView dequeueReusableCellWithIdentifier:@"LoadingCell" forIndexPath:indexPath];
    }
    
    return cell;
}

// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return NO;
}

// User is prompted if they want to do something with the selected information.
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Phone
    if (indexPath.section == 1) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"Call %@", self.contact.name] message:[[self.contact.phones allValues] objectAtIndex:indexPath.row] delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Call", nil];
        self.selectedIndexPath = indexPath;
        [alert show];
    }
    
    // Email
    else if (indexPath.section == 2) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"Email %@", self.contact.name] message:self.contact.email delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Email", nil];
        self.selectedIndexPath = indexPath;
        [alert show];
    }
    
    // Address
    else if (indexPath.section == 3) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Open Maps" message:@"Open this address in Maps" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Open", nil];
        self.selectedIndexPath = indexPath;
        [alert show];
    }
    
    // Website
    else if (indexPath.section == 4) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Open Website" message:self.contact.website delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Open", nil];
        self.selectedIndexPath = indexPath;
        [alert show];
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    // Selected the button that is not 'Cancel' (i.e. 'Open', 'Email', 'Call', etc...)
    if (buttonIndex == 1) {
        
        // Phone
        if (self.selectedIndexPath.section == 1) {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"tel://%@", [[self.contact.phones allValues] objectAtIndex:self.selectedIndexPath.row]]]];
        }
        
        // Email
        else if (self.selectedIndexPath.section == 2) {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"mailto:%@", self.contact.email]]];
        }
        
        // Address
        else if (self.selectedIndexPath.section == 3) {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://maps.apple.com/maps?q=%@,%@", [self.contact.address valueForKey:@"latitude"], [self.contact.address valueForKey:@"longitude"]]]];
        }
        
        // Website
        else if (self.selectedIndexPath.section == 4) {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:self.contact.website]];
        }
    }
}

// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return NO;
}

@end
