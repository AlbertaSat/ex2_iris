/* Standard includes */
#include <stdio.h>

#include "iris_api.h"

int heuristic_img(buf_handle_t buffer, int imgnum);

int compress_img(buf_handle_t buffer, int imgnum);

int send_img(buf_handle_t buffer, int imgnum);

int capture_img();
