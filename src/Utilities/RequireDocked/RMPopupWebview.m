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

//@property (nonatomic, strong) WKWebView *webView;
@property (nonatomic, strong) WKWebView *wkWebView API_AVAILABLE(ios(8.0));
@property (nonatomic, strong) UIWebView *uiWebView;
@property (nonatomic, strong) UIButton *dismissButton;

@end

@implementation RMPopupWebview

#pragma mark -- Object lifecycle

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor blackColor];
        
        if (@available(iOS 8, *)) {
            [self addSubview:self.wkWebView];
        } else {
            [self addSubview:self.uiWebView];
        }
        
        [self addSubview:self.dismissButton];
    }
    return self;
}

#pragma mark -- Layout

- (void)layoutSubviews
{
    [super layoutSubviews];
    if (@available(iOS 8.0, *)) {
        self.wkWebView.frame = self.bounds;
    } else {
        self.uiWebView.frame = self.bounds;
    }
    self.dismissButton.origin = CGPointMake(10, 10);
}

#pragma mark -- Public properties

- (WKWebView *)wkWebView API_AVAILABLE(ios(8.0)) {
    if (!_wkWebView) {
        // Equivalent to scalesPageToFit = YES;
        NSString *javascript = @"var meta = document.createElement('meta'); meta.setAttribute('name', 'viewport'); meta.setAttribute('content', 'width=device-width'); document.getElementsByTagName('head')[0].appendChild(meta);";
        WKUserScript *wkUserScript = [[WKUserScript alloc] initWithSource:javascript injectionTime:WKUserScriptInjectionTimeAtDocumentEnd forMainFrameOnly:YES];
        WKUserContentController *wkUController = [[WKUserContentController alloc] init];
        [wkUController addUserScript:wkUserScript];
        WKWebViewConfiguration *wkWebConfig = [[WKWebViewConfiguration alloc] init];
        wkWebConfig.userContentController = wkUController;
        _wkWebView = [[WKWebView alloc] initWithFrame:self.frame configuration:wkWebConfig];
        
        _wkWebView.scrollView.bounces = NO;
    }
    
    return _wkWebView;
}

- (UIWebView *)uiWebView
{
    if (!_uiWebView) {
        _uiWebView = [[UIWebView alloc] init];
        _uiWebView.scrollView.bounces = NO;
        _uiWebView.scalesPageToFit = YES;
    }
    
    return _uiWebView;
}

- (UIButton *)dismissButton
{
    if (!_dismissButton) {
        _dismissButton = [UIButton backButtonWithImage:nil];
    }
    
    return _dismissButton;
}

@end
