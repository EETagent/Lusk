//
//  Downloader.m
//  Lusk!
//
//  Created by Vojtěch Jungmann
//

#import "Downloader.h"

#import "Page.h"

@implementation Downloader {
    NSURLSessionDownloadTask *downloadTask;
}


- (instancetype)initWithPage:(Page*)page withPart:(NSUInteger)partId {
    self = [super init];
    if (self) {
        [self setPage:page];
        [self setPartId:partId];
    }
    return self;
}

- (void)beginDownload {
    [self setSession:[NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:[NSOperationQueue new]]];
    
    NSURL *finalURL = [[self page] quickDownloadURL] ? [[self page] quickDownloadURL] : [[self page] slowDownloadURL];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:finalURL];
    
    self->downloadTask = [[self session] downloadTaskWithRequest:request];
    
    // Download in different thread
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
        if (self->downloadTask)
            [self->downloadTask resume];
    });
}

- (void) stopDownload {
    [[self session] invalidateAndCancel];
    [self setSession:nil];

    self->downloadTask = nil;
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
    #ifdef DEBUG
        NSLog(@"%lld / %lld", totalBytesWritten, totalBytesExpectedToWrite);
    #endif
    
    [[self downloaderDelegate] URLSession:session downloadTask:downloadTask didWriteData:bytesWritten totalBytesWritten:totalBytesWritten totalBytesExpectedToWrite:totalBytesExpectedToWrite];
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location {
    dispatch_async(dispatch_get_main_queue(), ^(void){
        [[[self page] pageDelegate] partDownloadedWithId:[self partId]];
    });
    
}

- (void)URLSession:(NSURLSession *)session didBecomeInvalidWithError:(NSError *)error {
    NSLog(@"%@", [error localizedDescription]);
    [self setSession:nil];
}

@end
