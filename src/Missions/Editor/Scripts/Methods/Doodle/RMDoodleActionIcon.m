//
//  RMDoodleIcon.m
//  Romo
//

#import "RMDoodleActionIcon.h"
#import <QuartzCore/QuartzCore.h>
#import <Romo/UIView+Additions.h>

@interface RMDoodleActionIcon ()

@end

@implementation RMDoodleActionIcon

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        UIImageView *doodleIcon = [[UIImageView alloc] initWithImage:[UIImage cacheableImageNamed:@"doodleIcon.png"]];
        doodleIcon.frame = self.contentView.bounds;
        doodleIcon.contentMode = UIViewContentModeCenter;
        [self.contentView addSubview:doodleIcon];
    }
    return self;
}

@end
