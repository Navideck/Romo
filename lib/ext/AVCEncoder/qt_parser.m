//
//  spspps_parser.m
//  AVCEncoder
//
//  Created by Steve McFarlin on 5/5/11.
//  Copyright 2011 Steve McFarlin. All rights reserved.
//
/*
 TODO:  We need to go through the mdat parser and frame parser throughly to make
 sure we check for EOF.
 */


#import "qt_parser.h"
#import "h264_stream.h"

#include <stdio.h>
#include <errno.h>
#include <unistd.h>
#include <fcntl.h>
#include <string.h>

#define ATOM_TYPE_COUNT 4
#define ATOM_SIZE_COUNT 4
static uint32_t nal_start = 0x00000001;

OSType containerAtoms[] = {
    'moov', 'trak', 'udta', 'tref', 'imap',
    'mdia', 'minf', 'stbl', 'edts', 'mdra',
    'rmra', 'imag', 'vnrp', 'dinf', 'tapt'
};
#define ATOM_CONTAINERS_COUNT 15


OSType stsd = 'stsd';
OSType mdat = 'mdat';
OSType avcC = 'avcC';
typedef struct QTAtom {
uint32_t size;
OSType type;
} QTAtom;
//Forwards
//BOOL parse_sps_pps_recursive(FILE *file, long offset, long len, NSData** sps, NSData **pps);
BOOL parse_to_mdat(AVCParserStruct* parser);
BOOL parse_avc(AVCParserStruct* parser);
static void generate_aud(AVCParserStruct *parser);

AVCParserStruct* alloc_parser(uint32_t bufferSize) {
	
    AVCParserStruct *parser = malloc(sizeof(AVCParserStruct));
    if(parser == NULL) return NULL;
    parser->parse_buffer_size = bufferSize;
    parser->parse_buffer = malloc(sizeof(char) * bufferSize);
    if(parser->parse_buffer == NULL) return NULL;
    parser->reader_queue = dispatch_queue_create("com.stevemcfarlin.gcdqueue.frame_packager", NULL);
	
    parser->avcStream = h264_new();
    
    generate_aud(parser);
    
    return parser;
}

void free_parser(AVCParserStruct* parser) {
    if(parser->parsing)
        stop_parser(parser);
    free(parser->parse_buffer);
    free(parser);
    
    h264_free(parser->avcStream);
}

void init_parser(AVCParserStruct* parser) {
    parser->parsing = NO;
    parser->file = NULL;
    parser->found_mdat = NO;
    parser->frame_size = 0;
    parser->bytes_read = 0;
    parser->frame_count = 0;
    parser->spspps = nil;
	parser->sps = nil;
	parser->pps = nil;
    parser->parser_function = parse_to_mdat;
}

BOOL start_parser(AVCParserStruct* parser, NSString* fileName) {
    const char *fn = [fileName cStringUsingEncoding:NSASCIIStringEncoding];
    const char* mode = "rb";
	
    //NSLog(@"Startin parser with file: %@", fileName);
    FILE *file = fopen(fn, mode);
    if (file == NULL) {
        //NSLog(@"File Open Failed");
        return NO;
    }
    
    parser->file = file;
    parser->source_queue = dispatch_source_create(DISPATCH_SOURCE_TYPE_READ, parser->file->_file, 0, parser->reader_queue);
    parser->parsing = YES;
    
	//parser->callback([parser->sps bytes], [parser->sps length]);
	//parser->callback([parser->pps bytes], [parser->pps length]);
	
    __block AVCParserStruct* p = parser;
    dispatch_source_set_event_handler(p->source_queue, ^{
        //NSLog(@"Dispatch Read");
        
        //dispatch_async(parser->reader_queue, ^{
		//            struct flock fl;
		//            fl.l_type = F_RDLCK;			/*type of lock*/
		//            fl.l_whence = SEEK_SET;
		//            fl.l_start = parser->bytes_read;				/*offset in the file to start the lock at*/
		//            fl.l_len = 16000;
		//            
		//            if(fcntl(fileno(parser->file), F_SETLKW, &fl)==-1)
		//            {
		//               //NSLog(@"Failed to get lock");
		//            }
		//            else
		//            {
		//               //NSLog(@"File Lock successful");
		//                
		while( p->parsing && p->parser_function(p) ) {}
		//                
		//                fl.l_type = F_UNLCK;
		//                if(fcntl(fileno(parser->file), F_SETLK, &fl) == -1)
		//                {
		//                }
		//            }
		
		
        //});
        
        //while( p->parser_function(p) ) {}
        //NSLog(@"Exit Dispatch Read");
    });
    
    dispatch_resume(parser->source_queue);
    return YES;
}

