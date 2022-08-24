//
//  SpeedView.m
//  Lusk!
//
//  Created by Vojtěch Jungmann
//

#import "SpeedView.h"

@implementation SpeedView

-  (IBAction)stepperSetNum:(id)sender {
    // Little hack for incrementing and decrementing using NSStepper
    // 1 for inc or -1 for dec
    int getDirection = [sender intValue];
    // Reset
    [sender setIntValue:0];
    
    [self setSpeed:getDirection];
}

- (void)setSpeed:(int)direction {
    int currentValue = [[[self textField] stringValue] intValue];
    NSNumber *setValue = [NSNumber numberWithInt:currentValue];
    if (direction == 1)
        setValue = @([setValue intValue] + 1);
    else if (currentValue > 0)
        setValue = @([setValue intValue] - 1);
    [[self textField] setStringValue:[setValue stringValue]];
}

@end
