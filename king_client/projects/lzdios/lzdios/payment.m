//
//  payment.m
//  lzdios
//
//  Created by elliotlee on 2018/7/26.
//  Copyright © 2018年 egret. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "payment.h"
#import "sdk.h"

@implementation PaymentMgr
{
    
}

static PaymentMgr *_instace = nil;

+ (instancetype) shareInstance {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instace = [[self alloc] init];
    });
    return _instace;
}

- (void) init:(AppDelegate *)app {
    appInst = app;
    productInfos = [NSMutableDictionary dictionary];
    [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
}

- (void) validateProductIdentifiers:(NSArray *)productIdentifiers {
    SKProductsRequest *productsRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:[NSSet setWithArray:productIdentifiers]];
    self->request = productsRequest;
    productsRequest.delegate = self;
    [productsRequest start];
}

- (NSString *) localizedProductPrice:(SKProduct *)product {
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    [formatter setNumberStyle:NSNumberFormatterCurrencyStyle];
    [formatter setLocale:product.priceLocale];
    NSLog(@"%@", formatter.currencyCode);
    return [formatter stringFromNumber:product.price];
}

// SKProductsRequestDelegate protocol method
- (void) productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response {
    NSArray *products = response.products;
    for (SKProduct *info in products) {
        if (info != nil) {
            NSString *pid = info.productIdentifier;
            [productInfos setObject:info forKey:pid];
            NSLog(@"product: [id=%@, price=%d localized_price=%@]", info.productIdentifier, [info.price intValue], [self localizedProductPrice:info]);
        }
    }
    
    for (NSString * invalidId in response.invalidProductIdentifiers) {
        [productInfos removeObjectForKey:invalidId];
        NSLog(@"invalid product: [%@]", invalidId);
    }
    
    NSMutableArray *pids = [NSMutableArray array];
    for (NSString *pid in productInfos) {
        SKProduct *product = [productInfos objectForKey:pid];
        NSArray *pinfo = @[
                            product.productIdentifier,
                            product.price,
                            [self localizedProductPrice:product]
                        ];
        [pids addObject:pinfo];
    }
    NSDictionary *args = @{@"success":@true, @"info":pids};
    [[SDKBase getSdkInstance] callToJS:@"appstoreGetProducts" withArgs:args];
}

- (void) pay:(NSString *)productIdentifier withPrice:(int)price withCount:(int)count {
    SKProduct *product = [productInfos objectForKey:productIdentifier];
    if (product == nil) {
        [[SDKBase getSdkInstance] callToJS:@"finishPay" withArgs:@{@"success":@false, @"productId":productIdentifier, @"reason":@"商品信息不存在"}];
    } else {
        SKMutablePayment *payment = [SKMutablePayment paymentWithProduct:product];
        payment.quantity = count;
        [[SKPaymentQueue defaultQueue] addPayment:payment];
    }
}

- (void) onPaySuccess:(SKPaymentTransaction *)transaction {
    NSData *receiptData;
    if (NSFoundationVersionNumber >= NSFoundationVersionNumber_iOS_7_0) {
        receiptData = [NSData dataWithContentsOfURL:[[NSBundle mainBundle] appStoreReceiptURL]];
    } else {
        receiptData = transaction.transactionReceipt;
    }
    
    NSString *receipt = [self encodeWithBase64:(uint8_t*)receiptData.bytes length:receiptData.length];
    NSDictionary *args = @{@"success":@true, @"productId":transaction.payment.productIdentifier, @"receipt":receipt};
    [[SDKBase getSdkInstance] callToJS:@"finishPay" withArgs:args];
    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
    
    SKProduct *product = [productInfos objectForKey:transaction.payment.productIdentifier];
    if (product != nil) {
        [[SDKBase getSdkInstance] onPaySuccess:product];
    }
}

- (void) onPayFail:(SKPaymentTransaction *)transaction forReason:(NSString *)reason {
    NSString *productIdentifier = transaction.payment.productIdentifier;
    [[SDKBase getSdkInstance] callToJS:@"finishPay" withArgs:@{@"success":@false, @"productId":productIdentifier, @"reason":reason}];
    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
}

// SKPaymentTransactionObserver protocol method
- (void) paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray<SKPaymentTransaction *> *)transactions {
    for (SKPaymentTransaction *transaction in transactions) {
        switch (transaction.transactionState) {
            case SKPaymentTransactionStatePurchasing:
                NSLog(@"Purchasing %@", transaction.payment.productIdentifier);
                break;
            case SKPaymentTransactionStateDeferred:
                NSLog(@"Purchase deferred %@", transaction.payment.productIdentifier);
                break;
            case SKPaymentTransactionStatePurchased:
                NSLog(@"==== Purchased %@", transaction.payment.productIdentifier);
                [self onPaySuccess:transaction];
                break;
            case SKPaymentTransactionStateFailed:
                NSLog(@"==== Purchase failed %@", transaction.error.localizedDescription);
                [self onPayFail:transaction forReason:transaction.error.localizedDescription];
                break;
            case SKPaymentTransactionStateRestored:
                NSLog(@"==== Purchase restored %@", transaction.payment.productIdentifier);
                [self onPaySuccess:transaction];
                break;
            default:
                NSLog(@"Unexpected transaction state %@", @(transaction.transactionState));
                break;
        }
    }
}

- (NSString *)encodeWithBase64:(const uint8_t *)input length:(NSInteger)length {
    static char table[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=";
    
    NSMutableData *data = [NSMutableData dataWithLength:((length + 2) / 3) * 4];
    uint8_t *output = (uint8_t *)data.mutableBytes;
    
    for (NSInteger i = 0; i < length; i += 3) {
        NSInteger value = 0;
        for (NSInteger j = i; j < (i + 3); j++) {
            value <<= 8;
            
            if (j < length) {
                value |= (0xFF & input[j]);
            }
        }
        
        NSInteger index = (i / 3) * 4;
        output[index + 0] =                    table[(value >> 18) & 0x3F];
        output[index + 1] =                    table[(value >> 12) & 0x3F];
        output[index + 2] = (i + 1) < length ? table[(value >> 6)  & 0x3F] : '=';
        output[index + 3] = (i + 2) < length ? table[(value >> 0)  & 0x3F] : '=';
    }
    
    return [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
}
@end
