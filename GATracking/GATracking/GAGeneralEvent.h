//
//  GAGeneralEvent.h
//  GATracking
//
//  Created by Ivan Ablamskyi on 08.01.13.
//  Copyright (c) 2013 Coppertino Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GAHit.h"

@interface GAGeneralEvent : NSObject <GAHit>

@property (nonatomic) GAHitType hitType;
@property NSString *contentDescription;
@property NSString *location;
@property NSString *hostName;
@property NSString *path;
@property NSString *title;

+ (id)screenViewWithName:(NSString *)screenName;

+ (id)trackAppEventWithName:(NSString *)name
            inEventCategory:(NSString *)ec
                  forAction:(NSString *)eventAction
                  withValue:(NSNumber *)value;

@end
