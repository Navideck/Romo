//
//  RMBuyRomoView.m
//  Romo
//
//  Created on 7/16/13.
//  Copyright (c) 2013 Romotive. All rights reserved.
//

#import "RMPopupWebview.h"

#import "UIButton+RMButtons.h"
#import "UIView+Additions.h"

@interface RMPopupWebview ()

@property (nonatomic, strong) WKWebView *webView;
@property (nonatomic, strong) UIButton *dismissButton;

@end

@implementation RMPopupWebview

#pragma mark -- Object lifecycle

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor blackColor];
        [self addSubview:self.webView];
        [self addSubview:self.dismissButton];
    }
    return self;
}

#pragma mark -- Layout

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.webView.frame = self.bounds;
    self.dismissButton.origin = CGPointMake(10, 10);
}

#pragma mark -- Public properties

- (WKWebView *)webView
{
    if (!_webView) {
        // Equivalent to scalesPageToFit = YES;
        NSString *javascript = @"var meta = document.createElement('meta'); meta.setAttribute('name', 'viewport'); meta.setAttribute('content', 'width=device-width'); document.getElementsByTagName('head')[0].appendChild(meta);";
        WKUserScript *wkUserScript = [[WKUserScript alloc] initWithSource:javascript injectionTime:WKUserScriptInjectionTimeAtDocumentEnd forMainFrameOnly:YES];
        WKUserContentController *wkUController = [[WKUserContentController alloc] init];
        [wkUController addUserScript:wkUserScript];
        WKWebViewConfiguration *wkWebConfig = [[WKWebViewConfiguration alloc] init];
        wkWebConfig.userContentController = wkUController;
        _webView = [[WKWebView alloc] initWithFrame:self.frame configuration:wkWebConfig];

        _webView.scrollView.bounces = NO;
    }
    
    return _webView;
}

- (UIButton *)dismissButton
{
    if (!_dismissButton) {
        _dismissButton = [UIButton backButtonWithImage:nil];
    }
    
    return _dismissButton;
}

@end
