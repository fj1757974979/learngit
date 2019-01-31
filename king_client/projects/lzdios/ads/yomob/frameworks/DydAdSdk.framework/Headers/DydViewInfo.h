//
//  DydViewInfo.h
//  DydAdSdk
//
//  Created by lxr on 2017/12/11.
//  Copyright © 2017年 lxr. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DydViewInfo : NSObject
//代表一个布尔值，即视频是否可以被认为得到了完整播放。
@property (nonatomic, readonly) BOOL completedView;
//用户观看视频的时间（以秒为单位）。
@property (nonatomic, readonly) float playTime;
//代表一个布尔值，即用户是否点击了下载按钮。
@property (nonatomic, readonly) BOOL didDownload;
@end
