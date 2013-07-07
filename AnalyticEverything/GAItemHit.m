//
//  GAItemHit.m
//  AnalyticEverythingSample
//
//  Created by Coppertino on 7/7/13.
//  Copyright (c) 2013 Coppertino Inc. All rights reserved.
//

#import "GAItemHit.h"

@implementation GAItemHit

+ (instancetype)itemWithName:(NSString *)name andSKU:(NSString *)sku andPrice:(NSNumber *)price forCurrency:(NSString *)currency;
{
    GAItemHit *item = [[self alloc] init];
    item.itemName = name;
    item.itemCode = sku;
    item.price = price;
    item.quantity = @1;
    item.currency = currency;
    
    return item;
}

- (GAHitType)hitType { return GAItem; }
- (BOOL)nonInteractive { return YES; }
- (BOOL)isMobile { return NO; }

- (NSDictionary *)dictionaryRepresentation
{
    NSMutableDictionary *dict = [@{@"t" : @"item", @"ni" : @(self.nonInteractive)} mutableCopy];
    dict[@"ti"] = self.transactionId;
    dict[@"in"] = self.itemName;
    
    if (self.itemCode)
        [dict setValue:self.itemCode forKey:@"ic"];
    
    if (self.price)
        [dict setValue:self.price forKey:@"ip"];
    
    if (self.quantity)
        [dict setValue:self.quantity forKey:@"iq"];

    if (self.category)

        [dict setValue:self.category forKey:@"iv"];
    
    if (self.currency)
        [dict setValue:self.currency forKey:@"cu"];
    
    
    return [NSDictionary dictionaryWithDictionary:dict];
}


@end
