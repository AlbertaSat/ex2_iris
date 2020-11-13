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
#include "../inc/iris_buffer.h"
#include "../payload_base/include/FreeRTOS.h"

/**
 * @brief
 * 		Compresses raster file image using the CCSDS compression protocol written by the ESA.
 * @param buffer
 * 		Image buffer.
 * @param imgnum
 * 		Designator for the image.
 * @return
 * 		Returns 1 if not sucessful.
 */
int compress_img(buf_handle_t buffer, int imgnum)
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
        input_feature_t input_params = (buffer->buffer)[imgnum].image_metadata;
        encoder_config_t encoder_params;
        predictor_config_t predictor_params;
        unsigned short int * residuals = NULL;
        strcpy(samples_file, (buffer->buffer)[imgnum].image_file);
        strcpy(out_file, "test1compressed.fl");

        init_table_file[0] = '\x0';
        init_weight_file[0] = '\x0';
        // memset(&input_params, 0, sizeof(input_feature_t));
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

        // Value in range [1,8], **IMAGE SIZE MUST BE A MULTIPLE OF WORDSIZE** **FIX**
        encoder_params.out_wordsize = 8;


        // *********************** here is the actual compression step *********************** //
        residuals = (unsigned short int *)malloc(sizeof(unsigned short int)*input_params.x_size*input_params.y_size*input_params.z_size);
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

        //Finally deallocate everything
        if(encoder_params.k_init != NULL)
                free(encoder_params.k_init);
        if(predictor_params.weight_init_table != NULL){
                int i = 0;
                for(i = 0; i < input_params.z_size; i++){
                if(predictor_params.weight_init_table[i] != NULL)
                        free(predictor_params.weight_init_table[i]);
                }
                free(predictor_params.weight_init_table);
        }
        if(residuals != NULL)
                free(residuals);

        // *********************** end of the actual compression step *********************** //
        
        //Setting compression stats in image packet
        (buffer->buffer)[imgnum].comp_duration = compressionEndTime - compressionStartTime;
        (buffer->buffer)[imgnum].pred_duration = predictionEndTime - compressionStartTime;
        (buffer->buffer)[imgnum].encode_duration = compressionEndTime - predictionEndTime;
        (buffer->buffer)[imgnum].compressed_bytes = compressed_bytes, ((double)compressed_bytes)/(1024.0);
        (buffer->buffer)[imgnum].compressed_rate = ((double)compressed_bytes*8)/(input_params.y_size*input_params.x_size*input_params.z_size);

        //and now we print some stats
        printf("Overall Compression duration %lf (sec)\n", compressionEndTime - compressionStartTime);
        printf("Prediction duration %lf (sec)\n", predictionEndTime - compressionStartTime);
        printf("Encoding duration %lf (sec)\n", compressionEndTime - predictionEndTime);
        printf("%d bytes (%.2lf kb) in the compressed image\n", compressed_bytes, ((double)compressed_bytes)/(1024.0));
        printf("Compressed rate %lf bits/sample\n", ((double)compressed_bytes*8)/(input_params.y_size*input_params.x_size*input_params.z_size));

        return 0;
}

