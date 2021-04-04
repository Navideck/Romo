//
//  RMLightBlinkActionIcon
//  Romo
//

#import "RMLightBlinkActionIcon.h"
#import <QuartzCore/QuartzCore.h>
#import <Romo/UIView+Additions.h>

@interface RMLightBlinkActionIcon ()

@property (nonatomic, strong) UIImageView *robot;

@end

@implementation RMLightBlinkActionIcon

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _robot = [[UIImageView alloc] initWithImage:[UIImage cacheableImageNamed:@"iconLightOn.png"]];
        self.robot.centerX = self.contentView.width / 2;
        [self.contentView addSubview:self.robot];
    }
    return self;
}

- (void)startAnimating
{
    self.robot.animationImages = @[
                                   [UIImage cacheableImageNamed:@"iconLightOn.png"],
                                   [UIImage cacheableImageNamed:@"iconLightOff.png"],
                                   ];
    self.robot.animationDuration = 0.75;
    [self.robot startAnimating];
}

- (void)stopAnimating
{
    [self.robot stopAnimating];
}

@end
