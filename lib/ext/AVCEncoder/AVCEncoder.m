//
//  AVCEncoder.m
//  AVCEncoder
//
//  Created by Steve McFarlin on 5/5/11.
//  Copyright 2011 Steve McFarlin. All rights reserved.
//
/**
 Development Notes:
 
 This class uses GCD queues exclusivly. There are 2 main internal queues.
 
 Writer queue - This is used in the encoding methods, and also to create AVFoundation support classes.
 Monitor queue - This is used to monitor the AVC data file, and to invoke parsing.
 
 In order to support dynamic bitrate changes we must create a new AVAssetWriter and associated support 
 classes. The way these are created is to push a Asset Creation block onto the writer queue. This way
 we do not have to write in any lock code to prevent a caller context from attempting to write to a
 deallocated AVAssetWriter. By pushing into the same serial queue as the writer it wil get in line
 and we will be insured it will be created.
 
 Another reason to use queues is to create a lockless call chain. By dispatching all property setup
 and start/stop messages on the queue we prevent outside calls from accessing local members when 
 they should not.
 
 TODO: Change all error handling to simply return a BOOL. Setup an error memeber for users to check.
 
 BUG: We need to verify the encoding parameters are valid.
 
 */

#import "AVCEncoder.h"
#import <AVFoundation/AVFoundation.h>
#include "qt_parser.h"
#include "SMFileUtil.h"

#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>


#pragma mark -
#pragma mark Defines
#pragma mark -

#define kBaseDirectory  @"libavcencoder"

#pragma mark -
#pragma mark Globals
#pragma mark -


#pragma mark -
#pragma mark Block declarations
#pragma mark -

/**
 NOTE: Currently not used. Will be handy if performance of current implementation need improvement.
 @discussion
 
 This block is used to create the asset writer and associated support. This block
 should be issued on the writer queue. This way we can switch writers without 
 having to use locks. This enables us to simulate realtime bitrate changes.
 
 @param encoder The encoder this block will use to set the writer properties on.
 */
typedef void (^AVCWriterCreationBlock)(AVCEncoder*);

/**
 @discussion
 
 The encoder block that submits frames to AVAssetWriterInput
 */
typedef void (^AVCEncoderBlock)(CMSampleBufferRef);

/**
 @discussion
 
 Release the file monitor queue after the queue is released.
 */
//void MonitorQueueTeardown(void* obj) {
//    dispatch_queue_t queue = (dispatch_queue_t) obj;
//    dispatch_release(queue);
//}

#pragma mark -
#pragma mark Class extention
#pragma mark -

//forwards
@class AVCTimeObj, AVCWriterObj;

@interface AVCEncoder () 
@property (nonatomic, readwrite, retain) NSError* error;
@property (nonatomic, assign, readwrite) BOOL isEncoding;

@property (nonatomic, retain) NSMutableArray* timeQueue;
@property (nonatomic, retain) NSMutableDictionary* compressionProperties;
@property (nonatomic, retain) NSMutableDictionary* videoSettings;
@property (nonatomic, retain) AVCWriterObj* writerObj;
@property (nonatomic, retain) AVCWriterCreationBlock writerCreationBlock;
@property (nonatomic, copy) AVCEncoderBlock encoderBlock;
@property (nonatomic, copy) AVCFrameCallback parserCallback;
@property (nonatomic, retain) dispatch_queue_t writer_queue;
@property (nonatomic, retain) dispatch_source_t timer;
@property (nonatomic, assign) double timeOfBitrateChange;
@property (nonatomic, retain) NSString* path;
@property (nonatomic, assign) AVCParserStruct* parser;
@property (nonatomic, retain, readwrite) NSData *spspps; //only valid after encoder is prepared. In Annex B format
@property (nonatomic, retain, readwrite) NSData *sps, *pps;

- (void) setupProperties;
- (AVCWriterObj*) setupWriterObj;
- (BOOL) generateSPSPPS:(CVPixelBufferRef) pixelBuffer;
- (void) createEncoderBlock;
- (void) createParserCallback;
@end

#pragma mark -
#pragma mark Time object
#pragma mark -

@interface AVCTimeObj : NSObject {
@public
    CMTime time_stamp;
}
@end
@implementation AVCTimeObj
- (id)initWithTime:(CMTime) time {
    self = [super init];
    if (self) {
        time_stamp = time;
    }
    return self;
}
@end

#pragma mark -
#pragma mark Monitor Container
#pragma mark -


#pragma mark -
#pragma mark Writer object
#pragma mark -