void stop_parser(AVCParserStruct* parser) {
    if(!parser->parsing) return;
    //Dispatch in queue to prevent cancelation while in read source block
    dispatch_sync(parser->reader_queue, ^{
        parser->parsing = NO;
        dispatch_source_cancel(parser->source_queue);
    });
    fclose(parser->file);
}

#pragma mark -
#pragma NAL generation
#pragma mark -

static void generate_aud(AVCParserStruct *parser) {
    uint8_t len;
    uint8_t buff[64];
    nal_t *nal = parser->avcStream->nal;
    nal->forbidden_zero_bit = 0;
    nal->nal_ref_idc = 0;
    nal->nal_unit_type = 9;
    
    buff[0] = 0; buff[1] = 0; buff[2] = 0; buff[3] = 1;
    //Generate AUD for I frame only 7.4.2.4
    parser->avcStream->aud->primary_pic_type = 0;
    
    len = write_nal_unit(parser->avcStream, &buff[4], 64);
    
    parser->aud_i = [[NSData alloc] initWithBytes:buff length:len + 4];
    
    nal->nal_unit_type = 9;
    
    parser->avcStream->aud->primary_pic_type = 1;
    
    len = write_nal_unit(parser->avcStream, &buff[4], 64);
    
    parser->aud_ip = [[NSData alloc] initWithBytes:buff length:len + 4];
    
}

#pragma mark -
#pragma Parsing code
#pragma mark -

void parse_atom(QTAtom *atom, unsigned int size, unsigned int type) {
    atom->size = CFSwapInt32BigToHost(size);
    atom->type = (OSType) CFSwapInt32BigToHost(type);
}

void dump_atom(QTAtom *atom) {
    //OSType type = (OSType) CFSwapInt32BigToHost(atom->type);
    //printf("Type: %.4s Size: %u - \n", (char*) &type, atom->size);
}

BOOL check_stsd(OSType atom) {
    return (atom == stsd) ? YES : NO;
}

BOOL check_mdat(OSType atom) {
    return (atom == mdat) ? YES : NO;
}

BOOL is_container_atom(OSType atom) {
    for(int i = 0; i < ATOM_CONTAINERS_COUNT; i++) {
        //printf("%.4s == %.4s \n", (char*) &atom, (char*) &containerAtoms[i]);
        if(atom == containerAtoms[i])
            return YES;
    }
    return NO;
}

/**
 Parses the stsd atom for the SPS/PPS NALs. This function assumes the
 file only has AVC media in it.
 */
