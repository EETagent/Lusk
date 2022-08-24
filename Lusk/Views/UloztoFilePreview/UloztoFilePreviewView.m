//
//  UloztoFilePreviewView.m
//  Lusk!
//
//  Created by Vojtěch Jungmann
//


#import <HTMLKit/HTMLKit.h>

#import "UloztoFilePreviewView.h"

#import "Page.h"

@implementation UloztoFilePreviewView

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        //Background color
        //#333333
        [self setWantsLayer:YES];
        [[self layer] setBackgroundColor:[[NSColor colorWithSRGBRed:0.2 green:0.2 blue:0.2 alpha:1] CGColor]];
    }
    return self;
}

// Padding for UloztoFilePreviewView
- (NSEdgeInsets)alignmentRectInsets {
    NSEdgeInsets insets = NSEdgeInsetsMake(10, 10, 10, 10);
    return insets;
}

- (void)setPreviewImageWithImage:(NSImage *)image {
    [[self previewImage] setImage:image];
}

- (void)setTitleWithString:(nullable NSString *)title setResolutionWithString:(nullable NSString *)resolution setDurationWithString:(nullable NSString *)duration setSizeWithString:(nullable NSString *)size {
    
    // Show & Hide metadata item and it's icon
    void (^labelAndIconControl)(NSString*, NSString*, BOOL) = ^void(NSString* name, NSString* value, BOOL clearOrNot) {
        // xxxIcon
        NSString *nameIcon = [NSString stringWithFormat:@"%@Icon", name];
        // Clear UloztoFilePreview
        if (clearOrNot) {
            NSTextField *textField = (NSTextField *)[self valueForKey:name];
            if (textField) [textField setStringValue:@""];
            NSImageView *imageView = (NSImageView *)[self valueForKey:nameIcon];
            if (imageView) [imageView setHidden:YES];
            return;
        }
        // Show value
        if (value) {
            // For property with specified name
            NSTextField *textField = (NSTextField *)[self valueForKey:name];
            if (textField) [textField setStringValue:value];
            NSImageView *imageView = (NSImageView *)[self valueForKey:nameIcon];
            if (imageView) [imageView setHidden:NO];
        }
    };
    
    // Bypass default title
    if (title && !([title isEqualTo:@"Ulož.to"] && !resolution && !size && !duration))
        [[self title] setStringValue:title];
    else
        [[self title] setStringValue:@""];
    
    NSUInteger metadataLoopIndex = 0;
    #define N(x) x ? x : [NSNull new]
    NSArray *metadataValues = @[N(resolution), N(size) , N(duration)];
    #define S(x) (@""#x)
    for (NSString *metadata in @[S(resolution), S(size), S(duration)]) {
        // Increment metadataLoopIndex after function call
        NSString *value = [metadataValues objectAtIndex:metadataLoopIndex++];
        if (![value isMemberOfClass:[NSNull class]])
            // Show
            labelAndIconControl(metadata, value, NO);
        else
            // Remove
            labelAndIconControl(metadata, nil, YES);
    }
    
    if (resolution || size || duration)
        [[self greenCheckIcon] setHidden:NO];
    else
        [[self greenCheckIcon] setHidden:YES];
}


- (void)clearView {
    [[self previewImage] setImage:nil];
    [self setTitleWithString:nil setResolutionWithString:nil setDurationWithString:nil setSizeWithString:nil];
}

- (void) getUloztoFileMetadata:(NSURL *)url{
    // Start animating loading wheel on main thread
    dispatch_async(dispatch_get_main_queue(), ^(void){
        [[self progressIndicator] setHidden:NO];
        [[self progressIndicator] startAnimation:nil];
    });
    
    Page *page = [Page new];
    [page setupForURL:url withParts:0 withCompletion:^{
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
            // Parse metadata
            [page parseMetadata];
            // Get thumbnail
            NSImage *imageThumbnail;
            if ([page previewImageURL]) {
                imageThumbnail = [[NSImage alloc] initWithContentsOfURL:[NSURL URLWithString:[page previewImageURL]]];
            }
            // Update view on main thread
            dispatch_async(dispatch_get_main_queue(), ^(void){
                [self setTitleWithString:[page title] setResolutionWithString:[page resolution] setDurationWithString:[page duration] setSizeWithString:[page size]];
                if (imageThumbnail)
                    [self setPreviewImageWithImage:imageThumbnail];
                else
                    [self setPreviewImageWithImage:nil];
                // Stop loading animation
                [[self progressIndicator] stopAnimation:nil];
                [[self progressIndicator] setHidden:YES];
            });
        });
        
    }];
}

@end
