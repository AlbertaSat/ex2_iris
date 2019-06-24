#include "spi.h"
#include "FreeRTOS.h"
#include "FreeRTOSConfig.h"
#include "gio.h"


struct MelexisCommands{
    //only the first control byte (command id) is specified here
    //remaining control bytes in a command need to be set appropriately when used
    uint32 NOP; //idle
    uint32 CR; //chip reset
    uint32 RT; //read threshold
    uint32 WT; //write threshold
    uint32 SI; //start integration, integration time set to 0 initially
    uint32 SIL; //start integration long, " "
    uint32 RO1; //read-out 1 bit
    uint32 RO2; //read-out 2 bit
    uint32 R04; //read-out 4 bit
    uint32 RO8; //read-out 8 bit
    uint32 TZ1; //Test Zebra Pattern 1
    uint32 TZ2; //Test Zebra Pattern 2
    uint32 TZ12; //Test Zebra Pattern 1&2
    uint32 TZ0; //Test Zebra Pattern 0
    uint32 SM; //Sleep Mode
    uint32 WU; //Wake Up
}melexisCommands;

void initCommandStructure(){
    melexisCommands.NOP = (uint32)0U;
    melexisCommands.CR = (uint32)0xF00000U;
    melexisCommands.RT = (uint32)0xD80000;
    melexisCommands.WT  = (uint32)0xCCB300;
    melexisCommands.SI = (uint32)0xB80000;
    melexisCommands.SIL = (uint32)0xB40000;
    melexisCommands.RO1  = (uint32)0x9C0000;
    melexisCommands.RO2 = (uint32)0x960000;
    melexisCommands.R04 = (uint32)0x930000;
    melexisCommands.RO8 = (uint32)0x990000;
    melexisCommands.TZ1 = (uint32)0xE80000;
    melexisCommands.TZ2 = (uint32)0xE40000;
    melexisCommands.TZ12 = (uint32)0xE20000;
    melexisCommands.TZ0 = (uint32)0xE10000;
    melexisCommands.SM = (uint32)0xC60000;
    melexisCommands.WU = (uint32)0xC30000;
}

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

    /** - Finally start SPI4 */
    spiREG4->GCR1 = (spiREG4->GCR1 & 0xFEFFFFFFU) | 0x01000000U;
}

void transferFirstPart(uint32 command){
    spiREG4->FMT0 = spiREG4->FMT0 | (uint32)((uint32)16U << 0U); //reset the data word length to 16
    spiREG4->DAT1 = spiREG4->DAT1 & (uint32)0U //clear the dat registers
                  | (uint32)((uint32)1U << 28) //set cs hold
                  | (uint32)(command >> 8); //removes the 8 LSB bits, writes first 16 bits of command
}

void transferSecondPart(uint32 command){
    spiREG4->FMT0 = spiREG4->FMT0 | (uint32)((uint32)8U << 0U); //reset data word length to 8
    spiREG4->DAT1 = spiREG4->DAT1 & (uint32)0U //clear the dat registers
                  | (uint32)((uint32)1U << 26) //set wdel
                  | (uint32)((uint32)(command & (uint32)255U)); //write only the 8 LSB bits of command
}

void transmitAndReceive(spiBASE_t* spi, uint32 command, uint16* destbuf){
    uint32 transferCount = 0;
    while(transferCount < 2){
//        xSemaphoreTake(semphr, portMAX_DELAY);
        if(transferCount == 0){
            transferFirstPart(command);
        }
        else{
            transferSecondPart(command);
        }
        while((spi->FLG & 0x00000100U) != 0x00000100U){}//wait until we receive data
        *destbuf = (uint16)spi->BUF;
        destbuf++;
        transferCount++;
//        xSemaphoreGive(semphr);
    }
}

//void receiveSanityByte(spiBASE_t* spi, uint32 blocksize, uint16* destbuf){
//    while(blocksize > 0){
//        xSemaphoreTake(semphr, portMAX_DELAY);
//
//    }
//}

void sanityByteTest(){
//    INCLUDE_vTaskSuspend = 1; //all tasks to block indefinitely
    uint16* destbuf;
    transmitAndReceive(spiREG4, melexisCommands.WU, destbuf);
    uint16 sanityByte = (uint16)(destbuf[0] & 0x00U);
    uint16 commandCounter = (uint16)(sanityByte & 0x1F);
    if(commandCounter == 0){
        gioToggleBit(gioPORTB,1);
    }
}

