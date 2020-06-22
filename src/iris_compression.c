#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <math.h>
#include <time.h>

#include "../inc/iris_predictor.h"
#include "../inc/iris_entropy_encoder.h"
#include "../inc/iris_utils.h"
#include "../inc/iris_configs.h"

int compress()
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
        // samples_file[0] = '\x0';
        // out_file[0] = '\x0';
        // init_table_file[0] = '\x0';
        // init_weight_file[0] = '\x0';
        memset(&input_params, 0, sizeof(input_feature_t));
        memset(&encoder_params, 0, sizeof(encoder_config_t));
        memset(&predictor_params, 0, sizeof(predictor_config_t));
        encoder_params.k = (unsigned int)-1;
        input_params.dyn_range = 16;
        encoder_params.encoding_method = BLOCK;

        //File naming **TESTING, DELETE AFTER**
        



        //Obtaining predictor params
        predictor_params.pred_bands = input_params.z_size; //Remove user_input_pred_bands?

        if (input_params.x_size == 1) {
                predictor_params.full == 0;
        } else {
                predictor_params.full == 1;
        }

        //Column-oriented local sums are not recommended under full prediction mode.
        predictor_params.neighbour_sum = 0;
        //**Double check this after**
        //NOTE: Increasing the register size R reduces the chance of an overflow occurring in the calculation of a scaled predicted sample value.
        predictor_params.register_size = 32; 
        //Increasing the number of bits used to represent weight values provides increased resolution in the prediction calculation. This value is 4 <= W <= 19;
        predictor_params.weight_resolution = 4;
        //**Double check this after**
        predictor_params.weight_interval = 16;

        //These configs will default as 0
        // predictor_params.weight_initial;
        // predictor_params.weight_final;
        // predictor_params.weight_init_resolution;
        // predictor_params.weight_init_table;

        //Obtaining encoding params -> Default as 0 from previous memset
        // unsigned int u_max;
        // unsigned int y_star;
        // unsigned int y_0;
        // unsigned int k;
        // unsigned int * k_init;
        // interleaving_t out_interleaving;
        // unsigned int out_interleaving_depth;
        // unsigned int out_wordsize;
        // encoder_t encoding_method;
        // unsigned char block_size;
        // unsigned char restricted;
        // unsigned int ref_interval;

        // *********************** here is the actual compression step *********************** //
        residuals = (unsigned short int *)malloc(sizeof(unsigned short int)*input_params.x_size*input_params.y_size*input_params.z_size);
        if(residuals == NULL){
                fprintf(stderr, "Error in allocating %lf kBytes for the residuals buffer\n\n", ((double)sizeof(unsigned short int)*input_params.x_size*input_params.y_size*input_params.z_size)/1024.0);
                return -1;
        }

        compressionStartTime = ((double)clock())/CLOCKS_PER_SEC;
        if(predict(input_params, predictor_params, samples_file, residuals) != 0){
                fprintf(stderr, "\nError during the computation of the residuals (i.e. prediction)\n\n");
                return -1;
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
                return -1;            
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

        //and now we print some stats
        printf("Overall Compression duration %lf (sec)\n", compressionEndTime - compressionStartTime);
        printf("Prediction duration %lf (sec)\n", predictionEndTime - compressionStartTime);
        printf("Encoding duration %lf (sec)\n", compressionEndTime - predictionEndTime);
        printf("%d bytes (%.2lf kb) in the compressed image\n", compressed_bytes, ((double)compressed_bytes)/(1024.0));
        printf("Compressed rate %lf bits/sample\n", ((double)compressed_bytes*8)/(input_params.y_size*input_params.x_size*input_params.z_size));

        return 0;
}

int main()
{
        compress();
}