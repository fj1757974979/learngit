#import "AppDelegate.h"
#import "OpenewWebView.h"

#import "sdk.h"
#import "ads.h"
#import "SoundMgr.h"
#import "payment.h"
#import "TalkingDataGA.h"
#import <Bugly/Bugly.h>
#import "cocos2d.h"

#ifdef XUANDONG
//ios appstore包
const char *homeUrl = "https://client.lzd2.openew.com/king_war/";
//内部测试包
//const char *homeUrl = "https://ctc-hf.fire233.com/king_war_test/";
//const char *homeUrl = "http://192.168.1.198:5379";
//const char *homeUrl = "http://www.openew.com/king_war_v2";
//const char *homeUrl = "http://192.168.1.212:5507";
//const char *homeUrl = "http://192.168.1.232:5773";

const char *appStoreAppId = "1371944201";
#endif

#ifdef HANDJOY
const char *homeUrl = "https://client.dny.lzd.openew.com/king_war/?shdate=190107";
//const char *homeUrl = "https://client.dny.lzd.openew.com/king_war_test/";
const char *appStoreAppId = "1439678059";
#endif

#define AppID @"wx5ab527c87f7118f5"
#define AppSecret @"681f3d66297dfaab7770c0d402f9263a"

@implementation AppDelegate {
    OpenewWebView* _viewController;
    NSMutableArray* _commandList;
    UIImageView *_splash;
    NSTimer *_splashAni;
    int _splashStep;
    BOOL _isLogin;
}

// 3d Touch 功能
- (void)configShortcutItems {
    CGFloat currentDeviceVersionFloat = [[[UIDevice currentDevice] systemVersion] floatValue];
    //判断版本号，3D Touch是从iOS9.0后开始使用
    if (currentDeviceVersionFloat < 9.0) return;

    UIApplicationShortcutItem *item0 = [[UIApplicationShortcutItem alloc] initWithType:@"0" localizedTitle:@"开始对战" localizedSubtitle:nil icon:[UIApplicationShortcutIcon iconWithType:UIApplicationShortcutIconTypeSearch] userInfo:nil];
    [UIApplication sharedApplication].shortcutItems = @[item0];
}

- (void)application:(UIApplication *)application performActionForShortcutItem:(UIApplicationShortcutItem *)shortcutItem completionHandler:(void (^)(BOOL))completionHandler{
    int value = [shortcutItem.type intValue];
    if (value == 0) {
        [self callJSAfterLogin:@"{\"msg\":\"onStartMatch\", \"args\":{}}"];
    }
}

//递归读取解压路径下的所有文件
- (void)showAllFileWithPath:(NSString *) path {
    NSFileManager * fileManger = [NSFileManager defaultManager];
    BOOL isDir = NO;
    BOOL isExist = [fileManger fileExistsAtPath:path isDirectory:&isDir];
    if (isExist) {
        if (isDir) {
            NSArray * dirArray = [fileManger contentsOfDirectoryAtPath:path error:nil];
            NSString * subPath = nil;
            for (NSString * str in dirArray) {
                subPath  = [path stringByAppendingPathComponent:str];
                BOOL issubDir = NO;
                [fileManger fileExistsAtPath:subPath isDirectory:&issubDir];
                [self showAllFileWithPath:subPath];
            }
        }else{
            //NSString *fileName = [[path componentsSeparatedByString:@"/"] lastObject];
            //if ([fileName hasSuffix:@".png"]) {
//            NSLog(@"%@", fileName);
            //}
        }
    } else {
        NSLog(@"this path is not exist!");
    }
}

/*
- (UIInterfaceOrientationMask)application:(UIApplication *)application supportedInterfaceOrientationsForWindow:(nullable UIWindow *)window {
    return UIInterfaceOrientationMaskPortrait;
}
 */


