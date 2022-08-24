//
//  PageDelegate.h
//  Lusk!
//
//  Created by Vojtěch Jungmann
//

#import <Foundation/Foundation.h>

#import "UloztoResolutionStatus.h"

@class Part;

@protocol PageDelegate <NSObject>

@optional

- (void)partCreated:(Part *)part;

- (void)updatePartWithId:(NSUInteger)partId withStatus:(UloztoResolutionStatus)status;

- (void)downloadPartWithId:(NSUInteger)partId;

- (void)partDownloadedWithId:(NSUInteger)partId;

@end
