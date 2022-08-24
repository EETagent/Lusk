//
//  CaptchaCodeTextField.m
//  Lusk!
//
//  Created by Vojtěch Jungmann
//

#import "CaptchaCodeTextField.h"

#define LIMIT 4

@implementation CaptchaCodeTextField {
    NSString *cache;
}

- (void)textDidChange:(NSNotification *)notification {
    NSUInteger length = [[self stringValue] length];
    if (length > LIMIT)
        [self setStringValue:cache];
    else {
        cache = [self stringValue];
    }
}

@end
