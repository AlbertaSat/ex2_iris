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

entity lvds_decoder_lvds_rx is
generic (
    n_channels : integer;
    bit_width  : integer
);
port (
    rx_channel_data_align   : in std_logic_vector (n_channels-1 downto 0);
    rx_in                   : in std_logic_vector (n_channels-1 downto 0);
    rx_inclock              : in std_logic;
    rx_out                  : out std_logic_vector (bit_width*n_channels-1 downto 0);
    rx_outclock             : out std_logic
);
end entity lvds_decoder_lvds_rx;


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity lvds_decoder_fifo is
generic (
    n_channels : integer;
    bit_width  : integer
);
port (
    aclr		: in std_logic;
    data		: in std_logic_vector(bit_width*n_channels-1 downto 0);
    rdclk		: in std_logic;
    rdreq		: in std_logic;
    wrclk		: in std_logic;
    wrreq		: in std_logic;
    q		    : out std_logic_vector(bit_width*n_channels-1 downto 0);
    rdempty		: out std_logic;
    wrfull		: out std_logic 
);
end entity lvds_decoder_fifo;


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.vnir_types.all;


entity lvds_decoder is
port (
    clock          : in std_logic;
    reset_n        : in std_logic;
    start_align    : in std_logic;
    align_done     : out std_logic;
    lvds_in        : in vnir_lvds_t;
    parallel_out   : out vnir_parallel_lvds_t;
    data_available : out std_logic
);
end entity lvds_decoder;


architecture rtl of lvds_decoder is

    constant control_target : vnir_pixel_t := (9 => '1', others => '0');

    constant n_channels : integer := vnir_lvds_data_width + 1; -- Include control
    constant bit_width : integer := vnir_pixel_bits;

    signal rx_channel_data_align : std_logic_vector (n_channels-1 downto 0);
    signal rx_in                 : std_logic_vector (n_channels-1 downto 0);
    signal rx_out                : std_logic_vector (bit_width*n_channels-1 downto 0);
    signal rx_outclock           : std_logic;

    signal control               : vnir_pixel_t;
    
    signal reset                 : std_logic;
    signal rdack                 : std_logic;
    signal q_out                 : std_logic_vector (bit_width*n_channels-1 downto 0);
    signal rdempty               : std_logic;

    signal start_align_rx_outclock : std_logic;
    signal align_done_rx_outclock  : std_logic;

    component cmd_cross_clock is
    port (
        reset_n : in std_logic;
        i_clock : in std_logic;
        i       : in std_logic;
        o_clock : in std_logic;
        o       : out std_logic
    );
    end component cmd_cross_clock;

    component lvds_decoder_fifo is
    generic (
        n_channels : integer;
        bit_width  : integer
    );
    port (
        aclr		: in std_logic;
        data		: in std_logic_vector(bit_width*n_channels-1 downto 0);
        rdclk		: in std_logic;
        rdreq		: in std_logic;
        wrclk		: in std_logic;
        wrreq		: in std_logic;
        q		    : out std_logic_vector(bit_width*n_channels-1 downto 0);
        rdempty		: out std_logic;
        wrfull		: out std_logic 
    );
    end component lvds_decoder_fifo;

    component lvds_decoder_lvds_rx is
    generic (
        n_channels : integer;
        bit_width  : integer
    );
    port (
        rx_channel_data_align   : in std_logic_vector (n_channels-1 downto 0);
        rx_in                   : in std_logic_vector (n_channels-1 downto 0);
        rx_inclock              : in std_logic;
        rx_out                  : out std_logic_vector (bit_width*n_channels-1 downto 0);
        rx_outclock             : out std_logic
    );
    end component lvds_decoder_lvds_rx;

    pure function calc_align_offset(
        control : vnir_pixel_t;
        control_target : vnir_pixel_t
        ) return integer is
    begin
        for i in 0 to vnir_pixel_bits-1 loop
            if rotate_right(control, i) = control_target then
                return i;
            end if;
        end loop;

        return 0;  -- TODO: trigger some kind of error if we get here
    end;

