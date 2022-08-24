//
//  Page.m
//  Lusk!
//
//  Created by Vojtěch Jungmann
//

#import <Cocoa/Cocoa.h>
#import <HTMLKit/HTMLKit.h>

#import "Page.h"
#import "Part.h"

#import "UloztoResolutionStatus.h"

#import "CaptchaCracker.h"

@implementation Page {
    BOOL STOP_DOWNLOAD;
    NSOperationQueue *operationQueueSerial;
}

// Return base URL without tracking # suffix
-(NSURL *)stripTrackingInfoFromURL:(NSURL *)url {
    NSString *urlAsString = [url absoluteString];
    if ([urlAsString containsString:@"#!"]) {
        return [NSURL URLWithString:[[urlAsString componentsSeparatedByString:@"#!"] objectAtIndex:0]];
    }
    return url;
}

- (void)setupForURL:(NSURL *)url withParts:(int)parts withCompletion:(void (^)(void))completion {
    [self setParts:parts];
    
    [self setUrl:[self stripTrackingInfoFromURL:url]];
    
    // Get slug from URL without regex
    NSArray<NSString*> *urlSeperated = [[[self url] path] componentsSeparatedByString:@"/"];
    if ([urlSeperated count] >= 2) {
        [self setSlug:[urlSeperated objectAtIndex:2]];
    }
    // Run blocking function in different thread
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
        NSError *error;
        NSString *body = [NSString stringWithContentsOfURL:url encoding: NSUTF8StringEncoding error:&error];
        [self setBody:[body copy]];
        // Run completion callback in main queue again
        dispatch_async(dispatch_get_main_queue(), ^{
            completion();
        });
    });
}


