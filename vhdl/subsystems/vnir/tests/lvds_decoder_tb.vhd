library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.spi_types.all;
use work.vnir_types.all;

entity lvds_decoder_tb is
end entity lvds_decoder_tb;

architecture tests of lvds_decoder_tb is
    type state_t is (IDLE, TRANSMIT);
    signal state : state_t;

    subtype word_t is std_logic_vector(vnir_pixel_bits-1 downto 0);
    type word_vector_t is array(integer range <>) of word_t;
    subtype lvds_data_t is word_vector_t(vnir_lvds_data_width-1 downto 0);
    type lvds_data_vector_t is array(integer range <>) of lvds_data_t;

    constant control_idle : word_t := (vnir_pixel_bits-10 => '1', others => '0');
    constant control_readout : word_t := (vnir_pixel_bits-1 => '1', others => '0');

    constant data_idle : lvds_data_t := (0 => "1010101100", 1 => "1000101111", 2 => "1001110101", 3 => "0011000000", 4 => "1101000011", 5 => "1011111011", 6 => "1011000011", 7 => "0101100111", 8 => "0000001001", 9 => "1011010011", 10 => "0100010101", 11 => "1011110010", 12 => "1100100100", 13 => "1001010111", 14 => "0001000110", 15 => "0111011000");
    constant data_transmit : lvds_data_vector_t := (
        0 => (0 => "1001011000", 1 => "0110001100", 2 => "0100111010", 3 => "1011000001", 4 => "0111100110", 5 => "1000100111", 6 => "0001010111", 7 => "0010101110", 8 => "1001011000", 9 => "1101010001", 10 => "1010100101", 11 => "1000011001", 12 => "1101001101", 13 => "0001001000", 14 => "1100001001", 15 => "1110010100"),
        1 => (0 => "0001110011", 1 => "1111010000", 2 => "1011110011", 3 => "1011000101", 4 => "1111111110", 5 => "1101001111", 6 => "0110101111", 7 => "0111000000", 8 => "1101010010", 9 => "0001100011", 10 => "1111011000", 11 => "0010110001", 12 => "1011110011", 13 => "1100011101", 14 => "1010010011", 15 => "0010010011"),
        2 => (0 => "1110001110", 1 => "0110100111", 2 => "0100100000", 3 => "1111000001", 4 => "0100001001", 5 => "1010111001", 6 => "1001111111", 7 => "1000100000", 8 => "1000011111", 9 => "1011001010", 10 => "0011110100", 11 => "0010010111", 12 => "1010100011", 13 => "0111111110", 14 => "0111001011", 15 => "1101110010"),
        3 => (0 => "0010110111", 1 => "0000011100", 2 => "1100100010", 3 => "0010000000", 4 => "0010000000", 5 => "1110100100", 6 => "0000110101", 7 => "1110000101", 8 => "1000100110", 9 => "0111101000", 10 => "1011110100", 11 => "0100010001", 12 => "0101001111", 13 => "0110000100", 14 => "1001101001", 15 => "0000101010"),
        4 => (0 => "0110111010", 1 => "1000011111", 2 => "1101111000", 3 => "0100000001", 4 => "0101000001", 5 => "1111100111", 6 => "1110101001", 7 => "0000111001", 8 => "0100100011", 9 => "1101100110", 10 => "0001110111", 11 => "1100001011", 12 => "0110101110", 13 => "0001010010", 14 => "0001011011", 15 => "1110000000"),
        5 => (0 => "0110001110", 1 => "1001100011", 2 => "1000110101", 3 => "1110001100", 4 => "1001111001", 5 => "1110101010", 6 => "0001010100", 7 => "0011001011", 8 => "0101000100", 9 => "1100000110", 10 => "1111000100", 11 => "0000101111", 12 => "1001111111", 13 => "1111110100", 14 => "0010000011", 15 => "1111001100"),
        6 => (0 => "1101100100", 1 => "0010110100", 2 => "1111101000", 3 => "1101001110", 4 => "0010001111", 5 => "1010010100", 6 => "0011100011", 7 => "1110111010", 8 => "1100010111", 9 => "1011001111", 10 => "1110001101", 11 => "0101110101", 12 => "1101010101", 13 => "1000110000", 14 => "0100110001", 15 => "1001000101"),
        7 => (0 => "0010101001", 1 => "1010100011", 2 => "0111000000", 3 => "0001011111", 4 => "0011000101", 5 => "1001011110", 6 => "0100000000", 7 => "1101110001", 8 => "1010110010", 9 => "0100100100", 10 => "1110100010", 11 => "1100110000", 12 => "1101011101", 13 => "0110000011", 14 => "1001100010", 15 => "1000101010"),
        8 => (0 => "1111001101", 1 => "0101110000", 2 => "1111100111", 3 => "1110010101", 4 => "0011001001", 5 => "0101111111", 6 => "1000000000", 7 => "1110001010", 8 => "0101110010", 9 => "1000101011", 10 => "1110111010", 11 => "0101111111", 12 => "0000010111", 13 => "1010111011", 14 => "0010000010", 15 => "0101111001"),
        9 => (0 => "0001100010", 1 => "1000111110", 2 => "1110100011", 3 => "1011011110", 4 => "0001111011", 5 => "1111000011", 6 => "1001010010", 7 => "1110101110", 8 => "1011100011", 9 => "0010010100", 10 => "0011010001", 11 => "1000110010", 12 => "0110011011", 13 => "1100001110", 14 => "0000101001", 15 => "0000111010")
    );

    pure function to_word(u : unsigned) return word_t is
        variable w : word_t;
    begin
        for i in w'range loop
            w(i) := u(i);
        end loop;
        return w;
    end function to_word;

    constant lvds_clock_period : time := 4.167 ns;
    constant clock_period : time := 20 ns;

    signal clock : std_logic := '0';
    signal reset_n : std_logic := '0';
    signal start_align : std_logic := '0';
    signal align_done : std_logic;
    signal lvds : vnir_lvds_t := (
        clock => '0', 
        control => '0',
        data => (others => '0')
    );
    signal parallel_out : vnir_parallel_lvds_t;
    signal data_available : std_logic;

    procedure lvds_transmit(
        control : in word_t;
        data : in word_vector_t;
        signal lvds : inout vnir_lvds_t
    ) is
    begin
        for i in control'range loop
            lvds.control <= control(i);
            for j in data'range loop
                lvds.data(j) <= data(j)(i);
            end loop;
            wait for lvds_clock_period / 2;
            lvds.clock <= not lvds.clock;
        end loop;
    end procedure lvds_transmit;

    component lvds_decoder is
    port (
        clock          : in std_logic;
        reset_n        : in std_logic;
        start_align    : in std_logic;
        align_done     : out std_logic;
        lvds_in        : in vnir_lvds_t;
        parallel_out   : out vnir_parallel_lvds_t;
        data_available : out std_logic
    );
    end component lvds_decoder;
