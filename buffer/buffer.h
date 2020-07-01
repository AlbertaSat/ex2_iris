#ifndef BUFFER_H
#define BUFFER_H

#include <stdbool.h>
#include "configs.h"

/**************************************************************/
typedef struct buffer_packet{
        input_feature_t image_metadata;
        double heuristic_value;
        double pred_duration;
        double encode_duration;
        double compressed_bytes;
        double compressed_rate;
        char image_file[128]; //Make pointer???? Leave for now
} buffer_packet_t;

//Buffer structure
typedef struct image_buffer{
        buffer_packet_t * buffer; //Pointer to underlying image buffer
        int size;
        int maxSize;
        bool full;
} image_buffer_t;

//Typedef the handle as a pointer to the image buffer
typedef image_buffer_t* buf_handle_t;

buf_handle_t buffer_init(buffer_packet_t* buffer, int maxSize);

bool buffer_full(buf_handle_t buffer);

int buffer_capacity(buf_handle_t buffer);

int buffer_put(buf_handle_t buffer, buffer_packet_t packet);

buffer_packet_t buffer_get(buf_handle_t buffer, int imgnum);

int buffer_size(buf_handle_t buffer);

void buffer_free(buf_handle_t buffer);

#endif


// typedef struct buffer_info{
//         int size;
//         int maxSize;
//         bool full;
//         // bool compressed;
//         // bool heuristic;
// } buffer_info_t;