//
//  MVUserInfo.h
//  MVSDK
//
//  Created by 陈俊杰 on 2017/11/23.
//  Copyright © 2017年 Mobvista. All rights reserved.
//

#import <Foundation/Foundation.h>


typedef NS_ENUM(NSInteger, MVUserPrivateType) {
    MVUserPrivateType_ALL         = 0,
    MVUserPrivateType_GeneralData = 1,
    MVUserPrivateType_DeviceId    = 2,
    MVUserPrivateType_Gps         = 3,
};


@interface MVUserPrivateTypeInfo : NSObject

@property (nonatomic,assign)  BOOL isGeneralDataAllowed;
@property (nonatomic,assign)  BOOL isDeviceIdAllowed;
@property (nonatomic,assign)  BOOL isGpsAllowed;

@end
/**
 *
 *@param userPrivateTypeInfo:User privacy authorization status
 *@param error:Non-europe users do not support (kMVErrorCodeNoSupportPopupWindow)
 */
typedef void (^MVUserPrivateInfoTipsResultBlock)(MVUserPrivateTypeInfo *userPrivateTypeInfo,NSError *error);


typedef NS_ENUM(NSUInteger, MVGender) {
    MVGender_Unknown = 0,
    MVGender_Man     = 1,
    MVGender_Woman   = 2,
};

typedef NS_ENUM(NSUInteger, MVUserPayType) {
    MVUserPayType_Unpaid  = 0,
    MVUserPayType_Pay     = 1,
    MVUserPayType_Unknown = 2,
};

@interface MVUserInfo : NSObject

@property (nonatomic,assign) MVGender gender;
@property (nonatomic,assign) NSInteger age;
@property (nonatomic,assign) MVUserPayType pay;
@property (nonatomic,  copy) NSString *custom;
@property (nonatomic,  copy) NSString *longitude;
@property (nonatomic,  copy) NSString *latitude;

@end
