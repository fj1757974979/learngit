//
//  OpenewWebView.h
//  lzdios
//
//  Created by 兰清 on 07/07/2018.
//  Copyright © 2018 egret. All rights reserved.
//

#ifndef OpenewWebView_h
#define OpenewWebView_h
#import <UIKit/UIKit.h>

/*
 *  System Versioning Preprocessor Macros
 */

#define SYSTEM_VERSION_EQUAL_TO(v)                  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedSame)
#define SYSTEM_VERSION_GREATER_THAN(v)              ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedDescending)
#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN(v)                 ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN_OR_EQUAL_TO(v)     ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedDescending)

#define IS_IPHONEX (CGSizeEqualToSize(CGSizeMake(375.f, 812.f), [UIScreen mainScreen].bounds.size) ||  CGSizeEqualToSize(CGSizeMake(414.f, 896.f),[UIScreen mainScreen].bounds.size))
@interface OpenewWebView: UIViewController <UIDocumentInteractionControllerDelegate>

@property (nonatomic, strong) UIDocumentInteractionController *documentController;
-(instancetype) initWithUrl:(NSString *)homeUrl;
- (void)callJS:(NSString *)msg;
- (void)initNativeCall:(void(^)(NSString*))callback;
- (void)startRecord;
- (void)stopRecord;
- (void)shareVideo;
- (void)saveToPhoto;
- (bool)supportRecord;
@end

#endif /* OpenewWebView_h */
