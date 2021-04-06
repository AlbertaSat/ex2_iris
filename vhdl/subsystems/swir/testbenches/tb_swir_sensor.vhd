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

-- Testbench to simulate behaviour of g11508 short-wave infrared sensor

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_swir_sensor is
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
end entity;

architecture sim of tb_swir_sensor is 
	component tb_swir_half_sensor is
	port (
		sensor_clock		: in std_logic;
        sensor_reset        : in std_logic;

		AD_sp				: out std_logic;
		AD_trig				: out std_logic;
		video				: out integer;
		
		data_sel			: in integer
    );
	end component tb_swir_half_sensor;
	
begin

	sensor_odd : component tb_swir_half_sensor
	port map(
		sensor_clock		=> sensor_clock_odd,
        sensor_reset        => sensor_reset_odd,

		AD_sp				=> AD_sp_odd,
		AD_trig				=> AD_trig_odd,
		video				=> video_odd,
		
		data_sel			=> 1
    );
	
	sensor_even : component tb_swir_half_sensor
	port map(
		sensor_clock		=> sensor_clock_even,
        sensor_reset        => sensor_reset_even,

		AD_sp				=> AD_sp_even,
		AD_trig				=> AD_trig_even,
		video				=> video_even,
		
		data_sel			=> 0
    );
	
	-- Check that cf signal are of acceptable values
	assert ((Cf_select1 = '1' and Cf_select2 = '1') or (Cf_select1 = '1' and Cf_select2 = '0')) 
		report "sensor cf undefined state" severity error;
		
end architecture;