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

    /** - Data Format 0 */
    spiREG4->FMT0 = (uint32)((uint32)5U << 24U)  /* wdelay */
                  | (uint32)((uint32)0U << 23U)  /* parity Polarity */
                  | (uint32)((uint32)0U << 22U)  /* parity enable */
                  | (uint32)((uint32)0U << 21U)  /* wait on enable */
                  | (uint32)((uint32)0U << 20U)  /* shift direction */
                  | (uint32)((uint32)1U << 17U)  /* clock polarity */
                  | (uint32)((uint32)0U << 16U)  /* clock phase */
                  | (uint32)((uint32)44U << 8U) /* baudrate prescale */
                  | (uint32)((uint32)16U << 0U);  /* data word length, must be changed for second part of command transfer */

    /** - Delays */
    spiREG4->DELAY = (uint32)((uint32)6U << 24U)  /* C2TDELAY */
                   | (uint32)((uint32)7U << 16U)  /* T2CDELAY */
                   | (uint32)((uint32)0U << 8U)   /* T2EDELAY */
                   | (uint32)((uint32)0U << 0U);  /* C2EDELAY */

}