- (UIImage *)addTextToImage:(NSString*) text
                    inImage:(UIImage*)  image
                    atPoint:(CGPoint)   point
{
    UIGraphicsBeginImageContextWithOptions(image.size, YES, 0.0f);
    [image drawInRect:CGRectMake(0,0,image.size.width,image.size.height)];
    CGRect rect = CGRectMake(point.x, point.y, image.size.width, image.size.height);
    [[UIColor whiteColor] set];

    UIFont *font = [UIFont systemFontOfSize:20];
    if([text respondsToSelector:@selector(drawInRect:withAttributes:)])
    {
        //iOS 7
        NSDictionary *att = @{NSFontAttributeName:font};
        [text drawInRect:rect withAttributes:att];
    }
    else
    {
        //legacy support
        [text drawInRect:CGRectIntegral(rect) withFont:font];
    }

    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return newImage;
}

- (void)splashAnimation: (NSTimer *)step
{

}

- (void)hideSplash{
    if (_splash) {
        [_splash removeFromSuperview];
        _splash = nil;
        self.window.rootViewController.view.alpha = 1;
    }

    if (_splashAni) {
        [_splashAni invalidate];
        _splashAni = nil;
    }
}

// 挡住加载过程
- (void)showSplash {
    self.window.rootViewController.view.alpha = 0;
    _loadingPercent = @"";
#ifdef XUANDONG
    NSString *path = [[NSBundle mainBundle] pathForResource:@"splash" ofType:@"jpg"];
#endif
#ifdef HANDJOY
    NSString *path = [[NSBundle mainBundle] pathForResource:@"splash_abroad" ofType:@"jpg"];
#endif
    UIImage *image = [UIImage imageWithContentsOfFile:path];
#ifndef HANDJOY
    image = [self addTextToImage:@"正在解压资源" inImage:image atPoint:CGPointMake(167, 650)];
#endif
    CGSize windowSize;
    windowSize.width = MIN(_window.bounds.size.width, _window.bounds.size.height);
    windowSize.height = MAX(_window.bounds.size.width, _window.bounds.size.height);
    float dx = windowSize.width - _window.bounds.size.width;
    float dy = windowSize.height - _window.bounds.size.height;
    UIImageView* imageView = [[UIImageView alloc] initWithFrame:CGRectMake(-dx/2, -dy/2, windowSize.width, windowSize.height)];
    imageView.contentMode = UIViewContentModeScaleAspectFill;
    [imageView setImage:image];
    if (_window.bounds.size.width > _window.bounds.size.height) {
        imageView.transform = CGAffineTransformMakeRotation(-3.1415926/2);
    }

    [self.window addSubview:imageView];

    _splash = imageView;
    _splashStep = 0;

    _splashAni = [NSTimer scheduledTimerWithTimeInterval:0.5 repeats:TRUE block:^(NSTimer * _Nonnull timer) {
        NSString *text;
#ifdef XUANDONG
        if (self->_splashStep == 0) {
            text = [NSString stringWithFormat:@"正在加载资源,请耐心等待%@",self.loadingPercent];
        } else if (self->_splashStep == 1) {
            text = [NSString stringWithFormat:@"正在加载资源,请耐心等待%@.",self.loadingPercent];
        } else if (self->_splashStep == 2) {
            text = [NSString stringWithFormat:@"正在加载资源,请耐心等待%@..",self.loadingPercent];
        } else {
            text = [NSString stringWithFormat:@"正在加载资源,请耐心等待%@...",self.loadingPercent];
        }
#endif
#ifdef HANDJOY
//        if (self->_splashStep == 0) {
//            text = @"請稍候";
//        } else if (self->_splashStep == 1) {
//            text = @"請稍候.";
//        } else if (self->_splashStep == 2) {
//            text = @"請稍候..";
//        } else {
//            text = @"請稍候...";
//        }
        text = @"";
#endif
        self->_splashStep = ++ self->_splashStep % 4;
        UIImage *image = [UIImage imageWithContentsOfFile:path];
        image = [self addTextToImage:text inImage:image atPoint:CGPointMake(100, 650)];
        [imageView setImage:image];
    }];

    //[UIView animateWithDuration:2 animations:^{ self.window.rootViewController.view.alpha = 1.0; } completion:^(BOOL finished) { [imageView removeFromSuperview];}];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
#ifdef XUANDONG
    [Bugly startWithAppId:@"5d8120368f"];
    [TalkingDataGA onStart:@"DA82D687626F4F3185D914C449302546" withChannelId:@"lzd_pkgsdk"];
#endif
    
#ifdef HANDJOY
    [Bugly startWithAppId:@"515d5c3fb5"];
    [TalkingDataGA onStart:@"1B0A6EDFA8AF40A5BE1EF0183206F001" withChannelId:@"lzd_handjoy"];
#endif
    
    // Override point for customization after application launch.
    _window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    _window.backgroundColor = [UIColor colorWithWhite:0 alpha:0];

    //_viewController = [[ViewController alloc] initWithEAGLView:[NativeLauncher createEAGLView]];

    dispatch_queue_t queue = dispatch_get_main_queue();
    dispatch_block_t block = ^ {
        NSString *cachesDir =[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject];
        //            NSString *libraryDir =[NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) firstObject];
        NSString *libraryCachesWebKitDir = [NSString stringWithFormat:@"%@/%@",cachesDir,@"WebKit"];
        NSString *bundlePath = [[NSBundle mainBundle] bundlePath];
        //            NSString *libraryWebKitDir =[NSString stringWithFormat:@"%@/%@",libraryDir,@"WebKit"];
        NSString *bundleCachesWebKitDir = [NSString stringWithFormat:@"%@/%@", bundlePath, @"data/WebKit"];
        //            NSString *bundleWebKitDir =[NSString stringWithFormat:@"%@/%@", bundlePath, @"WebKit"];
        
        NSFileManager *fileManager = [NSFileManager defaultManager];
        BOOL isDir = FALSE;
        BOOL isDirExist = [fileManager fileExistsAtPath:libraryCachesWebKitDir
                                            isDirectory:&isDir];
        if (!(isDir && isDirExist)) {
            NSError *copyError = nil;
            
            if (![[NSFileManager defaultManager] copyItemAtPath:bundleCachesWebKitDir toPath:libraryCachesWebKitDir error:&copyError]) {
                NSLog(@"Error copying files: %@", [copyError localizedDescription]);
            }
            NSString *Version13 = [NSString stringWithFormat:@"%@/%@", bundlePath, @"data/WebKit/NetworkCache/Version 13"];
            NSString *Version12 = [NSString stringWithFormat:@"%@/%@", cachesDir, @"WebKit/NetworkCache/Version 12"];
            if (![[NSFileManager defaultManager] copyItemAtPath:Version13 toPath:Version12 error:&copyError]) {
                NSLog(@"Error copying files: %@", [copyError localizedDescription]);
            }
        }
        
        NSLog(@"==== prepare done ====");
    };
    if ([NSThread isMainThread]) {
        block();
    } else {
        dispatch_sync(queue, block);
    }
    
    NSLog(@"==== begin initialize ====");
    _viewController = [[OpenewWebView alloc]
                       initWithUrl:[[NSString alloc] initWithUTF8String:homeUrl]];
    [_window setRootViewController:_viewController];
    [_window makeKeyAndVisible];
    
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 10.0) {
        [self showSplash];
    }
    
    [self configShortcutItems];
    _isLogin = FALSE;
    
    [[SDKBase getSdkInstance] init:self];
    [[SDKBase getSdkInstance] initView];
    
    [[AdsBase getAdsInstance] init:self];
