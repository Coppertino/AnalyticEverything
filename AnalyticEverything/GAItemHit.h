//
//  GAItemHit.h
//  AnalyticEverythingSample
//
//  Created by Coppertino on 7/7/13.
//  Copyright (c) 2013 Coppertino Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GAHit.h"

@interface GAItemHit : NSObject <GAHit>

@property (nonatomic) NSString *transactionId;
@property (nonatomic) NSString *itemName;
@property (nonatomic) NSString *itemCode;
@property (nonatomic) NSString *category;

@property (nonatomic) NSString *currency;
@property (nonatomic) NSNumber *price;
@property (nonatomic) NSNumber *quantity;

+ (instancetype)itemWithName:(NSString *)name andSKU:(NSString *)sku andPrice:(NSNumber *)price forCurrency:(NSString *)currency;


@end
