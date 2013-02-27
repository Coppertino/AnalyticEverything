//
//  GATracking.m
//  GATracking
//
//  Created by Ivan Ablamskyi on 19.12.12.
//  Copyright (c) 2012 Coppertino Inc. All rights reserved.
//

#import "GATracking.h"
#import "GAHit.h"
#import "GAGeneralEvent.h"
#import "GASocialHit.h"
#import "GAExceptionHit.h"
#import <ExceptionHandling/ExceptionHandling.h>

// Pods
#import <AFNetworking/AFHTTPClient.h>
#import <CocoaLumberjack/DDTTYLogger.h>
#import <CocoaLumberjack/DDASLLogger.h>
#import <libextobjc/extobjc.h>


NSString *const kGAVersion = @"1";
NSString *const kGAErrorDomain = @"com.google-analytics.errorDomain";
NSString *const kGAReceiverURLString = @"http://www.google-analytics.com/collect";
NSString *const kGASecureReceiverURLString = @"https://ssl.google-analytics.com/collect";
NSString *const kGAUUIDKey = @"_googleAnalyticsUUID_";
NSString *const kGASavedHitsKey = @"_googleAnalyticsOLDHits_";



@interface GATracking (/*Private*/)
@property (nonatomic) NSMutableArray *hits;
@property (nonatomic) AFHTTPClient *httpClient;
@property (nonatomic) NSTimer *timer;
@property (nonatomic, copy, readwrite)  NSString *trackingId;
@property (nonatomic) NSUInteger sessionCount;
@property (nonatomic) BOOL terminating, sessionChanged;
@end

@implementation GATracking
@synthesize clientId = _clientId;

+ (GATracking *)sharedTracker {
    static GATracking *_sharedTracker = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *googleID = nil;
        NSDictionary* infoDict = [[NSBundle mainBundle] infoDictionary];
        NSString *key = [infoDict objectForKey:GA_INFO_PLIST_ID_FILE_KEY];
        if (key)
        {
            NSString *filePath = [[NSBundle mainBundle] pathForResource:key
                                                                 ofType:nil];
            NSData *data = [NSData dataWithContentsOfFile:filePath];
            
            if (data)
            {
                googleID = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            }
        }
        
        if (!googleID)
        {
            googleID = [infoDict objectForKey:GA_INFO_PLIST_ID_KEY];
        }
        
        if (!googleID || [googleID isEqualToString:@""])
        {
            NSLog(@"Couldn't find id file");
        } else {
            NSLog(@"Found id: %@",googleID);
            _sharedTracker = [GATracking trackerWithID:googleID];
        }
    });
    
    return _sharedTracker;
}

+ (GATracking *)trackerWithID:(NSString *)trackingID;
{
    GATracking *tracker = [[self alloc] init];
    if (trackingID) {
        tracker.trackingId = trackingID;
        tracker.trackUncaughtExceptions = YES;

        // Restore prev hits
        NSArray *prevHits = [[NSUserDefaults standardUserDefaults] objectForKey:kGASavedHitsKey];
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:kGASavedHitsKey];
        if (prevHits && prevHits.count > 0) {
            [tracker.hits addObjectsFromArray:prevHits];
            [tracker dispatch];
        }
    }
    
    return tracker;
}

- (id)init {
    self = [super init];
    if (self) {
        self.hits = [NSMutableArray array];
        self.httpClient = [AFHTTPClient clientWithBaseURL:[NSURL URLWithString:kGAReceiverURLString]];
        self.dispatchInterval = 120;
        
#ifdef DEBUG
        self.debug = YES;
#endif

        @weakify(self);
        
        // If there are appDelegate than we need to extends its functionality, otherwise set self as delegate

        if ([NSApp delegate]) {
            id appDelegate = [NSApp delegate];
            NSApplicationTerminateReply (^AppTerminationBlock)(NSApplication *) = ^(NSApplication *app){
                if (self.hits.count > 0) {
                    self.terminating = YES;
                    [self dispatch];
                    return (NSApplicationTerminateReply)NSTerminateLater;
                }
                return (NSApplicationTerminateReply)NSTerminateNow;
            };
            
            ext_addBlockMethod([appDelegate class], @selector(applicationShouldTerminate:), AppTerminationBlock, ext_copyBlockTypeEncoding(AppTerminationBlock));
            
        } else {
            [NSApp setDelegate:self];
        }
        
        [[NSNotificationCenter defaultCenter] addObserverForName:AFNetworkingReachabilityDidChangeNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
            if ([[note.userInfo valueForKey:AFNetworkingReachabilityNotificationStatusItem] integerValue] > AFNetworkReachabilityStatusNotReachable)
                @strongify(self);
                [self logString:@"Reachability: %@", note];
                [self dispatch];
        }];
        
        [[NSNotificationCenter defaultCenter] addObserverForName:NSApplicationWillTerminateNotification object:NSApp queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
            @strongify(self);
            [self logString:@"Application will terminate: %@", note];
            NSMutableArray *saveHits = [NSMutableArray arrayWithCapacity:self.hits.count];
            [self.hits enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                [saveHits addObject:[obj dictionaryRepresentation]];
            }];
            
            
            [NSApp replyToApplicationShouldTerminate:NO];
            
            [[NSUserDefaults standardUserDefaults] setObject:saveHits forKey:kGASavedHitsKey];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }];
    }
    
    return self;
}