//    [[PaymentMgr shareInstance] init:self];
    //WKWebsiteDataStore
    [self setExternalInterfaces];
    
    _commandList = [[NSMutableArray alloc] init];
    //向微信注册
    [WXApi registerApp:AppID];
    
    [self removeNotify];
    
    [[SDKBase getSdkInstance] application:application didFinishLaunchingWithOptions:launchOptions];
    
    return YES;
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options {
    return [[SDKBase getSdkInstance] application:application openURL:url options:options];
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    return [[SDKBase getSdkInstance] application:application openURL:url sourceApplication:sourceApplication annotation:annotation];
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    [self callJS:@"{\"msg\":\"onStop\", \"args\":{}}"];
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    [self removeNotify];
    [self callJS:@"{\"msg\":\"onStart\", \"args\":{}}"];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    
    [[SDKBase getSdkInstance] applicationBecomeActive:application];
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

/**
 * 只能评分，不能编写评论
 * 有次数限制，一年只能使用三次
 * 使用次数超限后，需要跳转appstore
 */
- (IBAction)systemComentBtnAction {
    if([SKStoreReviewController respondsToSelector:@selector(requestReview)]) {// iOS 10.3 以上支持
        //防止键盘遮挡
        [[UIApplication sharedApplication].keyWindow endEditing:YES];
        [SKStoreReviewController requestReview];
    } else {
        static NSString * const reviewURL = @"itms-apps://itunes.apple.com/app/id1371944201";

        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:reviewURL]];
    }
}

- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url
{
    return [WXApi handleOpenURL:url delegate:self];
}

int _shareScene = 0;
-(void) onResp:(BaseResp*)resp
{
    if([resp isKindOfClass:[SendMessageToWXResp class]])
    {
//        NSString *strTitle = [NSString stringWithFormat:@"发送媒体消息结果"];
//        NSString *strMsg;
//        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:strTitle message:strMsg delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
//        [alert show];
        if (resp.errCode == 0) {
            NSString *msg = [NSString stringWithFormat:@"{\"msg\":\"shareApp2Wechat\", \"args\":{\"errCode\":%d, \"scene\":%d}}", resp.errCode, _shareScene];
            [self callJS:msg];
        }

    }
}

- (void) shareApp2Wechat:(NSString *)title withDescription:(NSString *)description withUrl:(NSString *)url withScene:(int)scene
{
    WXMediaMessage *message = [WXMediaMessage message];
    message.title = title;
    message.description = description;
    [message setThumbImage:[UIImage imageNamed:@"icon.png"]];

    WXWebpageObject *ext = [WXWebpageObject object];
    ext.webpageUrl = url;

    message.mediaObject = ext;

    SendMessageToWXReq* req = [[SendMessageToWXReq alloc] init];
    req.bText = NO;
    req.message = message;
    req.scene = scene;

    [WXApi sendReq:req];
}

- (void)createNotify:(int)time message:(NSString*)msg{
    UILocalNotification *localNotifi = [UILocalNotification new];
    UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeBadge | UIUserNotificationTypeSound | UIUserNotificationTypeAlert categories:nil];
    [[UIApplication sharedApplication] registerUserNotificationSettings:settings];
    localNotifi.fireDate = [NSDate dateWithTimeIntervalSinceNow:time];
    localNotifi.alertBody = msg;
    //localNotifi.applicationIconBadgeNumber = 1;
    [[UIApplication sharedApplication] scheduleLocalNotification:localNotifi];
}

- (void)removeNotify {
    [[UIApplication sharedApplication] cancelAllLocalNotifications];
}

