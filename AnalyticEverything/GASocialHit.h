//
//  GASocialHit.h
//  CPGATracking
//
//  Created by Ivan Ablamskyi on 20.12.12.
//  Copyright (c) 2012 Coppertino Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GAHit.h"

/*!
 Social Interactions. This hit could be used for notify about social activity
 */
@interface GASocialHit : NSObject <GAHit>
/*!
 Social Network
 
 Required for social hit type.
 
 Example value: `facebook`
 */
@property (nonatomic) NSString *network;

/*!
 Social Action
 
 Required for social hit type.
 
 Specifies the social interaction action. For example on Google Plus when a user clicks the +1 button, the social action is 'plus'.
 Example value: `like`
 */
@property (nonatomic) NSString *action;

/*!
 Social Action Target
 
 Required for social hit type.
 
 Specifies the target of a social interaction. This value is typically a URL but can be any text.

 Example value: http://foo.com
 */
@property (nonatomic) NSString *target;

@end