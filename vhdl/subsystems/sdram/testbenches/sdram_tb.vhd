library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.vnir;
use work.sdram;

use work.img_buffer_pkg.all;
use work.custom_master_pkg.all;
use work.swir_types.all;
use work.fpga.all;

entity sdram_tb is
end entity sdram_tb;

architecture sim of sdram_tb is

    -- components 
    component ocram_test is
		port (
			clk_clk                             : in  std_logic                      := 'X';             -- clk
			reset_reset_n                       : in  std_logic                      := 'X';             -- reset_n
			master_write_control_fixed_location : in  std_logic                      := 'X';             -- fixed_location
			master_write_control_write_base     : in  std_logic_vector(25 downto 0)  := (others => 'X'); -- write_base
			master_write_control_write_length   : in  std_logic_vector(25 downto 0)  := (others => 'X'); -- write_length
			master_write_control_go             : in  std_logic                      := 'X';             -- go
			master_write_control_done           : out std_logic;                                         -- done
			master_write_user_write_buffer      : in  std_logic                      := 'X';             -- write_buffer
			master_write_user_buffer_input_data : in  std_logic_vector(127 downto 0) := (others => 'X'); -- buffer_input_data
			master_write_user_buffer_full       : out std_logic                                          -- buffer_full
		);
	end component ocram_test;

    
   constant clock_frequency    : integer := 50000000;  -- 20 MHz
   constant clock_period       : time := 1000 ms / clock_frequency;

   constant reset_period       : time := clock_period * 4;
   
   constant vnir_row_clocks    : time := clock_period * 128; -- clock cycles between VNIR rows
   constant vnir_frame_clocks  : time := clock_period * 3000;

   constant swir_pxl_clocks    : time := clock_period * 64; -- clock cycles between SWIR pixels (1 clock cycle in 0.78125MHz clock, 50/0.78125 = 64)
   constant swir_row_clocks    : time := swir_pxl_clocks * 25; -- clock cycles between SWIR rows
   
   -- Control inputs
   signal clock                : std_logic := '1';
   signal reset_n              : std_logic := '0';

   -- Data inputs
   signal vnir_row             : vnir.row_t := (others => "1111111111");
   signal vnir_row_rdy         : vnir.row_type_t := vnir.ROW_NONE;
   signal swir_pixel           : swir_pixel_t := "1010101010101010";
   signal swir_pxl_rdy         : std_logic := '0';

   -- Imaging Buffer <=> Command Creator 
   signal row_req              : std_logic := '0'; -- input row request
   signal transmitting_o       : std_logic;        -- output flag
   signal row_data             : row_fragment_t;
   signal row_type             : sdram.row_type_t;


   signal vnir_img_header      : sdram.header_t;
   signal swir_img_header      : sdram.header_t;
   signal address              : sdram.address_t;
   signal sdram_busy           : std_logic;
   signal master_cmd_in        : from_master_t;
   signal master_cmd_out       : to_master_t;


