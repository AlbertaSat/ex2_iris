library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.LVDS_data_array_pkg.all;

entity testbench_LVDS_reader is

end entity;


architecture tb of testbench_LVDS_reader is

	-- Up to 240 MHz
	constant clockPeriod	: time := 4.2 ns;

	-- Main system clock and reset
	signal system_clock		: std_logic := '0';
	signal system_reset		: std_logic := '0';
	
	-- Input from LVDS data and clock pins
	signal lvds_data_in	: std_logic_vector (15 downto 0) := (others => '0');
	signal lvds_ctrl_in		: std_logic := '0';
	signal lvds_clock_in	: std_logic := '0';
	
	-- Word alignment signals
	signal alignment_done	: std_logic;
	signal cmd_start_align	: std_logic := '0';
	
	-- LVDS reader status signals
	signal pll_locked			: std_logic;
	signal word_alignment_error	: std_logic;
	
	-- Enable/disable LVDS input clock signal
	signal clock_enable		: std_logic := '1';
	
	signal lvds_parallel_clock	: std_logic;
	
	signal lvds_parallel_data	: t_lvds_data_array(16 downto 0)(9 downto 0);
	

	component lvds_reader_top is
		generic (
			NUM_CHANNELS 			: integer;
			DATA_TRAINING_PATTERN	: std_logic_vector (9 downto 0)
		);
		port(
			system_clock		: in std_logic;
			system_reset		: in std_logic;
			
			lvds_data_in	: in std_logic_vector (15 downto 0);
			lvds_ctrl_in	: in std_logic;
			lvds_clock_in	: in std_logic;
			
			alignment_done	: out std_logic;
			cmd_start_align	: in  std_logic;
			
			word_alignment_error    : out std_logic;
			pll_locked				: out std_logic;
			
			lvds_parallel_clock	: out std_logic;
			
			lvds_parallel_data		: out t_lvds_data_array(16 downto 0)(9 downto 0)		
		);
	end component;



begin

	-- Generate main and lvds clock signals
	clockGen : process
		subtype t_clockDivider is integer range 4 downto 0;
		variable clockDivider : t_clockDivider := 0;
	begin
		wait for clockPeriod / 2;
		if (clock_enable = '1') then
			lvds_clock_in <= not lvds_clock_in;
		end if;
		
		if(clockDivider = 4) then
			system_clock <= not system_clock;
			clockDivider := 0;
		else
			clockDivider := clockDivider + 1;		
		end if;	
	end process clockGen;
	
	
	
	-- Input CMV4000 training pattern to the SERDES module
	generateTrainingPattern : process(lvds_clock_in)
		constant trainingPattern_data : std_logic_vector (9 downto 0) := "0001010101";
		constant trainingPattern_ctrl : std_logic_vector (9 downto 0) := (9 => '1', others => '0');
		subtype t_trainingPatternIndex is integer range 9 downto 0;
		variable trainingPatternIndex : t_trainingPatternIndex := 5;	
	begin
		
		lvds_data_in	<= (others => trainingPattern_data(trainingPatternIndex));
		lvds_ctrl_in	<= trainingPattern_ctrl(trainingPatternIndex);
		
		-- Select next digit in training pattern
		if(trainingPatternIndex = 9) then
			trainingPatternIndex := 0;
		else
			trainingPatternIndex := trainingPatternIndex + 1;
		end if;
	
	end process generateTrainingPattern;
	
	
	-- Coordinates testing signals
	test : process
	begin
	
		-- Apply reset at startup to give signals initial values
		system_reset <= '1';
		wait for 84 ns;
		system_reset <= '0';
		
		-- Wait until PLL achieves lock
		wait until (pll_locked = '1');
		cmd_start_align <= '1';
		wait for 42 ns;
		cmd_start_align <= '0';
		
		-- -- Turn off clock so PLL loses lock
		-- wait for 500 ns;
		-- clock_enable <= '0';
		-- wait until pll_locked = '0';
		-- wait for 100 ns;
		-- clock_enable <= '1';
		-- wait until pll_locked = '1';
		-- wait for 100 ns;
		-- wait;
		
		wait until (alignment_done = '1');
		wait;
	end process test;
	
	
	
	dut : lvds_reader_top
		generic map(
			NUM_CHANNELS 			=> 16,
			DATA_TRAINING_PATTERN	=> "0001010101"
			)
		port map(
			system_clock		    => system_clock,
			system_reset		    => system_reset,
			lvds_data_in 	        => lvds_data_in,
			lvds_ctrl_in			=> lvds_ctrl_in,
			lvds_clock_in	        => lvds_clock_in,
			alignment_done	        => alignment_done,
			cmd_start_align	        => cmd_start_align,
			word_alignment_error    => word_alignment_error,
			pll_locked				=> pll_locked,
			lvds_parallel_clock		=> lvds_parallel_clock,
			lvds_parallel_data		=> lvds_parallel_data		
		);



end tb;