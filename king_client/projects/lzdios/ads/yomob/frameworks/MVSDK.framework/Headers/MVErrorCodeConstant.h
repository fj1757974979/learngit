//
//  MVErrorCodeConstant.h
//  MVSDK
//
//  Created by CharkZhang on 2017/11/7.
//  Copyright © 2017年 Mobvista. All rights reserved.
//

#import <Foundation/Foundation.h>
NS_ASSUME_NONNULL_BEGIN

extern NSString * const kMVErrorDomain;

typedef NS_ENUM (NSInteger, MVErrorCode) {

    kMVErrorCodeRewardVideoFailedToLoadVideoData               = 129300061,
    kMVErrorCodeRewardVideoFailedToLoadPlayable                = 129300062,
    kMVErrorCodeRewardVideoFailedToLoadTemplateImage           = 129300063,
    kMVErrorCodeRewardVideoFailedToLoadPlayableURLFailed       = 129300064,
    kMVErrorCodeRewardVideoFailedToLoadPlayableURLReadyTimeOut = 129300065,
    kMVErrorCodeRewardVideoFailedToLoadPlayableURLReadyNO      = 129300066,
    kMVErrorCodeRewardVideoFailedToLoadPlayableURLInvalid      = 129300067,
    kMVErrorCodeRewardVideoFailedToLoadMd5Invalid              = 129300068,
    KMVErrorCodeEmptyUnitId                                    = 129300001,

    kMVErrorCodeNoAds                                          = 12930001,
    kMVErrorCodeConnectionLost                                 = 12930002,
    kMVErrorCodeURLisEmpty                                     = 12930003,
    kMVErrorCodeNoAdsAvailableToPlay                           = 12930004,
    kMVErrorCodeFailedToPlay                                   = 12930005,
    kMVErrorCodeFailedToLoad                                   = 12930006,
    kMVErrorCodeDailyLimit                                     = 12930007,
    kMVErrorCodeLoadAdsTimeOut                                 = 12930008,

    kMVErrorCodeNoSupportPopupWindow                           = 12930009,

};

@interface MVErrorCodeConstant : NSObject

@end
NS_ASSUME_NONNULL_END
