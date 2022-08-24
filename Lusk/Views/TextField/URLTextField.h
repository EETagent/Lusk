//
//  URLTextField.h
//  Lusk!
//
//  Created by Vojtěch Jungmann
//

#import <Cocoa/Cocoa.h>

#import "UloztoFilePreviewView.h"

@interface URLTextField : NSTextField

@property(nonatomic, weak) IBOutlet UloztoFilePreviewView* uloztoFilePreviewView;

- (BOOL)isValidURL;

- (NSURL*)getURL;

@end
