library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity testbench_1 is

end entity;


architecture tb of testbench_1 is

	-- Up to 240 MHz
	constant clockPeriod	: time := 4.2 ns;

	-- Main system clock and reset
	signal system_clk		: std_logic := '0';
	signal reset_sys		: std_logic := '0';
	
	-- Input from LVDS data and clock pins
	signal lvds_signal_in	: std_logic_vector (16 downto 0) := (others => '0');
	signal lvds_clock_in	: std_logic := '0';
	
	-- Word alignment signals
	signal alignment_done	: std_logic;
	signal cmd_start_align	: std_logic := '0';
	
	-- LVDS reader status signals
	signal pll_locked			: std_logic;
	signal word_alignment_error	: std_logic;
	
	-- Enable/disable LVDS input clock signal
	signal clock_enable		: std_logic := '1';
	
	signal data_par_00		: std_logic_vector (9 downto 0);
	signal data_par_01		: std_logic_vector (9 downto 0);
	signal data_par_02		: std_logic_vector (9 downto 0);
	signal data_par_03		: std_logic_vector (9 downto 0);
	signal data_par_04		: std_logic_vector (9 downto 0);
	signal data_par_05		: std_logic_vector (9 downto 0);
	signal data_par_06		: std_logic_vector (9 downto 0);
	signal data_par_07		: std_logic_vector (9 downto 0);
	signal data_par_08		: std_logic_vector (9 downto 0);
	signal data_par_09		: std_logic_vector (9 downto 0);
	signal data_par_10		: std_logic_vector (9 downto 0);
	signal data_par_11		: std_logic_vector (9 downto 0);
	signal data_par_12		: std_logic_vector (9 downto 0);
	signal data_par_13		: std_logic_vector (9 downto 0);
	signal data_par_14		: std_logic_vector (9 downto 0);
	signal data_par_15		: std_logic_vector (9 downto 0);
	signal ctrl_par			: std_logic_vector (9 downto 0);	

	component lvds_reader_top is
		generic (
			NUM_CHANNELS 	: integer
		);
		port(
			clock_sys		: in std_logic;
			reset_sys		: in std_logic;
			
			lvds_signal_in	: in std_logic_vector (16 downto 0);
			lvds_clock_in	: in std_logic;
			
			alignment_done	: out std_logic;
			cmd_start_align	: in  std_logic;
			
			word_alignment_error    : out std_logic;
			pll_locked				: out std_logic;
			
			data_par_00		: out std_logic_vector (9 downto 0);
			data_par_01		: out std_logic_vector (9 downto 0);
			data_par_02		: out std_logic_vector (9 downto 0);
			data_par_03		: out std_logic_vector (9 downto 0);
			data_par_04		: out std_logic_vector (9 downto 0);
			data_par_05		: out std_logic_vector (9 downto 0);
			data_par_06		: out std_logic_vector (9 downto 0);
			data_par_07		: out std_logic_vector (9 downto 0);
			data_par_08		: out std_logic_vector (9 downto 0);
			data_par_09		: out std_logic_vector (9 downto 0);
			data_par_10		: out std_logic_vector (9 downto 0);
			data_par_11		: out std_logic_vector (9 downto 0);
			data_par_12		: out std_logic_vector (9 downto 0);
			data_par_13		: out std_logic_vector (9 downto 0);
			data_par_14		: out std_logic_vector (9 downto 0);
			data_par_15		: out std_logic_vector (9 downto 0);
			ctrl_par		: out std_logic_vector (9 downto 0)		
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
			system_clk <= not system_clk;
			clockDivider := 0;
		else
			clockDivider := clockDivider + 1;		
		end if;	
	end process clockGen;
	
	
	
	-- Input CMV4000 training pattern to the SERDES module
	generateTrainingPattern : process(lvds_clock_in)
		constant trainingPattern : std_logic_vector (9 downto 0) := "0001010101";
		subtype t_trainingPatternIndex is integer range 9 downto 0;
		variable trainingPatternIndex : t_trainingPatternIndex := 5;	
	begin
	
		lvds_signal_in(0)  <= trainingPattern(trainingPatternIndex);
		lvds_signal_in(1)  <= trainingPattern(trainingPatternIndex);
		lvds_signal_in(2)  <= trainingPattern(trainingPatternIndex);
		lvds_signal_in(3)  <= trainingPattern(trainingPatternIndex);
		lvds_signal_in(4)  <= trainingPattern(trainingPatternIndex);
		lvds_signal_in(5)  <= trainingPattern(trainingPatternIndex);
		lvds_signal_in(6)  <= trainingPattern(trainingPatternIndex);
		lvds_signal_in(7)  <= trainingPattern(trainingPatternIndex);
		lvds_signal_in(8)  <= trainingPattern(trainingPatternIndex);
		lvds_signal_in(9)  <= trainingPattern(trainingPatternIndex);
		lvds_signal_in(10) <= trainingPattern(trainingPatternIndex);
		lvds_signal_in(11) <= trainingPattern(trainingPatternIndex);
		lvds_signal_in(12) <= trainingPattern(trainingPatternIndex);
		lvds_signal_in(13) <= trainingPattern(trainingPatternIndex);
		lvds_signal_in(14) <= trainingPattern(trainingPatternIndex);
		lvds_signal_in(15) <= trainingPattern(trainingPatternIndex);
		lvds_signal_in(16) <= trainingPattern(trainingPatternIndex);
		
		-- Select next digit in training pattern
		if(trainingPatternIndex = 9) then
			trainingPatternIndex := 0;
		else
			trainingPatternIndex := trainingPatternIndex + 1;
		end if;
	
	end process generateTrainingPattern;
	
	
	test : process
	begin
	
		-- Wait until PLL achieves lock
		wait until (pll_locked = '1');
		cmd_start_align <= '1';
		wait for 42 ns;
		cmd_start_align <= '0';
		
		-- Turn off clock so PLL loses lock
		wait for 500 ns;
		clock_enable <= '0';
		wait until pll_locked = '0';
		wait for 100 ns;
		clock_enable <= '1';
		wait until pll_locked = '1';
		wait for 100 ns;
		wait;
		
		--wait until (alignment_done = '1');
		--wait;
	end process test;
	
	
	
	dut : lvds_reader_top
		generic map(
			NUM_CHANNELS => 16
			)
		port map(
			clock_sys		        => system_clk,
			reset_sys		        => reset_sys,
			lvds_signal_in 	        => lvds_signal_in,
			lvds_clock_in	        => lvds_clock_in,
			alignment_done	        => alignment_done,
			cmd_start_align	        => cmd_start_align,
			word_alignment_error    => word_alignment_error,
			pll_locked				=> pll_locked,
			data_par_00		        => data_par_00,
			data_par_01		        => data_par_01,
			data_par_02		        => data_par_02,
			data_par_03		        => data_par_03,
			data_par_04		        => data_par_04,
			data_par_05		        => data_par_05,
			data_par_06		        => data_par_06,
			data_par_07		        => data_par_07,
			data_par_08		        => data_par_08,
			data_par_09		        => data_par_09,
			data_par_10		        => data_par_10,
			data_par_11		        => data_par_11,
			data_par_12		        => data_par_12,
			data_par_13		        => data_par_13,
			data_par_14		        => data_par_14,
			data_par_15		        => data_par_15,
			ctrl_par		        => ctrl_par		
		);



end tb;