void parse_stsd(FILE *file, unsigned int size, AVCParserStruct* parser) {
    unsigned int    uint;
    unsigned short  ushort;
    char    ubyte;
    char    dump_buff[8];
    
    //TODO: Considate all this stuff into a single read.
    
    //we have already read out the size and type.
    
    //Read out version
    fread(&ubyte, sizeof(unsigned char), 1, file);
    //printf("Version %u\n", ubyte);
    
    uint = 0;
    fread(&uint, sizeof(unsigned char), 3, file);
    //printf("Flags %x\n", CFSwapInt32BigToHost(uint));
    
    uint = 0;
    fread(&uint, sizeof(unsigned int), 1, file);
    //printf("Number of entries %u\n", CFSwapInt32BigToHost(uint));
    
    uint = 0;
    fread(&uint, sizeof(unsigned int), 1, file);
    //printf("Size %u\n", CFSwapInt32BigToHost(uint));
    
    uint = 0;
    fread(&uint, sizeof(unsigned int), 1, file);
    //printf("Format %.4s\n", (char*) &uint);
    
    //read out reserved
    fread(dump_buff, sizeof(char), 6, file);
	//    fread(&uint, sizeof(unsigned char), 4, file);
	//    fread(&uint, sizeof(unsigned char), 2, file);
    
    ushort = 0;
    fread(&ushort, sizeof(unsigned short), 1, file);
    //printf("Data Reference Index %u\n", CFSwapInt16BigToHost(ushort));
    
    uint = 0;
    fread(&ushort, sizeof(unsigned short), 1, file);
    //printf("PRedefined %u\n", CFSwapInt32BigToHost(ushort));
    
    uint = 0;
    fread(&ushort, sizeof(unsigned short), 1, file);
    //printf("Reserved %u\n", CFSwapInt32BigToHost(ushort));
    
    uint = 0;
    fread(&uint, sizeof(unsigned int), 1, file);
    //printf("Predefined_1 %u\n", CFSwapInt32BigToHost(uint));
    
    uint = 0;
    fread(&uint, sizeof(unsigned int), 1, file);
    //printf("Predefined_2 %u\n", CFSwapInt32BigToHost(uint));
    
    uint = 0;
    fread(&uint, sizeof(unsigned int), 1, file);
    //printf("Predefined_3 %u\n", CFSwapInt32BigToHost(uint));
    
    uint = 0;
    fread(&ushort, sizeof(unsigned short), 1, file);
    //printf("width %u\n", CFSwapInt16BigToHost(ushort));
    
    uint = 0;
    fread(&ushort, sizeof(unsigned short), 1, file);
    //printf("Height %u\n", CFSwapInt16BigToHost(ushort));
    
    uint = 0;
    fread(&ushort, sizeof(unsigned int), 1, file);
    //printf("h rez %u\n", CFSwapInt16BigToHost(ushort));
    
    uint = 0;
    fread(&ushort, sizeof(unsigned short), 1, file);
    //printf("v rez %u\n", CFSwapInt16BigToHost(ushort));
    
    //read out reserved
    fread(dump_buff, sizeof(unsigned char), 4, file);
    //fread(&uint, sizeof(unsigned char), 2, file);
    
    uint = 0;
    fread(&uint, sizeof(unsigned int), 1, file);
    //printf("frame count %u\n", CFSwapInt32BigToHost(uint));
    
    fread(&uint, sizeof(unsigned char), 1, file);
    
    char name[31];
    fread(&name, sizeof(char), 31, file);
    //printf("Compressor name %.6s\n", name);
    
    uint = 0;
    fread(&ushort, sizeof(unsigned short), 1, file);
    //printf("Depth %u\n", CFSwapInt16BigToHost(ushort));
    
    uint = 0;
    fread(&ushort, sizeof(unsigned short), 1, file);
    //printf("Predefined %u\n", CFSwapInt16BigToHost(ushort));
    
    //Extra stuff RGB data etc. See ffmpeg libavformat/mov.c
    //Always 8 bytes
    fread(dump_buff, sizeof(char), 8, file);
    
    //See ISO-14496-15 5.2.4.1.1 for parsing of PPS/SPS
    
    //Dump decoder configuration record header
    fread(dump_buff, sizeof(char), 6, file);
    
    //We are now at SPS size
    uint32_t nal_nbo = CFSwapInt32HostToBig(nal_start);
    fread(&ushort, sizeof(unsigned short), 1, file);
    unsigned short sps_size = CFSwapInt16BigToHost(ushort);
    
    //read sps
    uint8_t sps_buff[256];
    fread(sps_buff, sizeof(char), sps_size, file);
    
    //Rewrite the SPS to add VUI/HRD parameters for SEI message support.
    //See ISO.14496-10 E.1, D.1.1 and D.1.2
    
    read_nal_unit(parser->avcStream, (uint8_t*)sps_buff, sps_size);
    
    //debug_nal(parser->h264stream, parser->h264stream->nal);
    
    sps_t *sps = parser->avcStream->sps;
    
    sps->vui_parameters_present_flag = 1;
    sps->vui.aspect_ratio_info_present_flag = 1;
    sps->vui.sar_height = 0;
    sps->vui.sar_width = 0;
    sps->vui.video_signal_type_present_flag = 1;
    sps->vui.video_format = 2;
    sps->vui.timing_info_present_flag = 0;
    sps->vui.num_units_in_tick = 642857;
    sps->vui.time_scale = 18000000;
    sps->vui.fixed_frame_rate_flag = 0;
    sps->vui.nal_hrd_parameters_present_flag = 1;
    sps->vui.vcl_hrd_parameters_present_flag = 1;
    sps->vui.low_delay_hrd_flag = 1;
    sps->vui.pic_struct_present_flag = 1;
    sps->vui.bitstream_restriction_flag = 1;
    sps->vui.motion_vectors_over_pic_boundaries_flag = 1;
    sps->vui.max_bytes_per_pic_denom = 2;
    sps->vui.max_bits_per_mb_denom = 1;
    sps->vui.log2_max_mv_length_horizontal = 8;
    sps->vui.log2_max_mv_length_vertical = 8;
    sps->vui.num_reorder_frames = 0;
    sps->vui.max_dec_frame_buffering = 1;
    
    sps->hrd.cpb_cnt_minus1 = 0;
    sps->hrd.bit_rate_scale = 0;
    sps->hrd.cpb_size_scale = 0;
    sps->hrd.initial_cpb_removal_delay_length_minus1 = 31;
    sps->hrd.cpb_removal_delay_length_minus1 = 17;
    sps->hrd.dpb_output_delay_length_minus1 = 17;
    sps->hrd.time_offset_length = 24;
    
    //debug_nal(parser->h264stream, parser->h264stream->nal);
    
    memcpy(sps_buff, &nal_nbo, sizeof(uint32_t));
    sps_size = sizeof(uint32_t);
    sps_size += write_nal_unit(parser->avcStream, &sps_buff[4], 252);
    parser->sps = [[NSData alloc] initWithBytes:sps_buff length:sps_size];
    fread(&ubyte, sizeof(unsigned char), 1, file);
    //printf("PPS Count %u\n", ubyte);
    
    fread(&ushort, sizeof(unsigned short), 1, file);
    unsigned short pps_size = CFSwapInt16BigToHost(ushort);
    
    //read pps
    char pps_buff[pps_size + sizeof(uint32_t)];
    memcpy(pps_buff, &nal_nbo, sizeof(uint32_t));
    fread(pps_buff + sizeof(uint32_t), sizeof(char), pps_size, file);
    pps_size += sizeof(uint32_t);
    
	parser->pps = [[NSData alloc] initWithBytes:pps_buff length:pps_size];
	
    //concat sps and pps
    char sps_pps[sps_size + pps_size + sizeof(uint32_t) * 2];
    memcpy(sps_pps, sps_buff, sps_size);
    memcpy(sps_pps + sps_size, pps_buff, pps_size);
    
    parser->spspps = [[NSData alloc] initWithBytes:sps_pps length:sps_size + pps_size];
    //NSLog(@"SPSPPS Size: %d", [*spspps length]);
    
}

