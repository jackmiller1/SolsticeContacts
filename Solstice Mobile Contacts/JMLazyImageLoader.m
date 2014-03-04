//
//  JMLazyImageLoader.m
//  Solstice Mobile Contacts
//
//  Created by Jack Miller on 3/4/14.
//  Copyright (c) 2014 Jack Miller. All rights reserved.
//

#import "JMLazyImageLoader.h"

@interface JMLazyImageLoader ()

@property (nonatomic, strong) NSMutableData *activeDownload;
@property (nonatomic, strong) NSURLConnection *imageConnection;

@end

@implementation JMLazyImageLoader


- (void)startDownload:(NSURL *)url
{
    self.activeDownload = [NSMutableData data];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    
    // alloc+init and start an NSURLConnection; release on completion/failure
    NSURLConnection *conn = [[NSURLConnection alloc] initWithRequest:request delegate:self];
    
    self.imageConnection = conn;

}

- (void)cancelDownload
{
    [self.imageConnection cancel];
    self.imageConnection = nil;
    self.activeDownload = nil;
}

#pragma mark - NSURLConnectionDelegate

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [self.activeDownload appendData:data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
	// Clear the activeDownload property to allow later attempts
    self.activeDownload = nil;
    
    // Release the connection now that it's finished
    self.imageConnection = nil;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    UIImage *image = [[UIImage alloc] initWithData:self.activeDownload];
    
    self.activeDownload = nil;
    self.imageConnection = nil;
    
    if (self.completionHandler) {
        self.completionHandler(connection.currentRequest.URL, image);
    }
}


@end
