//
//  GATransactionEvent.m
//  AnalyticEverythingSample
//
//  Created by Coppertino on 7/7/13.
//  Copyright (c) 2013 Coppertino Inc. All rights reserved.
//

#import "GATransactionEventHit.h"

@implementation GATransactionEventHit
{
    NSMutableArray *_items;
}

+ (instancetype)transactionWithID:(NSString *)transactionID forCurrency:(NSString *)currency;
{
    GATransactionEventHit *trx = [[self alloc] init];
    
    trx.transactionId = transactionID;
    trx.currency = currency;
    
    return trx;
}

- (GAHitType)hitType { return GATransaction; }
- (BOOL)nonInteractive { return NO; }
- (BOOL)isMobile { return YES; }

- (NSDictionary *)dictionaryRepresentation
{
    NSMutableDictionary *dict = [@{@"t" : @"transaction", @"ni" : @(self.nonInteractive)} mutableCopy];
    dict[@"ti"] = self.transactionId;

    if (self.affiliate)
        dict[@"ta"] = self.affiliate;
    
    if (self.revenue)
        dict[@"tr"] = self.revenue;
    
    if (self.shipping)
        dict[@"ts"] = self.shipping;
    
    if (self.tax)
        dict[@"tt"] = self.tax;
    
    if (self.currency)
        dict[@"cu"] = self.currency;
    
    return dict;
    
}

- (void)addItem:(GAItemHit *)item
{
    if (!_items)
        _items = [NSMutableArray array];
    
    item.transactionId = self.transactionId;

    [_items addObject:item];
}

- (NSArray *)items
{
    return _items;
}


@end
