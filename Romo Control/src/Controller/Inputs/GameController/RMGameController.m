//
//  RMGameController.m
//  Romo Control
//
//  Created by Foti Dim on 15.12.20.
//  Copyright © 2020 Romotive. All rights reserved.
//

#import "RMGameController.h"
#import <GameController/GameController.h>

@interface RMGameController()

@property (nonatomic, strong) GCController *controller;
@property (nonatomic, strong) id connectObserver;
//@property (nonatomic, strong) id disconnectObserver;

@end

@implementation RMGameController

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.connectObserver = [[NSNotificationCenter defaultCenter] addObserverForName:GCControllerDidConnectNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
            [self setupControllers];
        }];

//        self.disconnectObserver = [[NSNotificationCenter defaultCenter] addObserverForName:GCControllerDidDisconnectNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
//
//        }];

        [self setupControllers];
    }
    return self;
}

-(void)setupControllers {
    // Run through each controller currently connected to the system
    for (GCController *controller in GCController.controllers) {
        //Check to see whether it is an extended Game Controller
        if (controller.extendedGamepad != nil) {
            self.controller = controller;
            controller.playerIndex = GCControllerPlayerIndex1;
            [self setupControllerControls];
        }
    }
}

-(void)setupControllerControls {
    __weak RMGameController *weakSelf = self;
    [self.controller.extendedGamepad.leftThumbstick setValueChangedHandler:^(GCControllerDirectionPad * _Nonnull dpad, float xValue, float yValue) {
        float distance = MIN(1.0, sqrtf(powf(xValue, 2) + powf(yValue, 2)));;
        float radians = atan2(yValue, xValue);
        float angle = ((radians) * (180.0 / M_PI));
        if (angle < 0) {
            angle += 360;
        }

        //        float distance = MIN(1.0, sqrtf(powf(gamepad.leftThumbstick.xAxis.value, 2) + powf(gamepad.leftThumbstick.yAxis.value, 2)));
        //        float direction = (angle >= 180) || (angle < 0) ? -1 : 1;
        //        float driveSpeed = powf(distance, 2) * direction;
        //        float driveRadius = tanf(((-angle) * (M_PI / 180.0)));

        if (distance == 0 ) {
            [weakSelf.delegate thumbstickInputDetectedwithDistance:0 angle:0];
        } else {
            [weakSelf.delegate thumbstickInputDetectedwithDistance:distance angle:angle];
        }
    }];

    [self.controller.extendedGamepad.rightShoulder setValueChangedHandler:^(GCControllerButtonInput * _Nonnull button, float value, BOOL pressed) {
        [weakSelf.delegate shoulderInputDetectedwithTiltDirectionPositive:true pressed:pressed];
    }];

    [self.controller.extendedGamepad.leftShoulder setValueChangedHandler:^(GCControllerButtonInput * _Nonnull button, float value, BOOL pressed) {
        [weakSelf.delegate shoulderInputDetectedwithTiltDirectionPositive:false pressed:pressed];
    }];
}

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self.connectObserver];
//  [[NSNotificationCenter defaultCenter] removeObserver:self.disconnectObserver];
}

@end
