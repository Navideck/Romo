//
//  RMShuffleActionView.m
//  Romo
//

#import "RMShuffleActionView.h"
#import <QuartzCore/QuartzCore.h>
#import <Romo/UIView+Additions.h>
#import "UIFont+RMFont.h"

@implementation RMShuffleActionView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        UIImageView *shuffle = [[UIImageView alloc] initWithImage:[UIImage cacheableImageNamed:@"shuffleIcon.png"]];
        shuffle.center = CGPointMake(self.contentView.width / 2, self.contentView.height / 2 + 12);
        [self.contentView addSubview:shuffle];
    }
    return self;
}

@end
