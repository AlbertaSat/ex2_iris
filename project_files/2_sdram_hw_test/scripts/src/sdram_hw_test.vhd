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
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

use work.vnir;
use work.sdram;

use work.img_buffer_pkg.all;
use work.custom_master_pkg.all;
use work.swir_types.all;
use work.fpga.all;

entity sdram_hw_test is
  port (

    -- clocks 
    FPGA_CLK2_50 : in std_logic;

    -- SDRAM IO
    HPS_DDR3_ADDR    : out std_logic_vector(14 downto 0);
    HPS_DDR3_BA      : out std_logic_vector(2 downto 0);
    HPS_DDR3_CAS_N   : out std_logic;
    HPS_DDR3_CKE     : out std_logic;
    HPS_DDR3_CK_N    : out std_logic;
    HPS_DDR3_CK_P    : out std_logic;
    HPS_DDR3_CS_N    : out std_logic;
    HPS_DDR3_DM      : out std_logic_vector(3 downto 0);
    HPS_DDR3_DQ      : inout std_logic_vector(31 downto 0);
    HPS_DDR3_DQS_N   : inout std_logic_vector(3 downto 0);
    HPS_DDR3_DQS_P   : inout std_logic_vector(3 downto 0);
    HPS_DDR3_ODT     : out std_logic;
    HPS_DDR3_RAS_N   : out std_logic;
    HPS_DDR3_RESET_N : out std_logic;
    HPS_DDR3_RZQ     : in std_logic;
    HPS_DDR3_WE_N    : out std_logic;

    HPS_LED          : inout std_logic := 'X'
  );
end entity sdram_hw_test;

architecture rtl of sdram_hw_test is

  -- component declarations 
  component rw_test_sdram is
    port (
      clk_clk                             : in std_logic    := 'X'; 
      hps_io_hps_io_gpio_inst_GPIO53      : inout std_logic := 'X'; 
      memory_mem_a                        : out std_logic_vector(14 downto 0); 
      memory_mem_ba                       : out std_logic_vector(2 downto 0); 
      memory_mem_ck                       : out std_logic; 
      memory_mem_ck_n                     : out std_logic; 
      memory_mem_cke                      : out std_logic; 
      memory_mem_cs_n                     : out std_logic; 
      memory_mem_ras_n                    : out std_logic; 
      memory_mem_cas_n                    : out std_logic; 
      memory_mem_we_n                     : out std_logic; 
      memory_mem_reset_n                  : out std_logic; 
      memory_mem_dq                       : inout std_logic_vector(31 downto 0) := (others => 'X'); 
      memory_mem_dqs                      : inout std_logic_vector(3 downto 0)  := (others => 'X'); 
      memory_mem_dqs_n                    : inout std_logic_vector(3 downto 0)  := (others => 'X'); 
      memory_mem_odt                      : out std_logic; 
      memory_mem_dm                       : out std_logic_vector(3 downto 0); 
      memory_oct_rzqin                    : in std_logic                     := 'X'; 
      write_master_control_fixed_location : in std_logic                     := 'X'; 
      write_master_control_write_base     : in std_logic_vector(31 downto 0) := (others => 'X'); 
      write_master_control_write_length   : in std_logic_vector(31 downto 0) := (others => 'X'); 
      write_master_control_go             : in std_logic                     := 'X'; 
      write_master_control_done           : out std_logic; 
      write_master_user_write_buffer      : in std_logic                      := 'X'; 
      write_master_user_buffer_input_data : in std_logic_vector(127 downto 0) := (others => 'X'); 
      write_master_user_buffer_full       : out std_logic; 
      reset_reset_n                       : in std_logic := 'X'; 
      hps_0_h2f_reset_reset_n             : out std_logic 
    );
  end component rw_test_sdram;

  -- SIGNALS

  -- inputs
  signal clock          : std_logic;
  signal reset_n        : std_logic;
  signal reset_clocks   : integer := 10;  -- Hold reset for 10 clock cycles on startup
  signal test_countdown : integer := 120*50000000; -- 120 seconds

  -- wires
  signal write_master_cmd_in  : from_master_t;
  signal write_master_cmd_out : to_master_t;

  signal h2f_reset      : std_logic;

  -- Data inputs
  signal vnir_row       : vnir.row_t      := (others => "1111111111");
  signal vnir_row_rdy   : vnir.row_type_t := vnir.ROW_NONE;
  signal swir_pixel     : swir_pixel_t    := "1010101010101010";
  signal swir_pxl_rdy   : std_logic       := '0';
  signal swir_pxl_count : integer range 0 to 512;

  -- wires: Imaging Buffer <=> Command Creator 
  signal row_req        : std_logic := '0'; -- input row request
  signal transmitting_o : std_logic; -- output flag
  signal row_data       : row_fragment_t;
  signal row_type       : sdram.row_type_t;

  signal vnir_img_header : sdram.header_t;
  signal swir_img_header : sdram.header_t;
  signal address         : sdram.address_t;
  signal sdram_busy      : std_logic;

  -- state machine 
  type sm_top_type is (s0_reset, s1_data_in, s1_data_wait, s2_end);
    signal sm_state : sm_top_type; -- Register to hold the current state

    -- Attribute "safe" implements a safe state machine. 
    -- It can recover from an illegal state (by returning to the reset state).
    attribute syn_encoding                : string;
    attribute syn_encoding of sm_top_type : type is "safe";

