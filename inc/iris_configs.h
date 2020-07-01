/*
 * Copyright (C) 2015  University of Alberta
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 */

/**
 * @file iris_configs.c
 * @author Luca Fossati (ESA), Scott Chu
 * @date 2020-06-23
 */

#ifndef IRIS_CONFIGS_H
#define IRIS_CONFIGS_H

#include "iris_utils.h"

#define Z_PIXELS 4      //B, R, NIR, SWIR Bands
#define Y_PIXELS 2048   //Y dimension of image are constant

//Macro used to move from a matrix notation to a linear array, when the matrix is ordered according to the BSQ order
#define MATRIX_BSQ_INDEX(matrix, input_params, x, y, z) matrix[input_params.x_size*((z)*input_params.y_size + (y)) + (x)]

typedef enum{BSQ, BIL, BIP} interleaving_t;
typedef enum{LITTLE, BIG} endianness_t;
typedef enum{SAMPLE, BLOCK} encoder_t;

//Type representing the characteristics of the input data fed to the algorithm
typedef struct input_feature{
    char signed_samples;
    unsigned char dyn_range;
    unsigned char regular_input;
    unsigned int x_size;
    unsigned int y_size;
    unsigned int z_size;
    interleaving_t in_interleaving;
    unsigned int in_interleaving_depth;
    endianness_t byte_ordering;
} input_feature_t;

//Type representing the configuration of the predictor
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

//Type representing the configuration of the encoder algorithm
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