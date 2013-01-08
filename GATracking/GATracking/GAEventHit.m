//
//  GAEventHit.m
//  CPGATracking
//
//  Created by Ivan Ablamskyi on 19.12.12.
//  Copyright (c) 2012 Coppertino Inc. All rights reserved.
//

#import "GAEventHit.h"

@implementation GAEventHit

- (GAHitType)hitType { return GAEvent; }
- (BOOL)nonInteractive { return NO; }
- (BOOL)isMobile { return NO; }

- (NSDictionary *)dictionaryRepresentation
{
    NSMutableDictionary *dict = [@{@"t" : @"event", @"ni" : @(self.nonInteractive)} mutableCopy];
    
    if (self.category)
        [dict setValue:self.category forKey:@"ec"];
    
    if (self.action)
        [dict setValue:self.action forKey:@"ea"];
    
    if (self.label)
        [dict setValue:self.label forKey:@"el"];
    
    if (self.value)
        [dict setValue:self.value forKey:@"ev"];
    
    return [NSDictionary dictionaryWithDictionary:dict];
}

@end
