----------------------------------------------------------------
-- Copyright 2020 University of Alberta

-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at

--     http://www.apache.org/licenses/LICENSE-2.0

-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
----------------------------------------------------------------

-- Top level testbench that connects individual testbenches to DUT

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.swir_types.all;

entity tb_top is 
end entity;

architecture sim of tb_top is 
	component swir_subsystem is
	port (
		clock           	: in std_logic;
        reset_n         	: in std_logic;
		
		start_config		: in std_logic;
		config_done			: out std_logic;
        config          	: in swir_config_t;
        control         	: in swir_control_t;
			
        do_imaging      	: in std_logic;
	
		-- Signals to SDRAM subsystem
        pixel           	: out swir_pixel_t;
        pixel_available 	: out std_logic;
		
		-- Signals to ADC
		sdi					: out std_logic;
		sdo					: in std_logic;
		sck					: out std_logic;
		cnv					: out std_logic;
		
		-- Signals to SWIR sensor
        sensor_clock_even   : out std_logic;
		sensor_clock_odd    : out std_logic;
        sensor_reset_even   : out std_logic;
		sensor_reset_odd    : out std_logic;
		Cf_select1			: out std_logic;
		Cf_select2			: out std_logic;
		AD_sp_even			: in std_logic;
		AD_sp_odd			: in std_logic;
		AD_trig_even		: in std_logic;
		AD_trig_odd			: in std_logic;
		
		-- SWIR Voltage control
		SWIR_4V0			: out std_logic;	
		SWIR_1V2			: out std_logic;
				
		-- Signals to SWIR Switch
		sensor_clock		: out std_logic
	);
	end component swir_subsystem;
	
	component tb_swir_sensor is
	port (
		sensor_clock_even   : in std_logic;
	    sensor_clock_odd    : in std_logic;
	    sensor_reset_even   : in std_logic;
	    sensor_reset_odd    : in std_logic;
	    Cf_select1			: in std_logic;
	    Cf_select2			: in std_logic;
	    
	    AD_sp_even			: out std_logic;
	    AD_sp_odd			: out std_logic;
	    AD_trig_even		: out std_logic;
	    AD_trig_odd			: out std_logic;
	    
	    video_even			: out integer;
	    video_odd			: out integer
	);
	end component tb_swir_sensor;
	
	component tb_adc is
	port (
		sdi				: in std_logic;
	    sck				: in std_logic;
	    cnv				: in std_logic;
	    sdo				: out std_logic;
	    
	    video_in		: in integer
	);
	end component tb_adc;
	
	component tb_fpga is
	port (
		fpga_clock			: out std_logic;
		reset_n         	: out std_logic;
		
		start_config		: out std_logic;
		config_done			: in std_logic;
		config          	: out swir_config_t;
        control         	: out swir_control_t;
		
		do_imaging			: out std_logic;
		
		pixel           	: in swir_pixel_t;
        pixel_available 	: in std_logic
	);
	end component tb_fpga;
	
	component tb_switch is
	port (
		s1					: in integer;
		s2					: in integer;
        in_pin			  	: in std_logic;
		d				    : out integer
    );
	end component tb_switch;
	
	signal fpga_clk					:	std_logic;
	signal fpga_reset_n				:	std_logic;
	signal fpga_do_imaging			:	std_logic;
	signal fpga_pixel				:	swir_pixel_t;
	signal fpga_pixel_available		:	std_logic;
	signal fpga_config				:	swir_config_t;
	signal fpga_control				:   swir_control_t;
	signal fpga_start_config		:	std_logic;
	signal fpga_config_done			:   std_logic;
	
	signal adc_sdi					:	std_logic;
	signal adc_sck					:	std_logic;
	signal adc_cnv					:	std_logic;
	signal adc_sdo					:	std_logic;
	
	signal swir_sensor_clock_even	:	std_logic;
	signal swir_sensor_clock_odd	:	std_logic;
	signal swir_sensor_reset_even	:	std_logic;
	signal swir_sensor_reset_odd	:	std_logic;
	signal swir_Cf_select1			:	std_logic;
	signal swir_Cf_select2			:	std_logic;
	signal swir_AD_sp_even			:	std_logic;
	signal swir_AD_sp_odd			:	std_logic;
	signal swir_AD_trig_even		:	std_logic;
	signal swir_AD_trig_odd			:	std_logic;
	signal swir_video_even			:	integer;
	signal swir_video_odd			:	integer;
	signal swir_voltage_4V0			:	std_logic;
	signal swir_voltage_1V2			:	std_logic;
	signal swir_select				:	std_logic;
	signal swir_video				:	integer;
	
