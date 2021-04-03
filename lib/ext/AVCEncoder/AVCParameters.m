//
//  AVCParameters.m
//  AVCEncoder
//
//  Created by Steve McFarlin on 5/5/11.
//  Copyright 2011 Steve McFarlin. All rights reserved.
//

#import "AVCParameters.h"


@implementation AVCParameters
@synthesize outWidth, outHeight, keyFrameInterval; //inWidth, inHeight, 
@synthesize bps, pixelFormat, videoProfileLevel; //videoScalingMode, 

- (id)init {
    self = [super init];
    if (self) {
        outWidth = 480;
        outHeight = 360;
        keyFrameInterval = 30;
        bps = 256000;
        pixelFormat = kCVPixelFormatType_32BGRA;
        // TODO: Figure out kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange
        //self.videoScalingMode = AVVideoScalingModeFit;
        videoProfileLevel = AVVideoProfileLevelH264Baseline31;   
    }
    return self;
}

- (void)dealloc {
///    self.videoScalingMode = nil;
    self.videoProfileLevel = nil;
}
@end
