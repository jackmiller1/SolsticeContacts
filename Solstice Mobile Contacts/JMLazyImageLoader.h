//
//  JMLazyImageLoader.h
//  Solstice Mobile Contacts
//
//  Created by Jack Miller on 3/4/14.
//  Copyright (c) 2014 Jack Miller. All rights reserved.
//
//  This is based on the implementation of IconDownloader provided by
//  Apple Inc. (http://developer.apple.com/iphone/library/samplecode/LazyTableImages/index.html)


#import <Foundation/Foundation.h>

// Downloads a single image in the background and then the completion handler is called.
@interface JMLazyImageLoader : NSObject

// Called once the image is done downloading.
//   url - the url the image was downloaded from
//   image - a UIImage of the image downloaded
@property (nonatomic, copy) void (^completionHandler)(NSURL *url, UIImage *image);

// Starts a download from the url
- (void)startDownload:(NSURL *)url;

// Cancels download
- (void)cancelDownload;

- (void)thisDoesNothing:(NSHashTable *)somehashtablewithareallylongname withThis:(CATransformLayer *)a;

@end
