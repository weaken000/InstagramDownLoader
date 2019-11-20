//
//  InstagramViewController.m
//  InsgramDownLoader
//
//  Created by mac on 2019/10/17.
//  Copyright © 2019 leke. All rights reserved.
//

#import "InstagramViewController.h"

#import <WebKit/WebKit.h>
#import "ToastView.h"
#import "PhotosTool.h"
#import "WKUrlToModelTransform.h"
#import "ColorUtils.h"

@interface InstagramViewController ()<WKNavigationDelegate, WKScriptMessageHandler>

@property (nonatomic, strong) WKWebView *webView;

@end

@implementation InstagramViewController {
    UIButton *_downloadButton;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupUserScript];
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
    _downloadButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [_downloadButton setTitle:@"正在等待资源加载" forState:UIControlStateNormal];
    [_downloadButton addTarget:self action:@selector(click_pushToImage) forControlEvents:UIControlEventTouchUpInside];
    [_downloadButton setTitleColor:[ColorUtils grayColor] forState:UIControlStateNormal];
    _downloadButton.enabled = NO;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:_downloadButton];
    
//    BOOL isOpen = [[NSUserDefaults standardUserDefaults] boolForKey:@"com.wk.open"];
//    UIButton *left = [UIButton buttonWithType:UIButtonTypeSystem];
//    [left setTitle:isOpen?@"关闭code":@"开启code" forState:UIControlStateNormal];
//    [left addTarget:self action:@selector(click_openCode:) forControlEvents:UIControlEventTouchUpInside];
//    UIBarButtonItem *leftItem = [[UIBarButtonItem alloc] initWithCustomView:left];
//
//    self.navigationItem.leftBarButtonItems = @[leftItem];
}

- (void)setupInstance {
    
    NSString *cache = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
    NSString *dir = [cache stringByAppendingPathComponent:@"com.cache.lk"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:dir]) {
        [[NSFileManager defaultManager] removeItemAtPath:dir error:nil];
    }
    
    [PhotosTool share];
}

