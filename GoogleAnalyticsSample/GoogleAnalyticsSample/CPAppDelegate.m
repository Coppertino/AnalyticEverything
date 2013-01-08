//
//  CPAppDelegate.m
//  GoogleAnalyticsSample
//
//  Created by Ivan Ablamskyi on 19.12.12.
//  Copyright (c) 2012 Coppertino Inc. All rights reserved.
//

#import "CPAppDelegate.h"
#import "DDLog.h"
#import <GATracking.h>
#import <GAGeneralEvent.h>

@implementation CPAppDelegate
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
    GATracking *tracking = [GATracking trackerWithID:@"UA-000000-XX"]; /// <---------- YOUR ID here
    [tracking trackHit:[GAGeneralEvent screenViewWithName:@"MainView"]];
    [tracking trackHit:[GAGeneralEvent trackAppEventWithName:@"Window" inEventCategory:@"states" forAction:@"load" withValue:NULL]];
    [tracking performSelector:@selector(forcePush)];
    
    
}

@end
