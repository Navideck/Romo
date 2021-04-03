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

#include "bs.h"
#include "h264_stream.h"
#include "h264_sei.h"

#include <stdlib.h> // malloc
#include <string.h> // memset

static const uint8_t sei_num_clock_ts_table[9]={
    1,  1,  1,  2,  2,  3,  3,  2,  3
};


sei_t* sei_new()
{
    sei_t* s = (sei_t*)malloc(sizeof(sei_t));
    memset(s, 0, sizeof(sei_t));
    s->payload = NULL;
    s->sei_type_struct = NULL;
    return s;
}

void sei_free(sei_t* s)
{
    if (s->payload != NULL) { free(s->payload); }
    if (s->sei_type_struct != NULL) { free(s->sei_type_struct);}
    free(s);
}

// D.1.1 SEI buffering period syntax
static void read_sei_type_0(h264_stream_t* h, sei_t* s) {
    int sched_sel_idx;
    bs_t bs;
    sps_t *sps = h->sps;
    
    sei_type_0 *bp = malloc(sizeof(sei_type_0));
    
    bs_init(&bs, s->payload, s->payloadSize);
    
    bp->seq_parameter_set_id = bs_read_ue(&bs);
    
    if(sps->vui.nal_hrd_parameters_present_flag) {
        for (sched_sel_idx = 0; sched_sel_idx < sps->hrd.cpb_cnt_minus1 + 1; sched_sel_idx++) {
            bp->initial_cbp_removal_delay[sched_sel_idx] = bs_read_u(&bs, sps->hrd.initial_cpb_removal_delay_length_minus1 + 1);
            bp->initial_cbp_removal_delay_offset[sched_sel_idx] = bs_read_u(&bs, sps->hrd.initial_cpb_removal_delay_length_minus1 + 1);
        }
    }
    if (sps->vui.vcl_hrd_parameters_present_flag) {
        for (sched_sel_idx = 0; sched_sel_idx < sps->hrd.cpb_cnt_minus1 + 1; sched_sel_idx++) {
            bp->initial_cbp_removal_delay[sched_sel_idx] = bs_read_u(&bs, sps->hrd.initial_cpb_removal_delay_length_minus1 + 1);
            bp->initial_cbp_removal_delay_offset[sched_sel_idx] = bs_read_u(&bs, sps->hrd.initial_cpb_removal_delay_length_minus1 + 1);
        }
    }
    s->sei_type_struct = bp;
}

//This function assumes the values are set elsewhere.
static void write_sei_type_0(h264_stream_t* h, sei_t* s, bs_t* b) {
    int sched_sel_idx;
    sps_t *sps = h->sps;
    
    sei_type_0 *bp = s->sei_type_struct;
    
    if(sps->vui.nal_hrd_parameters_present_flag) {
        for (sched_sel_idx = 0; sched_sel_idx < sps->hrd.cpb_cnt_minus1 + 1; sched_sel_idx++) {
            bs_write_u(b, bp->initial_cbp_removal_delay[sched_sel_idx], h->sps->hrd.initial_cpb_removal_delay_length_minus1 + 1);
            bs_write_u(b, bp->initial_cbp_removal_delay_offset[sched_sel_idx], sps->hrd.initial_cpb_removal_delay_length_minus1 + 1);
        }
    }
    if (sps->vui.vcl_hrd_parameters_present_flag) {
        for (sched_sel_idx = 0; sched_sel_idx < sps->hrd.cpb_cnt_minus1 + 1; sched_sel_idx++) {
            bs_write_u(b, bp->initial_cbp_removal_delay[sched_sel_idx], h->sps->hrd.initial_cpb_removal_delay_length_minus1 + 1);
            bs_write_u(b, bp->initial_cbp_removal_delay_offset[sched_sel_idx], sps->hrd.initial_cpb_removal_delay_length_minus1 + 1);
        }
    }
}


// D.1.2 SEI picture timing syntax
static void read_sei_type_1(h264_stream_t* h, sei_t* s) {
    bs_t bs;
    sps_t *sps = h->sps;
    uint32_t pict_struct, num_clock_ticks;
    bs_init(&bs, s->payload, s->payloadSize);
    sei_type_1 *pt_struct = NULL;
    
    if(sps->vui.nal_hrd_parameters_present_flag || sps->vui.vcl_hrd_parameters_present_flag) {
        pt_struct = calloc(sizeof(sei_type_1), 1);
        pt_struct->cpb_removal_delay = bs_read_u(&bs, sps->hrd.cpb_removal_delay_length_minus1 + 1);
        pt_struct->dpb_output_delay = bs_read_u(&bs, sps->hrd.dpb_output_delay_length_minus1 + 1);
    }
    
    if (sps->vui.pic_struct_present_flag) {
        pict_struct = bs_read_u(&bs, 4);
        if (pict_struct > SEI_PIC_STRUCT_FRAME_TRIPLING) {
            return;
        }
        num_clock_ticks = sei_num_clock_ts_table[pict_struct];
        pt_struct->timings = calloc(sizeof(sei_type_1_pic_timing) * num_clock_ticks, 1);
        pt_struct->NumClockTS = num_clock_ticks;
        pt_struct->pic_struct = pict_struct;
        
        for (int i = 0; i < num_clock_ticks; i++) {
            sei_type_1_pic_timing *pt = &pt_struct->timings[i];
            pt->clock_timestamp_flag = bs_read_u(&bs, 1);
            if (pt->clock_timestamp_flag) {
                pt->ct_type = bs_read_u(&bs, 2);
                pt->nuit_field_based_flag = bs_read_u(&bs, 1);
                pt->counting_type = bs_read_u(&bs, 5);
                pt->full_timestamp_flag = bs_read_u(&bs, 1);
                pt->discontinuity_flag = bs_read_u(&bs, 1);
                pt->cnt_dropped_flag = bs_read_u(&bs, 1);
                pt->n_frames = bs_read_u(&bs, 8);
                if (pt->full_timestamp_flag) {
                    pt->seconds_value = bs_read_u(&bs, 6);
                    pt->minutes_value = bs_read_u(&bs, 6);
                    pt->hours_value = bs_read_u(&bs, 5);
                }else {
                    pt->seconds_flag = bs_read_u(&bs, 1);
                    if (pt->seconds_flag) {
                        pt->seconds_value = bs_read_u(&bs, 6);
                        pt->minutes_flag = bs_read_u(&bs, 1);
                        if(pt->minutes_flag) {
                            pt->minutes_value = bs_read_u(&bs, 6);
                            pt->hours_flag = bs_read_u(&bs, 1);
                            if (pt->hours_flag) {
                                pt->hours_value = bs_read_u(&bs, 5);
                            }
                        }
                    }
                }
                if (sps->hrd.time_offset_length > 0) {
                    pt->time_offset = bs_read_u(&bs, sps->hrd.time_offset_length);
                }   
            }
        }
    }
    s->sei_type_struct = pt_struct;
}