begin

  -- component instantiations
  u0 : component rw_test_sdram
    port map(
      clk_clk => clock,
      hps_io_hps_io_gpio_inst_GPIO53      => HPS_LED,
      memory_mem_a                        => HPS_DDR3_ADDR,
      memory_mem_ba                       => HPS_DDR3_BA,
      memory_mem_ck                       => HPS_DDR3_CK_P,
      memory_mem_ck_n                     => HPS_DDR3_CK_N,
      memory_mem_cke                      => HPS_DDR3_CKE,
      memory_mem_cs_n                     => HPS_DDR3_CS_N,
      memory_mem_ras_n                    => HPS_DDR3_RAS_N,
      memory_mem_cas_n                    => HPS_DDR3_CAS_N,
      memory_mem_we_n                     => HPS_DDR3_WE_N,
      memory_mem_reset_n                  => HPS_DDR3_RESET_N,
      memory_mem_dq                       => HPS_DDR3_DQ,
      memory_mem_dqs                      => HPS_DDR3_DQS_P,
      memory_mem_dqs_n                    => HPS_DDR3_DQS_N,
      memory_mem_odt                      => HPS_DDR3_ODT,
      memory_mem_dm                       => HPS_DDR3_DM,
      memory_oct_rzqin                    => HPS_DDR3_RZQ,
      write_master_control_fixed_location => write_master_cmd_out.control_fixed_location,
      write_master_control_write_base     => write_master_cmd_out.control_write_base,
      write_master_control_write_length   => write_master_cmd_out.control_write_length,
      write_master_control_go             => write_master_cmd_out.control_go,
      write_master_control_done           => write_master_cmd_in.control_done,
      write_master_user_write_buffer      => write_master_cmd_out.user_write_buffer,
      write_master_user_buffer_input_data => write_master_cmd_out.user_buffer_data,
      write_master_user_buffer_full       => write_master_cmd_in.user_buffer_full,
      reset_reset_n                       => reset_n,
      hps_0_h2f_reset_reset_n             => h2f_reset
    );

    imaging_buffer_component : entity work.imaging_buffer port map(
      clock            => clock,          -- external input
      reset_n          => reset_n,        -- external input
      vnir_row         => vnir_row,       -- external input
      vnir_row_ready   => vnir_row_rdy,   -- external input
      swir_pixel       => swir_pixel,     -- external input
      swir_pixel_ready => swir_pxl_rdy,   -- external input
      row_request      => row_req,        -- imaging_buffer <==  command_creator
      fragment_out     => row_data,       -- imaging_buffer  ==> command_creator
      fragment_type    => row_type,       -- imaging_buffer  ==> command_creator
      transmitting     => transmitting_o  -- imaging_buffer  ==> command_creator
      );

    command_creator_component : entity work.command_creator port map(
      clock               => clock,               -- external input
      reset_n             => reset_n,             -- external input
      vnir_img_header     => vnir_img_header,     -- header_creator  ==> command_creator
      swir_img_header     => swir_img_header,     -- header_creator  ==> command_creator
      row_data            => row_data,            -- imaging_buffer  ==> command_creator
      row_type            => row_type,            -- imaging_buffer  ==> command_creator
      buffer_transmitting => transmitting_o,      -- imaging_buffer  ==> command_creator
      address             => address,             -- memory_map      ==> command_creator
      next_row_req        => row_req,             -- imaging_buffer <==  command_creator
      sdram_busy          => sdram_busy,          -- external output   
      master_cmd_in       => write_master_cmd_in,
      master_cmd_out      => write_master_cmd_out
      );

    -- PROCESSES

    -- reset process: Hold reset for 10 clock cycles on startup
    process (clock)
    begin
        if rising_edge(clock) then
            if reset_clocks > 0 then
                reset_clocks <= reset_clocks - 1;
                reset_n <= '0';
            else
                reset_n <= '1';
            end if;
        end if;
    end process;

    -- test countdown; allows you to program the preloader before starting the read & writes 
    process (clock)
    begin
        if rising_edge(clock) then
            if test_countdown > 0 then
                test_countdown <= test_countdown - 1;
            else
                test_countdown <= 0;
            end if;
        end if;
    end process;

    -- state machine : state transfers
    process_sm_transfers : process (clock, reset_n) is
    begin
      if (reset_n = '0') then
        sm_state <= s0_reset;
      elsif rising_edge(clock) then
        case sm_state is
          when s0_reset =>
            if (reset_n = '1' and test_countdown = 0) then
              sm_state <= s1_data_in;
            else
              sm_state <= s0_reset;
            end if;
          when s1_data_in =>
            sm_state <= s1_data_wait;
          when s1_data_wait =>
            if (swir_pxl_count = 512) then
              sm_state <= s2_end;
            else
              sm_state <= s1_data_in;
            end if;
          when s2_end =>
            sm_state <= s2_end;
        end case;
      end if;
    end process process_sm_transfers;
    
    -- giving inputs to the imaging buffer
    swir_model_process : process (clock) is
    begin
      if rising_edge(clock) then
        case sm_state is
          when s1_data_in =>
            swir_pxl_rdy   <= '1';
            swir_pxl_count <= swir_pxl_count + 1;
            swir_pixel     <= stdlogicvector_to_swir_pixel(std_logic_vector(to_unsigned(swir_pxl_count, swir_pixel'length)));
          when s1_data_wait =>
            swir_pxl_rdy   <= '0';
            swir_pxl_count <= swir_pxl_count;
            swir_pixel     <= stdlogicvector_to_swir_pixel(std_logic_vector(to_unsigned(0, swir_pixel'length)));
          when others =>
            swir_pxl_rdy   <= '0';
            swir_pxl_count <= 0;
            swir_pixel     <= stdlogicvector_to_swir_pixel(std_logic_vector(to_unsigned(0, swir_pixel'length)));
        end case;
      end if;
    end process swir_model_process;

    address <= (others => '0');

    -- outside connections (I/O)
    clock <= FPGA_CLK2_50;

  end architecture rtl;