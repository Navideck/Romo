//
//  RMAlarmIcon.m
//  Romo
//

#import "RMAlarmActionIcon.h"
#import <QuartzCore/QuartzCore.h>
#import <Romo/UIView+Additions.h>

@interface RMAlarmActionIcon ()

@end

@implementation RMAlarmActionIcon

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        UIImageView *alarmIcon = [[UIImageView alloc] initWithImage:[UIImage cacheableImageNamed:@"alarmIcon.png"]];
        alarmIcon.top = 0;
        alarmIcon.centerX = self.contentView.width / 2.0;
        [self.contentView addSubview:alarmIcon];
    }
    return self;
}

@end
