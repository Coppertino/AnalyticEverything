//
//  CPAppDelegate.m
//  GoogleAnalyticsSample
//
//  Created by Ivan Ablamskyi on 19.12.12.
//  Copyright (c) 2012 Coppertino Inc. All rights reserved.
//

#import "CPAppDelegate.h"
#import "DDLog.h"

#import "GATracking.h"
#import "GAGeneralEvent.h"
#import "GATransactionEventHit.h"

@implementation CPAppDelegate
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
    GATracking *tracking = [GATracking trackerWithID:@"UA-523507-58"]; /// <---------- YOUR ID here
    tracking.debug = YES;
//    GATracking *tracking = [GATracking sharedTracker];
    [tracking sendView:@"MainView"];
    [tracking sendEventWithCategory:@"States" withAction:@"Load" withLabel:@"Screen load" withValue:@(100)];
    
    [self.window.contentView setWantsLayer:YES];
    
    [[self.window.contentView layer] setBackgroundColor:[[NSColor selectedMenuItemColor] CGColor]];
    
    
    GATransactionEventHit *trx = [GATransactionEventHit transactionWithID:@"000001" forCurrency:@"USD"];
    [trx addItem:[GAItemHit itemWithName:@"TEST" andSKU:@"com.coppertino.TestItem" andPrice:@0.99 forCurrency:@"USD"]];
    [tracking trackHit:trx];
    
    [tracking dispatch];
}

@end
