//
//  GetWifiMac.h
//  mangosanguo
//
//  Created by 莫 on 12-9-28.
//  Copyright (c) 2012年 private. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HuoShuGetWifiMac : NSObject

// 获取app版本号
+(NSString *)obtainAppVersion;
// 获取设备名称
+(NSString *)obtainDeviceName;
// 获取当前系统版本号
+(NSString *)obtainSystemVersion;
// 获取唯一的识别码uuid
+(NSString *)obtainDeviceUUID;
// 获取设备的ip
+(NSString *)obtainDeviceIP;
// 获取设备类型
+(NSString *)obtainDevieModel;
// 获取当前时间的时间戳
+(NSString *)obtainTimeString;
// 获取当前设备的分辨率
+(NSString *)obtainDeviceSize;
// 将unicode文字转换为中文
+(NSString *)transForChina:(NSString *)unicodeStr;
// 获取手机类型
+ (NSString*)iphoneType;
// 获取IDFA 广告标识符
+(NSString *)obtainMacAdvertising;
// 获取IDFV Vendor标识用户
+(NSString *)obtainIDFV;
// 获取UUID
+(NSString *)obtainUUID;
// 获取mac地址
+ (NSString *)obtainMacaddress;
// 获取当前时间
+(NSString *)obtainCurrentTime;
+(NSString *)obtainAdvertisingId;
// 计算两个时间差的值
+ (int)dateTimeDifferenceWithStartTime:(NSString *)startTime endTime:(NSString *)endTime;
// string的encode方法
+(NSString *)stringToEncoding:(NSString *)str;
@end


