/* Standard includes. */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
// #include "FreeRTOS.h"
// #include "task.h"
#include "buffer.h"
// #include "buffer.c"


int main(void)
{	
	buffer_packet_t * buffer = malloc(5*sizeof(buffer_packet_t));
	buf_handle_t image_buffer = buffer_init(buffer, 5);

	//Creating dummy packet 1
	buffer_packet_t image1;
	memset(&image1, 0, sizeof(buffer_packet_t));
	input_feature_t metadata;
	memset(&metadata, 0, sizeof(input_feature_t));
	image1.image_metadata = metadata;

	//Creating dummy packet 2
	buffer_packet_t image2;
	memset(&image2, 0, sizeof(buffer_packet_t));
	input_feature_t metadata2;
	memset(&metadata2, 0, sizeof(input_feature_t));
	image1.image_metadata = metadata2;
	
	//Checking new size of buffer
	printf("%d \n", buffer_size(image_buffer));

	//Putting new packet in buffer
	buffer_put(image_buffer, image1);

	//Checking new size of buffer
	printf("%d \n", buffer_size(image_buffer));

	//Putting new packet in buffer
	buffer_put(image_buffer, image2);

	//Checking new size of buffer
	printf("%d \n", buffer_size(image_buffer));


	return 0;
}

