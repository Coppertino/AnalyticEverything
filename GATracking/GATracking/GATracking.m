//
//  GATracking.m
//  GATracking
//
//  Created by Ivan Ablamskyi on 19.12.12.
//  Copyright (c) 2012 Coppertino Inc. All rights reserved.
//

#import "GATracking.h"
#import "GAHit.h"

#import <WebKit/WebKit.h>

// Pods
#import <AFNetworking/AFHTTPClient.h>
#import <CocoaLumberjack/DDTTYLogger.h>
#import <CocoaLumberjack/DDASLLogger.h>

NSString *const kGAVersion = @"1";
NSString *const kGAErrorDomain = @"com.google-analytics.errorDomain";
NSString *const kGAReceiverURLString = @"http://www.google-analytics.com/collect";
NSString *const kGASecureReceiverURLString = @"https://ssl.google-analytics.com/collect";
NSString *const kGAUUIDKey = @"_googleAnalyticsUUID_";

@interface GATracking (/*Private*/)
@property (nonatomic) NSMutableOrderedSet *hits;
@property (nonatomic) AFHTTPClient *httpClient;
@property (nonatomic) NSUInteger queueSize;
@property (nonatomic, copy, readwrite)  NSString *trackingId;
@end

@implementation GATracking
@synthesize clientId = _clientId;

+ (void)initialize
{
    // Logging setup
    [DDLog addLogger:[DDASLLogger sharedInstance]];
    [DDLog addLogger:[DDTTYLogger sharedInstance]];
    
    [[DDTTYLogger sharedInstance] setForegroundColor:[NSColor greenColor] backgroundColor:nil forFlag:LOG_FLAG_INFO];
    [[DDTTYLogger sharedInstance] setForegroundColor:[NSColor redColor] backgroundColor:nil forFlag:LOG_FLAG_ERROR];
    [[DDTTYLogger sharedInstance] setForegroundColor:[NSColor blueColor] backgroundColor:nil forFlag:LOG_FLAG_VERBOSE];
    [[DDTTYLogger sharedInstance] setForegroundColor:[NSColor orangeColor] backgroundColor:nil forFlag:LOG_FLAG_WARN];
    
    [[DDTTYLogger sharedInstance] setColorsEnabled:YES];
}

+ (GATracking *)trackerWithID:(NSString *)trackingID;
{
    GATracking *tracker = [[self alloc] init];
    if (trackingID) {
        tracker.trackingId = trackingID;
    }
    
    return tracker;
}

- (id)init {
    self = [super init];
    if (self) {
        self.queueSize = 5;
        self.hits = [NSMutableOrderedSet orderedSetWithCapacity:self.queueSize*2];
        self.httpClient = [AFHTTPClient clientWithBaseURL:[NSURL URLWithString:kGAReceiverURLString]];

        __weak __typeof(&*self) weakSelf = self;
        [[NSNotificationCenter defaultCenter] addObserverForName:AFNetworkingReachabilityDidChangeNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
            DDLogInfo(@"Netwokr status changes: %@", note);
            
            if ([[note.userInfo valueForKey:AFNetworkingReachabilityNotificationStatusItem] integerValue] > AFNetworkReachabilityStatusNotReachable)
                [weakSelf pushHits];
        }];
}
    
    return self;
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
        WebView *wv = [[WebView alloc] init];
        [_httpClient setDefaultHeader:@"User-Agent" value:[wv userAgentForURL:_httpClient.baseURL]];
        wv = nil;
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
    return [NSString stringWithFormat:@"%fx%f", size.width, size.height];
}

- (NSString *)screenColors {
    NSInteger bits = NSBitsPerPixelFromDepth([[NSScreen mainScreen] depth]);
    return [NSString stringWithFormat:@"%lu-bit", bits];
}

- (NSString *)userLanguage { return [[NSUserDefaults standardUserDefaults] valueForKey:@"AppleLocale"]; }

#pragma mark - Trackers
- (BOOL)trackHit:(id<GAHit>)hitObject;
{
    DDLogVerbose(@"Add hit: %@", hitObject);
    
//    NSAssert([hitObject conformsToProtocol:@protocol(GAHit)], @"Track object have be GA Hit type");
    if (self.hits.count < (self.queueSize * 2)) {
        [self.hits addObject:hitObject];
        return YES;
    }
    DDLogWarn(@"Queue is full. Event %@ will skipped.", hitObject);
    return NO;
}


#pragma mark - Senders
- (void)forcePush;
{
    NSAssert(self.trackingId, @"Tracking ID not specified");
    NSDictionary *defaultParams = @{@"v" : kGAVersion, @"tid" : self.trackingId, @"cid" : self.clientId, @"an" : @(self.anonymize) };
    NSOrderedSet *copyHits = [self.hits copy];
    
    [copyHits enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSMutableDictionary *params = [defaultParams mutableCopy];
        id<GAHit>hit = obj;
        
        if ([hit isMobile]) {
            [params addEntriesFromDictionary:@{
             @"an" : [self appName],
             @"av" : [self appVersion],
             }];
        }
        
        [params addEntriesFromDictionary:[hit dictionaryRepresentation]];
        
        [self.httpClient postPath:@"/collect" parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
            DDLogInfo(@"succes post info %@", [NSString stringWithUTF8String:[(NSData *)responseObject bytes]]);
            [self.hits removeObject:obj];
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            DDLogError(@"Fail to submit params: %@ with error %@", params, error);
        }];
    }];
}

- (BOOL)pushHits;
{
    // Queue size and network is available
    if (self.hits.count >= self.queueSize && self.httpClient.networkReachabilityStatus > AFNetworkReachabilityStatusNotReachable) {
        [self forcePush];
        return YES;
    }
    
    return NO;
}

@end
