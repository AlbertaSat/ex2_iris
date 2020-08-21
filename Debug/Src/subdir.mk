################################################################################
# Automatically-generated file. Do not edit!
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
C_SRCS += \
../Src/can.c \
../Src/init_seq.c \
../Src/interrupt.c \
../Src/main.c 

C_DEPS += \
./Src/can.d \
./Src/init_seq.d \
./Src/interrupt.d \
./Src/main.d 

OBJS += \
./Src/can.o \
./Src/init_seq.o \
./Src/interrupt.o \
./Src/main.o 


# Each subdirectory must supply rules for building sources it contributes
Src/%.o: ../Src/%.c
	@echo 'Building file: $<'
	@echo 'Invoking: ARM C Compiler 5'
	armcc -I"/home/scott/electra_hps/test1/Altera_Code/HardwareLibrary/include/socal" -I"/home/scott/electra_hps/test1/Altera_Code/SoCSupport/include" -I"/home/scott/electra_hps/test1/Altera_Code/SoCSupport/include" -I"/home/scott/electra_hps/test1/Altera_Code/HardwareLibrary/include" -O0 -g --md --depend_format=unix_escaped --no_depend_system_headers --depend_dir="Src" -c -o "$@" "$<"
	@echo 'Finished building: $<'
	@echo ' '


