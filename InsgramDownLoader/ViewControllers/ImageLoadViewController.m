//
//  ImageLoadViewController.m
//  InsgramDownLoader
//
//  Created by mac on 2019/10/17.
//  Copyright © 2019 leke. All rights reserved.
//

#import "ImageLoadViewController.h"
#import "DownloadProgressViewController.h"
#import "YoutubeViewController.h"

#import <WebKit/WebKit.h>
#import "ToastView.h"
#import "PhotosTool.h"

@interface ImageLoadViewController ()<WKNavigationDelegate>

@property (nonatomic, strong) WKWebView *webView;

@end

@implementation ImageLoadViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSString *getUrlsJS =
    @"function getImages() {\
    var objs = document.getElementsByClassName(\"btn btn-download\");\
    var imgUrls = [];\
    for(var i=0;i<objs.length;i++){\
    if (objs[i]!=null) {\
    imgUrls.push(objs[i].href);\
    }\
    };\
    return imgUrls;\
    }\
    ";
    
    NSString *fillPasteJS =
    @"function fillTF(paste) {\
    var tf = document.getElementById(\'url\');\
    if (tf.value && tf.value == paste) {\
    return false;\
    }\
    tf.value = paste;\
    return true;\
    }\
    ";
    
    NSString *colorJS =
    @"window.onload = function(){\
    document.body.style.backgroundColor = '#333333';\
    document.h.style.backgroundColor = '#000000';\
    }";

    WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
    config.userContentController = [[WKUserContentController alloc] init];
    
    //获取下载链接的注入
    WKUserScript *getUrlsUserScript = [[WKUserScript alloc] initWithSource:getUrlsJS injectionTime:WKUserScriptInjectionTimeAtDocumentStart forMainFrameOnly:NO];
    [config.userContentController addUserScript:getUrlsUserScript];
    //将剪切板内容填充进输入框的注入
    WKUserScript *fillPasteUserScript = [[WKUserScript alloc] initWithSource:fillPasteJS injectionTime:WKUserScriptInjectionTimeAtDocumentStart forMainFrameOnly:NO];
    [config.userContentController addUserScript:fillPasteUserScript];
    //背景色修改的注入
    WKUserScript *colorUserScript = [[WKUserScript alloc] initWithSource:colorJS injectionTime:WKUserScriptInjectionTimeAtDocumentStart forMainFrameOnly:NO];
    [config.userContentController addUserScript:colorUserScript];

    self.view.backgroundColor = [UIColor whiteColor];
    self.webView = [[WKWebView alloc] initWithFrame:self.view.bounds configuration:config];
    self.webView.navigationDelegate = self;
    [self.view addSubview:self.webView];
    NSURLRequest *req = [NSURLRequest requestWithURL:[NSURL URLWithString:@"https://igsave.net/zh"]];
    [self.webView loadRequest:req];
    
    [self setupNavi];
    [self setupInstance];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    self.webView.frame = self.view.bounds;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self fillInputFiled];
}

#pragma mark -

- (void)setupNavi {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    [button setTitle:@"下载图片" forState:UIControlStateNormal];
    [button addTarget:self action:@selector(click_pushToImage) forControlEvents:UIControlEventTouchUpInside];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:button];
    
    BOOL isOpen = [[NSUserDefaults standardUserDefaults] boolForKey:@"com.wk.open"];
    UIButton *left = [UIButton buttonWithType:UIButtonTypeSystem];
    [left setTitle:isOpen?@"关闭code":@"开启code" forState:UIControlStateNormal];
    [left addTarget:self action:@selector(click_openCode:) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *leftItem = [[UIBarButtonItem alloc] initWithCustomView:left];
    
    UIButton *jumpToYoutubeButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [jumpToYoutubeButton setTitle:@"跳转Youtube" forState:UIControlStateNormal];
    [jumpToYoutubeButton addTarget:self action:@selector(click_openYoutube) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *jumpToYoutubeItem = [[UIBarButtonItem alloc] initWithCustomView:jumpToYoutubeButton];

    self.navigationItem.leftBarButtonItems = @[jumpToYoutubeItem, leftItem];
}

- (void)setupInstance {
    
    NSString *cache=[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
    NSString *dir = [cache stringByAppendingPathComponent:@"com.cache.lk"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:dir]) {
        [[NSFileManager defaultManager] removeItemAtPath:dir error:nil];
    }
    
    [PhotosTool share];
}

#pragma mark - WKNavigationDelegate
- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    [self fillInputFiled];
}

#pragma mark - Actions
- (void)click_pushToImage {
    [ToastView showLoading];
    [self.webView evaluateJavaScript:@"getImages()" completionHandler:^(id _Nullable value, NSError * _Nullable error) {
        [ToastView hiddenLoading];
        DownloadProgressViewController *next = [[DownloadProgressViewController alloc] init];
        next.urls = value;
        [self.navigationController pushViewController:next animated:YES];
    }];
}

- (void)click_openCode:(UIButton *)sender {
    BOOL isOpen = [[NSUserDefaults standardUserDefaults] boolForKey:@"com.wk.open"];
    isOpen = !isOpen;
    [[NSUserDefaults standardUserDefaults] setBool:isOpen forKey:@"com.wk.open"];
    [sender setTitle:isOpen?@"关闭code":@"开启code" forState:UIControlStateNormal];
}

- (void)click_openYoutube {
    UIStoryboard *storyBoard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    UIViewController *vc = [storyBoard instantiateViewControllerWithIdentifier:@"youtube"];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)fillInputFiled {
    NSString *string = [UIPasteboard generalPasteboard].string;
    if (string && string.length > 0 && [string hasPrefix:@"https://www.instagram.com"]) {
        __weak typeof(self) weakSelf = self;
        [self.webView evaluateJavaScript:[NSString stringWithFormat:@"fillTF(\'%@\')", string] completionHandler:^(id _Nullable res, NSError * _Nullable error) {
            if (!error && [res boolValue]) {
                [weakSelf.webView evaluateJavaScript:@"analyze()" completionHandler:^(id _Nullable res, NSError * _Nullable error) {
                    
                }];
            }
        }];
    }
}

@end