- (void)setExternalInterfaces
{
    [_viewController initNativeCall:^(NSString *msg) {
//        NSLog(@"Openew Launcher %@", msg);
        NSData *data= [msg dataUsingEncoding:NSUTF8StringEncoding];
        NSError *error = nil;
        id jsonObject = [NSJSONSerialization JSONObjectWithData:data
                                                        options:NSJSONReadingAllowFragments
                                                          error:&error];
        NSDictionary *param = (NSDictionary *)jsonObject;
        NSString *msgId = [param objectForKey:@"msg"];
//        NSLog(@"msgId %@", msgId);
        if ([msgId isEqualToString:@"log"]) {
            NSLog(@"[JSLog] %@", [param objectForKey:@"args"]);
        } else if ([msgId isEqualToString:@"login"]) {
            [[SDKBase getSdkInstance] login];
            [self hideSplash];
        } else if ([msgId isEqualToString:@"onEnterGame"]) {
            NSDictionary *args = (NSDictionary *)[param objectForKey:@"args"];
            NSString *userId = [args objectForKey:@"userId"];
            NSString *userName = [args objectForKey:@"userName"];
            int level = [[args objectForKey:@"level"] intValue];
            int serverId = [[args objectForKey:@"serverId"] intValue];
            NSString *serverName = [args objectForKey:@"serverName"];
            [[SDKBase getSdkInstance] onEnterGame:userId withUserName:userName withLevel:level withServerId:serverId withServerName:serverName];

            for (int i=0; i< [self->_commandList count]; i++) {
                NSString *msg = [self->_commandList objectAtIndex:i];
                [self callJS:msg];
            }
            [self->_commandList removeAllObjects];
            self->_isLogin = TRUE;
        } else if ([msgId isEqualToString:@"onCreateRole"]) {
            NSDictionary *args = (NSDictionary *)[param objectForKey:@"args"];
            NSString *userId = [args objectForKey:@"userId"];
            NSString *userName = [args objectForKey:@"userName"];
            int serverId = [[args objectForKey:@"serverId"] intValue];
            NSString *serverName = [args objectForKey:@"serverName"];
            [[SDKBase getSdkInstance] onCreateRole:userId withUserName:userName withServerId:serverId withServerName:serverName];
        } else if ([msgId isEqualToString:@"startRecord"]) {
            [self->_viewController startRecord];
        } else if ([msgId isEqualToString:@"stopRecord"]) {
            [self->_viewController stopRecord];
        } else if ([msgId isEqualToString:@"saveToPhoto"]) {
            [self->_viewController saveToPhoto];
        } else if ([msgId isEqualToString:@"shareVideo"]) {
            [self->_viewController shareVideo];
        } else if ([msgId isEqualToString:@"initAds"]) {
            [[AdsBase getAdsInstance] preload];
        } else if ([msgId isEqualToString:@"adsIsReady"]) {
            BOOL isReady = [[AdsBase getAdsInstance] isAdsReady];
            NSDictionary *args = nil;
            if (isReady) {
                args = @{@"success":@true};
            } else {
                args = @{@"success":@false};
            }
            [[AdsBase getAdsInstance] callToJS:@"adsReady" withArgs:args];
        } else if ([msgId isEqualToString:@"showRwdAds"]) {
            [[AdsBase getAdsInstance] showRewardAds];
        } else if ([msgId isEqualToString:@"useNativeSound"]) {
            int topMargin = 0;
            int bottomMargin = 0;
            NSString *record = @"false";
            if (IS_IPHONEX) {
                topMargin = 38;
                bottomMargin = 10;
            }
            if ([self->_viewController supportRecord]) {
                record = @"true";
            }
            NSString *js = [NSString stringWithFormat:@"{\"msg\":\"setSupportRecord\", \"args\":{\"support\":%@, \"topMargin\":%d, \"bottomMargin\":%d}}",
                            record,
                            topMargin,
                            bottomMargin];
            [self callJS:js];
            [self callJS:@"{\"msg\":\"useNativeSound\", \"args\":{\"support\":true}}"];
        } else if ([msgId isEqualToString:@"playSound"]){
            NSDictionary *args = (NSDictionary *)[param objectForKey:@"args"];
            NSString *sound = [args objectForKey:@"sound"];
            NSNumber *volume = [args objectForKey:@"volume"];
            [[SoundMgr sharedMgr] playSound:sound volume:volume];
        } else if ([msgId isEqualToString:@"playMusic"]) {
            NSDictionary *args = (NSDictionary *)[param objectForKey:@"args"];
            NSString *music = [args objectForKey:@"sound"];
            NSNumber *volume = [args objectForKey:@"volume"];
            [[SoundMgr sharedMgr] playMusic:music volume:volume];
        } else if ([msgId isEqualToString:@"stopMusic"]) {
            [[SoundMgr sharedMgr] stopMusic];
        } else if ([msgId isEqualToString:@"setMusicVolume"]) {
            NSDictionary *args = (NSDictionary *)[param objectForKey:@"args"];
            NSNumber *volume = [args objectForKey:@"volume"];
            [[SoundMgr sharedMgr] setMusicVolume:volume];
        } else if ([msgId isEqualToString:@"initAppstorePay"]) {
            [[PaymentMgr shareInstance] init: self];
        } else if ([msgId isEqualToString:@"appstoreRequestProducts"]) {
            NSDictionary *args = (NSDictionary *)[param objectForKey:@"args"];
            NSArray *productIdentifiers = [args objectForKey:@"productIds"];
            [[PaymentMgr shareInstance] validateProductIdentifiers:productIdentifiers];
        } else if ([msgId isEqualToString:@"startPay"]) {
            NSDictionary *args = (NSDictionary *)[param objectForKey:@"args"];
            NSString *productIndentifier = [args objectForKey:@"productId"];
            BOOL isSDKPay = [[args objectForKey:@"isSDKPay"] boolValue];
            int price = [[args objectForKey:@"price"] intValue];
            int count = [[args objectForKey:@"count"] intValue];
            if (isSDKPay) {
                NSString *orderId = [args objectForKey:@"orderId"];
                [[SDKBase getSdkInstance] pay:productIndentifier withPrice:price withCount:count withParam: orderId];
            } else {
                [[PaymentMgr shareInstance] pay:productIndentifier withPrice:price withCount:count];
            }
        } else if ([msgId isEqualToString:@"openAppComment"]) {
            [self systemComentBtnAction];
        } else if ([msgId isEqualToString:@"onShowLoading"]) {
            [self hideSplash];
        } else if ([msgId isEqualToString:@"shareApp2Wechat"]) {
            NSDictionary *args = (NSDictionary *)[param objectForKey:@"args"];
            NSString *title = (NSString *)[args objectForKey:@"title"];
            NSString *description = (NSString *)[args objectForKey:@"description"];
            NSString *url = (NSString *)[args objectForKey:@"url"];
            int scene = [(NSNumber *)[args objectForKey:@"scene"] intValue];
            _shareScene = scene;
            [self shareApp2Wechat:title withDescription:description withUrl:url withScene:scene];
        } else if ([msgId isEqualToString:@"getTDChannelID"]) {
            [self callJS:@"{\"msg\":\"getTDChannelID\", \"args\":{\"tdChannelID\":\"lzd_pkgsdk\", \"native\":true}}"];
        } else if ([msgId isEqualToString:@"td_Account"]) {
            NSDictionary *args = (NSDictionary *)[param objectForKey:@"args"];
            NSString *accountId = (NSString *)[args objectForKey:@"accountId"];
            NSString *accountName = (NSString *)[args objectForKey:@"accountName"];
            NSNumber *accountType = (NSNumber *)[args objectForKey:@"accountType"];
            NSNumber *accountLevel = (NSNumber *)[args objectForKey:@"level"];
            NSString *gameServer = (NSString *)[args objectForKey:@"gameServer"];

            self.tdgaAccount = [TDGAAccount setAccount:accountId];
            [self.tdgaAccount setAccountName:accountName];
            [self.tdgaAccount setAccountType:(TDGAAccountType)accountType.intValue];
            [self.tdgaAccount setLevel:accountLevel.intValue];
            [self.tdgaAccount setGameServer:gameServer];
        } else if ([msgId isEqualToString:@"td_onMissionBegin"]) {
            NSDictionary *args = (NSDictionary *)[param objectForKey:@"args"];
            NSString *mission = (NSString *)[args objectForKey:@"mission"];
            [TDGAMission onBegin:mission];
        } else if ([msgId isEqualToString:@"td_onMissionCompleted"]) {
            NSDictionary *args = (NSDictionary *)[param objectForKey:@"args"];
            NSString *mission = (NSString *)[args objectForKey:@"mission"];
            [TDGAMission onCompleted:mission];
        } else if ([msgId isEqualToString:@"td_onMissionFailed"]){
            NSDictionary *args = (NSDictionary *)[param objectForKey:@"args"];
            NSString *mission = (NSString *)[args objectForKey:@"mission"];
            NSString *reason = (NSString *)[args objectForKey:@"reason"];
            [TDGAMission onFailed:mission failedCause:reason];
        } else if ([msgId isEqualToString:@"td_setLevel"]){
            NSDictionary *args = (NSDictionary *)[param objectForKey:@"args"];
            NSNumber *level = (NSNumber *)[args objectForKey:@"level"];
            [self.tdgaAccount setLevel:level.intValue];
        } else if ([msgId isEqualToString:@"td_onItemPurchase"]) {
            NSDictionary *args = (NSDictionary *)[param objectForKey:@"args"];
            NSString *item = (NSString *)[args objectForKey:@"item"];
            NSNumber *number = (NSNumber *)[args objectForKey:@"itemNumber"];
            NSNumber *price = (NSNumber*)[args objectForKey:@"priceInVirtualCurrency"];
            [TDGAItem onPurchase:item itemNumber:number.intValue priceInVirtualCurrency:price.doubleValue];
        } else if ([msgId isEqualToString:@"td_onItemUse"]) {
            NSDictionary *args = (NSDictionary *)[param objectForKey:@"args"];
            NSString *item = (NSString *)[args objectForKey:@"item"];
            NSNumber *number = (NSNumber *)[args objectForKey:@"itemNumber"];
            [TDGAItem onUse:item itemNumber:number.intValue];
        } else if ([msgId isEqualToString:@"td_onEvent"]) {
            NSDictionary *args = (NSDictionary *)[param objectForKey:@"args"];
            NSString *event = (NSString *)[args objectForKey:@"name"];
            NSDictionary *data = (NSDictionary *)[args objectForKey:@"data"];
            [TalkingDataGA onEvent:event eventData:data];
        } else if ([msgId isEqualToString:@"loginGameCenter"]) {
            // GameCenter登陆
            NSLog(@"loginGameCenter");
//            GKLocalPlayer.localPlayer.authenticateHandler = ^(UIViewController * _Nullable viewController, NSError * _Nullable error) {
//                NSLog(@"loginGameCenter: %@", error);
//                [self authGameCenterView:viewController withError:error];
//            };
            [[GKLocalPlayer localPlayer] setAuthenticateHandler:^(UIViewController * _Nullable viewController, NSError * _Nullable error) {
                NSLog(@"loginGameCenter: %@", error);
                [self authGameCenterView:viewController withError:error];
            }];
        } else if ([msgId isEqualToString:@"scoreToGameCenter"]) {
            NSDictionary *args = (NSDictionary *)[param objectForKey:@"args"];
            int score = [[args objectForKey:@"score"] intValue];
            [self recordScoreToGameCenter:score];
        } else if ([msgId isEqualToString:@"showGameCenterRank"]) {
            [self showGameCenterRank];
        } else if ([msgId isEqualToString:@"startGame"]) {
            CCScene *scene = [CCScene node];
            [[CCDirector sharedDirector] setFixedUpdateInterval:50];
            [[CCDirector sharedDirector] runWithScene:scene];
            [[CCDirector sharedDirector] setViewport];
        } else if ([msgId isEqualToString:@"createNotify"]) {
            NSDictionary *args = (NSDictionary *)[param objectForKey:@"args"];
            NSString *msg = (NSString *)[args objectForKey:@"message"];
            NSNumber *number = (NSNumber *)[args objectForKey:@"time"];
            [self createNotify:number.intValue message:msg];
        } else if ([msgId isEqualToString:@"removeNotify"]) {
            [self removeNotify];
        } else if ([msgId isEqualToString:@"setLoadingPercent"]) {
            NSDictionary *args = (NSDictionary *)[param objectForKey:@"args"];
            self.loadingPercent = (NSString *)[args objectForKey:@"percentStr"];
        } else if ([msgId isEqualToString:@"getLocale"]) {
            NSLocale *locale = [NSLocale currentLocale];
            NSString *countryCode = [locale objectForKey:NSLocaleCountryCode];
            NSString *language = [[[NSUserDefaults standardUserDefaults] objectForKey:@"AppleLanguages"] objectAtIndex:0];
            NSDictionary *args = @{@"country":countryCode, @"language":language};
            [self callJSWithArgs:@"getLocale" withArgs:args];
        } else if ([msgId isEqualToString:@"appStoreCheckVersion"]) {
            [self checkVersionUpdate];
        } else if ([msgId isEqualToString:@"shareLink"]) {
            NSDictionary *args = (NSDictionary *)[param objectForKey:@"args"];
            NSString *title = [args objectForKey:@"title"];
            NSString *link = [args objectForKey:@"link"];
            [[SDKBase getSdkInstance] shareLink:title withLink:link];
        }
    }];
}

