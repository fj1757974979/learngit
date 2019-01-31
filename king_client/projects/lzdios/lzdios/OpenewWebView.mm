//
//  OpenewWebView.m
//  lzdios
//
//  Created by 兰清 on 07/07/2018.
//  Copyright © 2018 egret. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OpenewWebView.h"
#import <JavaScriptCore/JavaScriptCore.h>
#import <WebKit/WebKit.h>
#import <ReplayKit/ReplayKit.h>

@interface OpenewWebView()<WKNavigationDelegate, WKScriptMessageHandler, RPPreviewViewControllerDelegate, UIDocumentInteractionControllerDelegate>{
};

@property (nonatomic,strong) WKWebView *myWebView;
@property (nonatomic,strong) NSString *homeUrl;
@property (nonatomic, strong) WKWebViewConfiguration * webConfig;
@property (nonatomic) void(^nativeCallBack)(NSString*);
@property (nonatomic, strong) RPScreenRecorder *screenRecorder;
@property (nonatomic, strong) AVAssetWriterInput *assetWriterInput;
@property (nonatomic, strong) AVAssetWriterInput *assetWriterInputAudio;
@property (nonatomic, strong) AVAssetWriter *assetWriter;
@property (nonatomic, strong) NSString *videoPath;

@property BOOL isLoaded;

@end

@implementation OpenewWebView

- (instancetype) initWithUrl:(NSString *)homeUrl {
    if (self = [super init]) {
        self.homeUrl = homeUrl;
        self.isLoaded = FALSE;
    }
    return self;
}

#pragma mark - WKNavigationDelegate

- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(null_unspecified WKNavigation *)navigation withError:(NSError *)error
{
    if (!self.isLoaded) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self requestHomeUrl];
        });
    }
    NSLog(@"didFailProvisionalNavigation %@", error.localizedDescription);
}

#pragma mark - UIDocumentInteractionControllerDelegate

- (UIViewController*)documentInteractionControllerViewControllerForPreview:(UIDocumentInteractionController*)interactionController
{
    return self;
}

- (BOOL)shouldAutorotate {
    return NO;
}
/*
-(NSUInteger)supportedInterfaceOrientations{
    return UIInterfaceOrientationMaskPortrait;
}
 */


- (bool)supportRecord {
    return [[RPScreenRecorder sharedRecorder] isAvailable] && !SYSTEM_VERSION_LESS_THAN(@"11.0");
}

- (void)stopRecord {
    if (![self supportRecord]) {
        NSLog(@"不支持startCaptureWithHandler");
        return;
    }
    
    [[RPScreenRecorder sharedRecorder] stopCaptureWithHandler:^(NSError * _Nullable error) {
        if (error) {
            NSLog(@"error: %@", error);
        } else {
            NSLog(@"结束录屏");
            [self.assetWriter finishWritingWithCompletionHandler:^{
                NSLog(@"finish...!");
            }];
        }
    }];
    return;
}

- (void)saveToPhoto {
    if (UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(self.videoPath)) {
        UISaveVideoAtPathToSavedPhotosAlbum(self.videoPath, self,
                                        @selector(video:didFinishSavingWithError:contextInfo:), nil);
    }
}

- (void)video:(NSString *)videoPath didFinishSavingWithError:(NSError *)error
  contextInfo:(void *)contextInfo {
    NSLog(@"保存视频完成");
    [[NSFileManager defaultManager] removeItemAtPath:self.videoPath error:NULL];
}

- (void)shareVideo {
    NSURL * url = [NSURL fileURLWithPath:self.videoPath];
    _documentController = [UIDocumentInteractionController interactionControllerWithURL:url];
    UIViewController * vc = [UIApplication sharedApplication].keyWindow.rootViewController;
    [_documentController presentOpenInMenuFromRect:[UIScreen mainScreen].bounds  inView:vc.view animated:YES];
    _documentController.delegate = self;
}

