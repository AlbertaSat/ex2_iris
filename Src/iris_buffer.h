/*
 *Copyright 2020 University of Alberta
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
*/

/**
 * @file iris_buffer.h
 * @author Scott Chu
 * @date 2020-06-29
 */

#ifndef IRIS_BUFFER_H
#define IRIS_BUFFER_H

#include <stdbool.h>
#include "iris_configs.h"

/**************************************************************/
//Packet structure
typedef struct buffer_packet{
        input_feature_t image_metadata;
        double heuristic_value;
        double comp_duration;
        double pred_duration;
        double encode_duration;
        double compressed_bytes;
        double compressed_rate;
        char image_file[128];
        char compressed_file[128];
} buffer_packet_t;

//Buffer structure
typedef struct image_buffer{
        buffer_packet_t * buffer; //Pointer to underlying image buffer
        int size;
        int maxSize;
        int full;
} image_buffer_t;


typedef image_buffer_t* buf_handle_t;

buf_handle_t buffer_init(buffer_packet_t* buffer, int maxSize);

int buffer_full(buf_handle_t buffer);

int buffer_capacity(buf_handle_t buffer);

int buffer_put(buf_handle_t buffer, buffer_packet_t packet);

buffer_packet_t buffer_get(buf_handle_t buffer, int imgnum);

int buffer_size(buf_handle_t buffer);

void buffer_free(buf_handle_t buffer);

#endif
