//
//  SpeedView.h
//  Lusk!
//
//  Created by Vojtěch Jungmann
//

#import <Cocoa/Cocoa.h>

#import "TextField/NumberTextField.h"

@interface SpeedView : NSStackView

@property(nonatomic, weak) IBOutlet NumberTextField *textField;

@property(nonatomic, weak) IBOutlet NSStepper *stepper;

@end

