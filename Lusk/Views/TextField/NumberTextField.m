//
//  NumberTextField.m
//  Lusk!
//
//  Created by Vojtěch Jungmann
//

#import "NumberTextField.h"

@implementation NumberTextField {
    NSInteger cacheNumber;
}

- (void)textDidChange:(NSNotification *)notification {
    NSString *stringValue = [self stringValue];
    // Parse string as NSInteger or return zero
    NSString *stringValueNumberOnly = [NSString stringWithFormat:@"%li",(long)[stringValue integerValue]];
    // Accept only non zero valid number input
    if (![stringValueNumberOnly isEqualTo:@"0"]) {
        [self setStringValue:stringValueNumberOnly];
        self->cacheNumber = [stringValueNumberOnly intValue];
    }
    // Restore from cache
    else
        [self setStringValue:[NSString stringWithFormat:@"%lu", (unsigned long)self->cacheNumber]];
}


@end
