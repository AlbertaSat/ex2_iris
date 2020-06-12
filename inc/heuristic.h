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
 * @file heuristic.h
 * @author Scott Chu
 * @date 2020-05-28
 */

#ifndef HEURISTIC_H
#define HEURISTIC_H

//Macro used to move from a matrix notation to a linear array, when the matrix
//is ordered according to the BSQ order
//#define MATRIX_BSQ_INDEX(matrix, input_params, x, y, z) matrix[(z)*input_params.x_size*input_params.y_size + (y)*input_params.x_size + (x)]

#define MATRIX_BSQ_INDEX(matrix, input_params, x, y, z) matrix[input_params.x_size*((z)*input_params.y_size + (y)) + (x)]

typedef enum{BSQ, BIP, BIL} interleaving_t;
typedef enum{LITTLE, BIG} endianness_t;

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


#endif 