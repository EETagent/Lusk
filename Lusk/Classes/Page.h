//
//  Page.h
//  Lusk!
//
//  Created by Vojtěch Jungmann
//

#import <Foundation/Foundation.h>

#import "PageDelegate.h"

@interface Page : NSObject <NSURLSessionTaskDelegate>

@property(nonatomic, weak) id <PageDelegate> pageDelegate;

@property BOOL coreML;

@property NSURL *url;
@property NSString *body;

@property NSString *title;
@property NSString *previewImageURL;
@property NSString *resolution;
@property NSString *duration;
@property NSString *size;

@property NSString *filename;
@property NSString *slug;

@property NSURL *slowDownloadURL;
@property NSURL *quickDownloadURL;

@property NSURL *captchaURL;

@property BOOL isDirectDownload;

@property NSUInteger parts;

@property NSUInteger totalSize;

@property NSUInteger alreadyDownloaded;

- (void)setupForURL:(NSURL *)url withParts:(int)parts withCompletion:(void (^)(void))completion;

- (void) parseMetadata;

- (BOOL) parseDownloadInfo;

- (void) initDownload;

- (void) stopDownload;

@end
