//
//  ViewController.m
//  WKWebviewDemo
//
//  Created by apple on 16/11/30.
//  Copyright © 2016年 guchunli. All rights reserved.
//

#import "ViewController.h"
#import <WebKit/WebKit.h>

@interface ViewController ()<WKNavigationDelegate,WKUIDelegate,WKScriptMessageHandler>

@property (nonatomic,strong)WKWebView *webView;
@property (nonatomic,strong)WKUserContentController *userCC;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //1.
//    WKWebView *webView = [[WKWebView alloc] initWithFrame:self.view.bounds];
//    webView.allowsBackForwardNavigationGestures = YES;
////    webView.backForwardList
//    webView.UIDelegate = self;
//    webView.navigationDelegate = self;
//    [webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"https://www.baidu.com"]]];
//    [self.view addSubview:webView];
    
    
    //2.wkwebview加载本地文件
    self.webView = [[WKWebView alloc] initWithFrame:CGRectMake(0, 74, self.view.frame.size.width, self.view.frame.size.height-74)];
    [self.webView sizeToFit];
    self.webView.UIDelegate = self;
    [self.view addSubview:self.webView];
    [self loadLocalFile];
    
    //3.oc-js交互
    self.userCC = [self.webView configuration].userContentController;
    [self.userCC addScriptMessageHandler:self name:@"nativeMethod"];
    
    [self.webView addObserver:self forKeyPath:@"estimatedProgress" options:NSKeyValueObservingOptionNew context:nil];
    [self.webView addObserver:self forKeyPath:@"title" options:NSKeyValueObservingOptionNew context:nil];
    [self.webView addObserver:self forKeyPath:@"loading" options:NSKeyValueObservingOptionNew context:nil];
    
    //OC注册供JS调用的方法
    UIButton *btn = [[UIButton alloc]initWithFrame:CGRectMake(0, 20, 100, 44)];
    btn.backgroundColor = [UIColor orangeColor];
    [btn addTarget:self action:@selector(toJSMethod) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn];
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context{

    if ([keyPath isEqualToString:@"estimatedProgress"]) {
        
        NSLog(@"progress:%f",self.webView.estimatedProgress);
    }else if ([keyPath isEqualToString:@"title"]) {
        
        NSLog(@"title:%@",self.webView.title);
    }else if ([keyPath isEqualToString:@"loading"]) {
        
        NSLog(@"loading");
    }
}

- (void)toJSMethod{

    [self.webView evaluateJavaScript:@"jsFunc('oc-js','222')" completionHandler:^(id _Nullable response, NSError * _Nullable error) {
        
        //NSLog(@"%@ %@",response,error);
    }];
}

//- (void)nativeMethod:(NSString *)param{
//
//    NSLog(@"native:%@",param);
//}

-(void)viewDidDisappear:(BOOL)animated{

    [super viewDidDisappear:animated];
    
    [self.userCC removeScriptMessageHandlerForName:@"estimatedProgress"];
    [self.webView removeObserver:self forKeyPath:@"loading"];
    [self.webView removeObserver:self forKeyPath:@"title"];
    [self.webView removeObserver:self forKeyPath:@"loading"];
}

#pragma mark - oc-js交互
//OC在JS调用方法做的处理
// message: 收到的脚本信息.
- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message{
    
    NSLog(@"JS 调用了 OC %@ 方法，传回参数 %@",message.name,message.body);
    if ([message.name isEqualToString:@"nativeMethod"]) {
        
        NSLog(@"123");
    }
}

#pragma mark - 加载本地文件
- (void)loadLocalFile{
    
//    NSString *filePath = [[NSBundle mainBundle]pathForResource:@"index" ofType:@"html"];
//    NSString * str = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:nil];
//    [self.webView loadHTMLString:str baseURL:nil];

    //调用逻辑
    NSString *path = [[NSBundle mainBundle] pathForResource:@"index" ofType:@"html"];
    if(path){
        if ([[UIDevice currentDevice].systemVersion floatValue] >= 9.0) {
            // iOS9. One year later things are OK.
            NSURL *fileURL = [NSURL fileURLWithPath:path];
            [self.webView loadFileURL:fileURL allowingReadAccessToURL:fileURL];
        } else {
            // iOS8. Things can be workaround-ed
            //   Brave people can do just this
            //   fileURL = try! pathForBuggyWKWebView8(fileURL)
            //   webView.loadRequest(NSURLRequest(URL: fileURL))
            
            NSURL *fileURL = [self fileURLForBuggyWKWebView8:[NSURL fileURLWithPath:path]];
            NSURLRequest *request = [NSURLRequest requestWithURL:fileURL];
            [self.webView loadRequest:request];
        }
    }
}