@interface AVCWriterObj : NSObject {
    NSString* fileName;
@public
    AVAssetWriter* writer;
    AVAssetWriterInput* writerInput;
    AVAssetWriterInputPixelBufferAdaptor* pixelAdaptor;
}
@property (nonatomic, copy) NSString* fileName;
@property (nonatomic, retain) AVAssetWriter* writer;
@property (nonatomic, retain) AVAssetWriterInput* writerInput;
@property (nonatomic, retain) AVAssetWriterInputPixelBufferAdaptor *pixelAdaptor;
@end

@implementation AVCWriterObj
@synthesize fileName, writer, writerInput, pixelAdaptor;
- (void)dealloc {
    if(writer && writer.status == AVAssetWriterStatusWriting) [writer finishWriting];
    [SMFileUtil deleteFile:self.fileName];
    self.fileName = nil;
    self.writer = nil;
    self.writerInput = nil;
    self.pixelAdaptor = nil;
}

@end


#pragma mark -
#pragma mark Block Creation
#pragma mark -

//This will only be usefull if we find that the overhead of dispatch
//is causing an issue with inplace blocks.
/*
 AVCWriterCreationBlock CreateWriterBlock() {
 
 AVCWriterCreationBlock block = ^(AVCEncoder* encoder) {
 };
 
 return Block_copy(block);
 }
 */

//##################################################################################################################


#pragma mark -
#pragma mark AVCEncoder Implementation
#pragma mark -

@implementation AVCEncoder
@dynamic averagebps;
@dynamic parameters;
@synthesize maxBitrate;
@synthesize spspps, sps, pps;
@synthesize callback, callbackOnSerialQueue;
@synthesize timeQueue, compressionProperties, videoSettings;
@synthesize writerObj;
@synthesize writerCreationBlock;
//@synthesize monitorObject;
@synthesize encoderBlock;
@synthesize writer_queue;
@synthesize path;
@synthesize isEncoding;
@synthesize error;
@synthesize parser;
@synthesize parserCallback;
@synthesize timeOfBitrateChange;
@synthesize timer;
#pragma mark -

#pragma mark Lifecycle
#pragma mark -/

-(id) init {
    self = [super init];
    if (self) {
		
        self.maxBitrate = 0;
        self.timeQueue = [[NSMutableArray alloc] init];
        self.isEncoding = NO;
        [self createEncoderBlock];
        [self createParserCallback];
        self.path = [SMFileUtil getResourceDirectory:kBaseDirectory];
        [SMFileUtil cleanDirectory:kBaseDirectory];
    }
    return self;
}

- (void)dealloc {
    if (isEncoding) {
        [self stop];
    }
    if (parser) {
        free_parser(parser);
    }
    self.writerObj = nil;
    //TODO: This causes an error when restarting the stream repediatly. Generally if the stream fails a bunch of times.
    //      Check for releases in other places, or the possibility it is not created.
    //      we had a release where we should not have.
    //if (encoderBlock) {
    self.encoderBlock = nil;
    //}
    self.spspps = nil;
	self.sps = nil;
	self.pps = nil;
    self.timeQueue = nil;
    self.compressionProperties = nil;
    self.videoSettings = nil;
    self.writerCreationBlock = nil;
    self.parserCallback = nil;
    self.path = nil;
}

#pragma mark -
#pragma mark Misc properties.
#pragma mark -
/*
- (NSData *)spspps {
    if (parser) {
        return parser->spspps;
    }
    return nil;
}
*/

#pragma mark -
#pragma mark Encoder preperation
#pragma mark -

- (void) setupProperties {
    
    AVCParameters* params = self.parameters;
    self.compressionProperties = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
                                   [NSNumber numberWithInt:params.bps], AVVideoAverageBitRateKey,
                                   [NSNumber numberWithInt:params.keyFrameInterval],AVVideoMaxKeyFrameIntervalKey,
                                   //videoCleanApertureSettings, AVVideoCleanApertureKey,
                                   params.videoProfileLevel, AVVideoProfileLevelKey,
                                   nil ];
    
    self.videoSettings = [[NSMutableDictionary alloc] initWithObjectsAndKeys:AVVideoCodecH264, AVVideoCodecKey,
                           [NSNumber numberWithInt:params.outWidth], AVVideoWidthKey,
                           [NSNumber numberWithInt:params.outHeight], AVVideoHeightKey, 
                           self.compressionProperties, AVVideoCompressionPropertiesKey,
                           nil];
	
	//NSLog(@"Video Settings: %@", self.videoSettings);
	
}


