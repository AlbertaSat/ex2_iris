#include "spi.h"


/** @fn void spi_Melexis_Init(void)
*   @brief Initializes the SPI module for use
*   with melexis sensor
*/
void spi_Melexis_Init(void){
    /** bring SPI out of reset */
    spiREG4->GCR0 = 0U;
    spiREG4->GCR0 = 1U;

    /** SPI4 enable pin configuration */
//    spiREG4->INT0 = (spiREG4->INT0 & 0xFEFFFFFFU) | (uint32)((uint32)0U << 24U);  /* ENABLE HIGH Z */

    spiREG4->PC0  =   (uint32)((uint32)1U << 0U)  /* Enable CS 0 pin */
                    | (uint32)((uint32)0U << 8U)  /* Disable spiena */
                    | (uint32)((uint32)1U << 9U)  /* Enable CLK */
                    | (uint32)((uint32)1U << 10U) /* Enable MOSI */
                    | (uint32)((uint32)1U << 11U) /* Enable MISO */
                    | (uint32)((uint32)1U << 24U) /* Sets MISO pin 0 to functional */
                    | (uint32)((uint32)1U << 16U); /* Sets MOSI pin 0 to functional */

    /** SPI4 master mode and clock configuration */
    spiREG4->GCR1 = (spiREG4->GCR1 & 0xFFFFFFFCU) | ((uint32)((uint32)1U << 1U)  /* CLOKMOD */
                  | 1U);  /* MASTER */


}