static void write_sei_type_1(h264_stream_t* h, sei_t* s, bs_t* b) {
    bs_t bs;
    sps_t *sps = h->sps;

    sei_type_1 *pt_struct = s->sei_type_struct;
    
    if(sps->vui.nal_hrd_parameters_present_flag || sps->vui.vcl_hrd_parameters_present_flag) {
        bs_write_u(b, pt_struct->cpb_removal_delay, sps->hrd.cpb_removal_delay_length_minus1 + 1);
        bs_write_u(b, pt_struct->dpb_output_delay, sps->hrd.cpb_removal_delay_length_minus1 + 1);        
    }
    
    if (sps->vui.pic_struct_present_flag) {
        if (pt_struct->pic_struct > SEI_PIC_STRUCT_FRAME_TRIPLING) {
            return;
        }
        
        bs_write_u(&bs, pt_struct->pic_struct, 4);
        
        for (int i = 0; i < pt_struct->NumClockTS; i++) {
            sei_type_1_pic_timing *pt = &pt_struct->timings[i];
            bs_write_u(&bs, pt->clock_timestamp_flag, 1);
 
            if (pt->clock_timestamp_flag) {
                bs_write_u(&bs, pt->ct_type, 2);
                bs_write_u(&bs, pt->nuit_field_based_flag, 1);
                bs_write_u(&bs, pt->counting_type, 5);
                bs_write_u(&bs, pt->full_timestamp_flag, 1);
                bs_write_u(&bs, pt->discontinuity_flag, 1);
                bs_write_u(&bs, pt->cnt_dropped_flag, 1);
                bs_write_u(&bs, pt->n_frames, 8);

                if (pt->full_timestamp_flag) {
                    bs_write_u(&bs, pt->seconds_value, 6);
                    bs_write_u(&bs, pt->minutes_value, 6);
                    bs_write_u(&bs, pt->hours_flag, 5);
                }else {
                    bs_write_u(&bs, pt->seconds_flag, 1);
                    if (pt->seconds_flag) {
                        bs_write_u(&bs, pt->seconds_value, 6);
                        bs_write_u(&bs, pt->minutes_flag, 1);
                        
                        if(pt->minutes_flag) {
                            bs_write_u(&bs, pt->minutes_value, 6);
                            bs_write_u(&bs, pt->hours_flag, 1);
                            
                            if (pt->hours_flag) {
                                bs_write_u(&bs, pt->hours_value, 5);
                            }
                        }
                    }
                }
                if (sps->hrd.time_offset_length > 0) {
                    bs_write_u(&bs, pt->time_offset, sps->hrd.time_offset_length);
                }   
            }
        }
    }
    s->sei_type_struct = pt_struct;
}


// D.1 SEI payload syntax
void read_sei_payload( h264_stream_t* h, bs_t* b, int payloadType, int payloadSize)
{
    sei_t* s = h->sei;

    s->payload = malloc(payloadSize);

    int i;
    for( i = 0; i < payloadSize; i++ )
    {
        s->payload[i] = bs_read_u(b, 8);
    }
    
    switch (payloadType) {
        case SEI_TYPE_BUFFERING_PERIOD:
            read_sei_type_0(h, s);
            break;
        case SEI_TYPE_PIC_TIMING:
            read_sei_type_1(h, s);
            break;
        default:
            //Not implemented
            break;
    }
    
}


// D.1 SEI payload syntax
void write_sei_payload( h264_stream_t* h, bs_t* b, int payloadType, int payloadSize)
{
    sei_t* s = h->sei;

    int i;
    
    switch (payloadType) {
        case SEI_TYPE_BUFFERING_PERIOD:
            write_sei_type_0(h, s, b);
            break;
        case SEI_TYPE_PIC_TIMING:
            //payloadSize = sizeof(sei_type_1)
            write_sei_type_1(h, s, b);
            break;
        default:
            for( i = 0; i < payloadSize; i++ )
            {
                bs_write_u(b, 8, s->payload[i]);
            }
            //Not implemented
            break;
    }
    
}

