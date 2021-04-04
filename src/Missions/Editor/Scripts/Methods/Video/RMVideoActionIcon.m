//
//  RMVideoActionIcon.m
//  Romo
//

#import "RMVideoActionIcon.h"
#import <QuartzCore/QuartzCore.h>
#import <Romo/UIView+Additions.h>

@interface RMVideoActionIcon ()

@property (nonatomic, strong) UIImageView *lensGlow;

@end

@implementation RMVideoActionIcon

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        UIImageView *iPhone = [[UIImageView alloc] initWithImage:[UIImage cacheableImageNamed:@"iconVideo.png"]];
        iPhone.centerX = self.contentView.width / 2;
        iPhone.bottom = self.contentView.height + 0.5;
        [self.contentView addSubview:iPhone];

        _lensGlow = [[UIImageView alloc] initWithImage:[UIImage cacheableImageNamed:@"iphoneCameraGlow.png"]];
        self.lensGlow.center = CGPointMake(23, 16.5);
        self.lensGlow.alpha = 0.5;
        self.lensGlow.transform = CGAffineTransformMakeScale(0.6, 0.6);
        [iPhone addSubview:self.lensGlow];
    }
    return self;
}

@end
