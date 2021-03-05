//
//  RMGameController.h
//  Romo Control
//
//  Created by Foti Dim on 15.12.20.
//  Copyright © 2020 Romotive. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol RMGameControllerDelegate;

@interface RMGameController : NSObject
@property (nonatomic, weak) id <RMGameControllerDelegate> delegate;

@end

@protocol RMGameControllerDelegate

- (void)thumbstickInputDetectedwithDistance:(float)distance angle:(float)angle;
- (void)shoulderInputDetectedwithTiltDirectionPositive:(BOOL)isTiltDirectionPositive pressed:(BOOL)pressed;

@end

NS_ASSUME_NONNULL_END
