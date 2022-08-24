//
//  LuskUITests.m
//  Lusk! UITests
//
//  Created by Vojtěch Jungmann
//

#import <XCTest/XCTest.h>

@interface LuskUITests : XCTestCase

@end

@implementation LuskUITests

- (void)setUp {
    [self setContinueAfterFailure:NO];
}

- (void)tearDown {}

// Sample test for checking "Speed Test" button
- (void)testButtonSpeedTest {
    XCUIApplication *app = [XCUIApplication new];
    [app launch];
    
    XCUIApplication *safari = [[XCUIApplication alloc] initWithBundleIdentifier:@"com.apple.Safari"];
    
    XCUIElement *speedTestButton = [[app buttons] objectForKeyedSubscript:@"SpeedTest"];
    
    [speedTestButton tap];
    
    BOOL waitBrowser = [safari waitForState:XCUIApplicationStateRunningForeground timeout:3];
    
    if (!waitBrowser)
        @throw([NSException exceptionWithName:NSPortTimeoutException reason:@"Safari load timeout" userInfo:nil]);
            
    
    NSString *addressBarValue = (NSString *) [[[safari textFields] objectForKeyedSubscript:@"WEB_BROWSER_ADDRESS_AND_SEARCH_FIELD"] value];

    NSLog(@"%@", addressBarValue);
    
    XCTAssertTrue([@"https://librespeed.org" isEqualTo:addressBarValue]);
    
    [app activate];
}

- (void) testSpeedView {
    XCUIApplication *app = [XCUIApplication new];
    [app launch];
    
    XCUIElement *speedTextField = [[app textFields] objectForKeyedSubscript:@"speedTextField"];
    
    XCUIElement *speedStepper = [[app steppers] objectForKeyedSubscript:@"speedStepper"];
    
    [speedTextField tap];
    
    [speedTextField typeText:@"0"];
    XCTAssertTrue([@"0" isEqualTo:[speedTextField value]]);
        
    //TODO: Stepper

}

- (void)testLaunchPerformance {
    if (@available(macOS 10.15, *)) {
        [self measureWithMetrics:@[[XCTApplicationLaunchMetric new]] block:^{
            XCUIApplication *app = [XCUIApplication new];
            [app launch];
        }];
    }
}

@end
