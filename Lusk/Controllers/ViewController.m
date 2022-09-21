//
//  ViewController.m
//  Lusk!
//
//  Created by Vojtěch Jungmann
//

#import "ViewController.h"

#import "Page.h"
#import "Part.h"

#import "UloztoResolutionStatus.h"

#import "UloztoFilePreviewView.h"
#import "StatusCellView.h"

@implementation ViewController {
    Page *page;
    NSMutableArray<Part *> *downloads;
    BOOL downloadRunning;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self->downloads = [NSMutableArray new];
    self->downloadRunning = NO;
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];
}

- (void)downloadButtonClicked:(id)sender {
    if (!self->downloadRunning) {
        if ([[self urlTextField] isValidURL]) {
            [self startDownload];
            [[self downloadButton] setTitle:@"Stop"];
        }
        
    } else {
        [self stopDownload];
        [[self downloadButton] setTitle:@"Download"];
    }
}

- (void)startDownload {
    self->downloads = [NSMutableArray new];
    self->downloadRunning = YES;
    
    NSURL *url = [[self urlTextField] getURL];
    self->page = [Page new];
    [self->page setupForURL:url withParts:10 withCompletion:^{
        [self->page setPageDelegate:self];
            
        if ([[self coreMlCheckBox] state] == NSControlStateValueOn)
            [self->page setCoreML:YES];
        else
            [self->page setCoreML:NO];
            
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self->page parseDownloadInfo];
            [self->page initDownload];
        });
    }];
}

- (void)stopDownload {
    [self->page stopDownload];
    self->page = nil;
    for (Part *download in downloads)
        [[download progressCellView] stopDownload];
    self->downloads = nil;
    
    [[self downloadTable] reloadData];
    self->downloadRunning = NO;
}

- (void)speedTestButtonClicked:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://librespeed.org"]];
}

- (void)partCreated:(Part *)part {
    [self->downloads addObject:part];
    
    // Create and fill progressCellView
    ProgressCellView *progressCellView = [[self downloadTable] makeViewWithIdentifier:@"progressCell" owner:self];
    if (progressCellView) {
        [part setProgressCellView:progressCellView];
        [[[part progressCellView] progressBar] setIndeterminate:YES];
        [[[part progressCellView] progressBar] startAnimation:nil];
    }
    
    // Create and fill statusCellView
    StatusCellView *statusCellView =  [[self downloadTable] makeViewWithIdentifier:@"statusCell" owner:self];
    
    if (statusCellView) [part setStatusCellView:statusCellView];
    
    [[self downloadTable] reloadData];
}

- (Part *)partGetWithId:(NSUInteger)partId {
    if (self->downloads && [self->downloads count] > partId)
        return [self->downloads objectAtIndex:partId];
    return nil;
}

- (void)updatePartWithId:(NSUInteger)partId withStatus:(UloztoResolutionStatus)status {
    if (self->downloads && [self->downloads count] >= partId + 1) {
        Part *part = [self->downloads objectAtIndex:partId];
        if (part) [part updateWithStatus:status];
    }
}

- (void)downloadPartWithId:(NSUInteger)partId {
    Part *part = [self->downloads objectAtIndex:partId];
    ProgressCellView *cellView = [part progressCellView];
    if (cellView)
        [cellView beginDownloadWithPartId:partId withPageData:self->page];
}

- (void)partDownloadedWithId:(NSUInteger)partId {
    [self->page setAlreadyDownloaded:[self->page alreadyDownloaded] + 1];
    if ([self->page alreadyDownloaded] == [self->page parts]) {}
    //TODO: Check if all parts are downloaded, if this is last part
    
    [self updatePartWithId:partId withStatus:OK];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return [self->downloads count];
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    if ([[tableColumn identifier] isEqualTo:@"partColumn"]) {
        NSTableCellView *cellView =  [tableView makeViewWithIdentifier:@"partCell" owner:self];
        if (cellView) {
            [[cellView textField] setIntValue:(int)row];
            return cellView;
        }
    }
    else if ([[tableColumn identifier] isEqualTo:@"progressColumn"]) {
        ProgressCellView *cellView = [[downloads objectAtIndex:(int)row] progressCellView];
        if (cellView)
            return cellView;
    }
    else if ([[tableColumn identifier] isEqualTo:@"statusColumn"]) {
        StatusCellView *cellView = [[downloads objectAtIndex:(int)row] statusCellView];
        if (cellView)
            return cellView;
    }
    return  nil;
}

@end
