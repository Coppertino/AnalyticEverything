//
//  GASocialHit.m
//  CPGATracking
//
//  Created by Ivan Ablamskyi on 20.12.12.
//  Copyright (c) 2012 Coppertino Inc. All rights reserved.
//

#import "GASocialHit.h"

@implementation GASocialHit

- (GAHitType)hitType { return GASocial; }
- (BOOL)nonInteractive { return NO; }
- (BOOL)isMobile { return NO; }

- (NSDictionary *)dictionaryRepresentation
{
    NSMutableDictionary *dict = [@{@"t" : @"social", @"ni" : @(self.nonInteractive)} mutableCopy];
    
    if (self.network)
        [dict setValue:self.network forKey:@"sn"];
    
    if (self.action)
        [dict setValue:self.action forKey:@"sa"];
    
    if (self.target)
        [dict setValue:self.target forKey:@"st"];
    
    
    return [NSDictionary dictionaryWithDictionary:dict];
}

@end
