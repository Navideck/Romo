//
//  RMTurnActionIcon.m
//  Romo
//

#import "RMTurnActionIcon.h"
#import <QuartzCore/QuartzCore.h>
#import <Romo/UIView+Additions.h>

@interface RMTurnActionIcon ()

@property (nonatomic, strong) UIImageView *robot;

@end

@implementation RMTurnActionIcon

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _robot = [[UIImageView alloc] initWithImage:[UIImage cacheableImageNamed:@"romoTurn1.png"]];
        self.robot.contentMode = UIViewContentModeCenter;
        self.robot.animationImages = @[
                                       [UIImage cacheableImageNamed:@"romoTurn1.png"],
                                       [UIImage cacheableImageNamed:@"romoTurn3.png"],
                                       [UIImage cacheableImageNamed:@"romoTurn4.png"],
                                       [UIImage cacheableImageNamed:@"romoTurn5.png"],
                                       [UIImage cacheableImageNamed:@"romoTurn6.png"],
                                       [UIImage cacheableImageNamed:@"romoTurn7.png"],
                                       [UIImage cacheableImageNamed:@"romoTurn8.png"],
                                       [UIImage cacheableImageNamed:@"romoTurn9.png"],
                                       [UIImage cacheableImageNamed:@"romoTurn10.png"],
                                       [UIImage cacheableImageNamed:@"romoTurn11.png"],
                                       [UIImage cacheableImageNamed:@"romoTurn13.png"],
                                       [UIImage cacheableImageNamed:@"romoTurn14.png"],
                                       [UIImage cacheableImageNamed:@"romoTurn15.png"],
                                       [UIImage cacheableImageNamed:@"romoTurn17.png"],
                                       [UIImage cacheableImageNamed:@"romoTurn18.png"],
                                       [UIImage cacheableImageNamed:@"romoTurn19.png"],
                                       [UIImage cacheableImageNamed:@"romoTurn20.png"],
                                       [UIImage cacheableImageNamed:@"romoTurn21.png"],
                                       [UIImage cacheableImageNamed:@"romoTurn24.png"],
                                       [UIImage cacheableImageNamed:@"romoTurn26.png"],
                                       [UIImage cacheableImageNamed:@"romoTurn27.png"],
                                       [UIImage cacheableImageNamed:@"romoTurn28.png"],
                                       [UIImage cacheableImageNamed:@"romoTurn29.png"],
                                       [UIImage cacheableImageNamed:@"romoTurn30.png"],
                                       [UIImage cacheableImageNamed:@"romoTurn31.png"],
                                       [UIImage cacheableImageNamed:@"romoTurn34.png"],
                                       [UIImage cacheableImageNamed:@"romoTurn35.png"],
                                       [UIImage cacheableImageNamed:@"romoTurn36.png"],
                                       [UIImage cacheableImageNamed:@"romoTurn37.png"],
                                       [UIImage cacheableImageNamed:@"romoTurn38.png"],
                                       [UIImage cacheableImageNamed:@"romoTurn39.png"],
                                       [UIImage cacheableImageNamed:@"romoTurn40.png"],
                                       [UIImage cacheableImageNamed:@"romoTurn41.png"],
                                       ];
        self.robot.animationRepeatCount = 0;
        self.robot.frame = CGRectMake(0, 0, 200, 200);
        self.robot.transform = CGAffineTransformMakeScale(0.35, 0.35);
        self.robot.center = CGPointMake(self.contentView.width / 2, self.contentView.height / 2 + 3);
        self.robot.animationDuration = self.robot.animationImages.count / 24.0;
        [self.contentView addSubview:self.robot];
    }
    return self;
}

- (void)startAnimating
{
    [self.robot startAnimating];
}

- (void)stopAnimating
{
    [self.robot.layer removeAllAnimations];
    [self.robot stopAnimating];
}

@end
