/* Standard includes. */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

// #include "FreeRTOS.h"
// #include "task.h"

#include "../inc/iris_buffer.h"
#include "../inc/iris_configs.h"
#include "iris_heuristic.c"

int main(void)
{	
	//Initalize image buffer of size 5.
	buffer_packet_t * buffer = malloc(5*sizeof(buffer_packet_t));
	buf_handle_t image_buffer = buffer_init(buffer, 5);

	//Creating dummy packet 1
	buffer_packet_t image1;
	input_feature_t metadata1;
	strcpy(image1.image_file, "../test/test1.bin");
	metadata1.dyn_range = 8;
	metadata1.x_size = 512;
	metadata1.y_size = 2048;
	metadata1.z_size = 4;
	metadata1.signed_samples = 0;
	metadata1.in_interleaving = BSQ;
	metadata1.in_interleaving_depth = 0;
	metadata1.byte_ordering = LITTLE;
	metadata1.regular_input = 1;
	image1.image_metadata = metadata1;

	//Creating dummy packet 2
	buffer_packet_t image2;
	input_feature_t metadata2;
	strcpy(image2.image_file, "../test/test2.bin");
	metadata2.dyn_range = 16;
	metadata2.x_size = 1024;
	metadata2.y_size = 2048;
	metadata2.z_size = 4;
	metadata2.signed_samples = 0;
	metadata2.in_interleaving = BSQ;
	metadata2.in_interleaving_depth = 0;
	metadata2.byte_ordering = LITTLE;
	metadata2.regular_input = 1;
	image2.image_metadata = metadata2;

	//Creating dummy packet 2
	buffer_packet_t image3;
	input_feature_t metadata3;
	strcpy(image3.image_file, "../test/test3.bin");
	metadata3.x_size = 512;
	metadata3.y_size = 2048;
	metadata3.z_size = 4;
	metadata3.signed_samples = 0;
	metadata3.in_interleaving = BSQ;
	metadata3.in_interleaving_depth = 0;
	metadata3.byte_ordering = LITTLE;
	metadata3.regular_input = 1;
	image3.image_metadata = metadata3;

	/*DEMO CODE*/
	
	//Putting new packets in buffer
	buffer_put(image_buffer, image1);
	buffer_put(image_buffer, image2);
	buffer_put(image_buffer, image3);

	//Calculate heuristic value of image 2.
	heuristic_img(image_buffer, 2);
	printf("%f\n", buffer_get(image_buffer, 2).heuristic_value);
	
	return 0;
}

 