//
//  Page.m
//  Lusk!
//
//  Created by Vojtěch Jungmann
//

#import <Cocoa/Cocoa.h>

#import <HTMLKit/HTMLKit.h>
#import <Tor/Tor-umbrella.h>

#import "Page.h"
#import "Part.h"

#import "UloztoResolutionStatus.h"

#import "CaptchaCracker.h"

@implementation Page {
    BOOL STOP_DOWNLOAD;
    
    TORConfiguration *torConfiguration;
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

- (void)downloadPartWithId:(NSUInteger)partId resetTor:(BOOL)resetTor failed:(BOOL)failed {
    if (partId < [self parts] && !self->STOP_DOWNLOAD) {
        @autoreleasepool {
            Part *checkIfExists = [[self pageDelegate] partGetWithId:partId];
            Part *part;
            if (checkIfExists) {
                part = checkIfExists;
            } else {
                part = [[Part alloc] initWithId:partId];
                // Initialize part on main thread
                dispatch_sync(dispatch_get_main_queue(), ^{
                    [[self pageDelegate] partCreated:part];
                });
            }
            
            // Update status => STARTING
            [part updateWithStatus:STARTING];
            
            // Slight delay required for Tor.framework
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, !failed ? 2 * NSEC_PER_SEC : 4 * NSEC_PER_SEC), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0) , ^{
                // Update status => TOR_STARTING
                [part updateWithStatus:TOR_STARTING];
                            
                TORController *controller = [[TORController alloc] initWithControlPortFile:[self->torConfiguration controlPortFile]];
                [controller authenticateWithData:[self->torConfiguration cookie] completion:^(BOOL success, NSError *error) {
                    __weak TORController *c = controller;
                    
                    if (!success) {
                        // Update status => TOR_ERROR
                        [part updateWithStatus:TOR_ERROR];
                        return;
                    }
                    
                    void (^proceed)(void) = ^void() {
                        [c addObserverForCircuitEstablished:^(BOOL established) {
                            if (!established) {
                                return;
                            }

                            [controller getSessionConfiguration:^(NSURLSessionConfiguration *configuration) {
                                NSURLSession *torSession = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:nil];
                                NSMutableURLRequest *requestCaptchaGET = [NSMutableURLRequest new];
                                
                                [requestCaptchaGET setHTTPMethod:@"GET"];
                                [requestCaptchaGET setURL:[self captchaURL]];
                                
                                NSURLSessionTask *sessionsTaskCaptchaGET = [torSession dataTaskWithRequest:requestCaptchaGET completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                    
                                    if (data && error == nil) {
                                        NSString *requestCaptchaGETResponse = [[NSString alloc] initWithData:data encoding: NSUTF8StringEncoding];
                                        
                                        // Update status => LOADING
                                        [part updateWithStatus:LOADING];
                                        
                                        HTMLDocument *captchaDocument = [HTMLDocument documentWithString:requestCaptchaGETResponse];
                                        
                                        NSArray<HTMLElement *> *captchaImageElements = [captchaDocument querySelectorAll:@".xapca-image"];
                                        
                                        if ([captchaImageElements count] == 0) {
                                            [torSession invalidateAndCancel];
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
                                            [torSession invalidateAndCancel];
                                            [self stopDownload];
                                            return;
                                        }
                                        else if (captchaCode)
                                            [captchaData setObject:captchaCode forKey:@"captcha_value"];
                                        
                                        #ifdef DEBUG
                                            NSLog(@"%@", captchaCode);
                                        #endif
                                        
                                        NSMutableURLRequest *requestCaptchaPOST = [NSMutableURLRequest new];
                                        
                                        [requestCaptchaPOST setHTTPMethod:@"POST"];
                                        [requestCaptchaPOST setURL:[self captchaURL]];
                                        [requestCaptchaPOST addValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
                                        [requestCaptchaPOST addValue:@"Go-http-client/1.1" forHTTPHeaderField:@"User-Agent"];
                                        
                                        NSMutableString *urlEncodedData = [NSMutableString new];
                                        for (NSString *key in [captchaData keyEnumerator]) {
                                            NSString *append = [NSString stringWithFormat:@"%@=%@&", key, [captchaData objectForKey:key]];
                                            [urlEncodedData appendString:append];
                                        }
                                        // Remove last &
                                        [urlEncodedData deleteCharactersInRange:NSMakeRange([urlEncodedData length]-1, 1)];
                                        
                                        [requestCaptchaPOST setHTTPBody:[urlEncodedData dataUsingEncoding:NSUTF8StringEncoding]];
                                        
                                        NSURLSessionTask *sessionsTaskCaptchaPOST = [torSession dataTaskWithRequest:requestCaptchaPOST completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                            
                                            if (data && error == nil) {
                                                NSString *requestCaptchaPOSTResponse = [[NSString alloc] initWithData:data encoding: NSUTF8StringEncoding];
                                                
                                                NSLog(@"%@",requestCaptchaPOSTResponse);
                                                
                                                UloztoResolutionStatus validate = [self validateResponse:requestCaptchaPOSTResponse];
                                                
                                                [part updateWithStatus:validate];
                                                
                                                if (validate == OK) {
                                                    [self downloadPartWithId:partId+1 resetTor:YES failed:NO];
                                                    if (![self totalSize]) {
                                                        /*NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[self slo]]];
                                                         [request setHTTPMethod:@"HEAD"];*/
                                                    }
                                                }
                                                else if (validate == LIMIT_EXCEEDED)
                                                    [self downloadPartWithId:partId resetTor:YES failed:YES];
                                                else if (validate == FORM_ERROR_CONTENT)
                                                    [self downloadPartWithId:partId resetTor:NO failed:YES];
                                            }
                                            
                                            [torSession invalidateAndCancel];
                                        }];
                                        // Start POST request
                                        [sessionsTaskCaptchaPOST resume];
                                    } else {
                                        [torSession invalidateAndCancel];
                                    }
                                }];
                                // Start GET request
                                [sessionsTaskCaptchaGET resume];
                            }];
                        }];
                    };
                    
                    if (resetTor) {
                        // Reset TOR Circuit
                        [controller resetConnection:^(BOOL success) {
                            if (!success)
                                return;
                            proceed();
                        }];
                    } else {
                        proceed();
                    }
                }];
            });
        }
    }
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
    
    // Slow download with TOR
    TORConfiguration *torConfiguration = [TORConfiguration new];
    
    [torConfiguration setIgnoreMissingTorrc:YES];
    [torConfiguration setAvoidDiskWrites:YES];
    [torConfiguration setClientOnly:YES];
    [torConfiguration setCookieAuthentication:YES];
    [torConfiguration setAutoControlPort:YES];
    [torConfiguration setDataDirectory:[NSURL fileURLWithPath:NSTemporaryDirectory()]];
    
    self->torConfiguration = torConfiguration;
    
    if (![TORThread activeThread]) {
        TORThread *torThread = [[TORThread alloc] initWithConfiguration:torConfiguration];
        [torThread start];
    }
    
    const NSUInteger FIRST = 0;
    [self downloadPartWithId:FIRST resetTor:NO failed:NO];
}

- (void)stopDownload {
    self->STOP_DOWNLOAD = YES;
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

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task willPerformHTTPRedirection:(NSHTTPURLResponse *)response newRequest:(NSURLRequest *)request completionHandler:(void (^)(NSURLRequest * _Nullable))completionHandler {
    completionHandler(nil);
}

@end
