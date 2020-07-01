/* Standard includes. */
#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>

// #include "FreeRTOS.h"
// #include "task.h"
#include "buffer.h"

buf_handle_t buffer_init(buffer_packet_t* buffer, int maxSize)
{
        buf_handle_t image_buffer = malloc(sizeof(image_buffer_t));
        image_buffer->buffer = buffer;
        image_buffer->maxSize = maxSize;
        image_buffer->size = 0;
        image_buffer->full = false;
        return image_buffer;
}

bool buffer_full(buf_handle_t buffer)
{ 
        if (buffer->size == buffer->maxSize) {
                buffer->full = true;
        } else if (buffer->size < buffer->maxSize)  {
                buffer->full = false;
        } 
        return buffer->full;
}

int buffer_capacity(buf_handle_t buffer)
{       
        return buffer->maxSize;
}

int buffer_size(buf_handle_t buffer)
{       
        return buffer->size;
}

int buffer_put(buf_handle_t buffer, buffer_packet_t packet)
{
        int index = buffer->size;
        bool full = buffer_full(buffer);

        if (full) {
                printf("Unable to add to buffer: buffer is full");
                return 1;
        } else {
                (buffer->buffer)[index] = packet;
                buffer->size++;
        }
}

buffer_packet_t buffer_get(buf_handle_t buffer, int imgnum)
{
        return (buffer->buffer)[imgnum];
}

void buffer_free(buf_handle_t buffer)
{
        free(buffer);
}



