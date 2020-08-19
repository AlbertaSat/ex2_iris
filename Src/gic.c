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
 * @file gic.c
 * @author Scott Chu
 * @date 2020-07-29
 */

/* Standard includes */
#include <stdio.h>

/* Altera hardware includes */
#include "alt_interrupt.h"
#include "alt_interrupt_common.h"


/**
 * @brief
 * 		Performs Initialization sequence for the GIC and calls the interrupt configurations
 */
void config_gic(void)
{
        alt_int_cpu_init();
        alt_int_cpu_enable_all();

        /* Configure interrupts */
        vRegisterIRQHandler(ALT_INT_INTERRUPT_CAN0_STS_IRQ, ( alt_int_callback_t ) FreeRTOS_Tick_Handler, NULL );
        config_interrupt(ALT_INT_INTERRUPT_CAN0_STS_IRQ, 0);
        alt_int_dist_trigger(ALT_INT_INTERRUPT_CAN0_STS_IRQ, ALT_INT_TRIGGER_LEVEL);

        vRegisterIRQHandler(ALT_INT_INTERRUPT_F2S_FPGA_IRQ0, ( alt_int_callback_t ) FreeRTOS_Tick_Handler, NULL );
        config_interrupt(ALT_INT_INTERRUPT_F2S_FPGA_IRQ0, 0);
        alt_int_dist_trigger(ALT_INT_INTERRUPT_F2S_FPGA_IRQ0, ALT_INT_TRIGGER_LEVEL);

        //alt_int_cpu_config_set
        alt_int_cpu_priority_mask_set(255);     // Allowing interrupts at all priorities
}


/**
 * @brief
 * 		Configures specified interrupts
 * @param int_id
 * 		Interrupt identifier
 * @param target
 * 		Target CPU which the interrupt is being forwarded to
 */
void config_interrupt(ALT_INT_INTERRUPT_t int_id, alt_int_cpu_target_t target)
{

        alt_int_dist_enable(int_id); // Enable the interrupt sourced from CAN controller (0 or 1)
        alt_int_dist_priority_set(int_id, 0); // Set the interrupt to highest priority
        alt_int_dist_target_set(int_id, target); // Set which CPU to foward interrupts to
}


/**
 * @brief
 * 		Configures specified interrupts
 * @param int_id
 * 		Interrupt identifier
 * @param target
 * 		Target CPU which the interrupt is being forwarded to
 */
int gic_init(void)
{
        alt_int_global_init(); // Interrupt controller Initialization
        alt_int_global_disable_all(); // Disable all interrupt forwarding from controller to CPU
        config_gic(); // Configures GIC

        // Waiting on interrupts
        for(;;);
}
