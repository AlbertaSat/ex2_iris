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
 * @file can.c
 * @author Scott Chu
 * @date 2020-08-07
 */

/* Standard includes */
#include <stdio.h>
#include <stdint.h>

#include "../Altera_Code/HardwareLibrary/include/socal/alt_can.h"
#include "../Altera_Code/HardwareLibrary/include/socal/socal.h"
#include "can.h"

/**
 * @brief
 * 		Configure CAN message objects
 */
void config_CAN_message(void)
{
    	unsigned int ARB_field;
    	unsigned int MSK_field;
    	unsigned int MCTR_field;
    	unsigned int CMR_field;

        /* Receive message configuration */
        while (alt_read_word(IF1CMR) & ALT_CAN_MSGIF_IF1CMR_BUSY_GET(1)); //While register is busy

        MSK_field = ALT_CAN_MSGIF_IF1MSK_MSK_SET(127)|
                        ALT_CAN_MSGIF_IF1MSK_MDIR_SET(1)|
                        ALT_CAN_MSGIF_IF1MSK_MXTD_SET(1);

        ARB_field = ALT_CAN_MSGIF_IF1ARB_MSGVAL_SET(1) |
                        ALT_CAN_MSGIF_IF1ARB_ID_SET(1) |
                        ALT_CAN_MSGIF_IF1ARB_DIR_SET(0) |
                        ALT_CAN_MSGIF_IF1ARB_XTD_SET(1);

        MCTR_field = ALT_CAN_MSGIF_IF1MCTR_DLC_SET(8) |
                        ALT_CAN_MSGIF_IF1MCTR_UMSK_SET(1) |
                        ALT_CAN_MSGIF_IF1MCTR_EOB_SET(1) |
                        ALT_CAN_MSGIF_IF1MCTR_TXIE_SET(1) |
                        ALT_CAN_MSGIF_IF1MCTR_RXIE_SET(1);

        alt_write_word(IF1CMR, MSK_field);
        alt_write_word(IF1ARB, ARB_field);
        alt_write_word(IF1MCTR, MCTR_field);

        while (alt_read_word(IF2CMR) & ALT_CAN_MSGIF_IF2CMR_BUSY_GET(1)); //While register is busy

        MSK_field = ALT_CAN_MSGIF_IF2MSK_MSK_SET(127) |
                    	ALT_CAN_MSGIF_IF2MSK_MDIR_SET(1) |
                        ALT_CAN_MSGIF_IF2MSK_MXTD_SET(1);

        ARB_field = ALT_CAN_MSGIF_IF2ARB_MSGVAL_SET(1) |
                        ALT_CAN_MSGIF_IF2ARB_ID_SET(2) |
                        ALT_CAN_MSGIF_IF2ARB_DIR_SET(1) |
                        ALT_CAN_MSGIF_IF2ARB_XTD_SET(1);

        MCTR_field = ALT_CAN_MSGIF_IF2MCTR_DLC_SET(1) |
                        ALT_CAN_MSGIF_IF2MCTR_UMSK_SET(1) |
                        ALT_CAN_MSGIF_IF2MCTR_EOB_SET(1) |
                        ALT_CAN_MSGIF_IF2MCTR_TXIE_SET(1) |
                        ALT_CAN_MSGIF_IF2MCTR_RXIE_SET(1);

        alt_write_word(IF2CMR, MSK_field);
        alt_write_word(IF2ARB, ARB_field);
        alt_write_word(IF2MCTR, MCTR_field);
}

/**
 * @brief
 * 		Initialize the CAN controller
 * @param can_controller
 * 	        Specifies which CAN controller to initalize. 0 or 1.
 */
void config_CAN_controller(uint8_t can_controller)
{
        /* Setting Init and CCE bit to 1 in the CCTRL register */
        unsigned int CCTRL_field = 0x00000000;
        unsigned int INIT = ALT_CAN_PROTO_CCTL_INIT_SET(1);
        unsigned int CCE = ALT_CAN_PROTO_CCTL_CCE_SET(1);

        CCTRL_field = INIT | CCE;

        if (can_controller == 0) {
                alt_write_word(CCTRL0, CCTRL_field);
        } else if (can_controller == 1) {
                alt_write_word(CCTRL1, CCTRL_field);
        }

        // Calculate bit rate here and set in BTR register....

        /* Initialize message RAM */
        if (can_controller == 0) {
                CAN_RAM_Init(0);
        } else if (can_controller == 1) {
                CAN_RAM_Init(1);
        }

        /* Setting Init and CCE bit back to 0 in the CCTRL register */
        INIT = ALT_CAN_PROTO_CCTL_INIT_SET(1);
        CCE = ALT_CAN_PROTO_CCTL_CCE_SET(1);
        CCTRL_field = INIT | CCE;

        if (can_controller == 0) {
                alt_write_word(CCTRL0, CCTRL_field);
        } else if (can_controller == 1) {
                alt_write_word(CCTRL1, CCTRL_field);
        }
}

/**
 * @brief
 * 		Initialize CAN message RAM and clears all message objects.
 * @param can_ram
 * 	        Specifies which CAN RAM to initialize. 0 or 1.
 */
void CAN_RAM_Init(uint8_t can_ram)
{
        unsigned int CFR_field;
        CFR_field = ALT_CAN_PROTO_CFR_RAMINIT_SET(1);

        if (can_ram == 0) {
                alt_write_word(CFR0, CFR_field);
        } else if (can_ram == 1) {
                alt_write_word(CFR1, CFR_field);
        }
}

/**
 * @brief
 * 		Performs entire CAN node init sequence
 */
int can_init(void)
{
        config_CAN_controller(0);
        config_CAN_message();
        return 0;
}
