//
//  RMBuyRomoView.h
//  Romo
//
//  Created on 7/16/13.
//  Copyright (c) 2013 Romotive. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>

@interface RMPopupWebview : UIView

@property (nonatomic, strong, readonly) WKWebView *webView;
@property (nonatomic, strong, readonly) UIButton *dismissButton;

@end
