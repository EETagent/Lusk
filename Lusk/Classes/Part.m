//
//  Part.m
//  Lusk!
//
//  Created by Vojtěch Jungmann
//

#import "Part.h"

#import "Page.h"

@implementation Part {
    // Custom setters and getters
    NSString *status;
    BOOL animating;
}

- (instancetype)initWithId:(NSUInteger)partId {
    self = [super init];
    if (self) {
        [self setPartId:partId];
    }
    return self;
}


- (NSString *)status {
    return self->status;
}

- (void)setStatus:(NSString *)status {
    self->status = status;
    // Update UI on main thread
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self statusCellView])
            [[[self statusCellView] textField] setStringValue:status];
    });
}


- (BOOL)statusAnimating {
    return self->animating;
}

- (void)setStatusAnimating:(BOOL)animating {
    self->animating = animating;
    // Update UI on main thread
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self statusCellView])
            [[self statusCellView] setAnimation:animating];
    });
}

- (void)updateWithStatus:(UloztoResolutionStatus)status {
    NSString* (^handleStatusAndReturnString)(void) = ^NSString*(void) {
        switch (status) {
            case STARTING:
                [self setStatusAnimating:YES];
                return @"Starting";
            case LOADING:
                [self setStatusAnimating:YES];
                return @"Loading";
            case CRACKING:
                return @"Cracking";
            case LIMIT_EXCEEDED:
                [self setStatusAnimating:NO];
                return @"Limit exceeded";
            case BLOCKED:
                [self setStatusAnimating:NO];
                return @"File blocked";
            case FORM_ERROR_CONTENT:
                [self setStatusAnimating:NO];
                return @"Bad captcha";
            case DOWNLOADING:
                [self setStatusAnimating:YES];
                return @"Downloading";
            case ERROR:
                [self setStatusAnimating:NO];
                return @"❌";
            case OK:
                [self setStatusAnimating:NO];
                return @"✅";
        }
    };
    [self setStatus:handleStatusAndReturnString()];
}

@end

