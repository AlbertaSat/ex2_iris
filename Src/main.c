/* Standard includes */
#include <stdio.h>
#include <stddef.h>

/* Scheduler include files */
#include "FreeRTOS.h"
#include "task.h"
#include "semphr.h"

void vConfigureInterrupts(void)
{


}

void vApplicationIRQHandler(uint32_t ulICCIAR)
{

}

int main(void)
{
        /* Initialize CAN controller */

        /* Configuring HPS General Interrupt Controller */
        alt_int_global_init(); // Interrupt controller Initialization
        alt_int_global_disable_all(); // Disable all interrupt forwarding from controller to CPU
        config_gic(); // Configures GIC

        /* Initialization sequence for FPGA subsystem */
        init_sequence()


        // Waiting on interrupts
        for(;;);
}
