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

-- TODO: Generate clocks

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.swir_types.all;


entity swir_subsystem is
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
end entity swir_subsystem;


architecture rtl of swir_subsystem is

	component swir_sensor is
    port (
        clock_swir      	: in std_logic;
        reset_n         	: in std_logic;
        
        integration_time    : in integer;
		
		ce					: in std_logic;
		do_imaging      	: in std_logic;
		adc_trigger			: out std_logic;
		adc_start			: out std_logic;
	
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
	end component swir_sensor;

	component swir_adc is
	port (
        clock_adc	      	: in std_logic;
		clock_main			: in std_logic;
		clock_swir			: in std_logic;
        reset_n         	: in std_logic;
			
        row             	: out swir_row_t;
        row_available   	: out std_logic;
		
		adc_trigger			: in std_logic;
		adc_start			: in std_logic;
		
		sdi					: out std_logic;						
		sdo					: out std_logic;	
		cnv					: out std_logic;
		
		fifo_rdreq			: in std_logic;
		fifo_rdempty		: out std_logic;
		fifo_data_read		: out std_logic_vector(15 downto 0)
    );
	end component swir_adc;
	
begin
	
	sensor_control_circuit : component swir_sensor
    port map (
        clock_swir      	=>
        reset_n         	=>
        
        integration_time    =>
		
		ce					=>
		do_imaging      	=>
		adc_trigger			=>
		adc_start			=>
	
		-- Signals to SWIR sensor
        sensor_clock_even   =>
		sensor_clock_odd    =>
        sensor_reset_even   =>
		sensor_reset_odd    =>
		Cf_select1			=>
		Cf_select1			=>
		AD_sp_even			=>
		AD_sp_odd			=>
		AD_trig_even		=>
		AD_trig_odd			=>
    );

	adc_control_circuit : component swir_adc
	port map (
        clock_adc	      	=>
		clock_main			=>
		clock_swir			=>
        reset_n         	=>
			
        row             	=>
        row_available   	=>
		
		adc_trigger			=>
		adc_start			=>
		
		sdi					=>					
		sdo					=>
		cnv					=>
		
		fifo_rdreq			=>
		fifo_rdempty		=>
		fifo_data_read		=>
    );

	-- Stretch reset and do_imaging signal to pass into lower frequency SWIR domain
	
	-- 
	
	
end architecture rtl;