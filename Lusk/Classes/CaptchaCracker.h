//
//  CaptchaCracker.h
//  Lusk!
//
//  Created by Vojtěch Jungmann
//

#import <Foundation/Foundation.h>

#import "UloztoCaptchaBreaker.h"

@interface CaptchaCracker : NSObject

- (instancetype)initWithCaptcha:(NSImage *)image;

- (NSString *)solveCoreML;
- (NSString *)solveManual;

- (NSString *)solve;

@end

