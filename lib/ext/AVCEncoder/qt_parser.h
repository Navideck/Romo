//
//  spspps_parser.h
//  AVCEncoder
//
//  Created by Steve McFarlin on 5/5/11.
//  Copyright 2011 Steve McFarlin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "h264_stream.h"
typedef void (^AVCFrameCallback)(const void *frame, uint32_t size, uint8_t type) ;

typedef struct AVCParserStruct {
    BOOL        parsing;
    
    FILE*       file;
    BOOL        found_mdat;
    uint32_t    frame_size;
    uint32_t    bytes_read;
    //uint32_t    bytes_left;
    uint64_t    frame_count;
    uint32_t    parse_buffer_size;
    char*       parse_buffer;
    char*       parse_buffer_idx;
    BOOL        send_sps_pps;
    BOOL (*parser_function)(struct AVCParserStruct*);
    
    //h264bitstream
    h264_stream_t *avcStream;
    
    NSData*     spspps; //Annex B format
    NSData*		sps;
	NSData*		pps;
    NSData*     aud_i;
    NSData*     aud_ip;
    dispatch_queue_t reader_queue;
    dispatch_source_t source_queue;
    
    AVCFrameCallback callback;
    
}AVCParserStruct;


AVCParserStruct* alloc_parser(uint32_t bufferSize);
void free_parser(AVCParserStruct* parser);
void init_parser(AVCParserStruct* parser);
BOOL start_parser(AVCParserStruct* parser, NSString* fileName);
void stop_parser(AVCParserStruct* parser);

//BOOL parse_sps_pps(NSString *filePath, NSData** outSPS, NSData** outPPS);
//BOOL parse_to_mdat(FILE *file, long offset, long len);

/**
 @discussion 
 
 This function expects a full Quicktime file. The file must only contain
 a video track. The way this is typically used is to create a tempororary
 QT file with a single image in it. The image and QT file will be in the
 same format as the file created for parsing. 
 */
BOOL parse_sps_pps(NSString *filePath, AVCParserStruct* parser);

