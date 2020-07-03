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
 * @file iris_buffer.c
 * @author Scott Chu
 * @date 2020-06-29
 */

/* Standard includes. */
#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>

// #include "FreeRTOS.h"
// #include "task.h"
#include "../inc/iris_buffer.h"

/**
 * @brief
 * 		Intialize image buffer with a specified max size.
 * @param buffer
 * 		Pointer to the underlying buffer with packet data type.
 * @param maxSize
 * 		Maximum size of buffer.
 * @return
 * 		Returns intiailied image buffer.
 */
buf_handle_t buffer_init(buffer_packet_t* buffer, int maxSize)
{
        buf_handle_t image_buffer = malloc(sizeof(image_buffer_t));
        image_buffer->buffer = buffer;
        image_buffer->maxSize = maxSize;
        image_buffer->size = 0;
        image_buffer->full = false;
        return image_buffer;
}

/**
 * @brief
 * 		Checks if image buffer is full.
 * @param buffer
 * 		Image buffer.
 * @return
 * 		Returns 1 (true), 0 (false)
 */
int buffer_full(buf_handle_t buffer)
{ 
        if (buffer->size == buffer->maxSize) {
                buffer->full = 1;
        } else if (buffer->size < buffer->maxSize)  {
                buffer->full = 0;
        } 
        return buffer->full;
}

/**
 * @brief
 * 		Checks maximum size of image buffer.
 * @param buffer
 * 		Image buffer.
 * @return
 * 		Returns maximum size of image buffer.
 */
int buffer_capacity(buf_handle_t buffer)
{       
        return buffer->maxSize;
}

/**
 * @brief
 * 		Checks current size of image buffer.
 * @param buffer
 * 		Image buffer
 * @return
 * 		Returns current size of image buffer.
 */
int buffer_size(buf_handle_t buffer)
{       
        return buffer->size;
}

/**
 * @brief
 * 		Inserts new image packet into buffer.
 * @param buffer
 * 		Image buffer.
 * @param packet
 * 		Packet to be added.
 * @return
 * 		Returns 1 if not sucessful.
 */
int buffer_put(buf_handle_t buffer, buffer_packet_t packet)
{
        int index = buffer->size;
        int full = buffer_full(buffer);

        if (full == 1) {
                printf("Unable to add to buffer: buffer is full");
                return 1;
        } else {
                (buffer->buffer)[index] = packet;
                buffer->size++;
        }
}

/**
 * @brief
 * 		Calculates the heuristic value of an image and stores it in image header.
 * @param buffer
 * 		Image buffer.
 * @param imgnum
 * 		Designator for the image.
 * @return
 * 		Returns image packet.
 */
buffer_packet_t buffer_get(buf_handle_t buffer, int imgnum)
{
        return (buffer->buffer)[imgnum];
}

/**
 * @brief
 * 		Frees allocated memory used for the image buffer.
 * @param imgnum
 * 		Designator for the image.
 */
void buffer_free(buf_handle_t buffer)
{
        free(buffer);
}

// /**
//  * @brief
//  * 		Calculates the heuristic value of an image and stores it in image header.
//  * @param imgnum
//  * 		Designator for the image.
//  * @return
//  * 		Returns image packet.
//  */
// buffer_packet_t buffer_remove(buf_handle_t buffer, int imgnum)
// {
//         free(&(buffer->buffer)[imgnum]);
//         buffer->size--;
// }