- (OpenewWebView *) getViewController {
    return _viewController;
}

- (void) callJS:(NSString *)message {
    [_viewController callJS:message];
}

- (void) callJSAfterLogin:(NSString *)message {
    if (_isLogin) {
        [self callJS:message];
    } else {
        [_commandList addObject:message];
    }
}

- (void) callJSWithArgs:(NSString *)msg withArgs: (NSDictionary *)args {
    NSError *parseError = nil;
    NSDictionary *param = @{@"msg":msg, @"args":args};
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:param options:0 error:&parseError];
    NSString *strArgs =  [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
//    NSLog(@"callToJS: %@", strArgs);
    [self callJS:strArgs];
}

- (void) authGameCenterView:(UIViewController *) viewController withError:(NSError *)error
{
    if (viewController != nullptr) {
        [_window.rootViewController presentViewController:viewController animated:TRUE completion:nil];
    }
}

- (void) recordScoreToGameCenter:(int)score
{
    if (GKLocalPlayer.localPlayer.authenticated) {
        GKScore * scoreReporter = [[GKScore alloc] initWithLeaderboardIdentifier:@"com.openew.game.lzd.rank"];
        scoreReporter.value = score;
        [GKScore reportScores:@[scoreReporter] withCompletionHandler:^(NSError * _Nullable error) {
            if (error != nil) {
                NSLog(@"record score to game center fail: %@", error);
            } else {
                NSLog(@"recore score to game center success");
            }
        }];
    }
}

