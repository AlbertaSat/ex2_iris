/*
 * Copyright (C) 2015  University of Alberta
 *
 * This program is Free software; you can redistribute it and/or
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
 * @file iris_heuristic.c
 * @author Luca Fossati (ESA), Scott Chu
 * @date 2020-06-23
 */

/*Standard Lib Includes*/
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <math.h>
#include <time.h>

/*File Includes*/
#include "../inc/iris_predictor.h"
#include "../inc/iris_entropy_encoder.h"
#include "../inc/iris_utils.h"
#include "../inc/iris_configs.h"
#include "../payload_base/include/FreeRTOS.h"

/**
 * @brief
 * 		Compresses raster file image using the CCSDS compression protocol written by the ESA.
 * @param imgnum
 * 		Designator for the image.
 * @return
 * 		Returns 1 if not sucessful.
 */
int img_compress(int imgnum)
{       
        //Statistics
        double compressionStartTime = 0.0;
        double compressionEndTime = 0.0;
        double predictionEndTime = 0.0;
        unsigned int compressed_bytes = 0;
        unsigned int dump_residuals = 0;

        //File declaration
        char samples_file[128];
        char out_file[128];
        char init_table_file[128];
        char init_weight_file[128];

        // Some initialization of default values
        input_feature_t input_params;
        encoder_config_t encoder_params;
        predictor_config_t predictor_params;
        unsigned short int * residuals = NULL;
        samples_file[0] = '\x0';
        out_file[0] = '\x0';
        init_table_file[0] = '\x0';
        init_weight_file[0] = '\x0';
        memset(&input_params, 0, sizeof(input_feature_t));
        memset(&encoder_params, 0, sizeof(encoder_config_t));
        memset(&predictor_params, 0, sizeof(predictor_config_t));
        encoder_params.k = (unsigned int)-1;
        input_params.dyn_range = 16;
        encoder_params.encoding_method = BLOCK;

        //Obtaining predictor params
        predictor_params.pred_bands = input_params.z_size; //Remove user_input_pred_bands?

        if (input_params.x_size == 1) {
                predictor_params.full == 0;
        } else {
                predictor_params.full == 1;
        }

        //Column-oriented local sums are not recommended under full prediction mode.
        predictor_params.neighbour_sum = 0;
        //NOTE: Increasing the register size R reduces the chance of an overflow occurring in the calculation of a scaled predicted sample value.
        predictor_params.register_size = 32; 
        //Increasing the number of bits used to represent weight values provides increased resolution in the prediction calculation. The range here is [4, 19];
        predictor_params.weight_resolution = 4;
        //**Double check this after**
        predictor_params.weight_interval = 16;

        //These configs will default as 0
        // predictor_params.weight_initial;
        // predictor_params.weight_final;
        // predictor_params.weight_init_resolution;
        // predictor_params.weight_init_table;

        // These are user specified, we can change them later after we see compression results. This will work for now.
        encoder_params.u_max = 18;
        encoder_params.y_star = 6;
        encoder_params.y_0 = 1;
        encoder_params.k = 6;
        
        // unsigned int * k_init;
        encoder_params.out_interleaving = BSQ;
        encoder_params.out_interleaving_depth = input_params.in_interleaving_depth;
        // Value in range [1,8], 
        encoder_params.out_wordsize = 8;


        // *********************** here is the actual compression step *********************** //
        residuals = (unsigned short int *)pvPortMalloc(sizeof(unsigned short int)*input_params.x_size*input_params.y_size*input_params.z_size);
        if(residuals == NULL){
                fprintf(stderr, "Error in allocating %lf kBytes for the residuals buffer\n\n", ((double)sizeof(unsigned short int)*input_params.x_size*input_params.y_size*input_params.z_size)/1024.0);
                return 1;
        }

        compressionStartTime = ((double)clock())/CLOCKS_PER_SEC;
        if(predict(input_params, predictor_params, samples_file, residuals) != 0){
                fprintf(stderr, "\nError during the computation of the residuals (i.e. prediction)\n\n");
                return 1;
        }
        if(dump_residuals != 0){
                // dumps the residuals as unsigned short int (16 bits each) in little endian format in
                // BIP order
                char residuals_name[100];
                FILE * residuals_file = NULL;
                int x = 0, y = 0, z = 0;
                sprintf(residuals_name, "residuals_%s.bip", out_file);
                if((residuals_file = fopen(residuals_name, "w+b")) == NULL){
                fprintf(stderr, "\nError in creating the file holding the residuals\n\n");
                return 1;            
                }
                for(y = 0; y < input_params.y_size; y++){
                for(x = 0; x < input_params.x_size; x++){
                        for(z = 0; z < input_params.z_size; z++){
                        fwrite(&(MATRIX_BSQ_INDEX(residuals, input_params, x, y, z)), 2, 1, residuals_file);
                        }
                }
                }
                fclose(residuals_file);
        }
        predictionEndTime = ((double)clock())/CLOCKS_PER_SEC;
        compressed_bytes = encode(input_params, encoder_params, predictor_params, residuals, out_file);
        compressionEndTime = ((double)clock())/CLOCKS_PER_SEC;

        //Finally I can deallocate everything
        if(encoder_params.k_init != NULL)
                vPortFree(encoder_params.k_init);
        if(predictor_params.weight_init_table != NULL){
                int i = 0;
                for(i = 0; i < input_params.z_size; i++){
                if(predictor_params.weight_init_table[i] != NULL)
                        vPortFree(predictor_params.weight_init_table[i]);
                }
                vPortFree(predictor_params.weight_init_table);
        }
        if(residuals != NULL)
                vPortFree(residuals);

        // *********************** end of the actual compression step *********************** //

        //and now we print some stats
        printf("Overall Compression duration %lf (sec)\n", compressionEndTime - compressionStartTime);
        printf("Prediction duration %lf (sec)\n", predictionEndTime - compressionStartTime);
        printf("Encoding duration %lf (sec)\n", compressionEndTime - predictionEndTime);
        printf("%d bytes (%.2lf kb) in the compressed image\n", compressed_bytes, ((double)compressed_bytes)/(1024.0));
        printf("Compressed rate %lf bits/sample\n", ((double)compressed_bytes*8)/(input_params.y_size*input_params.x_size*input_params.z_size));

        return 0;
}