BOOL parse_sps_pps(NSString *filePath, AVCParserStruct* parser) {
    uint32_t size;
    uint32_t type;
    __unused uint32_t read;
    uint32_t offset = 0;
    uint64_t len;
    QTAtom atom;
    
    //NSLog(@"Opening File: %@", filePath);
    FILE *infile = fopen([filePath cStringUsingEncoding:NSASCIIStringEncoding], "rb");
    
    if (infile == NULL) {
        //NSLog(@"File handle is 0");
        return NO;
    }
    
    fseek(infile, 0, SEEK_END);
    len = ftell(infile);
    //NSLog(@"File SIze: %llu", len);
    fseek(infile, 0, SEEK_SET);
	
    while(offset < len) {
        fseek(infile, offset, SEEK_SET);
        read = fread(&size, sizeof(unsigned int), 1, infile);
        read = fread(&type, sizeof(unsigned int), 1, infile);
        
        parse_atom(&atom, size, type);
        dump_atom(&atom);
        
        if( is_container_atom(atom.type) ) {
            offset += sizeof(QTAtom);
            continue;
        }
        else if( check_stsd(atom.type) ){
            //printf("####### STSD ATOM ############\n");
            parse_stsd(infile, atom.size, parser);
            return YES;
        }
        offset += atom.size;
    }
	
    fclose(infile);
    
    return YES;
}

