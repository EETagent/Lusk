//
//  Part.h
//  Lusk!
//
//  Created by Vojtěch Jungmann
//

#import <Foundation/Foundation.h>

#import "ProgressCellView.h"
#import "StatusCellView.h"

#import "UloztoResolutionStatus.h"

@interface Part : NSObject

@property(nonatomic, strong) ProgressCellView *progressCellView;
@property(nonatomic, strong) StatusCellView *statusCellView;

@property NSUInteger partId;

- (NSString *)status;
// Updating statusCellView on main thread
- (void)setStatus:(NSString *)status;

- (BOOL)statusAnimating;
// Updating statusCellView on main thread
- (void)setStatusAnimating:(BOOL)animating;

- (instancetype)initWithId:(NSUInteger)partId;

- (void)updateWithStatus:(UloztoResolutionStatus)status;

@end
