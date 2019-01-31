#ifndef NativeLauncher_h
#define NativeLauncher_h

#import <UIKit/UIKit.h>

#define RequestingRuntime @"requestingRuntime"
#define RetryRequestingRuntime @"retryRequestingRuntime"
#define LoadingGame @"loadingGame"
#define GameStarted @"gameStarted"
#define LoadRuntimeFailed @"loadRuntimeFailed"

@interface NativeLauncher : NSObject

- (instancetype)initWithViewController:(UIViewController*)viewController;
+ (UIView*)createEAGLView;
- (void)loadRuntime:(NSString*)token Callback:(void(^)(NSString*))callback;
- (void)startRuntime:(bool)showFPS;
- (void)startRuntime:(bool)showFPS FPSLOGTIME:(long)fpsLogTime;
- (void)setWebViewBackgroundTransparent:(BOOL)isTransparent;
- (void)setExternalInterface:(NSString*)funcName Callback:(void(^)(NSString*))callback;
- (void)callExternalInterface:(NSString*)funcName Value:(NSString*)value;
- (void)setLaunchScreenImagePathAndDuration:(NSString*)imagePath Duration:(int)duration;
- (void)showLaunchScreenIfPossible;
- (void)hideLaunchScreenIfPossible:(int)delayedMills;
@property int clearCache;
@property int closeLoadingViewAutomatically;
@property int logLevel;
@property unsigned long loadingTimeout;
@property NSString* preloadPath;

- (void)pause;
- (void)resume;
- (void)destroy;

- (void)showPrompt:(NSString*)str;
- (void)disableNativeRender;
- (void)disableConfig;

@end

#endif /* NativeLauncher_h */
