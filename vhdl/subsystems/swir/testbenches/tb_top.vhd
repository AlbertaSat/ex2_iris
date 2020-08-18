library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.swir_types.all;

entity tb_top is 
end entity;

architecture sim of tb_top is 
	component swir_subsystem is
	port (
		clock           : in std_logic;
        reset_n         : in std_logic;
        
        config          : in swir_config_t;
        control         : out swir_control_t;
        config_done     : out std_logic;
        
        do_imaging      : in std_logic;

        row             : out swir_row_t;
        row_available   : out std_logic;
		
		-- Signals to ADC
		sdi				: out std_logic;
		sdo				: in std_logic;
		sck				: out std_logic;
		cnv				: out std_logic;
		
		-- Signals to SWIR sensor
        sensor_clock_even   : out std_logic;
		sensor_clock_odd    : out std_logic;
        sensor_reset_even   : out std_logic;
		sensor_reset_odd    : out std_logic;
		Cf_select1			: out std_logic;
		Cf_select1			: out std_logic;
		AD_sp_even			: in std_logic;
		AD_sp_odd			: in std_logic;
		AD_trig_even		: in std_logic;
		AD_trig_odd			: in std_logic
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
		
		do_imaging			: out std_logic;
		
		row             	: in swir_row_t;
        row_available   	: in std_logic
	);
	end component tb_fpga;
	
	signal fpga_clock				:	std_logic;
	signal fpga_reset_n				:	std_logic;
	signal fpga_do_imaging			:	std_logic;
	signal fpga_row					:	swir_row_t;
	signal fpga_row_available		:	std_logic;
	
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
	
begin
	
	main_circuit : component swir_subsystem  -- Code to be tested
	port map (
		clock           	=>	fpga_clock,
        reset_n         	=>  fpga_reset_n,
        
        config          	=>	-- REVIEW
        control         	=>	
        config_done     	=>	
        
        do_imaging      	=>	fpga_do_imaging,

        row             	=>	fpga_row,
        row_available   	=>	fpga_row_available,
		
		-- Signals to ADC
		sdi					=>	adc_sdi,
		sdo					=>	adc_sck,
		sck					=>	adc_cnv,
		cnv					=>	adc_sdo,
		
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
		AD_trig_odd			=>	swir_AD_trig_odd
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
		                        
	    video_in			=>	swir_video_even
	);
	
	fpga_to_swir_subsystem : component tb_fpga is  -- Testbench
	port map(
		fpga_clock			=>	fpga_clock,
		reset_n         	=>  fpga_reset_n,	
		
		do_imaging			=>  fpga_do_imaging,
		
		row             	=>	fpga_row,
        row_available   	=>  fpga_row_available
	);

