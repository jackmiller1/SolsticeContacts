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

@interface JMLazyImageLoader : NSObject

@property (nonatomic, copy) void (^completionHandler)(NSURL *url, UIImage *image);

- (void)startDownload:(NSURL *)url;
- (void)cancelDownload;

@end
