#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import "OpenewWebView.h"
#import "wechat/WXApi.h"
#import "TalkingDataGA.h"
#import <GameKit/GameKit.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate, WXApiDelegate, GKGameCenterControllerDelegate>
@property (strong, nonatomic) UIWindow *window;
- (OpenewWebView *)getViewController;
- (void) callJS: (NSString *)message;

@property (strong, nonatomic) TDGAAccount *tdgaAccount;
@property (strong, nonatomic) NSString *loadingPercent;
@end