- (BOOL) prepareEncoder {
    //Create AVAssetWriter
    BOOL ret = YES;
    int itemp;
    
    if (self.isEncoding) { 
        NSMutableDictionary *errorDetail = [NSMutableDictionary dictionary];
        [errorDetail setValue:@"Encoder is running. Can not call prepareEncoder while encoding" forKey:NSLocalizedDescriptionKey];
        self.error = [NSError errorWithDomain:@"myDomain" code:100 userInfo:errorDetail];
        return NO; 
    }
    
    if (self.parameters == nil) {
        NSMutableDictionary *errorDetail = [NSMutableDictionary dictionary];
        [errorDetail setValue:@"AVCParameters is nil" forKey:NSLocalizedDescriptionKey];
        self.error = [NSError errorWithDomain:@"myDomain" code:101 userInfo:errorDetail];
        return NO;
    }
    
    [self setupProperties];
    
    //NOTE: The SPS/PPS does not change with regard to the input pixel type
    AVCParameters* params = self.parameters;
    CFDictionaryRef df = CVPixelFormatDescriptionCreateWithPixelFormatType(NULL, kCVPixelFormatType_32BGRA);
    CVPixelBufferRef pb = NULL;
    itemp = CVPixelBufferCreate(NULL, params.outWidth, params.outHeight, kCVPixelFormatType_32BGRA, df, &pb);
	//itemp = CVPixelBufferCreate(NULL, 640, 480, kCVPixelFormatType_32BGRA, df, &pb);
    CFRelease(df);
    if (itemp != kCVReturnSuccess) {
        NSMutableDictionary *errorDetail = [NSMutableDictionary dictionary];
        [errorDetail setValue:@"Error creating pixel buffer. Check Widht and Height" forKey:NSLocalizedDescriptionKey];
        self.error = [NSError errorWithDomain:@"AVCEncoder" code:1 userInfo:errorDetail];
        ret = NO;
    }
    
    if (parser) {
        free_parser(parser);
    }
    
    //TODO: WE need to find a better way to specify the size. This is still too large for an I frame.
    parser = alloc_parser(params.outWidth * params.outHeight);
    init_parser(parser);
    parser->callback = self.parserCallback;
    
    if(![self generateSPSPPS:pb]) {
		NSMutableDictionary *errorDetail = [NSMutableDictionary dictionary];
        [errorDetail setValue:@"Error generating SPS/PPS" forKey:NSLocalizedDescriptionKey];
        self.error = [NSError errorWithDomain:@"AVCEncoder" code:2 userInfo:errorDetail];
        ret = NO;
    }
    
	self.spspps = parser->spspps;
	self.sps = parser->sps;
	self.pps = parser->pps;
	
bail:
	
	CVPixelBufferRelease(pb);
	
    return ret;
}

- (AVCWriterObj*) setupWriterObj {
    
    NSError* err = nil;
    AVCParameters* params = self.parameters;
    //TODO: check error
    AVCWriterObj* wobj = [[AVCWriterObj alloc] init];
    
    CFUUIDRef uid = CFUUIDCreate(NULL);
    NSString* sid = CFBridgingRelease(CFUUIDCreateString(NULL, uid));
    NSString* fileurl = @"file://";
    NSString* file_path = [self.path stringByAppendingFormat:@"/%@.%@",sid,@"mov"];
    fileurl = [fileurl stringByAppendingString:file_path];
    
    //NSLog(@"Setup File: %@", file_path);
    
    CFRelease(uid);

    wobj.fileName = file_path;
    
    NSDictionary* pbp = [NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithInt:params.pixelFormat], kCVPixelBufferPixelFormatTypeKey, nil];
    
    wobj.writer = [[AVAssetWriter alloc] initWithURL:[NSURL URLWithString:fileurl] fileType:AVFileTypeQuickTimeMovie error:&err];
    
    if (err) {
        self.error = err;
        return nil;
    }
    
    //wobj.writer.shouldOptimizeForNetworkUse = NO;
    
    wobj.writerInput = [[AVAssetWriterInput alloc] initWithMediaType:AVMediaTypeVideo outputSettings:self.videoSettings];
    wobj.pixelAdaptor = [[AVAssetWriterInputPixelBufferAdaptor alloc] initWithAssetWriterInput:wobj.writerInput sourcePixelBufferAttributes:pbp];
    
    if( [wobj.writer canAddInput:wobj.writerInput] ) {
        [wobj.writer addInput:wobj.writerInput];
    }
    else {
        //TODO: Handle Error
        NSLog(@"Can not add writer input");
    }
    
    return wobj;
}