begin
    
    imaging_buffer_component : entity work.imaging_buffer port map(
        clock               => clock,                   -- external input
        reset_n             => reset_n,                 -- external input
        vnir_row            => vnir_row,                -- external input
        vnir_row_ready      => vnir_row_rdy,            -- external input
        swir_pixel          => swir_pixel,              -- external input
        swir_pixel_ready    => swir_pxl_rdy,            -- external input
        row_request         => row_req,                 -- imaging_buffer <==  command_creator
        fragment_out        => row_data,                -- imaging_buffer  ==> command_creator
        fragment_type       => row_type,                -- imaging_buffer  ==> command_creator
        transmitting        => transmitting_o           -- imaging_buffer  ==> command_creator
    );

    command_creator_component : entity work.command_creator port map(
        clock               => clock,                   -- external input
        reset_n             => reset_n,                 -- external input
        vnir_img_header     => vnir_img_header,         -- header_creator  ==> command_creator
        swir_img_header     => swir_img_header,         -- header_creator  ==> command_creator
        row_data            => row_data,                -- imaging_buffer  ==> command_creator
        row_type            => row_type,                -- imaging_buffer  ==> command_creator
        buffer_transmitting => transmitting_o,          -- imaging_buffer  ==> command_creator
        address             => address,                 -- memory_map      ==> command_creator
        next_row_req        => row_req,                 -- imaging_buffer <==  command_creator
        sdram_busy          => sdram_busy,              -- external output   
        master_cmd_in       => master_cmd_in,
        master_cmd_out      => master_cmd_out
    );

    u0 : component ocram_test
    port map (
        clk_clk                             => clock,                                                   
        reset_reset_n                       => reset_n,                                                 
        master_write_control_fixed_location => master_cmd_out.control_fixed_location,                                                     
        master_write_control_write_base     => master_cmd_out.control_write_base,            
        master_write_control_write_length   => master_cmd_out.control_write_length,   
        master_write_control_go             => master_cmd_out.control_go,             
        master_write_control_done           => master_cmd_in.control_done,           
        master_write_user_write_buffer      => master_cmd_out.user_write_buffer,      
        master_write_user_buffer_input_data => master_cmd_out.user_buffer_data,                
        master_write_user_buffer_full       => master_cmd_in.user_buffer_full        
    );

    clock <= not clock after clock_period / 2;

    reset_process: process
    begin
        reset_n <= '0';
        wait for reset_period; 
        reset_n <= '1';
        wait;
    end process reset_process;

    -- VNIR functionality 
    -- during normal operation, the VNIR subsystem will emit three rows (red, blue and NIR) in a burst 
    -- when it finishes exposing a frame. The pixel integrator operates on one 16-pixel fragment per 
    -- clock cycle, so these rows will be separated by 2048/16=128 clock cycles during the burst. 
    -- The time between bursts depends on the desired frame-rate. It should be about equal to 
    -- (frame_clocks - 3*128), though there may be some inconsistencies here due to clock domain crossing.

    -- The behaviour described above is also the worst case. In some cases (at the beginning and end of an image) 
    -- the burst will consist of only 1 or 2 rows. They should still be separated by 128 clock cycles.

    vnir_process: process
    begin
        for i in 0 to 2047 loop
            vnir_row(i) <= to_unsigned(i, 10);
        end loop;
        wait for reset_period; 

        for i in 1 to 100 loop
            vnir_row_rdy <= vnir.ROW_RED;
            wait until rising_edge(clock);
            vnir_row_rdy <= vnir.ROW_NONE;
            wait for vnir_row_clocks;

            vnir_row_rdy <= vnir.ROW_BLUE;
            wait until rising_edge(clock);
            vnir_row_rdy <= vnir.ROW_NONE;
            wait for vnir_row_clocks;

            vnir_row_rdy <= vnir.ROW_NIR;
            wait until rising_edge(clock);
            vnir_row_rdy <= vnir.ROW_NONE;
            wait for (vnir_frame_clocks-3*vnir_row_clocks);
        end loop;
        wait;
    end process vnir_process;

    -- Duration of each swir pixel: worst case: ~1000 ns; normal: ~1300 ns
    -- A row is 512 pixels, so takes 512 swir clock cycles to arrive, 
    -- where the swir clock is 0.78125 MHz. The time between rows is ~30 clock cycles
    -- swir_pxl_ready is sent on the 50MHz clock, same as the pixel.
    
    swir_process: process is
    begin
        wait for reset_period; 
        for i in 1 to 10 loop 
            for i in 1 to 512 loop -- one row of 512 pixels
                wait until rising_edge(clock);
                swir_pxl_rdy <= '1';
                swir_pixel <= to_unsigned(i, swir_pixel'length);

                wait until rising_edge(clock);
                swir_pxl_rdy <= '0';   
                swir_pixel <= (others => '0');
                
                wait for swir_pxl_clocks;
            end loop;
            wait for swir_row_clocks; -- time between rows
        end loop;
        wait;
    end process swir_process;

    address <= (others => '0');

end architecture sim;