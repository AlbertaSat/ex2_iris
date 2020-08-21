/* Standard includes */
#include <stdio.h>
#include <stdint.h>
#include <stddef.h>

/* Scheduler include files */
//#include "FreeRTOS.h"
//#include "task.h"
//#include "semphr.h"

/* HPS includes */
#include "can.h"
#include "interrupt.c"
#include "init_seq.c"

enum States
{
        HPS_init,
        HPS_config,
        HPS_command
};


void vConfigureInterrupts(void)
{

}

void vApplicationIRQHandler(uint32_t ulICCIAR)
{

}



int main(void)
{
        enum States state;
        state = HPS_init;

        while (state == HPS_init) {
                /* Initialize CAN controller */
                can_init();

                /* Configuring HPS General Interrupt Controller */
                alt_int_global_init();
                alt_int_global_disable_all();
                config_gic();

                state = HPS_config;
        }



        /* Initialization sequence for FPGA subsystem */
        init_sequence();

        /* Start Scheduler */
        vTaskStartScheduler();

        // Waiting on interrupts
        for(;;);
}

//void vApplicationIRQHandler( uint32_t ulICCIAR )
//{
//uint32_t ulInterruptID;
//void *pvContext;
//alt_int_callback_t pxISR;
//
//	/* Re-enable interrupts. */
//    __asm ( "cpsie i" );
//
//	/* The ID of the interrupt is obtained by bitwise anding the ICCIAR value
//	with 0x3FF. */
//	ulInterruptID = ulICCIAR & 0x3FFUL;
//
//	if( ulInterruptID < ALT_INT_PROVISION_INT_COUNT )
//	{
//		/* Call the function installed in the array of installed handler
//		functions. */
//		pxISR = xISRHandlers[ ulInterruptID ].pxISR;
//		pvContext = xISRHandlers[ ulInterruptID ].pvContext;
//		pxISR( ulICCIAR, pvContext );
//	}
//}