- (void)setupUserScript {
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
    
    NSString *downloadStateJS =
    @"$('#result').bind('DOMNodeInserted', function (e) {\
    var objs = document.getElementsByClassName(\"alert alert-danger\");\
    if (objs.length > 0) {\
    window.webkit.messageHandlers.app.postMessage({enable: false, length: objs.length});\
    } else {\
    window.webkit.messageHandlers.app.postMessage({enable: true, length: objs.length});\
    }\
    });\
    $('#result').bind('DOMNodeRemoved', function (e) {\
    window.webkit.messageHandlers.app.postMessage({enable: false});\
    });\
    ";
    
    NSString *ruleJS =
    @"function insertRule() {\
    $('.page-content').css('display', 'none');\
    $('header').css('display', 'none');\
    var heads = document.getElementsByClassName('jumbotron custom-jum no-mrg');\
    if (heads.length==0) {\
        return \"找不到head\";\
    }\
    var head = heads[0];\
    var textDiv = document.createElement('div');\
    textDiv.id = 'rule';\
    var title = document.createElement('h4');\
    title.innerText = '下载操作说明';\
    textDiv.appendChild(title);\
    var desc = document.createElement('p');\
    desc.innerText = '从instagram复制帖子链接填入到下面的输入框中，点击\"START\"按钮，等待图片资源加载完成后，点击右上角加载按钮进行下载，图片自动保存到相册中';\
    textDiv.appendChild(desc);\
    head.insertBefore(textDiv, head.childNodes[0]);\
    }";
    
    NSString *themeModeJS =
    @"function darkMode(darkMode) {\
    if (darkMode) {\
    $('body').css('backgroundColor', '#333333');\
    $('#rule').css('backgroundColor', '#333333');\
    $('.custom-jum').css('backgroundColor', '#333333');\
    $('footer').css('backgroundColor', '#333333');\
    $('.container').css('backgroundColor', '#333333');\
    $('.home-search').css('color', '#ffffff');\
    $('#rule').css('color', '#ffffff');\
    } else {\
    $('body').css('backgroundColor', '#ffffff');\
    $('#rule').css('backgroundColor', '#ffffff');\
    $('.custom-jum').css('backgroundColor', '#f5f8fa');\
    $('footer').css('backgroundColor', '#ffffff');\
    $('.container').css('backgroundColor', '#ffffff');\
    $('.home-search').css('color', '#333333');\
    $('#rule').css('color', '#333333');\
    }\
    }\
    ";

    WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
    config.userContentController = [[WKUserContentController alloc] init];

    //获取下载链接的注入
    WKUserScript *getUrlsUserScript = [[WKUserScript alloc] initWithSource:getUrlsJS injectionTime:WKUserScriptInjectionTimeAtDocumentStart forMainFrameOnly:NO];
    [config.userContentController addUserScript:getUrlsUserScript];

    //将剪切板内容填充进输入框的注入
    WKUserScript *fillPasteUserScript = [[WKUserScript alloc] initWithSource:fillPasteJS injectionTime:WKUserScriptInjectionTimeAtDocumentStart forMainFrameOnly:NO];
    [config.userContentController addUserScript:fillPasteUserScript];

    //是否可下载
    WKUserScript *downloadStateUserScript = [[WKUserScript alloc] initWithSource:downloadStateJS injectionTime:WKUserScriptInjectionTimeAtDocumentEnd forMainFrameOnly:NO];
    [config.userContentController addUserScript:downloadStateUserScript];

    //插入使用规则
    WKUserScript *ruleUserScript = [[WKUserScript alloc] initWithSource:ruleJS injectionTime:WKUserScriptInjectionTimeAtDocumentStart forMainFrameOnly:NO];
    [config.userContentController addUserScript:ruleUserScript];
    
    //主题颜色
    WKUserScript *themeUserScript = [[WKUserScript alloc] initWithSource:themeModeJS injectionTime:WKUserScriptInjectionTimeAtDocumentStart forMainFrameOnly:NO];
    [config.userContentController addUserScript:themeUserScript];
    
    [config.userContentController addScriptMessageHandler:self name:@"app"];
    
    self.view.backgroundColor = [ColorUtils whiteColor];
    self.webView = [[WKWebView alloc] initWithFrame:self.view.bounds configuration:config];
    self.webView.navigationDelegate = self;
    [self.view addSubview:self.webView];
}
#pragma mark -
- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    if (@available(iOS 13.0, *)) {
        if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection]) {
            if (self.traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {//暗黑模式
                [self.webView evaluateJavaScript:@"darkMode(true)" completionHandler:nil];
            } else {
                [self.webView evaluateJavaScript:@"darkMode(false)" completionHandler:nil];
            }
        }
    }
}

#pragma mark - WKNavigationDelegate
- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    [self fillInputFiled];
    [webView evaluateJavaScript:@"insertRule()" completionHandler:nil];
    if (@available(iOS 12.0, *)) {
        if (self.traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {//暗黑模式
            [self.webView evaluateJavaScript:@"darkMode(true)" completionHandler:nil];
        }
    }
}

#pragma mark - WKScriptMessageHandler
- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    BOOL enable = [message.body[@"enable"] boolValue];
    _downloadButton.enabled = enable;
    if (enable) {
        [_downloadButton setTitle:@"资源加载完成，点击下载" forState:UIControlStateNormal];
        [_downloadButton sizeToFit];
        [_downloadButton setTitleColor:[ColorUtils mainColor] forState:UIControlStateNormal];
    } else {
        [_downloadButton setTitle:@"正在等待资源加载" forState:UIControlStateNormal];
        [_downloadButton sizeToFit];
        [_downloadButton setTitleColor:[ColorUtils grayColor] forState:UIControlStateNormal];
    }
}

#pragma mark - Actions
- (void)click_pushToImage {
    [ToastView showLoading];
    [self.webView evaluateJavaScript:@"getImages()" completionHandler:^(id _Nullable value, NSError * _Nullable error) {
        [WKUrlToModelTransform transformInstagramUrls:value complete:^{
            [ToastView hiddenLoading];
            [self.tabBarController setSelectedIndex:2];
        }];
    }];
}

- (void)click_openCode:(UIButton *)sender {
    BOOL isOpen = [[NSUserDefaults standardUserDefaults] boolForKey:@"com.wk.open"];
    isOpen = !isOpen;
    [[NSUserDefaults standardUserDefaults] setBool:isOpen forKey:@"com.wk.open"];
    [sender setTitle:isOpen?@"关闭code":@"开启code" forState:UIControlStateNormal];
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
