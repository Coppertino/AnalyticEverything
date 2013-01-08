//
//  GATracking.h
//  GATracking
//
//  Created by Ivan Ablamskyi on 19.12.12.
//  Copyright (c) 2012 Coppretino Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol GAHit;

/*! Google Analytics version string.  */
extern NSString *const kGAVersion;

/*!
 NSError objects returned by the Google Analytics SDK may have this error domain
 to indicate that the error originated in the Google Analytics SDK.
 */
extern NSString *const kGAErrorDomain;

/*! Google Analytics error codes.  */
typedef NS_ENUM(NSInteger, GAErrorCode) {
    kGANoError = 0,        // This error code indicates that there was no error. Never used.
    kGADatabaseError,      // This error code indicates that there was a database-related error.
    kGANetworkError,       // This error code indicates that there was a network-related error.
};

/*!
 Google Analytics top-level class. Provides facilities to create trackers and set behaviorial flags.
 */
@interface GATracking : NSObject
/*!
 The tracking identifier (the string that begins with "UA-") this tracker is
 associated with.
 
 This property is read-only.
 */
@property(nonatomic, copy, readonly) NSString *trackingId;

/*!
 Tracking data collected while this is true will be anonymized by the Google
 Analytics servers by zeroing out some of the least significant bits of the
 IP address.
 
 In the case of IPv4 addresses, the last octet is set to zero. For
 IPv6 addresses, the last 10 octets are set to zero, although this is subject to
 change in the future.
 
 By default, this flag is false.
 */
@property(nonatomic, assign) BOOL anonymize;

/*!
 Tracking information collected while this is true will be submitted to Google
 Analytics using HTTPS connection(s); otherwise, HTTP will be used. Note that
 there may be additional overhead when sending data using HTTPS in terms of
 processing costs and/or battery consumption.
 
 By default, this flag is false.
 */
@property(nonatomic, assign) BOOL useHttps;

/*!
 The client ID for the tracker.
 
 This is a persistent unique identifier generated the first time the library is
 called and persisted unchanged thereafter. It is used to identify the client
 across multiple application sessions.
 */
@property(nonatomic, copy, readonly) NSString *clientId;


+ (GATracking *)trackerWithID:(NSString *)trackingID;
- (BOOL)trackHit:(id<GAHit>)hitObject;
- (void)forcePush;

@end
