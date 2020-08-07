/* Standard includes */
#include <stdio.h>
#include <stddef.h>

/* Scheduler include files */
#include "FreeRTOS.h"
#include "task.h"
#include "semphr.h"

/* Altera hardware lib includes */
#include "alt_bridge_manager.h"


/* HPS includes */
#include "gic.c"
#include "init_seq"




int main(void)
{
        /* Configuring HPS General Interrupt Controller */
        alt_int_global_init(); // Interrupt controller Initialization
        alt_int_global_disable_all(); // Disable all interrupt forwarding from controller to CPU
        config_gic(); // Configures GIC

        /* Initialization sequence for FPGA subsystem */
        init_sequence()


        // Waiting on interrupts
        for(;;);
}
