//
//  DydAdSdk.h
//  DydAdSdk
//
//  Created by lxr on 17/11/14.
//  Copyright © 2017年 lxr. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DydViewInfo.h"

@protocol DYDAdSDKDelegate <NSObject>
@optional

/**
 * 初始化缓存广告成功后调用
 */
-(void)onAdReady;
/**
 * 没有可以播放的广告
 * @param reason 不能播放广告原因
 */
-(void)onAdDidError:(NSString*)reason;

/**
 * 即将关闭广告
 * @param info 广告播放状态结果
 */
- (void)dydWillCloseAdWithViewInfo:(DydViewInfo *)info;
/**
 * 即将展示广告
 */
- (void)dydWillShowAd;
/**
 * 广告成功初始化
 * @param isInitSuccessed YES 成功
 */
- (void)dydSDKDidInitialize:(BOOL)isInitSuccessed; //广告成功初始化

@end

extern NSString *kPushPlayerViewControllerNotification;

@interface DydAdSdk : NSObject


@property (nonatomic,weak) id<DYDAdSDKDelegate> delegate;
/**
 *单例
 **/
+ (DydAdSdk *)sharedSDK;
/**
 *初始化
 *@param appId 用户id
 **/
-(void)startWithAppId:(NSString*)appId;
/**
 *视频播放
 *@param viewController UIViewController
 *@param delegate DYDAdSDKDelegate
 **/
- (BOOL)playAd:(UIViewController *)viewController delegate:(id<DYDAdSDKDelegate>)delegate error:(NSError **)error;
/**
 *是否开启奖励提醒功能
 *@param openRewardTip YES:开启
 **/
- (void)setOpenRewardTip:(BOOL)openRewardTip;
/**
 *开启奖励提醒功能描述语
 *@param closeDesc 开启奖励提醒功能描述语
 **/
- (void)setCloseDesc:(NSString *)closeDesc;
/**
 *是否静音
 *@param mute YES 静音
 *原setOpenSound
 **/
- (void)setMute:(BOOL)mute;

@property (nonatomic, readonly, getter=isAdPlayable) BOOL isAdPlayable;

@end