begin

    rx_in(0) <= lvds_in.control;
    flatten_inputs : for channel in 1 to n_channels-1 generate
        rx_in(channel) <= lvds_in.data(channel-1);
    end generate;

    lvds_rx : lvds_decoder_lvds_rx generic map (
        n_channels => n_channels,
        bit_width => bit_width
    ) port map (
        rx_channel_data_align => rx_channel_data_align,
        rx_in => rx_in,
        rx_inclock => lvds_in.clock,
        rx_out => rx_out,
        rx_outclock => rx_outclock
    );

    reset <= not reset_n;
    rdack <= not rdempty;
    
    fifo : lvds_decoder_fifo generic map (
        n_channels => n_channels,
        bit_width => bit_width
    ) port map (
        aclr => reset,
        data => rx_out,
        rdclk => clock,
        rdreq => rdack,
        wrclk => rx_outclock,
        wrreq => '1',
        q => q_out,
        rdempty => rdempty,
        wrfull => open
    );
    
    data_available <= not rdempty;
    control <= unsigned(q_out(bit_width-1 downto 0));
    parallel_out.control <= control;
    group_outputs : for channel in 1 to n_channels-1 generate
        parallel_out.data(channel-1) <= unsigned(
            q_out(bit_width*(channel+1)-1 downto bit_width*channel)
        );
    end generate;

    start_align_clock_bridge : cmd_cross_clock port map (
        reset_n => reset_n,
        i_clock => clock,
        i => start_align,
        o_clock => rx_outclock,
        o => start_align_rx_outclock
    );

    align_done_clock_bridge : cmd_cross_clock port map (
        reset_n => reset_n,
        i_clock => rx_outclock,
        i => align_done_rx_outclock,
        o_clock => clock,
        o => align_done
    );

    align_process : process (rx_outclock)
        type state_t is (READOUT, ALIGN_HIGH, ALIGN_LOW, ALIGN_WAIT);
        variable state : state_t;
        variable offset : integer;
    begin
        if rising_edge(rx_outclock) then
            align_done_rx_outclock <= '0';
            rx_channel_data_align <= (others => '0');

            if reset_n = '0' then
                state := READOUT;
            else
                case state is
                when READOUT =>
                    if start_align_rx_outclock = '1' then
                        state := ALIGN_HIGH;
                        offset := calc_align_offset(control, control_target);
                    end if;
                when ALIGN_HIGH =>
                    rx_channel_data_align <= (others => '1');
                    state := ALIGN_LOW;
                when ALIGN_LOW =>
                    offset := offset - 1;
                    if offset = 0 then
                        state := ALIGN_WAIT;
                    else
                        state := ALIGN_HIGH;
                    end if;
                when ALIGN_WAIT =>
                    if control = control_target then
                        align_done_rx_outclock <= '1';
                        state := READOUT;
                    end if;
                end case;
            end if;
        end if;
    end process align_process;

end architecture rtl;



architecture rtl of lvds_decoder_fifo is
    component fifo_170 is
    port (
        aclr		: in std_logic;
        data		: in std_logic_vector(170-1 downto 0);
        rdclk		: in std_logic;
        rdreq		: in std_logic;
        wrclk		: in std_logic;
        wrreq		: in std_logic;
        q		    : out std_logic_vector(170-1 downto 0);
        rdempty		: out std_logic;
        wrfull		: out std_logic 
    );
    end component fifo_170;
begin
    instantiate_17_10 : if n_channels = 17 and bit_width = 10 generate
        fifo : fifo_170 port map (
            aclr => aclr,
            data => data,
            rdclk => rdclk,
            rdreq => rdreq,
            wrclk => wrclk,
            wrreq => wrreq,
            q => q,
            rdempty => rdempty,
            wrfull => wrfull
        );
    end generate;
end architecture rtl;


architecture rtl of lvds_decoder_lvds_rx is
    component lvds_rx_10_17 is
    port (
        rx_channel_data_align   : in std_logic_vector (17-1 downto 0);
        rx_in                   : in std_logic_vector (17-1 downto 0);
        rx_inclock              : in std_logic;
        rx_out                  : out std_logic_vector (10*17-1 downto 0);
        rx_outclock             : out std_logic
    );
    end component lvds_rx_10_17;
begin
    instantiate_17_10 : if n_channels = 17 and bit_width = 10 generate
        lvds_rx : lvds_rx_10_17 port map (
            rx_channel_data_align => rx_channel_data_align,
            rx_in => rx_in,
            rx_inclock => rx_inclock,
            rx_out => rx_out,
            rx_outclock => rx_outclock
        );
    end generate;
end architecture rtl;