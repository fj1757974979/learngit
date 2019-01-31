//
//  MVInterstitialVideoAdManager.h
//  MVSDK
//
//  Created by CharkZhang on 2018/4/10.
//  Copyright © 2018年 Mobvista. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class MVInterstitialVideoAdManager;
/**
 *  This protocol defines a listener for ad video load events.
 */
@protocol MVInterstitialVideoDelegate <NSObject>
@optional

/**
 *  Called when the ad is successfully load , and is ready to be displayed
 */
- (void) onInterstitialVideoLoadSuccess:(MVInterstitialVideoAdManager *_Nonnull)adManager;

/**
 *  Called when there was an error loading the ad.
 *  @param error       - error object that describes the exact error encountered when loading the ad.
 */
- (void) onInterstitialVideoLoadFail:(nonnull NSError *)error adManager:(MVInterstitialVideoAdManager *_Nonnull)adManager;


/**
 *  Called when the ad display success
 */
- (void) onInterstitialVideoShowSuccess:(MVInterstitialVideoAdManager *_Nonnull)adManager;

/**
 *  Called when the ad failed to display for some reason
 *  @param error       - error object that describes the exact error encountered when showing the ad.
 */
- (void) onInterstitialVideoShowFail:(nonnull NSError *)error adManager:(MVInterstitialVideoAdManager *_Nonnull)adManager;

/**
 *  Called when the ad is clicked
 */
- (void) onInterstitialVideoAdClick:(MVInterstitialVideoAdManager *_Nonnull)adManager;

/**
 *  Called when the ad has been dismissed from being displayed, and control will return to your app
 *  @param converted   - BOOL describing whether the ad has converted
 */
- (void)onInterstitialVideoAdDismissedWithConverted:(BOOL)converted adManager:(MVInterstitialVideoAdManager *_Nonnull)adManager;


@end



@interface MVInterstitialVideoAdManager :  NSObject



@property (nonatomic, weak) id  <MVInterstitialVideoDelegate> _Nullable delegate;



@property (nonatomic, readonly)   NSString * _Nonnull currentUnitId;


/**
 * Play the video is mute in the beginning ,defult is NO
 *
 */
@property (nonatomic, assign) BOOL  playVideoMute;




- (nonnull instancetype)initWithUnitID:(nonnull NSString *)unitId delegate:(nullable id<MVInterstitialVideoDelegate>)delegate;


/**
 * Begins loading ad content for the interstitialVideo.
 *
 * You can implement the `onInterstitialVideoLoadSuccess:` and `onInterstitialVideoLoadFail: adManager:` methods of
 * `MVInterstitialVideoDelegate` if you would like to be notified as loading succeeds or
 * fails.
 */
- (void)loadAd;


/** @name Presenting an interstitialVideo Ad */

/**
 * Presents the interstitialVideo ad modally from the specified view controller.
 *
 * @param viewController The view controller that should be used to present the interstitialVideo ad.
 */
- (void)showFromViewController:(UIViewController *_Nonnull)viewController;


/**
 *  Clean all the video file cache from the disk.
 */
- (void)cleanAllVideoFileCache;





@end
