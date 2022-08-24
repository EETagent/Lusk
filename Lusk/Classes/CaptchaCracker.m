//
//  CaptchaCracker.m
//  Lusk!
//
//  Created by Vojtěch Jungmann
//

#import <Cocoa/Cocoa.h>
#import <CoreML/CoreML.h>

#import "CaptchaAlert.h"

#import "UloztoCaptchaBreaker.h"
#import "CaptchaCracker.h"

@implementation CaptchaCracker {
    NSImage *captchaImage;
    UloztoCaptchaBreaker *breaker;
}

- (instancetype)initWithCaptcha:(NSImage *)image {
    self = [super init];
    self->captchaImage = image;
    if (@available(macOS 12, *)) {
        self->breaker = [UloztoCaptchaBreaker new];
    }
    return self;
}

// Get indexes of largest value in -2 direction of 3D array
- (NSArray <NSNumber *> *)argmaxSecondAxisOnCaptchaMultiArray:(MLMultiArray *)multiArray {
    NSMutableArray <NSNumber *> *indexArray = [NSMutableArray new];
    
    short z = 0;
    for (short y = 0; y < 4; y++) {
        UInt largestIndexYet = 0;
        Float32 largestValueYet = 0;
        for (short x = 0; x < 26; x++) {
            // Access value in MLMultiArray using z y x index
            NSArray<NSNumber *> *subscript = @[[NSNumber numberWithShort:z], [NSNumber numberWithShort:y], [NSNumber numberWithShort:x]];
            NSNumber *item = [multiArray objectForKeyedSubscript:subscript];
            Float32 value = [item floatValue];
            
            if (value > largestValueYet) {
                largestIndexYet = x;
                largestValueYet = value;
            }
        }
        [indexArray addObject:[NSNumber numberWithUnsignedInt:largestIndexYet]];
    }
    return indexArray;
}

// Convert index in range 0-25 to English alphabet
- (NSString *)indexArrayToStringWithUIntList:(NSArray <NSNumber *> *)indexes {
    const NSString *chars = @"abcdefghijklmnopqrstuvwxyz";
    
    NSMutableString *outputString = [NSMutableString new];
    for (NSNumber* indexNumber in indexes) {
        NSUInteger index = [indexNumber intValue];
        if (index > 25) {
            NSLog(@"Index overflow %lu", index);
            continue;
        }
        UniChar character = [chars characterAtIndex:index];
        [outputString appendString:[NSString stringWithFormat: @"%C", character]];
    }
    return outputString;
}

// Solving captcha using CoreML and Neural Engine
- (NSString *)solveCoreML {
    // NSImage to CVPixelBuffer* in required format for ML Model (Correct dimensions & Grayscale)
    CGImageRef cgRef = [self->captchaImage CGImageForProposedRect:nil context:nil hints:nil];
    MLImageConstraint *imageConstraint = [[[[[breaker model] modelDescription] inputDescriptionsByName] objectForKey:@"captcha"] imageConstraint];
    
    NSError *error;
    MLFeatureValue *featureValue = [MLFeatureValue featureValueWithCGImage:cgRef constraint:imageConstraint options:nil error:&error];
    
    if (error != nil)
        NSLog(@"%@", error);
    
    CVPixelBufferRef pxbuf = [featureValue imageBufferValue];
    
    // Cracking
    error = nil;
    UloztoCaptchaBreakerOutput *breakerOutput = [breaker predictionFromCaptcha:pxbuf error:&error];
    
    if (error != nil)
        NSLog(@"%@", error);
    
    MLMultiArray *ml = [breakerOutput code];
    
    NSArray <NSNumber *> *argmax = [self argmaxSecondAxisOnCaptchaMultiArray:ml];
        
    NSString *result = [self indexArrayToStringWithUIntList:argmax];
    
    return result;
}

// Solving captcha using blocking alert window
- (NSString *)solveManual {
    __block NSString *result;
    // Use main thread for UI rendering
    // Sync, waiting for value returned
    dispatch_sync(dispatch_get_main_queue(), ^{
        CaptchaAlert *inputAlert = [[CaptchaAlert alloc] initWithCaptcha:self->captchaImage];
        
        NSModalResponse response = [inputAlert runModal];
        
        if (response == NSAlertFirstButtonReturn)
            result = [[inputAlert textField] stringValue];
        // Stop
        else if (response == NSAlertSecondButtonReturn)
            result = @"STOP_DOWNLOAD";
            
    });
    return result;
}

// Select fastest avaliable captcha breaker
- (NSString *)solve {
    if (self->breaker) {
        return [self solveCoreML];
    }
    return [self solveManual];
}

@end
