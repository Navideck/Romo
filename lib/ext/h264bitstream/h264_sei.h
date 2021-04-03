/* 
 * h264bitstream - a library for reading and writing H.264 video
 * Copyright (C) 2005-2007 Auroras Entertainment, LLC
 * 
 * Written by Alex Izvorski <aizvorski@gmail.com>
 * Addtions by Steve McFarlin <steve@tokbox.com>
 * 
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 * 
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 * 
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
 */

#include <stdint.h>

#ifndef _H264_SEI_H
#define _H264_SEI_H        1

#include "bs.h"

#ifdef __cplusplus
extern "C" {
#endif

//D.1 SEI payload syntax

#define SEI_TYPE_BUFFERING_PERIOD 0
#define SEI_TYPE_PIC_TIMING       1
#define SEI_TYPE_PAN_SCAN_RECT    2
#define SEI_TYPE_FILLER_PAYLOAD   3
#define SEI_TYPE_USER_DATA_REGISTERED_ITU_T_T35  4
#define SEI_TYPE_USER_DATA_UNREGISTERED  5
#define SEI_TYPE_RECOVERY_POINT   6
#define SEI_TYPE_DEC_REF_PIC_MARKING_REPETITION 7
#define SEI_TYPE_SPARE_PIC        8
#define SEI_TYPE_SCENE_INFO       9
#define SEI_TYPE_SUB_SEQ_INFO    10
#define SEI_TYPE_SUB_SEQ_LAYER_CHARACTERISTICS  11
#define SEI_TYPE_SUB_SEQ_CHARACTERISTICS  12
#define SEI_TYPE_FULL_FRAME_FREEZE  13
#define SEI_TYPE_FULL_FRAME_FREEZE_RELEASE  14
#define SEI_TYPE_FULL_FRAME_SNAPSHOT  15
#define SEI_TYPE_PROGRESSIVE_REFINEMENT_SEGMENT_START  16
#define SEI_TYPE_PROGRESSIVE_REFINEMENT_SEGMENT_END  17
#define SEI_TYPE_MOTION_CONSTRAINED_SLICE_GROUP_SET  18
#define SEI_TYPE_FILM_GRAIN_CHARACTERISTICS  19
#define SEI_TYPE_DEBLOCKING_FILTER_DISPLAY_PREFERENCE  20
#define SEI_TYPE_STEREO_VIDEO_INFO  21

typedef enum {
    SEI_PIC_STRUCT_FRAME             = 0, ///<  0: %frame
    SEI_PIC_STRUCT_TOP_FIELD         = 1, ///<  1: top field
    SEI_PIC_STRUCT_BOTTOM_FIELD      = 2, ///<  2: bottom field
    SEI_PIC_STRUCT_TOP_BOTTOM        = 3, ///<  3: top field, bottom field, in that order
    SEI_PIC_STRUCT_BOTTOM_TOP        = 4, ///<  4: bottom field, top field, in that order
    SEI_PIC_STRUCT_TOP_BOTTOM_TOP    = 5, ///<  5: top field, bottom field, top field repeated, in that order
    SEI_PIC_STRUCT_BOTTOM_TOP_BOTTOM = 6, ///<  6: bottom field, top field, bottom field repeated, in that order
    SEI_PIC_STRUCT_FRAME_DOUBLING    = 7, ///<  7: %frame doubling
    SEI_PIC_STRUCT_FRAME_TRIPLING    = 8  ///<  8: %frame tripling
} SEI_PicStructType;
    
/*
 */
    
//buffering period (D.1.1)
typedef struct
{
    uint8_t seq_parameter_set_id;
    uint32_t initial_cbp_removal_delay[32]; 
    uint32_t initial_cbp_removal_delay_offset[32];
    
}sei_type_0;

//picture timing (D.1.2)
typedef struct
{
    uint8_t clock_timestamp_flag;
    uint8_t ct_type;
    uint8_t nuit_field_based_flag;
    uint8_t counting_type;
    uint8_t full_timestamp_flag;
    uint8_t discontinuity_flag;
    uint8_t cnt_dropped_flag;
    uint8_t n_frames;
    uint8_t seconds_value;
    uint8_t minutes_value;
    uint8_t hours_value;
    uint8_t seconds_flag;
    uint8_t minutes_flag;
    uint8_t hours_flag;
    uint8_t time_offset;
} sei_type_1_pic_timing;
    
typedef struct
{
    uint32_t cpb_removal_delay;
    uint32_t dpb_output_delay;
    SEI_PicStructType pic_struct;
    uint32_t NumClockTS;
    sei_type_1_pic_timing *timings;
}sei_type_1;

typedef struct
{
    int payloadType;
    int payloadSize;
    uint8_t* payload;
    void* sei_type_struct;
    
} sei_t;

sei_t* sei_new();
void sei_free(sei_t* s);


#ifdef __cplusplus
}
#endif

#endif
