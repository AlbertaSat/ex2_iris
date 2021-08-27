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

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- use work.avalonmm;
-- use work.vnir;
-- use work.sdram;

-- use work.img_buffer_pkg.all;
-- use work.swir_types.all;
-- use work.fpga.all;

entity master_write_tb is
end entity master_write_tb;

architecture sim of master_write_tb is

    constant clock_frequency    : integer := 50000000;  -- 20 MHz
    constant clock_period       : time := 1000 ms / clock_frequency;
 
    constant reset_period       : time := clock_period * 4;
 

    signal clock                    : std_logic := '1';
    signal reset_n                  : std_logic := '0';
    signal control_write_length     : std_logic_vector(25 downto 0);
    signal control_write_base       : std_logic_vector(25 downto 0);
    signal control_go               : std_logic;
    signal control_done             : std_logic;
    signal user_write_buffer        : std_logic;
    signal user_buffer_data         : std_logic_vector(127 downto 0);
    signal user_buffer_full         : std_logic;

 

    component ocram_test is
        port (
            clk_clk                             : in  std_logic                      := 'X';             -- clk
            master_write_control_fixed_location : in  std_logic                      := 'X';             -- fixed_location
            master_write_control_write_base     : in  std_logic_vector(25 downto 0)  := (others => 'X'); -- write_base
            master_write_control_write_length   : in  std_logic_vector(25 downto 0)  := (others => 'X'); -- write_length
            master_write_control_go             : in  std_logic                      := 'X';             -- go
            master_write_control_done           : out std_logic;                                         -- done
            master_write_user_write_buffer      : in  std_logic                      := 'X';             -- write_buffer
            master_write_user_buffer_input_data : in  std_logic_vector(127 downto 0) := (others => 'X'); -- buffer_input_data
            master_write_user_buffer_full       : out std_logic;                                         -- buffer_full
            reset_reset_n                       : in  std_logic                      := 'X'              -- reset_n
        );
    end component ocram_test;

begin 


    u0 : component ocram_test
    port map (
        clk_clk                             => clock,                                                   
        reset_reset_n                       => reset_n,                                                 
        master_write_control_fixed_location => '0',                                                     
        master_write_control_write_base     => control_write_base,            
        master_write_control_write_length   => control_write_length,   
        master_write_control_go             => control_go,             
        master_write_control_done           => control_done,           
        master_write_user_write_buffer      => user_write_buffer,      
        master_write_user_buffer_input_data => user_buffer_data,                
        master_write_user_buffer_full       => user_buffer_full        
    );


    reset_process: process
    begin
        reset_n <= '0';
        wait for reset_period; 
        reset_n <= '1';
        wait;
    end process reset_process;
                                      
    clock <= NOT clock after clock_period / 2;

    data_process: process
    begin
        control_go              <= '0';
        user_write_buffer       <= '0';
        user_buffer_data        <= (others => '0');
        wait for reset_period * 10; 

        control_write_base      <= (others => '0');
        control_go              <= '1';
        control_write_length    <= std_logic_vector(to_unsigned(160, 26));
        wait for clock_period;

        control_go              <= '0';

        for i in 1 to 20 loop
            user_write_buffer           <= '1';
            user_buffer_data            <= std_logic_vector(to_unsigned(i, 128));
            wait for clock_period;
        end loop;
        wait; 
    end process data_process;

    

end architecture sim;
