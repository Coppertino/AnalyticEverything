//
//  GATracking.h
//  GATracking
//
//  Created by Ivan Ablamskyi on 19.12.12.
//  Copyright (c) 2012 Coppretino Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

// Plist keys to indicate ID storage
#define GA_INFO_PLIST_ID_FILE_KEY   @"GAInfoPlistIDFile"
#define GA_INFO_PLIST_ID_KEY        @"GAInfoPlistID"

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

/*!
 If true, Google Analytics debug messages will be logged with `NSLog()`. This is
 useful for debugging calls to the Google Analytics SDK.
 
 By default, this flag is set to `NO`. */
@property(nonatomic, assign) BOOL debug;


/*!
 When this is true, no tracking information will be gathered; tracking calls
 will effectively become no-ops. When set to true, all tracking information that
 has not yet been submitted. The value of this flag will be persisted
 automatically by the SDK.  Developers can optionally use this flag to implement
 an opt-out setting in the app to allows users to opt out of Google Analytics
 tracking.
 
 This is set to `NO` the first time the Google Analytics SDK is used on a
 device, and is persisted thereafter.
 */
@property(nonatomic, assign) BOOL optOut;

/*!
 If true, indicates the start of a new session. Note that when a tracker is
 first instantiated, this is initialized to true. To prevent this default
 behavior, set this to `NO` when the tracker is first obtained.
 
 By itself, setting this does not send any data. If this is true, when the next
 tracking call is made, a parameter will be added to the resulting tracking
 information indicating that it is the start of a session, and this flag will be
 cleared.
 */
@property(nonatomic, assign) BOOL sessionStart;

/*!
 If this value is negative, tracking information must be sent manually by
 calling dispatch. If this value is zero, tracking information will
 automatically be sent as soon as possible (usually immediately if the device
 has Internet connectivity). If this value is positive, tracking information
 will be automatically dispatched every dispatchInterval seconds.
 
 When the dispatchInterval is non-zero, setting it to zero will cause any queued
 tracking information to be sent immediately.
 
 By default, this is set to `120`, which indicates tracking information should
 be dispatched automatically every 120 seconds.
 */
@property(nonatomic, assign) NSTimeInterval dispatchInterval;

/*!
 When set to true, the SDK will record the currently registered uncaught
 exception handler, and then register an uncaught exception handler which tracks
 the exceptions that occurred using defaultTracker. If defaultTracker is not
 `nil`, this function will track the exception on the tracker and attempt to
 dispatch any outstanding tracking information for 5 seconds. It will then call
 the previously registered exception handler, if any. When set back to false,
 the previously registered uncaught exception handler will be restored.
 */
@property(nonatomic, assign) BOOL trackUncaughtExceptions;

+ (GATracking *)sharedTracker;
+ (GATracking *)trackerWithID:(NSString *)trackingID;

- (BOOL)trackHit:(id<GAHit>)hitObject;
/*!
 Dispatches any pending tracking information.
 
 It would be wise to call this when application is exiting to initiate the
 submission of any unsubmitted tracking information. Note that this does not
 have any effect on dispatchInterval, and can be used in conjuntion with
 periodic dispatch. */
- (void)dispatch;

#pragma mark - Simplified tracks
/*!
 Track that the specified view or screen was displayed. This call sets
 the appScreen property and generates tracking information to be sent to Google
 Analytics.
 
 If [GAI optOut] is true, this will not generate any tracking information.
 
 @param screen The name of the screen. Must not be `nil`.
 
 @return `YES` if the tracking information was queued for dispatch, or `NO` if
 there was an error (e.g. the tracker was closed).
 */
- (BOOL)sendView:(NSString *)screen;

/*!
 Track an event.
 
 If [GAI optOut] is true, this will not generate any tracking information.
 
 @param category The event category, or `nil` if none.
 
 @param action The event action, or `nil` if none.
 
 @param label The event label, or `nil` if none.
 
 @param value The event value, to be interpreted as a 64-bit signed integer, or
 `nil` if none.
 
 @return `YES` if the tracking information was queued for dispatch, or `NO` if
 there was an error (e.g. the tracker was closed).
 */
- (BOOL)sendEventWithCategory:(NSString *)category
                   withAction:(NSString *)action
                    withLabel:(NSString *)label
                    withValue:(NSNumber *)value;


/*!
 Track an exception.
 
 If [GAI optOut] is true, this will not generate any tracking information.
 
 @param isFatal A boolean indicating whether the exception is fatal.
 
 @param format A format string that will be used to create the exception
 description.
 
 @param ... An optional list of arguments to be substituted using the format
 string.
 
 @return `YES` if the tracking information was queued for dispatch, or `NO` if
 there was an error (e.g. the tracker was closed).
 */
- (BOOL)sendException:(BOOL)isFatal
      withDescription:(NSString *)format, ...;

/*! Convenience method for tracking an NSException that passes the exception
 name to trackException:withDescription:.
 
 If [GAI optOut] is true, this will not generate any tracking information.
 
 @param isFatal A boolean indicating whether the exception is fatal.
 
 @param exception The NSException exception object.
 
 @return `YES` if the tracking information was queued for dispatch, or `NO` if
 there was an error (e.g. the tracker was closed).
 */
- (BOOL)sendException:(BOOL)isFatal
      withNSException:(NSException *)exception;

/*! Convenience method for tracking an NSError that passes the domain, code, and
 description to trackException:withDescription:.
 
 If [GAI optOut] is true, this will not generate any tracking information.
 
 @param isFatal A boolean indicating whether the exception is fatal.
 
 @param error The NSError error object.
 
 @return `YES` if the tracking information was queued for dispatch, or `NO` if
 there was an error (e.g. the tracker was closed).
 */
- (BOOL)sendException:(BOOL)isFatal
          withNSError:(NSError *)error;

/*!
 Track social action.
 
 If [GAI optOut] is true, this will not generate any tracking information.
 
 @param network A string representing social network. Must not be nil.
 
 @param action A string representing a social action. Must not be nil.
 
 @param target A string representing the target. May be nil.
 
 @return `YES` if the tracking information was queued for dispatch, or `NO` if
 there was an error (e.g. the tracker was closed).
 */
- (BOOL)sendSocial:(NSString *)network
        withAction:(NSString *)action
        withTarget:(NSString *)target;
@end
