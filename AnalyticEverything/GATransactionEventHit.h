//
//  GATransactionEvent.h
//  AnalyticEverythingSample
//
//  Created by Coppertino on 7/7/13.
//  Copyright (c) 2013 Coppertino Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GAHit.h"
#import "GAItemHit.h"

@interface GATransactionEventHit : NSObject <GAHit>

@property (nonatomic) NSString *transactionId;
@property (nonatomic) NSString *affiliate;

@property (nonatomic) NSNumber *revenue;
@property (nonatomic) NSNumber *shipping;
@property (nonatomic) NSNumber *tax;
@property (nonatomic) NSString *currency;


+ (instancetype)transactionWithID:(NSString *)transactionID forCurrency:(NSString *)currency;
- (void)addItem:(GAItemHit *)item;
- (NSArray *)items;


@end