- (void) showGameCenterRank
{
    GKGameCenterViewController *gv = [[GKGameCenterViewController alloc] init];
    gv.gameCenterDelegate = self;
    gv.viewState = GKGameCenterViewControllerStateLeaderboards;
    gv.leaderboardIdentifier = @"com.openew.game.lzd.rank";
    [_window.rootViewController presentViewController:gv animated:TRUE completion:nil];
}

- (void) gameCenterViewControllerDidFinish: (GKGameCenterViewController *)gv
{
    [gv dismissViewControllerAnimated:YES completion:nil];
}

- (void) checkVersionUpdate
{
//    NSLog(@"checkVersionUpdate appId: %s", appStoreAppId);
    if (strlen(appStoreAppId) <= 0) {
        return;
    }
    NSString *urlStr = [NSString stringWithFormat:@"http://itunes.apple.com/lookup?id=%s", appStoreAppId];
//    NSLog(@"checkVersionUpdate request url: %@", urlStr);
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:urlStr]];
    [NSURLConnection connectionWithRequest:request delegate:self];
}

-(void)connection:(NSURLConnection *)connection didReceiveData:(nonnull NSData *)data
{
    NSError *error;
//    NSLog(@"checkVersionUpdate response: %@", data);
    id jsonObject = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&error];
    NSDictionary *appInfo = (NSDictionary *)jsonObject;
    if (appInfo == nil) {
        return;
    }
    NSArray *infoContent = [appInfo objectForKey:@"results"];
    if (infoContent == nil || [infoContent count] <= 0) {
        return;
    }
    NSString *version = [[infoContent objectAtIndex:0] objectForKey:@"version"];
    if (version == nil) {
        return;
    }
    NSDictionary *curInfo = [[NSBundle mainBundle] infoDictionary];
    NSString *currentVersion = [curInfo objectForKey:@"CFBundleShortVersionString"];
//    NSLog(@"checkVersionUpdate version: %@, currentVersion: %@", version, currentVersion);
    if ([currentVersion compare:version] == NSOrderedAscending) {
        // 需要更新
        NSLog(@"new version: %@, current: %@", version, currentVersion);
//        UIAlertController *alertText = [UIAlertController alertControllerWithTitle:@"更新提醒" message:@"已有新版本上架，是否更新？" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertController *alertText = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"updateTitle", nil) message:NSLocalizedString(@"updateMessage", nil) preferredStyle:UIAlertControllerStyleAlert];
        [alertText addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"updateCancel", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            
        }]];
        [alertText addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"updateConfirm", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            NSString *urlStr = [NSString stringWithFormat:@"itms-apps://itunes.apple.com/cn/app/id%s?mt=8", appStoreAppId];
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:urlStr]];
        }]];
        [self.window.rootViewController presentViewController:alertText animated:YES completion:nil];
    } else {
        NSLog(@"newest version");
    }
}
@end
