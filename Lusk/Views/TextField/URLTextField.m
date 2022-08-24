//
//  URLTextField.m
//  Lusk!
//
//  Created by Vojtěch Jungmann
//

#import "URLTextField.h"

@implementation URLTextField {
    NSString *urlTextFieldCache;
}

- (BOOL)isValidURL {
    NSString *urlInputFieldValue =  [self  stringValue];
    NSURL *url = [NSURL URLWithString:urlInputFieldValue];
    if (url && [url scheme] && [url host]) {
        if ([[url host] isEqualTo:@"uloz.to"])
            return YES;
    }
    return NO;
}

- (NSURL *)getURL {
    return [NSURL URLWithString:[self stringValue]];
}

- (NSString *)getShortURL:(nonnull NSString *)url {
    NSString *shortened = [[url componentsSeparatedByString:@"#!"] objectAtIndex:0];
    return shortened;
}

- (void)textDidChange:(NSNotification *)notification {
    NSString *shortURL = [self getShortURL:[self stringValue]];
    
    if ([self isValidURL]) {
        if ([shortURL isNotEqualTo:urlTextFieldCache]) {
            urlTextFieldCache = shortURL;
            [[self uloztoFilePreviewView] getUloztoFileMetadata:[NSURL URLWithString:shortURL]];
        }
        return;
    }
    [[self uloztoFilePreviewView] clearView];
    urlTextFieldCache = @"";
}

@end
