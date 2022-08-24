//
//  ViewController.h
//  Lusk!
//
//  Created by Vojtěch Jungmann
//

#import <Cocoa/Cocoa.h>

#import "PageDelegate.h"

#import "URLTextField.h"
#import "UloztoFilePreviewView.h"

@interface ViewController : NSViewController <NSTableViewDelegate, NSTableViewDataSource, PageDelegate>

@property(nonatomic, weak) IBOutlet URLTextField *urlTextField;

@property(nonatomic, weak) IBOutlet NSButton *downloadButton;

@property(nonatomic, weak) IBOutlet NSTextField *speedTextField;

@property(nonatomic, weak) IBOutlet NSButton *coreMlCheckBox;

@property(nonatomic, weak) IBOutlet UloztoFilePreviewView *uloztoFilePreview;

@property(nonatomic, weak) IBOutlet NSTableView *downloadTable;

// TODO: Integrated speed test?
- (IBAction)speedTestButtonClicked:(id)sender;

- (IBAction)downloadButtonClicked:(id)sender;
@end