begin
	
	main_circuit : component swir_subsystem  -- Code to be tested
	port map (
		clock           	=>	fpga_clk,
        reset_n         	=>  fpga_reset_n,
        
		start_config		=>	fpga_start_config,
		config_done			=>	fpga_config_done,
        config          	=>	fpga_config,
        control         	=>	fpga_control,
        
        do_imaging      	=>	fpga_do_imaging,

        pixel             	=>	fpga_pixel,
        pixel_available   	=>	fpga_pixel_available,
		
		-- Signals to ADC
		sdi					=>	adc_sdi,
		sdo					=>	adc_sdo,
		sck					=>	adc_sck,
		cnv					=>	adc_cnv,
		
		-- Signals to SWIR sensor
        sensor_clock_even   =>	swir_sensor_clock_even,
		sensor_clock_odd    =>  swir_sensor_clock_odd,
        sensor_reset_even   =>  swir_sensor_reset_even,
		sensor_reset_odd    =>  swir_sensor_reset_odd,
		Cf_select1			=>  swir_Cf_select1,
		Cf_select2			=>  swir_Cf_select2,
		AD_sp_even			=>	swir_AD_sp_even,
		AD_sp_odd			=>	swir_AD_sp_odd,
		AD_trig_even		=>	swir_AD_trig_even,
		AD_trig_odd			=>	swir_AD_trig_odd,
		
		SWIR_4V0			=>	swir_voltage_4V0,
		SWIR_1V2			=>	swir_voltage_1V2,
		
		sensor_clock		=>	swir_select
	);
	
	g11508 : component tb_swir_sensor  -- Testbench
	port map(
		sensor_clock_even   =>	swir_sensor_clock_even,
	    sensor_clock_odd    =>	swir_sensor_clock_odd,
	    sensor_reset_even   =>	swir_sensor_reset_even,
	    sensor_reset_odd    =>	swir_sensor_reset_odd,
	    Cf_select1			=>	swir_Cf_select1,
	    Cf_select2			=>	swir_Cf_select2,
	    
	    AD_sp_even			=>	swir_AD_sp_even,
	    AD_sp_odd			=>  swir_AD_sp_odd,
	    AD_trig_even		=>  swir_AD_trig_even,
	    AD_trig_odd			=>  swir_AD_trig_odd,
		
	    video_even			=>	swir_video_even,
	    video_odd			=>  swir_video_odd
	);
	
	adaq7980 : component tb_adc	 -- Testbench
	port map(
		sdi					=>	adc_sdi,
	    sck					=>  adc_sck,	
	    cnv					=>  adc_cnv,	
	    sdo					=>  adc_sdo,	
		                        
	    video_in			=>	swir_video
	);
	
	fpga_to_swir_subsystem : component tb_fpga  -- Testbench
	port map(
		fpga_clock			=>	fpga_clk,
		reset_n         	=>  fpga_reset_n,	
		
		start_config		=>	fpga_start_config,
		config_done			=>	fpga_config_done,
		config          	=>	fpga_config,
        control         	=>	fpga_control,
		
		do_imaging			=>  fpga_do_imaging,
		
		pixel             	=>	fpga_pixel,
        pixel_available   	=>  fpga_pixel_available
	);

	adg719brmz : component tb_switch
	port map(
		s1					=> swir_video_odd,
		s2					=> swir_video_even,
        in_pin			  	=> swir_select,
		d				    => swir_video
    );


end architecture;