- (void)startRecord {
    if (![self supportRecord]) {
        NSLog(@"不支持startCaptureWithHandler");
        return;
    }
    self.screenRecorder = [RPScreenRecorder sharedRecorder];
    if (self.screenRecorder.isRecording) {
        return;
    }
    NSError *error = nil;
    NSArray *pathDocuments = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *outputURL = pathDocuments[0];
    
    NSString *videoOutPath = [[outputURL stringByAppendingPathComponent:[NSString stringWithFormat:@"%@", @"screen"]] stringByAppendingPathExtension:@"mp4"];
    
    self.videoPath = videoOutPath;
    [[NSFileManager defaultManager] removeItemAtPath:videoOutPath error:NULL];
    self.assetWriter = [AVAssetWriter assetWriterWithURL:[NSURL fileURLWithPath:videoOutPath] fileType:AVFileTypeMPEG4 error:&error];
    
    NSDictionary *compressionProperties =
    @{
      AVVideoAverageBitRateKey       :  [NSNumber numberWithDouble:2000 * 1000],
      };
    
    NSNumber* width= [NSNumber numberWithFloat:self.view.frame.size.width*2];
    NSNumber* height = [NSNumber numberWithFloat:self.view.frame.size.height*2];
    NSDictionary *videoSettings =
    @{
      AVVideoCompressionPropertiesKey : compressionProperties,
      AVVideoCodecKey                 : AVVideoCodecH264,
      AVVideoWidthKey                 : width,
      AVVideoHeightKey                : height
      };
    
    NSDictionary *audioSettings = @{
                                    AVFormatIDKey                   : [NSNumber numberWithInt:kAudioFormatMPEG4AAC],
                                    AVSampleRateKey                 : @44100.0,
                                    AVEncoderBitRateKey             : @64000,
                                    AVNumberOfChannelsKey           : @1
                                    };
    
    self.assetWriterInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:videoSettings];
    self.assetWriterInputAudio = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeAudio outputSettings:audioSettings];
    self.assetWriterInput.expectsMediaDataInRealTime = YES;
    if ([self.assetWriter canAddInput:self.assetWriterInput]) {
        [self.assetWriter addInput:self.assetWriterInput];
    }
    if ([self.assetWriter canAddInput:self.assetWriterInputAudio]) {
        [self.assetWriter addInput:self.assetWriterInputAudio];
    }

    [self.screenRecorder startCaptureWithHandler:^(CMSampleBufferRef  _Nonnull sampleBuffer, RPSampleBufferType bufferType, NSError * _Nullable error) {
        if (CMSampleBufferDataIsReady(sampleBuffer)) {
            if (self.assetWriter.status == AVAssetWriterStatusUnknown &&
                (bufferType == RPSampleBufferTypeVideo ||
                 bufferType == RPSampleBufferTypeAudioApp) ) {
                
                [self.assetWriter startWriting];
                //丢掉无用帧
                CMTime pts = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
                int64_t videopts  = CMTimeGetSeconds(pts) * 1000;
                if(videopts < 0)
                    return ;
                [self.assetWriter startSessionAtSourceTime:pts];
            }
            
            if (self.assetWriter.status == AVAssetWriterStatusFailed) {
                NSLog(@"An error occured.");
                [[RPScreenRecorder sharedRecorder] stopCaptureWithHandler:^(NSError * _Nullable error) {}];
                return;
            }
            if (bufferType == RPSampleBufferTypeVideo ) {
                if (self.assetWriterInput.isReadyForMoreMediaData) {
                    //将sampleBuffer添加进视频输入源
                    [self.assetWriterInput appendSampleBuffer:sampleBuffer];
                }else{
                    NSLog(@"Not ready for video");
                }
            }
            
            if (bufferType == RPSampleBufferTypeAudioApp) {
                if (self.assetWriterInputAudio.isReadyForMoreMediaData) {
                    //将sampleBuffer添加进视频输入源
                    [self.assetWriterInputAudio appendSampleBuffer:sampleBuffer];
                }else{
                    NSLog(@"Not ready for video");
                }
            }
        }
    } completionHandler:^(NSError * _Nullable error) {
        if (!error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self callJS:@"{\"msg\":\"startRecordComplete\", \"args\":{\"success\":true}}"];
            });
            
            NSLog(@"Recording started successfully.");
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self callJS:@"{\"msg\":\"startRecordComplete\", \"args\":{\"success\":false}}"];
            });
            NSLog(@"Recording started error %@",error);
        }
    }];
}

- (void)dealloc{
    [[self.myWebView configuration].userContentController removeScriptMessageHandlerForName:@"callObjectC"];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.view addSubview:self.myWebView];
//    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[webView]|" options:0 metrics:nil views:@{@"webView":self.myWebView}]];
//    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[webView]|" options:0 metrics:nil views:@{@"webView":self.myWebView}]];
}

- (UIRectEdge)preferredScreenEdgesDeferringSystemGestures {
    return UIRectEdgeAll;
}

- (BOOL)prefersStatusBarHidden {
    // iphone X 显示
    if (IS_IPHONEX)
        return NO;
    else
        return YES;
}