BOOL parse_to_mdat(AVCParserStruct* parser) {
	//BOOL parse_to_mdat(FILE *file, long offset, long len) {
    uint32_t size;
    uint32_t type;
    __unused uint32_t bread;
    uint64_t len;
    uint64_t offset = 0;
	//    BOOL parsed_stsd = NO;
    QTAtom atom;
	
    fseek(parser->file, 0, SEEK_END);
    len = ftell(parser->file);
    fseek(parser->file, 0, SEEK_SET);
    //NSLog(@"File Size: %llu", len);
    if (len < 32) { return NO; }
    
    //printf("\nParsing len: %lu \n", len - offset);
    //while(offset < len && !parsed_stsd) {
    while(offset < len) {
        fseek(parser->file, offset, SEEK_SET);
        bread = fread(&size, sizeof(unsigned int), 1, parser->file);
        bread = fread(&type, sizeof(unsigned int), 1, parser->file);
        
        //bread = read(parser->file->_file, &size, sizeof(unsigned int));
        //bread = read(parser->file->_file, &type, sizeof(unsigned int));
        
        parse_atom(&atom, size, type);
        dump_atom(&atom);
        
        if( is_container_atom(atom.type) ) {
            //parsed_stsd = parse_to_mdat(file, ftell(file), offset + atom.size); //old recursive method.
            offset += sizeof(QTAtom);
            continue;
        }
        else if( check_mdat(atom.type) ){
            //printf("####### MDAT ATOM ############\n");
            //TODO: change parser function pointer.
            parser->found_mdat = YES;
            parser->parser_function = parse_avc;
            return YES;
        }
        offset += atom.size;
    }
    return NO;
}

/**
 */
BOOL parse_avc(AVCParserStruct* parser) {
    //NSLog(@"Parse AVC");
    uint32_t nal_size = 0;
    int32_t bread = 0;
    uint32_t nal_nbo = CFSwapInt32HostToBig(nal_start);
	
    if( (parser->frame_size - parser->bytes_read) == 0) {
        bread = fread(&nal_size, sizeof(uint32_t), 1, parser->file);
        if(bread == 0) {
            clearerr(parser->file);
            return NO;
        }
        parser->frame_size = CFSwapInt32BigToHost(nal_size);
        //NSLog(@"Frame Size: %u", parser->frame_size);
        //Insert Annex B NAL start code.
        memcpy(parser->parse_buffer, &nal_nbo, sizeof(uint32_t));
    }
    
    bread = fread(parser->parse_buffer + parser->bytes_read + 4 , sizeof(char), parser->frame_size - parser->bytes_read, parser->file);
    
    parser->bytes_read += bread;
    //NSLog(@"Bytes Read - %u  Frame Size - %u", bread, parser->frame_size);    
    
    //NSLog(@"Frame Size: %u", parser->frame_size);
    if(parser->bytes_read == parser->frame_size) {
		
        uint8_t nal = parser->parse_buffer[4];
        uint8_t type = (nal & 0x1f);
        
        if (type == 5) {
            parser->callback([parser->aud_i bytes], [parser->aud_i length], 9);
            parser->callback([parser->sps bytes], [parser->sps length], 7);
            parser->callback([parser->pps bytes], [parser->pps length], 8);
        }
        else {
            parser->callback([parser->aud_ip bytes], [parser->aud_i length], 9);
        }
        
		//XXX: The SPS and PPS NALU's are now sent individually
		//        if(parser->frame_count > 0) {
		parser->callback(parser->parse_buffer, parser->frame_size + 4, type);
		//        }
		//        else {
		//            NSMutableData *data = [[NSMutableData alloc] initWithCapacity:[parser->spspps length] + parser->frame_size + 4];
		//            [data appendData:parser->spspps];
		//            [data appendBytes:parser->parse_buffer length:parser->frame_size + 4];
		//            parser->callback(parser->parse_buffer, [data length]);
		//            [data release];
		//        }
        //NSLog(@"Parsed Frame");
        parser->frame_count++;
        parser->bytes_read = 0;
        parser->frame_size = 0;
        clearerr(parser->file); //XXX: Does this one need to be here?
        return YES;
    }    
	
    clearerr(parser->file);
    //NSLog(@"Incomplete frae: %u > %u", parser->frame_size, bread);
    return NO;
}

