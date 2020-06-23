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
 * @file iris_heuristic.c
 * @author Scott Chu
 * @date 2020-05-28
 */

/*Standard Lib Includes*/
#include <stdio.h>
#include <stdlib.h>

/*File Includes*/
#include "../inc/iris_heuristic.h"
#include "iris_cloud_detection.c"
#include "../payload_base/include/FreeRTOS.h"

struct input_feature img_buffer[10]; //Temporary solution for storing image parameters, this will eventually be stored in a buffer with the images.

/**
 * @brief
 * 		Generates an dummy image with a "width" amount of pixels in the x-direction.
 * @param width
 * 		Amount of pixels in the x-direction.
 * @return
 * 		Returns 1 if not sucessful.
 */
int generate_img(int width)
{       
        //Create image raster file 
        FILE *fptr;
        fptr = fopen("../test/testImage.bin", "wb");
        if (fptr == NULL) {
                return 1;
        }

        srand(0);

        //Dummy input parameter information
        //https://drive.google.com/file/d/1XUDoHPWYANqUkHEg-Cc4IDR-aIKXyQh9/view
        //Page 5-3
        input_feature_t input_params;
        input_params.x_size = width;
        input_params.y_size = Y_PIXELS;
        input_params.z_size = Z_PIXELS;
        input_params.signed_samples = 1;
        input_params.dyn_range = 8;
        input_params.in_interleaving = BSQ;
        input_params.in_interleaving_depth = 1; 
        input_params.byte_ordering = LITTLE;
        input_params.regular_input = 1;

        img_buffer[0] = input_params;

        //Generating random sample band values in specified raster formats
        if (input_params.in_interleaving == BSQ) {
                for (int z = 0; z < input_params.z_size; z++) {
                        for (int y = 0; y < input_params.y_size; y++){
                                for (int x = 0; x < input_params.x_size; x++) {
                                        int sample = rand() % (256 + 1 - 0) + 0;
                                        fprintf(fptr, "%d ", sample);
                                }
                                fprintf(fptr, "\n");
                        }
                }       
        } else if (input_params.in_interleaving == BIP || input_params.in_interleaving == BIL) {
                for (int y = 0; y < input_params.y_size; y++) {
                        for (int x = 0; x < input_params.x_size * input_params.z_size; x++) {
                                int sample = rand() % (256 + 1 - 0) + 0;
                                fprintf(fptr, "%d ", sample);
                        }
                        fprintf(fptr, "\n");
                }                  
        }

        fclose(fptr);
}

/**
 * @brief
 * 		Calculates the heuristic value of an image and stores it in image header.
 * @param imgnum
 * 		Designator for the image.
 * @return
 * 		Returns 1 if not sucessful.
 */
