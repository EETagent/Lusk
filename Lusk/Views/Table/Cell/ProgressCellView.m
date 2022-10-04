//
//  ProgressCell.m
//  Lusk!
//
//  Created by Vojtěch Jungmann
//

#import "ProgressCellView.h"

#import "Downloader.h"

@implementation ProgressCellView {
    Downloader *downloader;
}

- (void)beginDownloadWithPartId:(NSUInteger)partId withPageData:(Page *)page withURL:(NSURL *)downloadURL {
    [[self progressBar] setIndeterminate:NO];
    
    // Current value = 0
    [[self progressBar] setDoubleValue:0];
    [[self progressBar] setMinValue:0];
    [[self progressBar] setMaxValue:[page totalSize] ? [page totalSize] : 1];
    
    self->downloader = [[Downloader alloc] initWithPage:page withPart:partId withURL:downloadURL];

    [downloader setDownloaderDelegate:self];
    [downloader beginDownload];
}

- (void)stopDownload {
    [downloader stopDownload];
    self->downloader = nil;
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
    // Set progress
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([[self progressBar] maxValue] <= 1)
            [[self progressBar] setMaxValue:totalBytesExpectedToWrite];
        [[self progressBar] setDoubleValue:totalBytesWritten];
    });
}


@end
