//
//  LuskUITestsLaunchTests.m
//  Lusk! UITests
//
//  Created by Vojtěch Jungmann
//

#import <XCTest/XCTest.h>

@interface LuskUITestsLaunchTests : XCTestCase

@end

@implementation LuskUITestsLaunchTests

+ (BOOL)runsForEachTargetApplicationUIConfiguration {
    return YES;
}

- (void)setUp {
    self.continueAfterFailure = NO;
}

- (void)testLaunch {
    XCUIApplication *app = [XCUIApplication new];
    [app launch];

    XCTAttachment *attachment = [XCTAttachment attachmentWithScreenshot:XCUIScreen.mainScreen.screenshot];
    attachment.name = @"Launch Screen";
    attachment.lifetime = XCTAttachmentLifetimeKeepAlways;
    [self addAttachment:attachment];
}

@end