- (void)callJS:(NSString *)msg
{
//    NSLog(@"callJS: %@", msg);
    NSString *script = [[NSString alloc] initWithFormat:@"Core.callJS(\'%@\');",msg];
    [self.myWebView evaluateJavaScript:script completionHandler:^(id _Nullable response, NSError * _Nullable error) {
//        NSLog(@"evaluateJavaScript %@ result: %@ error: %@", msg, response, error);
    }];
}

- (void)initNativeCall:(void(^)(NSString*))callback {
    self.nativeCallBack = callback;
}
/*
- (void)viewWillLayoutSubviews {
    CGRect bounds;
    bounds.origin.x = 0;
    bounds.origin.y = 0;
    bounds.size.width = MAX(self.view.bounds.size.width, self.view.bounds.size.height);
    bounds.size.height = MIN(self.view.bounds.size.width, self.view.bounds.size.height);
    self.view.frame = bounds;
}
 */

- (BOOL)webView:(WKWebView *)webView
shouldPreviewElement:(WKPreviewElementInfo *)elementInfo
{
    return YES;
}

- (UIViewController *)webView:(WKWebView *)webView
previewingViewControllerForElement:(WKPreviewElementInfo *)elementInfo
               defaultActions:(NSArray<id<WKPreviewActionItem>> *)previewActions
{
    [self callJS:@"{\"msg\":\"on3DTouch\", \"args\":{\"success\":true}}"];
    return self;
}

// 允许应用程序向它创建的视图控制器弹出
- (void)webView:(WKWebView *)webView commitPreviewingViewController:(UIViewController *)previewingViewController {
    
    NSLog(@"----允许应用程序向它创建的视图控制器弹出");
}

- (void) requestHomeUrl
{
    NSDate *date = [NSDate dateWithTimeIntervalSinceNow:0];
    long long time = [date timeIntervalSince1970];
    NSURL *url = [[NSURL alloc] initWithString:[NSString stringWithFormat:@"%@?v=%lld",self.homeUrl, time]];
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:url cachePolicy:NSURLRequestReturnCacheDataElseLoad timeoutInterval:3];
    [_myWebView loadRequest:request];
    NSLog(@"requestHomeUrl %@ %f", url, [date timeIntervalSince1970]);
}

- (WKWebView *)myWebView
{
    if (!_myWebView) {
        CGRect bounds;
        bounds.origin.x = 0;
        bounds.origin.y = 0;
        bounds.size.width = MIN(self.view.bounds.size.width, self.view.bounds.size.height);
        bounds.size.height = MAX(self.view.bounds.size.width, self.view.bounds.size.height);
        _myWebView = [[WKWebView alloc] initWithFrame:self.view.bounds configuration:self.webConfig];
        _myWebView.backgroundColor = [UIColor whiteColor];
        //_myWebView.scalesPageToFit = YES;
        //_myWebView.delegate = self;
        _myWebView.navigationDelegate = self;
        _myWebView.scrollView.bounces = false;
        _myWebView.autoresizingMask = UIViewAutoresizingNone;
//        [_myWebView setTranslatesAutoresizingMaskIntoConstraints:NO];
        _myWebView.allowsLinkPreview = NO;
        //_myWebView.UIDelegate = self;
        [self requestHomeUrl];
        // 这一行导致键盘收回后视图不回弹
//        _myWebView.scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    }
    return _myWebView;
}

#pragma mark - WKNavigationDelegate
- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    NSLog(@"%s",__func__);
    self.isLoaded = TRUE;
}

- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    NSLog(@"%s. Error %@",__func__,error);
    NSLog(@"%@", error.localizedDescription);
}


#pragma mark -WKScriptMessageHandler
- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
//    NSLog(@"%@,%@", message.name, message.body);
    self.nativeCallBack(message.body);
}

#pragma mark - accessors
-(WKWebViewConfiguration*) webConfig {
    
    if (!_webConfig) {
        // Create WKWebViewConfiguration instance
        _webConfig = [[WKWebViewConfiguration alloc] init];
        
        // Setup WKUserContentController instance for injecting user script
        WKUserContentController* userController = [[WKUserContentController alloc]init];
        
        // Add a script message handler for receiving  "buttonClicked" event notifications posted from the JS document using window.webkit.messageHandlers.buttonClicked.postMessage script message
        [userController addScriptMessageHandler:self name:@"callObjectC"];
        
        // Configure the WKWebViewConfiguration instance with the WKUserContentController
        _webConfig.userContentController = userController;
        
    }
    return _webConfig;
    
}

@end
