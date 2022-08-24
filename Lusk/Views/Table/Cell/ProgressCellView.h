//
//  ProgressCell.h
//  Lusk!
//
//  Created by Vojtěch Jungmann
//

#import <Cocoa/Cocoa.h>

#import "Page.h"

#import "DownloaderDelegate.h"

@interface ProgressCellView : NSTableCellView <DownloaderDelegate>

@property(nonatomic, weak) IBOutlet NSProgressIndicator *progressBar;

- (void)beginDownloadWithPartId:(NSUInteger)partId withPageData:(Page *)page;

- (void)stopDownload;

@end
