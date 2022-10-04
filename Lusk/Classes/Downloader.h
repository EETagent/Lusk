//
//  Downloader.h
//  Lusk!
//
//  Created by Vojtěch Jungmann
//

#import <Foundation/Foundation.h>

#import "DownloaderDelegate.h"

#import "Page.h"

@interface Downloader : NSObject <NSURLSessionDownloadDelegate>

@property(nonatomic, weak) id <DownloaderDelegate> downloaderDelegate;

@property(weak) Page *page;

@property NSURLSession *session;

@property NSURL *downloadURL;

@property NSUInteger partId;

- (instancetype)initWithPage:(Page *)page withPart:(NSUInteger)partId withURL:(NSURL *)downloadURL;

- (void)beginDownload;

- (void)stopDownload;

@end