//TODO: error handling
- (BOOL) generateSPSPPS:(CVPixelBufferRef) pixelBuffer {
    
    NSError *err = nil;
    BOOL ret = YES;
    AVCParameters* params = self.parameters;
    NSMutableDictionary *errorDetail = [NSMutableDictionary dictionary];
    [errorDetail setValue:@"Error generating SPS/PPS" forKey:NSLocalizedDescriptionKey];
    
    NSString *fileurl = @"file://";
    CFUUIDRef uid = CFUUIDCreate(NULL);
    NSString* sid = CFBridgingRelease(CFUUIDCreateString(NULL, uid));
    NSString *file_path = [self.path stringByAppendingPathComponent:sid];
    fileurl = [fileurl stringByAppendingString:file_path];

    [SMFileUtil deleteFile:file_path];
    
    //NSDictionary* pbp = [NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithInt:params.pixelFormat], kCVPixelBufferPixelFormatTypeKey, nil];
	NSDictionary* pbp = [NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithInt:kCVPixelFormatType_32BGRA], kCVPixelBufferPixelFormatTypeKey, nil];
    
    //TODO: check error
    AVAssetWriter* _writer = [[AVAssetWriter alloc] initWithURL:[NSURL URLWithString:fileurl] fileType:AVFileTypeQuickTimeMovie error:&err];
    
    if (err) {
        self.error = err;
		return NO;
    }
    
    _writer.shouldOptimizeForNetworkUse = NO;
    
    AVAssetWriterInput* _writerInput = [[AVAssetWriterInput alloc] initWithMediaType:AVMediaTypeVideo outputSettings:self.videoSettings];
	
    AVAssetWriterInputPixelBufferAdaptor* _pixelAdaptor = [[AVAssetWriterInputPixelBufferAdaptor alloc] initWithAssetWriterInput:_writerInput sourcePixelBufferAttributes:pbp];
    
    [_writer addInput:_writerInput];
    
    if(![_writer startWriting]) {
		self.error = [NSError errorWithDomain:@"AVCEncoder" code:102 userInfo:errorDetail];
        ret = NO;
    }
    
    [_writer startSessionAtSourceTime:CMTimeMake(0, 15)];
    
    if(_writer.status != AVAssetWriterStatusWriting) {
		self.error = [NSError errorWithDomain:@"AVCEncoder" code:103 userInfo:errorDetail];
        ret = NO;
    }
    
    [_pixelAdaptor appendPixelBuffer:pixelBuffer withPresentationTime:CMTimeMake(42, 1)];
    
    if(![_writer finishWriting]) {
		self.error = [NSError errorWithDomain:@"AVCEncoder" code:104 userInfo:errorDetail];
        ret = NO;
    }
    
    if(!parse_sps_pps(file_path, parser)) {
        self.error = [NSError errorWithDomain:@"AVCEncoder" code:105 userInfo:errorDetail];
        ret = NO;
    }
    
    
    [SMFileUtil deleteFile:file_path];

    return ret;
}

#pragma mark -
#pragma mark Encoder Control
#pragma mark -

- (void) createParserCallback {
    
    AVCFrameCallback cb = ^(const void* frame, uint32_t size, uint8_t type) {
        //NSLog(@"Received frame. Size: %u", size);
		if (self->callback) {
            CMTime ts = {0};
            if (type == 5 || type == 1) {
                @synchronized(self->timeQueue) {
                    AVCTimeObj* to = [self.timeQueue objectAtIndex:0];
                    ts = to->time_stamp;
                    [self.timeQueue removeObjectAtIndex:0];
                }
                self->callback(frame, size, ts);
            }
            else {
                AVCTimeObj* to = [self.timeQueue objectAtIndex:0];
                ts = to->time_stamp;
                self->callback(frame, size, ts);
            }
        }

    };
    self.parserCallback = cb;
}

- (void) createEncoderBlock {
    
    AVCEncoderBlock block = ^(CMSampleBufferRef sample){
        CMTime startTime;
        switch (self.writerObj->writer.status) {
            case AVAssetWriterStatusUnknown:
                
                startTime = CMSampleBufferGetPresentationTimeStamp(sample);
                
                [self.writerObj->writer startWriting];
                [self.writerObj->writer startSessionAtSourceTime:startTime];
                
                
                if(! start_parser(parser, self.writerObj.fileName) ) {
                    //TODO: Handle Error
                }
                if (self.writerObj->writer.status != AVAssetWriterStatusWriting) {
                    break ;
                }            
                
            case AVAssetWriterStatusWriting:
                if( !writerObj->writerInput.readyForMoreMediaData) { 
                    break;
                }
                //NSLog(@"Encoding Frame");
                startTime = CMSampleBufferGetPresentationTimeStamp(sample);
                //TODO: Use a pool of CMTimeObj objects.
                @synchronized(self->timeQueue) {
                    [self->timeQueue addObject:[[AVCTimeObj alloc] initWithTime:startTime]];
                }
                
                //@try { 
                if( ![writerObj->writerInput appendSampleBuffer:sample] ) {
                    //We are not doing anything so why check
                    //TODO: We really need to do something this time steve.
                }
                //            }
                //            @catch (NSException *e) {
                //                NSLog(@"Video Exception Exception: %@", [e reason]);
                //                //The same goes for here too.
                //            }
                
                break;
            case AVAssetWriterStatusCompleted:
                return;
            case AVAssetWriterStatusFailed: 
                //NSLog(@"Writer Failed");
                //NSLog(@"Reason: %@", [writerObj->writer.error localizedDescription]);
                //TODO: WTF. We just like random problems dont we
                return;
            case AVAssetWriterStatusCancelled:
                break;
            default:
                break;
        }
    };    
    
    self.encoderBlock = block;
}

