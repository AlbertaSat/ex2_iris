################################################################################
# Automatically-generated file. Do not edit!
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
S_SRCS += \
../Altera_Code/HardwareLibrary/alt_interrupt_armcc.s 

C_SRCS += \
../Altera_Code/HardwareLibrary/alt_16550_uart.c \
../Altera_Code/HardwareLibrary/alt_address_space.c \
../Altera_Code/HardwareLibrary/alt_bridge_manager.c \
../Altera_Code/HardwareLibrary/alt_cache.c \
../Altera_Code/HardwareLibrary/alt_clock_manager.c \
../Altera_Code/HardwareLibrary/alt_dma.c \
../Altera_Code/HardwareLibrary/alt_dma_program.c \
../Altera_Code/HardwareLibrary/alt_ecc.c \
../Altera_Code/HardwareLibrary/alt_fpga_manager.c \
../Altera_Code/HardwareLibrary/alt_generalpurpose_io.c \
../Altera_Code/HardwareLibrary/alt_globaltmr.c \
../Altera_Code/HardwareLibrary/alt_i2c.c \
../Altera_Code/HardwareLibrary/alt_interrupt.c \
../Altera_Code/HardwareLibrary/alt_mmu.c \
../Altera_Code/HardwareLibrary/alt_nand.c \
../Altera_Code/HardwareLibrary/alt_qspi.c \
../Altera_Code/HardwareLibrary/alt_reset_manager.c \
../Altera_Code/HardwareLibrary/alt_sdmmc.c \
../Altera_Code/HardwareLibrary/alt_spi.c \
../Altera_Code/HardwareLibrary/alt_system_manager.c \
../Altera_Code/HardwareLibrary/alt_timers.c \
../Altera_Code/HardwareLibrary/alt_watchdog.c 

S_DEPS += \
./Altera_Code/HardwareLibrary/alt_interrupt_armcc.d 

C_DEPS += \
./Altera_Code/HardwareLibrary/alt_16550_uart.d \
./Altera_Code/HardwareLibrary/alt_address_space.d \
./Altera_Code/HardwareLibrary/alt_bridge_manager.d \
./Altera_Code/HardwareLibrary/alt_cache.d \
./Altera_Code/HardwareLibrary/alt_clock_manager.d \
./Altera_Code/HardwareLibrary/alt_dma.d \
./Altera_Code/HardwareLibrary/alt_dma_program.d \
./Altera_Code/HardwareLibrary/alt_ecc.d \
./Altera_Code/HardwareLibrary/alt_fpga_manager.d \
./Altera_Code/HardwareLibrary/alt_generalpurpose_io.d \
./Altera_Code/HardwareLibrary/alt_globaltmr.d \
./Altera_Code/HardwareLibrary/alt_i2c.d \
./Altera_Code/HardwareLibrary/alt_interrupt.d \
./Altera_Code/HardwareLibrary/alt_mmu.d \
./Altera_Code/HardwareLibrary/alt_nand.d \
./Altera_Code/HardwareLibrary/alt_qspi.d \
./Altera_Code/HardwareLibrary/alt_reset_manager.d \
./Altera_Code/HardwareLibrary/alt_sdmmc.d \
./Altera_Code/HardwareLibrary/alt_spi.d \
./Altera_Code/HardwareLibrary/alt_system_manager.d \
./Altera_Code/HardwareLibrary/alt_timers.d \
./Altera_Code/HardwareLibrary/alt_watchdog.d 

OBJS += \
./Altera_Code/HardwareLibrary/alt_16550_uart.o \
./Altera_Code/HardwareLibrary/alt_address_space.o \
./Altera_Code/HardwareLibrary/alt_bridge_manager.o \
./Altera_Code/HardwareLibrary/alt_cache.o \
./Altera_Code/HardwareLibrary/alt_clock_manager.o \
./Altera_Code/HardwareLibrary/alt_dma.o \
./Altera_Code/HardwareLibrary/alt_dma_program.o \
./Altera_Code/HardwareLibrary/alt_ecc.o \
./Altera_Code/HardwareLibrary/alt_fpga_manager.o \
./Altera_Code/HardwareLibrary/alt_generalpurpose_io.o \
./Altera_Code/HardwareLibrary/alt_globaltmr.o \
./Altera_Code/HardwareLibrary/alt_i2c.o \
./Altera_Code/HardwareLibrary/alt_interrupt.o \
./Altera_Code/HardwareLibrary/alt_interrupt_armcc.o \
./Altera_Code/HardwareLibrary/alt_mmu.o \
./Altera_Code/HardwareLibrary/alt_nand.o \
./Altera_Code/HardwareLibrary/alt_qspi.o \
./Altera_Code/HardwareLibrary/alt_reset_manager.o \
./Altera_Code/HardwareLibrary/alt_sdmmc.o \
./Altera_Code/HardwareLibrary/alt_spi.o \
./Altera_Code/HardwareLibrary/alt_system_manager.o \
./Altera_Code/HardwareLibrary/alt_timers.o \
./Altera_Code/HardwareLibrary/alt_watchdog.o 


# Each subdirectory must supply rules for building sources it contributes
Altera_Code/HardwareLibrary/%.o: ../Altera_Code/HardwareLibrary/%.c
	@echo 'Building file: $<'
	@echo 'Invoking: ARM C Compiler 5'
	armcc -I"/home/scott/electra_hps/test1/Altera_Code/HardwareLibrary/include/socal" -I"/home/scott/electra_hps/test1/Altera_Code/SoCSupport/include" -I"/home/scott/electra_hps/test1/Altera_Code/SoCSupport/include" -I"/home/scott/electra_hps/test1/Altera_Code/HardwareLibrary/include" -O0 -g --md --depend_format=unix_escaped --no_depend_system_headers --depend_dir="Altera_Code/HardwareLibrary" -c -o "$@" "$<"
	@echo 'Finished building: $<'
	@echo ' '

Altera_Code/HardwareLibrary/alt_interrupt_armcc.o: ../Altera_Code/HardwareLibrary/alt_interrupt_armcc.s
	@echo 'Building file: $<'
	@echo 'Invoking: ARM Assembler 5'
	armasm -g --md --depend_format=unix_escaped --depend="Altera_Code/HardwareLibrary/alt_interrupt_armcc.d" -o "$@" "$<"
	@echo 'Finished building: $<'
	@echo ' '


