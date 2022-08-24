//
//  CaptchaAlert.m
//  Lusk!
//
//  Created by Vojtěch Jungmann
//

#import "CaptchaAlert.h"

#import "CaptchaCodeTextField.h"

@implementation CaptchaAlert

- (instancetype)initWithCaptcha:(NSImage *)captcha {
    self = [super init];
    if (self) {
        // First button is the main button
        [self setAlertStyle:NSAlertFirstButtonReturn];
        
        // Stop for completely stopping alerts
        for (NSString *button in @[@"OK", @"Stop", @"Cancel"])
            [self addButtonWithTitle:button];
        
        // Title
        [self setMessageText:@"Captcha"];
        
        NSStackView *stackView = [NSStackView new];
        [stackView setFrameSize:NSMakeSize(300, 100)];
        [stackView setTranslatesAutoresizingMaskIntoConstraints:YES];
        [stackView setOrientation:NSUserInterfaceLayoutOrientationVertical];

        // Captcha image view
        NSImageView *imageView = [NSImageView new];
        [imageView setImage:captcha];
        [stackView addArrangedSubview:imageView];
        
        // Input
        CaptchaCodeTextField *textField = [[CaptchaCodeTextField alloc] initWithFrame:NSMakeRect(0, 0, 200, 24)];
        [self setTextField:textField];
        [stackView addArrangedSubview:[self textField]];
        
        [self setAccessoryView:stackView];
    }
    return self;
}

@end
