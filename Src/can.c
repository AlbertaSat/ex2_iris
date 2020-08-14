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
 * @date 2020-08-7
 */

/* Standard includes */
#include <stdio.h>
#include <stdint.h>

/* Altera library includes. */
#include "socal/socal.h"
#include "socal/can.h"

/* Defining CAN controller registers */
#define CAN0 *((uint32_t *) 0xFFC00000) // CAN controller base address 0
#define CAN1 *((uint32_t *) 0xFFC01000) // CAN controller base address 1
#define CCTRL0 *((uint32_t *) 0xFFC00000) // CAN control register 0
#define CCTRL1 *((uint32_t *) 0xFFC01000) // CAN control register 1
#define CBT0 *((uint32_t *) 0xFFC00000 + 0xC) // Bit timing register 0
#define CBT1 *((uint32_t *) 0xFFC01000 + 0xC) // Bit timing register 1
#define CFR0 *((uint32_t *) 0xFFC00000 + 0x18) // Function register 0
#define CFR1 *((uint32_t *) 0xFFC01000 + 0x18) // Function register 1

/* defining CAN interface registers */
#define IF1CMR *((uint32_t *) 0xFFC00000 + 0x100) //


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
        unsigned int INIT = ALT_CAN_PROTO_CCTL_INIT_SET(1));
        unsigned int CCE = ALT_CAN_PROTO_CCTL_CCE_SET(1));
        CCTRL_field = INIT | CCE;

        if (can_controller == 0) {
                alt_write_word(CCTRL0, CCTRL_field);
        } else if (can_controller == 1) {
                alt_write_word(CCTRL1, CCTRL_field);
        }

        // Calculate bit rate here and set in BTR register....

        /* Setting Init and CCE bit back to 0 in the CCTRL register */
        INIT = ALT_CAN_PROTO_CCTL_INIT_SET(1));
        CCE = ALT_CAN_PROTO_CCTL_CCE_SET(1));
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
 * 	        Specifies which CAN RAM to initalize. 0 or 1.
 */
void CAN_RAM_Init(uint8_t can_ram)
{

        unsigned int CFR_field;
        CFR_field = ALT_CAN_PROTO_CFR_RAMINIT_SET(1);

        if (can_ram == 0) {
                alt_write_word(CFR0, CFR_field);
        } else if (can_ram == 0) {
                alt_write_word(CFR0, CFR_field);
        }
}

/**
 * @brief
 * 		Configure CAN message object
 */
void config_CAN_message(void)
{

}
