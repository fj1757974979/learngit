//
//  YouaiNotifications.h
//  YouaiSDK
//
//  Created by 莫 东荣 on 13-4-10.
//  Copyright (c) 2013年 莫 东荣. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * const huoshuExitNotification;                  /**<  退出 */
extern NSString * const huoshuLoginNotification;                    /**< 登录完成的通知*/
extern NSString * const huoshuPaytNotification;                  /**< 支付通知 */
extern NSString * const huoshuShareNotification;                 /**<  分享通知 */
extern NSString * const huoshuCenterNotification;                /**<  用户中心通知  */
extern NSString * const huoshuErrorNotification;                 /**<  出错 */

extern NSString * const huoshuPayResultNotification;            /**<  查看支付结果，客户端不要以此发元宝，以服务器通知为准*/


@interface HuoShuNotifications : NSObject

@end


