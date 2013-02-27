//
//  GAGeneralEvent.m
//  GATracking
//
//  Created by Ivan Ablamskyi on 08.01.13.
//  Copyright (c) 2013 Coppertino Inc. All rights reserved.
//

#import "GAGeneralEvent.h"
#import "GAEventHit.h"


@interface GAAppEvent : GAEventHit

@end

@implementation GAAppEvent

- (BOOL)isMobile { return YES; }

@end

@implementation GAGeneralEvent

- (BOOL)nonInteractive { return NO; }
- (BOOL)isMobile
{
    switch (self.hitType) {
        case GAAppView: return YES; break;
        case GAEvent: return YES; break;
        default: break;
    }
    return NO;
}

- (NSDictionary *)dictionaryRepresentation
{
    NSString *hitTypeString = @"pageview";
    switch (self.hitType) {
        case GAPageView:    hitTypeString = @"pageview"; break;
        case GAAppView:     hitTypeString = @"appview"; break;
        case GAEvent:       hitTypeString = @"event"; break;
        case GATransaction: hitTypeString = @"transaction"; break;
        case GAItem:        hitTypeString = @"item"; break;
        case GASocial:      hitTypeString = @"social"; break;
        case GAException:   hitTypeString = @"exception"; break;
        case GATiming:      hitTypeString = @"timing"; break;
            
        default:
            break;
    }
    NSMutableDictionary *dict = [@{@"t" : hitTypeString, @"ni" : @(self.nonInteractive)} mutableCopy];
    
    if (self.contentDescription)
        [dict setValue:self.contentDescription forKey:@"cd"];

    if (self.location)
        [dict setValue:self.location forKey:@"dl"];

    if (self.hostName)
        [dict setValue:self.hostName forKey:@"dh"];
    
    if (self.path)
        [dict setValue:self.path forKey:@"dp"];
    
    if (self.title)
        [dict setValue:self.title forKey:@"dt"];

    return [NSDictionary dictionaryWithDictionary:dict];
}

- (NSString *)description {
    NSDictionary *d = self.dictionaryRepresentation;
    return [NSString stringWithFormat:@"<%@> Value: %@", d[@"t"], d[@"cd"]];
}

#pragma mark - Quickies
+ (id)screenViewWithName:(NSString *)screenName;
{
    GAGeneralEvent *event = [[self alloc] init];
    event.hitType = GAAppView;
    event.contentDescription = screenName;
    return event;
}

+ (id)trackAppEventWithName:(NSString *)name inEventCategory:(NSString *)ec forAction:(NSString *)eventAction withValue:(NSNumber *)value;
{
    GAAppEvent *event = [GAAppEvent new];
    event.category = ec;
    event.action = eventAction;
    event.value = value;
    event.label = name;
    
    return event;
}

@end