- (void)dealloc
{
    [self dispatch];
}

#pragma mark - Helpers
- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender;
{
    return NSTerminateLater;
}

- (void)logString:(NSString *)format, ...;
{
    va_list args;
	if (self.debug && format)
	{
		va_start(args, format);
		
		NSString *logMsg = [[NSString alloc] initWithFormat:format arguments:args];
		DDLogInfo(@"%@",logMsg);
		
		va_end(args);
	}

}

- (void)dispatch:(NSTimer *)timer;
{
    [self logString:@"[%@] Fire events (size: %@)", [timer fireDate], @(self.hits.count)];
    [self dispatch];
}

#pragma mark - Setter
- (void)setUseHttps:(BOOL)useHttps
{
    if (useHttps != _useHttps) {
        _useHttps = useHttps;
        self.httpClient = [AFHTTPClient clientWithBaseURL:
                           [NSURL URLWithString:(_useHttps ? kGASecureReceiverURLString : kGAReceiverURLString)]];
    }
}

- (void)setHttpClient:(AFHTTPClient *)httpClient
{
    _httpClient = httpClient;
    if (_httpClient) {
        NSDictionary *osInfo = [NSDictionary dictionaryWithContentsOfFile:@"/System/Library/CoreServices/SystemVersion.plist"];
        
        NSLocale *currentLocale = [NSLocale autoupdatingCurrentLocale];
        NSString *UA = [NSString stringWithFormat:@"GoogleAnalytics/2.0 (Macintosh; Intel %@ %@; %@-%@)",
                        osInfo[@"ProductName"], [osInfo[@"ProductVersion"] stringByReplacingOccurrencesOfString:@"." withString:@"_"],
                        [currentLocale objectForKey:NSLocaleLanguageCode], [currentLocale objectForKey:NSLocaleCountryCode]];
        
        [_httpClient setDefaultHeader:@"User-Agent" value:UA];
    }
}

- (void)setTrackUncaughtExceptions:(BOOL)trackUncaughtExceptions;
{
    _trackUncaughtExceptions = trackUncaughtExceptions;
    
    if (trackUncaughtExceptions) {
        [[NSExceptionHandler defaultExceptionHandler] setDelegate:self];
        [[NSExceptionHandler defaultExceptionHandler] setExceptionHandlingMask: NSLogAndHandleEveryExceptionMask];
    } else {
        [[NSExceptionHandler defaultExceptionHandler] setDelegate:nil];
        [[NSExceptionHandler defaultExceptionHandler] setExceptionHandlingMask: 0];
    }
}

- (void)setDispatchInterval:(NSTimeInterval)dispatchInterval;
{
    _dispatchInterval = dispatchInterval;
    if (self.timer) {
        [self.timer invalidate];
        self.timer = nil;
    }
    
    if (dispatchInterval > 0) {
        self.timer = [NSTimer scheduledTimerWithTimeInterval:dispatchInterval target:self selector:@selector(dispatch:) userInfo:NULL repeats:YES];
    }
}

#pragma mark - Visitor
- (NSString *)clientId {
    if (![[NSUserDefaults standardUserDefaults] stringForKey:kGAUUIDKey]) {
        CFUUIDRef theUUID = CFUUIDCreate(NULL);
        CFStringRef string = CFUUIDCreateString(NULL, theUUID);
        CFRelease(theUUID);
        [[NSUserDefaults standardUserDefaults] setValue:CFBridgingRelease(string) forKey:kGAUUIDKey];
    }
    
    if (!_clientId) {
        _clientId = [[NSUserDefaults standardUserDefaults] stringForKey:kGAUUIDKey];
    }
    
    return _clientId;
}

#pragma mark - App Tracking
- (NSString *)appName { return [[[NSBundle mainBundle] infoDictionary] valueForKey:(id)kCFBundleNameKey]; }
- (NSString *)appVersion { return [[[NSBundle mainBundle] infoDictionary] valueForKey:(id)kCFBundleVersionKey]; }
- (NSString *)appId { return [[NSBundle mainBundle] bundleIdentifier]; }

#pragma mark - System Info
- (NSString *)screenResolution {
    NSSize size = [[[[NSScreen mainScreen] deviceDescription] valueForKey:NSDeviceSize] sizeValue];
    return [NSString stringWithFormat:@"%ix%i", (int)size.width, (int)size.height];
}

- (NSString *)screenColors {
    NSInteger bits = NSBitsPerPixelFromDepth([[NSScreen mainScreen] depth]);
    return [NSString stringWithFormat:@"%lu-bit", bits];
}

