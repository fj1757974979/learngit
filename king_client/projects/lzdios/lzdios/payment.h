//
//  payment.h
//  lzdios
//
//  Created by elliotlee on 2018/7/26.
//  Copyright © 2018年 egret. All rights reserved.
//

#pragma once

#import <StoreKit/StoreKit.h>
#import "AppDelegate.h"


@interface PaymentMgr : NSObject <SKProductsRequestDelegate, SKPaymentTransactionObserver>
{
    AppDelegate *appInst;
    SKProductsRequest *request;
    NSMutableDictionary *productInfos;
}
- (void)init:(AppDelegate *)app;
- (void)validateProductIdentifiers:(NSArray *)productIdentifiers;
- (void)pay:(NSString *)productIdentifier withPrice:(int)price withCount:(int)count;
+ (instancetype)shareInstance;
@end
