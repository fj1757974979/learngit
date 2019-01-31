//
//  yomob.m
//  lzdios
//
//  Created by elliotlee on 2018/7/26.
//  Copyright © 2018年 egret. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ads.h"
#import "yomob.h"

@implementation YomobAds {
    
}
- (void) init: (AppDelegate *)app {
    [super init:app];
//    [TGSDK setDebugModel:YES];
    [TGSDK initialize:@"q90307O68Ln56cGH5oo1" callback:nil];
    [TGSDK setADDelegate:self];
//    NSLog(@"yomob ads init");
}

- (void) preload {
    [super preload];
    [TGSDK preloadAd:nil];
//    NSLog(@"yomob ads preload");
}

- (BOOL) isAdsReady {
//    NSLog(@"yomob isAdsReady");
    return [TGSDK couldShowAd:@"v2SEXtqE3xJnXeTz3So"];
}

- (void) showRewardAds {
//    NSLog(@"yomob showRewardAds");
    if ([self isAdsReady]) {
//        NSLog(@"yomob showRewardAds ready");
        self->hasGiveReward = false;
        [TGSDK showAd:@"v2SEXtqE3xJnXeTz3So"];
    } else {
//        NSLog(@"yomob showRewardAds not ready");
        NSDictionary *args = @{@"success":@false, @"reason":@"广告未加载完毕"};
        [self callToJS:@"finishRwdAds" withArgs:args];
    }
}

- (void) onShowSuccess:(NSString* _Nonnull)result {
    NSLog(@"yomob onShowSuccess");
}

- (void) onShowFailed:(NSString* _Nonnull)result WithError:(NSError* _Nullable)error {
    NSLog(@"yomob onShowFailed");
    NSDictionary *args = @{@"success":@false, @"reason":@"展示广告失败"};
    [self callToJS:@"finishRwdAds" withArgs:args];
}

- (void) onADComplete:(NSString* _Nonnull)result {
    NSLog(@"yomob onADComplete");
}

- (void) onADClick:(NSString* _Nonnull)result {
    NSLog(@"yomob onADClick");
    NSDictionary *args = @{@"success":@true};
    [self callToJS:@"finishRwdAds" withArgs:args];
    self->hasGiveReward = true;
}

- (void) onADClose:(NSString* _Nonnull)result {
    NSLog(@"yomob onADClose");
    if (!self->hasGiveReward) {
        NSDictionary *args = @{@"success":@true};
        [self callToJS:@"finishRwdAds" withArgs:args];
    }
}

@end
