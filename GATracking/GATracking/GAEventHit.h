//
//  GAEventHit.h
//  CPGATracking
//
//  Created by Ivan Ablamskyi on 19.12.12.
//  Copyright (c) 2012 Coppertino Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GAHit.h"

@interface GAEventHit : NSObject <GAHit>

@property NSString *category;
@property NSString *action;
@property NSString *label;
@property NSValue *value;

@end