int heuristic_img(int imgnum)
{
        int raw_heuristic = 0;
        FILE *fptr;
        fptr = fopen("../test/testImage.bin", "rb");

        if (fptr == NULL) {
                printf("Unable to open image file");
                return 1;
        }

        //Allocate memory for seperate band arrays
        float *b = pvPortMalloc(img_buffer[imgnum].x_size * img_buffer[imgnum].y_size * sizeof(float));
        float *r = pvPortMalloc(img_buffer[imgnum].x_size * img_buffer[imgnum].y_size * sizeof(float));
        float *nir = pvPortMalloc(img_buffer[imgnum].x_size * img_buffer[imgnum].y_size * sizeof(float));
        float *swir = pvPortMalloc(img_buffer[imgnum].x_size * img_buffer[imgnum].y_size * sizeof(float));
        if (b == NULL || r == NULL || nir == NULL || swir == NULL){
                printf("Unable to allocate memory for band array");
                return 1;
        }

        //Reading the BSQ formatted raster file. Populating b, r, nir, swir band arrays
        if (img_buffer[0].in_interleaving == BSQ) {
                for (int j = 0; j < img_buffer[imgnum].x_size * img_buffer[imgnum].y_size; j++) {
                        fscanf(fptr, "%f ", b+j);
                }

                for (int j = 0; j < img_buffer[imgnum].x_size * img_buffer[imgnum].y_size; j++) {
                        fscanf(fptr, "%f ", r+j);
                }
 
                for (int j = 0; j < img_buffer[imgnum].x_size * img_buffer[imgnum].y_size; j++) {
                        fscanf(fptr, "%f ", nir+j);
                }

                for (int j = 0; j < img_buffer[imgnum].x_size * img_buffer[imgnum].y_size; j++) {
                        fscanf(fptr, "%f ", swir+j);
                }

                //Loop through each index of the band arrays and running isCloud() on each iteration (each pixel)
                for (int i = 0; i < img_buffer[imgnum].x_size * img_buffer[imgnum].y_size; i++) {
                        printf("b: %f\nr: %f\nnir: %f\nswir: %f\n\n", *(b+i), *(r+i), *(nir+i), *(swir+i));
                        if (isCloud(*(b+i), *(r+i), *(nir+i), *(swir+i))) {
                                raw_heuristic+=1;
                        }
                }
                
                //Free allocated memory of the band arrays
                vPortFree(b);        
                vPortFree(r);
                vPortFree(nir);
                vPortFree(swir);
                fclose(fptr);

                //Returns number of cloudy pixels / all pixels.
                return raw_heuristic / (img_buffer[imgnum].x_size * img_buffer[imgnum].y_size);

        //Reading the BIP formatted raster file. Populating b, r, nir, swir band arrays
        } else if (img_buffer[0].in_interleaving == BIP) {
                for (int i = 0; i < img_buffer[imgnum].x_size * img_buffer[imgnum].y_size; i++) {
                        fscanf(fptr, "%f %f %f %f ", b+i, r+i, nir+i, swir+i);
                }

                for (int i = 0; i < img_buffer[imgnum].x_size * img_buffer[imgnum].y_size; i++) {
                        printf("b: %f\nr: %f\nnir: %f\nswir: %f\n\n", *(b+i), *(r+i), *(nir+i), *(swir+i));
                        if(isCloud(*(b+i), *(r+i), *(nir+i), *(swir+i))){
                                raw_heuristic+=1;
                        }
                }

                vPortFree(b);        
                vPortFree(r);
                vPortFree(nir);
                vPortFree(swir);
                fclose(fptr);

                return raw_heuristic / (img_buffer[imgnum].x_size * img_buffer[imgnum].y_size);

        //Reading the BIL formatted raster file. Populating b, r, nir, swir band arrays
        } else if (img_buffer[imgnum].in_interleaving == BIL) {
                int b_index, r_index, nir_index, swir_index = 0;
                for (int i = 1; i < (img_buffer[imgnum].x_size * img_buffer[imgnum].y_size)+1; i++) {
                        if(i%4 == 1) {
                                fscanf(fptr, "%f ", b+b_index);
                                b_index+=1; 
                        } else if(i%4 == 2) {
                                fscanf(fptr, "%f ", r+r_index);
                                r_index+=1; 
                        } else if(i%4 == 3) {
                                fscanf(fptr, "%f ", nir+nir_index);
                                nir_index+=1;            
                        } else if(i%4 == 0) {
                                fscanf(fptr, "%f ", swir+swir_index);
                                swir_index+=1; 
                        }

                }

                for( int i = 0; i < img_buffer[imgnum].x_size * img_buffer[imgnum].y_size; i++) {
                        printf("b: %f\nr: %f\nnir: %f\nswir: %f\n\n", *(b+i), *(r+i), *(nir+i), *(swir+i));
                        if (isCloud(*(b+i), *(r+i), *(nir+i), *(swir+i))) {
                                raw_heuristic+=1;
                        }
                }

                vPortFree(b);        
                vPortFree(r);
                vPortFree(nir);
                vPortFree(swir);
                fclose(fptr);

                return raw_heuristic / (img_buffer[imgnum].x_size * img_buffer[imgnum].y_size);      
        }
}

// int main()
// {
//         //Generate 4x2048x2048 image
//         generate_img(2048);

//         //Run heuristic calculation on generated dummy image binary file.
//         printf("Heuristic value: %d", heuristic_img(0));
//         return 0;
// }