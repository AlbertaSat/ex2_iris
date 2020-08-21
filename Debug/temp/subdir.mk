################################################################################
# Automatically-generated file. Do not edit!
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
C_SRCS += \
../temp/iris_buffer.c 

C_DEPS += \
./temp/iris_buffer.d 

OBJS += \
./temp/iris_buffer.o 


# Each subdirectory must supply rules for building sources it contributes
temp/%.o: ../temp/%.c
	@echo 'Building file: $<'
	@echo 'Invoking: ARM C Compiler 5'
	armcc -I"/home/scott/electra_hps/test1/Altera_Code/HardwareLibrary/include/socal" -I"/home/scott/electra_hps/test1/Altera_Code/SoCSupport/include" -I"/home/scott/electra_hps/test1/Altera_Code/SoCSupport/include" -I"/home/scott/electra_hps/test1/Altera_Code/HardwareLibrary/include" -O0 -g --md --depend_format=unix_escaped --no_depend_system_headers --depend_dir="temp" -c -o "$@" "$<"
	@echo 'Finished building: $<'
	@echo ' '