- (void) startWithCallbackQueue:(dispatch_queue_t) queue {}

- (BOOL) start {
    if (isEncoding) { return NO; }
    self.writer_queue = dispatch_queue_create("com.stevemcfarlin.avcencoder", 0);
    if (self.writer_queue == NULL) {
        NSMutableDictionary *errorDetail = [NSMutableDictionary dictionary];
        [errorDetail setValue:@"Error preparing encoder" forKey:NSLocalizedDescriptionKey];
        self.error = [NSError errorWithDomain:@"AVCEncoder" code:1 userInfo:errorDetail];
        return NO;
    }
    init_parser(parser);
    parser->pps = self.pps;
	parser->sps = self.sps;
    
    dispatch_sync(self.writer_queue, ^{
        //[self teardownWriter];
        [self setupProperties];
        self.writerObj = [self setupWriterObj];
    });
    
	//Setup a monitor. Changing the bitrate to itself will cause the old file to be erased. 
    //Basically to prevent the disk from filling up
    #define TIMER_DELTA 1ull * 60ull * NSEC_PER_SEC
	//#define TIMER_DELTA 1ull * 5ull * NSEC_PER_SEC
	#define BRC_MAX_DELTA_SEC 2 * 60
    self.timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER,0, 0, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0));
    dispatch_source_set_timer(timer, dispatch_time(DISPATCH_TIME_NOW, TIMER_DELTA), TIMER_DELTA, 10000);
    dispatch_source_set_event_handler(timer, ^{ 
        double delta = CACurrentMediaTime() - timeOfBitrateChange;
		if (delta > BRC_MAX_DELTA_SEC) {
            [self setAveragebps:self.parameters.bps];
        }
    });
    timeOfBitrateChange = CACurrentMediaTime();
    dispatch_resume(self.timer);
	
    self.isEncoding = YES;
    
    return YES;
}

- (void) stop {
    if (!isEncoding) { return; }
    
    dispatch_source_cancel(timer);

    dispatch_sync(self.writer_queue, ^{
        self.isEncoding = NO;
        self.writerObj = nil;
    });
    stop_parser(parser);
    [self.timeQueue removeAllObjects];
}

- (AVCParameters*) parameters {
	return parameters;
}

- (void) setParameters:(AVCParameters *)_parameters {
	
	if(parameters != _parameters) {
        parameters = _parameters;
    }
    
	if(maxBitrate > 0) {
		self.parameters.bps = (parameters.bps < maxBitrate) ? parameters.bps : maxBitrate;
	}
    
    if (isEncoding) {
        [self stop];
        [self prepareEncoder];
        [self start];
    }
}

- (unsigned) averagebps {
    return self.parameters.bps;
}

- (void) setAveragebps:(unsigned) abps {
	if (!isEncoding) { return; }
	
	if(abps < 100) return;
	
    //WNG: The timer relies on being able to set the same bitrate.
	if(maxBitrate > 0) {
		if(abps >= maxBitrate) {
			if (self.parameters.bps == maxBitrate) {return;}
			self.parameters.bps = maxBitrate;
		}
		else {
			self.parameters.bps = abps;
		}
	}
	else {
		self.parameters.bps = abps;
	}
	
    [self stop];
    [self prepareEncoder];
    [self start];
	timeOfBitrateChange = CACurrentMediaTime();
}

#pragma mark -
#pragma mark Encoding
#pragma mark -

- (void) encode:(CMSampleBufferRef) sample {
    if (!isEncoding) { return ; }
    
    dispatch_sync(writer_queue, ^{
        encoderBlock(sample);
    });
}

- (void) encode:(CVPixelBufferRef) buffer withPresentationTime:(CMTime) pts {
    if (!isEncoding) { return ; }
}


@end
