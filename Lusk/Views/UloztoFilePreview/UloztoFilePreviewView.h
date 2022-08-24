//
//  UloztoFilePreviewView.h
//  Lusk!
//
//  Created by Vojtěch Jungmann
//

#import <Cocoa/Cocoa.h>

@interface UloztoFilePreviewView : NSStackView

@property(nonatomic, weak) IBOutlet NSImageView *previewImage;

@property(nonatomic, weak) IBOutlet NSTextField *title;

@property(nonatomic, weak) IBOutlet NSTextField *resolution;
@property(nonatomic, weak) IBOutlet NSTextField *duration;
@property(nonatomic, weak) IBOutlet NSTextField *size;

@property(nonatomic, weak) IBOutlet NSImageView *resolutionIcon;
@property(nonatomic, weak) IBOutlet NSImageView *durationIcon;
@property(nonatomic, weak) IBOutlet NSImageView *sizeIcon;

@property(nonatomic, weak) IBOutlet NSImageView *greenCheckIcon;

@property(nonatomic, weak) IBOutlet NSProgressIndicator *progressIndicator;

- (void)setPreviewImageWithImage:(NSImage *) image;

- (void)setTitleWithString:(NSString *)title setResolutionWithString:(NSString *)resolution setDurationWithString:(NSString *)duration setSizeWithString:(NSString *)size;

- (void) clearView;

- (void) getUloztoFileMetadata:(NSURL *)url;

@end