- (void)parseMetadata {
    HTMLDocument *document = [HTMLDocument documentWithString: [self body]];
    
    NSArray<HTMLElement *> *titleHTMLElements = [document querySelectorAll:@"title"];
    if ([titleHTMLElements count] == 0) {
        return;
    }
    NSString *title = [[titleHTMLElements objectAtIndex:0] innerHTML];
    
    if ([title containsString:@"|"] && [title containsString:@"Ulož.to"]) {
        title = [[title componentsSeparatedByString:@"|"] objectAtIndex:0];
    }
    [self setTitle:title];
    
    NSArray<HTMLElement *> *thumbnailList = [document querySelectorAll:@".t-filedetail-box img"];
    
    if ([thumbnailList count] == 0)
        return;
    
    HTMLElement *thumbnail = [thumbnailList objectAtIndex:0];
    
    if (!thumbnail)
        return;
    
    NSDictionary<NSString *, NSString *> *previewImageAttributes =  [thumbnail attributes];
    [self setPreviewImageURL:[previewImageAttributes objectForKey:@"src"]];
    
    NSMutableArray<HTMLElement *> *descriptionList = [[document querySelectorAll:@".t-file-info-strip  .no-txt:not(.rating)"] mutableCopy];
    
    // Get value from HTML
    for (short i = 0; i <[descriptionList count]; i++) {
        for (short p = 0; p < 2; p++)
            [[descriptionList objectAtIndex:i] removeChildNodeAtIndex:p];
    }
    
    
    NSString* (^getTrimmedHTMLFromDescriptionListAtIndex)(int index) = ^NSString* (int index) {
        NSString *untrimmedTemp = [[descriptionList objectAtIndex:index] innerHTML];
        return [untrimmedTemp stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    };
    
    switch ([descriptionList count]) {
        case 3:
            // Resolution & Duration & Size
            [self setResolution:getTrimmedHTMLFromDescriptionListAtIndex(0)];
            [self setDuration:getTrimmedHTMLFromDescriptionListAtIndex(1)];
            [self setSize: getTrimmedHTMLFromDescriptionListAtIndex(2)];
            break;
        case 2:
            // Duration & Size
            [self setDuration: getTrimmedHTMLFromDescriptionListAtIndex(0)];
            [self setSize: getTrimmedHTMLFromDescriptionListAtIndex(1)];
            break;
        case 1:
            // Size
            [self setSize: getTrimmedHTMLFromDescriptionListAtIndex(0)];
            break;
        default:
            break;
    }
}

- (BOOL)parseDownloadInfo {
    BOOL download_found = NO;
    
    HTMLDocument *document = [HTMLDocument documentWithString: [self body]];
    
    // Sanitize filename
    NSCharacterSet* const illegalFileNameCharacters = [NSCharacterSet characterSetWithCharactersInString:@"/\\?%*|\"<>"];
    NSString *filename = [[[self title] componentsSeparatedByCharactersInSet:illegalFileNameCharacters] componentsJoinedByString:@"_"];
    [self setFilename:filename];
    
    NSArray<HTMLElement *> *linkElements = [document querySelectorAll:@"a"];
    if ([linkElements count] == 0) {
        return download_found;
    }
    
    // Quick download
    for (HTMLElement *element in linkElements) {
        NSDictionary<NSString *, NSString *> *attributes = [element attributes];
        NSString *href = [attributes objectForKey:@"href"];
        if ([href containsString:@"quickDownload"]) {
            download_found = YES;
            [self setQuickDownloadURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://uloz.to%@", href]]];
        }
    }
    
    // Direct download
    if ([[document querySelectorAll:@".js-free-download-button-direct"] count] > 0)
        [self setIsDirectDownload:YES];
    else
        [self setIsDirectDownload:NO];
    
    // Captcha URL
    for (HTMLElement *element in linkElements) {
        NSDictionary<NSString *, NSString *> *attributes =  [element attributes];
        NSString *dataHref = [attributes objectForKey:@"data-href"];
        if ([dataHref containsString:@"/download-dialog/free/"]) {
            download_found = YES;
            [self setCaptchaURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://uloz.to%@", dataHref]]];
        }
    }
    
    // Slow download
    [self setSlowDownloadURL:[self captchaURL]];
    
    return download_found;
}

- (void)initDownload {
    // Quick download
    if ([self quickDownloadURL]) {
        const short partId = 0;
        
        Part *part = [[Part alloc] initWithId:partId];
        
        // Quick download URL needs only one part
        [self setParts:1];
        
        // Initialize part on main thread
        dispatch_async(dispatch_get_main_queue(), ^{
            [[self pageDelegate] partCreated:part];
            
            [part updateWithStatus:DOWNLOADING];
            
            [[self pageDelegate] downloadPartWithId:0];
        });
        
        return;
    }
    
    // Slow download
    // Captcha resolution using serial queue
    self->operationQueueSerial = [NSOperationQueue new];
    [self->operationQueueSerial setMaxConcurrentOperationCount:1];
    
    for (NSUInteger partId = 0; partId < [self parts]; partId++) {
        [operationQueueSerial addOperationWithBlock:^{
            @autoreleasepool {
                if (self->STOP_DOWNLOAD)
                    return;
                
                __block BOOL captchaIsCorrect = NO;
                
                Part *part = [[Part alloc] initWithId:partId];
                
                // Initialize part on main thread
                dispatch_sync(dispatch_get_main_queue(), ^{
                    [[self pageDelegate] partCreated:part];
                });
                
                [part updateWithStatus:STARTING];

                while (!captchaIsCorrect && !self->STOP_DOWNLOAD) {
                    NSString *captchaPageBody = [NSString stringWithContentsOfURL:[self captchaURL] encoding: NSUTF8StringEncoding error:nil];
                    
                    [part updateWithStatus:LOADING];
                    
                    HTMLDocument *captchaDocument = [HTMLDocument documentWithString:captchaPageBody];
                    
                    NSArray<HTMLElement *> *captchaImageElements = [captchaDocument querySelectorAll:@".xapca-image"];
                    
                    if ([captchaImageElements count] == 0) {
                        return;
                    }
                    
                    HTMLElement *captchaImageElement = [captchaImageElements objectAtIndex:0];
                    
                    NSURL *captchaImageURL = [NSURL URLWithString:[[captchaImageElement attributes] objectForKey:@"src"]];
                    
                    
                    NSMutableDictionary<NSString *, NSString *> *captchaData = [NSMutableDictionary new];
                    for (NSString *name in @[@"_token_", @"timestamp", @"salt", @"hash", @"captcha_type", @"_do"]) {
                        NSArray<HTMLElement *> *nameElements = [captchaDocument querySelectorAll:[NSString stringWithFormat:@"[name='%@']", name]];
                        if ([nameElements count] > 0) {
                            HTMLElement *nameElement = [nameElements objectAtIndex:0];
                            NSString *value = [[nameElement attributes] objectForKey:@"value"];
                            [captchaData setObject:value forKey:name];
                        }
                        
                    }
                    
                    NSImage *captchaImage = [[NSImage alloc] initWithContentsOfURL:captchaImageURL];
                    
                    CaptchaCracker *breaker = [[CaptchaCracker alloc] initWithCaptcha:captchaImage];
                    
                    #ifdef DEBUG
                        NSLog(@"%@", captchaImageURL);
                    #endif
                    
                    [part updateWithStatus:CRACKING];
                    
                    NSString *captchaCode;
                    
                    if ([self coreML])
                        captchaCode = [breaker solveCoreML];
                    else
                        captchaCode = [breaker solveManual];
                    
                    if ([captchaCode isEqualTo:@"STOP_DOWNLOAD"]) {
                        [self stopDownload];
                        return;
                    }
                    else if (captchaCode)
                        [captchaData setObject:captchaCode forKey:@"captcha_value"];
                    
                    #ifdef DEBUG
                        NSLog(@"%@", captchaCode);
                    #endif
                    
                    NSMutableURLRequest *request = [NSMutableURLRequest new];
                    
                    [request setHTTPMethod:@"POST"];
                    [request setURL:[self captchaURL]];
                    [request addValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
                    [request addValue:@"Go-http-client/1.1" forHTTPHeaderField:@"User-Agent"];
                    
                    NSMutableString *urlEncodedData = [NSMutableString new];
                    for (NSString *key in [captchaData keyEnumerator]) {
                        NSString *append = [NSString stringWithFormat:@"%@=%@&", key, [captchaData objectForKey:key]];
                        [urlEncodedData appendString:append];
                    }
                    // Remove last &
                    [urlEncodedData deleteCharactersInRange:NSMakeRange([urlEncodedData length]-1, 1)];
                    
                    [request setHTTPBody:[urlEncodedData dataUsingEncoding:NSUTF8StringEncoding]];
                    
                    //sendSynchronousRequest alternative using semaphores
                    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
                    
                    NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
                    
                    // NSURLsession with delegate self for redirect disable
                    NSURLSession *session = [NSURLSession sessionWithConfiguration:sessionConfiguration delegate:self delegateQueue:nil];
                    
                    NSURLSessionTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                        
                        if (data) {
                            NSString *returnString = [[NSString alloc] initWithData:data encoding: NSUTF8StringEncoding];
                            
                            NSLog(@"%@",returnString);
                            
                            UloztoResolutionStatus validate = [self validateResponse:returnString];
                            
                            [part updateWithStatus:validate];
                            
                            if (validate == OK) {
                                captchaIsCorrect = YES;
                                if (![self totalSize]) {
                                    /*NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[self slo]]];
                                     [request setHTTPMethod:@"HEAD"];*/
                                }
                            }
                            
                        }
                        else
                            NSLog(@"error = %@", error);
                        
                        dispatch_semaphore_signal(semaphore);
                    }];
                    // Start request
                    [task resume];
                    // Wait
                    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
                    // Memory cleanup
                    [session invalidateAndCancel];
                }
            }
        }];
    }
}

- (void)stopDownload {
    [self->operationQueueSerial cancelAllOperations];
    self->STOP_DOWNLOAD = YES;
    self->operationQueueSerial = nil;
}

- (UloztoResolutionStatus)validateResponse:(NSString *)response {
    NSString* const limitExceeded = @"limit-exceeded";
    NSString* const formErrorContent = @"#frm-freeDownloadForm-form";
    if ([response containsString:limitExceeded])
        return LIMIT_EXCEEDED;
    else if ([response containsString:formErrorContent])
        return FORM_ERROR_CONTENT;
    return OK;
}


@end
