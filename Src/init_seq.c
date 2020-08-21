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
 * @file init_seq.c
 * @author Scott Chu
 * @date 2020-06-29
 */

/* Standard library includes. */
#include <stdio.h>

/* Altera library includes. */
#include "../Altera_Code/HardwareLibrary/include/socal/socal.h"
// #include "socal/alt_gpio.h"
// #include "alt_generalpurpose_io.h"
// #include "alt_address_space.h"


/**
 * @brief
 * 		Extracts 32 bits per cycle and writes it to the Avalon MM interface.
 * @param cycles
 * 		Number of times we extract 32 bits and write it.
 * @param bits
 * 		The bit stream being extracted from.
 * @return
 * 		Returns
 */
void extract_bits(unsigned int cycles, unsigned long long bits)
{
		unsigned int result;
		unsigned int r;
		unsigned int i;

        for (i = 0; i < cycles; i++) {
                r = 0;
                for (i = 0; i <= 31; i++) {
                        r |= 1 << i;
                }

                result = r & bits;
                alt_write_word(0x00000000, result);
                bits = bits>>32;

                // 1ms delay for FPGA to process before next write.
        }
}

/**
 * @brief
 * 		Sends configuration data from OBC to FPGA subsystem until both system and imaging configuration are set.
 * @return
 * 		Returns
 */
void init_sequence(void)
{
        // Sending system config data
        while (alt_read_word(0x00000000) != 20) {
                // Read config from CAN bus
                unsigned int bits = CAN_read();
                extract_bits(2, bits);
        }

        // Sending imaging config data
        while (alt_read_word(0x00000000) != 21) {
                unsigned int bits = CAN_read();
                extract_bits(2, bits);
        }

}
