//
//  CaptchaAlert.h
//  Lusk!
//
//  Created by Vojtěch Jungmann
//

#import <Cocoa/Cocoa.h>

@interface CaptchaAlert : NSAlert

@property(nonatomic, weak) NSTextField *textField;

- (instancetype)initWithCaptcha:(NSImage *)captcha;

@end
