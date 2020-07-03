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
 * @author Scott Chu
 * @date 2020-05-28
 */

/*Standard Lib Includes*/
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/*File Includes*/
#include "../inc/iris_configs.h"
#include "../inc/iris_buffer.h"
#include "iris_cloud_detection.c"
#include "../payload_base/include/FreeRTOS.h"

/**
 * @brief
 * 		Calculates the heuristic value of an image and stores it in image header.
 * @param imgnum
 * 		Designator for the image.
 * @return
 * 		Returns 1 if not sucessful.
 */
int heuristic_img(buf_handle_t buffer, int imgnum)
{       
        float raw_heuristic = 0.0;

        //Initializing file pointer
        FILE *fptr;
        char imageFile[128];
        strcpy(imageFile, (buffer->buffer)[imgnum].image_file);
        printf("Opening %s..\n", imageFile);
        fptr = fopen(imageFile, "rb");
        
        if (fptr == NULL) {
                printf("Unable to open image file\n");
                return 1;
        }

        //Obtaining metadata from buffer packet
        input_feature_t metadata = (buffer->buffer)[imgnum].image_metadata;

        //Allocate memory for seperate band arrays
        float *b = malloc(metadata.x_size * metadata.y_size * sizeof(float));
        float *r = malloc(metadata.x_size * metadata.y_size * sizeof(float));
        float *nir = malloc(metadata.x_size * metadata.y_size * sizeof(float));
        float *swir = malloc(metadata.x_size * metadata.y_size * sizeof(float));

        if (b == NULL || r == NULL || nir == NULL || swir == NULL){
                printf("Unable to allocate memory for band array");
                return 1;
        }

        //Reading the BSQ formatted raster file. Populating b, r, nir, swir band arrays
        if (metadata.in_interleaving == BSQ) {
                for (int j = 0; j < metadata.x_size * metadata.y_size; j++) {
                        fscanf(fptr, "%f ", b+j);
                }

                for (int j = 0; j < metadata.x_size * metadata.y_size; j++) {
                        fscanf(fptr, "%f ", r+j);
                }

                for (int j = 0; j < metadata.x_size * metadata.y_size; j++) {
                        fscanf(fptr, "%f ", nir+j);
                }

                for (int j = 0; j < metadata.x_size * metadata.y_size; j++) {
                        fscanf(fptr, "%f ", swir+j);
                }

                //Loop through each index of the band arrays and running isCloud() on each iteration (each pixel)
                for (int i = 0; i < metadata.x_size * metadata.y_size; i++) {
                        // printf("b: %f\nr: %f\nnir: %f\nswir: %f\n\n", *(b+i), *(r+i), *(nir+i), *(swir+i));
                        if (isCloud(*(b+i), *(r+i), *(nir+i), *(swir+i))) {
                                raw_heuristic+=1;
                        }
                }
                
                //Free allocated memory of the band arrays
                free(b);        
                free(r);
                free(nir);
                free(swir);
                fclose(fptr);

                //Sets the calculated heuristic value of image in the image packet.
                (buffer->buffer)[imgnum].heuristic_value = raw_heuristic / (metadata.x_size * metadata.y_size);
        }
        // //Reading the BIP formatted raster file. Populating b, r, nir, swir band arrays
        // } else if (metadata.in_interleaving == BIP) {
        //         for (int i = 0; i < metadata.x_size * metadata.y_size; i++) {
        //                 fscanf(fptr, "%f %f %f %f ", b+i, r+i, nir+i, swir+i);
        //         }

        //         for (int i = 0; i < metadata.x_size * metadata.y_size; i++) {
        //                 printf("b: %f\nr: %f\nnir: %f\nswir: %f\n\n", *(b+i), *(r+i), *(nir+i), *(swir+i));
        //                 if(isCloud(*(b+i), *(r+i), *(nir+i), *(swir+i))){
        //                         raw_heuristic+=1;
        //                 }
        //         }

        //         free(b);        
        //         free(r);
        //         free(nir);
        //         free(swir);
        //         fclose(fptr);

        //         (buffer->buffer)[imgnum].heuristic_value = raw_heuristic / (metadata.x_size * metadata.y_size);

        // //Reading the BIL formatted raster file. Populating b, r, nir, swir band arrays
        // } else if (metadata.in_interleaving == BIL) {
        //         int b_index, r_index, nir_index, swir_index = 0;
        //         for (int i = 1; i < (metadata.x_size * metadata.y_size)+1; i++) {
        //                 if(i%4 == 1) {
        //                         fscanf(fptr, "%f ", b+b_index);
        //                         b_index+=1; 
        //                 } else if(i%4 == 2) {
        //                         fscanf(fptr, "%f ", r+r_index);
        //                         r_index+=1; 
        //                 } else if(i%4 == 3) {
        //                         fscanf(fptr, "%f ", nir+nir_index);
        //                         nir_index+=1;            
        //                 } else if(i%4 == 0) {
        //                         fscanf(fptr, "%f ", swir+swir_index);
        //                         swir_index+=1; 
        //                 }

        //         }

        //         for( int i = 0; i < metadata.x_size * metadata.y_size; i++) {
        //                 printf("b: %f\nr: %f\nnir: %f\nswir: %f\n\n", *(b+i), *(r+i), *(nir+i), *(swir+i));
        //                 if (isCloud(*(b+i), *(r+i), *(nir+i), *(swir+i))) {
        //                         raw_heuristic+=1;
        //                 }
        //         }

        //         free(b);        
        //         free(r);
        //         free(nir);
        //         free(swir);
        //         fclose(fptr);

        //         (buffer->buffer)[imgnum].heuristic_value = raw_heuristic / (metadata.x_size * metadata.y_size); 
    
        // }
}
