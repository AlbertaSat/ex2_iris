#ifndef INCLUDES_H
#define INCLUDES_H

#include "iris_utils.h"

#define MATRIX_BSQ_INDEX(matrix, input_params, x, y, z) matrix[input_params.x_size*((z)*input_params.y_size + (y)) + (x)]

typedef enum{BSQ, BI} interleaving_t;
typedef enum{LITTLE, BIG} endianness_t;
typedef enum{SAMPLE, BLOCK} encoder_t;

///Type representing the characteristics of the input data fed to
///the algorithm
typedef struct input_feature{
    char signed_samples;
    unsigned char dyn_range;
    unsigned int x_size;
    unsigned int y_size;
    unsigned int z_size;
    interleaving_t in_interleaving;
    unsigned int in_interleaving_depth;
    endianness_t byte_ordering;
    unsigned char regular_input;
} input_feature_t;

///Type representing the configuration of the predictor
typedef struct predictor_config{
    unsigned char user_input_pred_bands;
    unsigned char pred_bands;
    unsigned char full;
    unsigned char neighbour_sum;
    unsigned char register_size;
    unsigned char weight_resolution;
    int weight_interval;  
    char weight_initial;
    char weight_final;
    unsigned char weight_init_resolution;
    int ** weight_init_table;
} predictor_config_t;

///Type representing the configuration of the encoder algorithm
typedef struct encoder_config{
    unsigned int u_max;
    unsigned int y_star;
    unsigned int y_0;
    unsigned int k;
    unsigned int * k_init;
    interleaving_t out_interleaving;
    unsigned int out_interleaving_depth;
    unsigned int out_wordsize;
    encoder_t encoding_method;
    unsigned char block_size;
    unsigned char restricted;
    unsigned int ref_interval;
} encoder_config_t;

#endif