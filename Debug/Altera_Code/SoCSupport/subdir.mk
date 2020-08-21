################################################################################
# Automatically-generated file. Do not edit!
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
C_SRCS += \
../Altera_Code/SoCSupport/cache_support.c \
../Altera_Code/SoCSupport/fpga_support.c \
../Altera_Code/SoCSupport/mmu_support.c \
../Altera_Code/SoCSupport/uart0_support.c 

C_DEPS += \
./Altera_Code/SoCSupport/cache_support.d \
./Altera_Code/SoCSupport/fpga_support.d \
./Altera_Code/SoCSupport/mmu_support.d \
./Altera_Code/SoCSupport/uart0_support.d 

OBJS += \
./Altera_Code/SoCSupport/cache_support.o \
./Altera_Code/SoCSupport/fpga_support.o \
./Altera_Code/SoCSupport/mmu_support.o \
./Altera_Code/SoCSupport/uart0_support.o 


# Each subdirectory must supply rules for building sources it contributes
Altera_Code/SoCSupport/%.o: ../Altera_Code/SoCSupport/%.c
	@echo 'Building file: $<'
	@echo 'Invoking: ARM C Compiler 5'
	armcc -I"/home/scott/electra_hps/test1/Altera_Code/HardwareLibrary/include/socal" -I"/home/scott/electra_hps/test1/Altera_Code/SoCSupport/include" -I"/home/scott/electra_hps/test1/Altera_Code/SoCSupport/include" -I"/home/scott/electra_hps/test1/Altera_Code/HardwareLibrary/include" -O0 -g --md --depend_format=unix_escaped --no_depend_system_headers --depend_dir="Altera_Code/SoCSupport" -c -o "$@" "$<"
	@echo 'Finished building: $<'
	@echo ' '