begin
    
    clock_process : process
    begin
        wait for clock_period / 2;
        clock <= not clock;
    end process clock_process;
    
    lvds_out_process : process
    begin
        case state is
        when IDLE =>
            lvds_transmit(control_idle, data_idle, lvds);
        when TRANSMIT =>
            for word in data_transmit'range loop
                lvds_transmit(control_readout, data_transmit(word), lvds);
            end loop;
        end case;
    end process lvds_out_process;

    tests_process : process
    begin
        state <= IDLE;
        
        wait for 100 ns;
        wait until rising_edge(clock);
        reset_n <= '1';
        
        wait for 100 ns;
        wait until rising_edge(clock);
        
        start_align <= '1'; wait until rising_edge(clock); start_align <= '0';
        wait until rising_edge(clock) and align_done = '1';
        
        for t in 0 to 10 loop  -- Check that we are producing data
            wait until rising_edge(clock) and data_available = '1';
            assert parallel_out.control = to_vnir_control(control_idle) severity failure;
            for i in parallel_out.data'range loop
                assert to_word(parallel_out.data(i)) = data_idle(i) severity failure;
            end loop;
            wait until rising_edge(clock);
        end loop;

        state <= TRANSMIT;
        wait until rising_edge(clock) and data_available = '1' and parallel_out.control = to_vnir_control(control_readout);

        for t in data_transmit'range loop
            assert parallel_out.control = to_vnir_control(control_readout) severity failure;
            for i in parallel_out.data'range loop
                assert to_word(parallel_out.data(i)) = data_transmit(t)(i) severity failure;
            end loop;
            wait until rising_edge(clock) and data_available = '1';
        end loop;

        report "ALL TESTS FINISHED." severity note;

        wait;
    end process tests_process;

    decoder : lvds_decoder port map (
        clock => clock,
        reset_n => reset_n,
        start_align => start_align,
        align_done => align_done,
        lvds_in => lvds,
        parallel_out => parallel_out,
        data_available => data_available
    );

end tests;
