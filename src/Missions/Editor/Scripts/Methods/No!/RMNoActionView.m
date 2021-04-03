//
//  RMNoActionView.m
//  Romo
//

#import "RMNoActionView.h"
#import "UIView+Additions.h"

@interface RMNoActionView ()

@property (nonatomic, strong) UIImageView *robot;

@end

@implementation RMNoActionView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _robot = [[UIImageView alloc] initWithImage:[UIImage cacheableImageNamed:@"romoDriveForward1.png"]];
        self.robot.contentMode = UIViewContentModeCenter;
        self.robot.frame = CGRectMake(0, 0, 200, 200);
        self.robot.transform = CGAffineTransformMakeScale(0.55, 0.55);
        self.robot.center = CGPointMake(self.contentView.width / 2, self.contentView.height / 2 + 5);
        self.robot.animationImages = @[
                                       [UIImage cacheableImageNamed:@"romoTurn28.png"],
                                       [UIImage cacheableImageNamed:@"romoTurn29.png"],
                                       [UIImage cacheableImageNamed:@"romoTurn30.png"],
                                       [UIImage cacheableImageNamed:@"romoTurn31.png"],
                                       [UIImage cacheableImageNamed:@"romoTurn34.png"],
                                       [UIImage cacheableImageNamed:@"romoTurn35.png"],
                                       [UIImage cacheableImageNamed:@"romoTurn35.png"],
                                       [UIImage cacheableImageNamed:@"romoTurn34.png"],
                                       [UIImage cacheableImageNamed:@"romoTurn31.png"],
                                       [UIImage cacheableImageNamed:@"romoTurn30.png"],
                                       [UIImage cacheableImageNamed:@"romoTurn29.png"],
                                       [UIImage cacheableImageNamed:@"romoTurn28.png"],
                                       [UIImage cacheableImageNamed:@"romoTurn28.png"],
                                       [UIImage cacheableImageNamed:@"romoTurn29.png"],
                                       [UIImage cacheableImageNamed:@"romoTurn30.png"],
                                       [UIImage cacheableImageNamed:@"romoTurn31.png"],
                                       [UIImage cacheableImageNamed:@"romoTurn34.png"],
                                       [UIImage cacheableImageNamed:@"romoTurn35.png"],
                                       [UIImage cacheableImageNamed:@"romoTurn35.png"],
                                       [UIImage cacheableImageNamed:@"romoTurn34.png"],
                                       [UIImage cacheableImageNamed:@"romoTurn34.png"],
                                       [UIImage cacheableImageNamed:@"romoTurn34.png"],
                                       [UIImage cacheableImageNamed:@"romoTurn31.png"],
                                       [UIImage cacheableImageNamed:@"romoTurn31.png"],
                                       [UIImage cacheableImageNamed:@"romoTurn31.png"],
                                       [UIImage cacheableImageNamed:@"romoTurn31.png"],
                                       [UIImage cacheableImageNamed:@"romoTurn31.png"],
                                       [UIImage cacheableImageNamed:@"romoTurn30.png"],
                                       [UIImage cacheableImageNamed:@"romoTurn30.png"],
                                       [UIImage cacheableImageNamed:@"romoTurn30.png"],
                                       [UIImage cacheableImageNamed:@"romoTurn29.png"],
                                       [UIImage cacheableImageNamed:@"romoTurn28.png"],
                                       ];
        self.robot.animationRepeatCount = 0;
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