- (NSString *)userLanguage {
    NSString *lang = [[NSLocale preferredLanguages] objectAtIndex:0];
    NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier: [lang isEqualToString:@"en"] ? @"en_US" : lang];
    
    return [NSString stringWithFormat:@"%@-%@", [locale objectForKey:NSLocaleLanguageCode], [locale objectForKey:NSLocaleCountryCode]];
}

#pragma mark - Excpetion delegate
- (BOOL)exceptionHandler:(NSExceptionHandler *)sender shouldHandleException:(NSException *)exception mask:(NSUInteger)aMask
{
    [self sendException:NO withNSException:exception];
    return YES;
}

#pragma mark - Trackers
- (BOOL)trackHit:(id<GAHit>)hitObject;
{
    // User do not like tracking
    if (self.optOut)
        return NO;
    
    // Limits 
    if (self.sessionCount > 500)
        return NO;

    [self.hits addObject:hitObject];
    [self logString:@"Added hit: %@", hitObject];
    return YES;
}


#pragma mark - Senders
- (void)dispatch;
{
    NSAssert(self.trackingId, @"Tracking ID not specified");
    NSDictionary *defaultParams = @{@"v" : kGAVersion, @"tid" : self.trackingId, @"cid" : self.clientId,
    @"an" : @(self.anonymize),
    @"sr" : [self screenResolution],
    @"sd" : [self screenColors],
    @"ul" : [self userLanguage],
    };
    NSOrderedSet *copyHits = [self.hits copy];
    
    [copyHits enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
              
        DDLogVerbose(@"index. %@", @(idx));
        
        NSMutableDictionary *params = [defaultParams mutableCopy];
        if ([obj isKindOfClass:[NSDictionary class]]) {
            [params addEntriesFromDictionary:params];
            [params addEntriesFromDictionary:@{
             @"an" : [self appName],
             @"av" : [self appVersion],
             }];
        } else {
            id<GAHit>hit = obj;
            
//            if ([hit isMobile]) {
                [params addEntriesFromDictionary:@{
                 @"an" : [self appName],
                 @"av" : [self appVersion],
                 }];
//            }
            
            [params addEntriesFromDictionary:[hit dictionaryRepresentation]];
        }
        
        // Start session
        if (idx == 0 && self.sessionChanged && self.sessionStart) {
            [params addEntriesFromDictionary:@{ @"sc" : @"start" }];
        }
        
        // Stop session
        if (self.hits.count == 1 && (self.terminating || (self.sessionChanged && !self.sessionStart))) {
            [params addEntriesFromDictionary:@{ @"sc" : @"stop" }];
        }
        
        [self.httpClient postPath:@"/collect" parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
            [self logString:@"succes post info (%@) %@", params, [NSString stringWithUTF8String:[(NSData *)responseObject bytes]]];
            [self.hits removeObject:obj];
            self.sessionCount = self.sessionCount + 1;

            if (self.hits.count == 0 && self.terminating) {
                [NSApp replyToApplicationShouldTerminate:YES];
            }

        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            [self logString:@"Fail to submit params: %@ with error %@", params, error];
            // Remove from queue anyway
            [self.hits removeObject:obj];

            if (self.hits.count == 0 && self.terminating) {
                [NSApp replyToApplicationShouldTerminate:YES];
            }
        }];
    }];
}

- (BOOL)sendView:(NSString *)screen;
{
    return [self trackHit:[GAGeneralEvent screenViewWithName:screen]];
}

- (BOOL)sendEventWithCategory:(NSString *)category withAction:(NSString *)action withLabel:(NSString *)label withValue:(NSNumber *)value;
{
    return [self trackHit:[GAGeneralEvent trackAppEventWithName:label inEventCategory:category forAction:action withValue:value]];
}

- (BOOL)sendSocial:(NSString *)network withAction:(NSString *)action withTarget:(NSString *)target;
{
    GASocialHit *hit = [GASocialHit new];
    hit.network = network;
    hit.action = action;
    hit.target = target;
    
    return [self trackHit:hit];
}

- (BOOL)sendException:(BOOL)isFatal withDescription:(NSString *)format, ...;
{
    va_list args;
	if (format)
	{
		va_start(args, format);
		
		NSString *logMsg = [[NSString alloc] initWithFormat:format arguments:args];
		
        return [self trackHit:[GAExceptionHit exceptionHitWithDescription:logMsg isFatal:isFatal]];
		
		va_end(args);
	}

    return NO;
}

- (BOOL)sendException:(BOOL)isFatal withNSError:(NSError *)error
{
    return [self sendException:isFatal withDescription:@"error:%@:%@:%@", error.domain, @(error.code), error.localizedDescription];
}

- (BOOL)sendException:(BOOL)isFatal withNSException:(NSException *)exception
{
    return [self sendException:isFatal withDescription:@"exception:%@",[exception description]];
}

@end