//将文件copy到tmp目录
- (NSURL *)fileURLForBuggyWKWebView8:(NSURL *)fileURL {
    NSError *error = nil;
    if (!fileURL.fileURL || ![fileURL checkResourceIsReachableAndReturnError:&error]) {
        return nil;
    }
    // Create "/temp/www" directory
    NSFileManager *fileManager= [NSFileManager defaultManager];
    NSURL *temDirURL = [[NSURL fileURLWithPath:NSTemporaryDirectory()] URLByAppendingPathComponent:@"www"];
    [fileManager createDirectoryAtURL:temDirURL withIntermediateDirectories:YES attributes:nil error:&error];
    
    NSURL *dstURL = [temDirURL URLByAppendingPathComponent:fileURL.lastPathComponent];
    // Now copy given file to the temp directory
    [fileManager removeItemAtURL:dstURL error:&error];
    [fileManager copyItemAtURL:fileURL toURL:dstURL error:&error];
    // Files in "/temp/www" load flawlesly :)
    return dstURL;
}

#pragma mark - WKNavigationDelegate
#pragma mark - 用来追踪加载过程（页面开始加载、加载完成、加载失败）的方法
// 页面开始加载时调用
- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation{

    NSLog(@"did start");
    NSLog(@"%f",webView.estimatedProgress);
}
// 当内容开始返回时调用
- (void)webView:(WKWebView *)webView didCommitNavigation:(WKNavigation *)navigation{

    NSLog(@"did commit");
}
// 页面加载完成之后调用
- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation{

    NSLog(@"did finish");
}
// 页面加载失败时调用
- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation{

    NSLog(@"did fail");
}

#pragma mark - 页面跳转的代理方法
// 接收到服务器跳转请求之后调用
- (void)webView:(WKWebView *)webView didReceiveServerRedirectForProvisionalNavigation:(WKNavigation *)navigation{

    NSLog(@"didReceive ServerRedirect");
}
// 在发送请求之前，决定是否跳转
- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler{
    
    NSLog(@"decidePolicyForNavigation Action");
    //这句是必须加上的，不然会异常
    decisionHandler(WKNavigationActionPolicyAllow);
}

// 在收到响应后，决定是否跳转
- (void)webView:(WKWebView *)webView decidePolicyForNavigationResponse:(WKNavigationResponse *)navigationResponse decisionHandler:(void (^)(WKNavigationResponsePolicy))decisionHandler{

    NSLog(@"decidePolicyForNavigation Response");
    //这句是必须加上的，不然会异常
    decisionHandler(WKNavigationResponsePolicyAllow);
}

//- (void)webView:(WKWebView *)webView didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential * _Nullable credential))completionHandler{
//
//    NSLog(@"didReceive AuthenticationChallenge");
//}

#pragma mark - WKUIDelegate
// 1.创建一个新的WebView
//- (WKWebView *)webView:(WKWebView *)webView createWebViewWithConfiguration:(WKWebViewConfiguration *)configuration forNavigationAction:(WKNavigationAction *)navigationAction windowFeatures:(WKWindowFeatures *)windowFeatures{
//
//    
//}
// 2.WebVeiw关闭（9.0中的新方法）
- (void)webViewDidClose:(WKWebView *)webView NS_AVAILABLE(10_11, 9_0){

    NSLog(@"did close");
}
// 3.显示一个JS的Alert（与JS交互）
- (void)webView:(WKWebView *)webView runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(void))completionHandler{
    
    NSLog(@"message:%@",message);
    completionHandler();
}
// 4.弹出一个输入框（与JS交互的）
- (void)webView:(WKWebView *)webView runJavaScriptTextInputPanelWithPrompt:(NSString *)prompt defaultText:(nullable NSString *)defaultText initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(NSString * __nullable result))completionHandler{

    
}
// 5.显示一个确认框（JS的）
- (void)webView:(WKWebView *)webView runJavaScriptConfirmPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(BOOL result))completionHandler{

    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
