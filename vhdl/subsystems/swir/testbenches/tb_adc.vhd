library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- This simulates the ADAQ7980 ADC, in 4-wire CS mode with busy indicator, with VIO above 1.7V
-- From data sheet: t(cyc) >= 1200 ns
--					t(acq) >= 290 ns
--					500 <= t(conv) <= 800 ns

entity tb_adc is
	 port (
		sdi				: in std_logic;
		sck				: in std_logic;
		cnv				: in std_logic;
		sdo				: out std_logic		:= '0';
		
		video_in		: in integer:
    );
end entity;

architecture sim of tb_adc is

	signal working				:	std_logic := '0';
	signal acquisition 			:	std_logic := '0';
	signal data_readout			:	std_logic := '0';
	signal conversion_counter	:	integer	= 0;
	signal data_counter			:	integer = 0;
	
	signal data_out				:	unsigned(15 downto 0);
	
	type timing_array is array(0 to 99) of integer;
	signal t_conv 				:	timing_array;
	
	constant ClockPeriod : time := 1 ns;
	signal ns_clk 				: std_logic := '1';
	signal acq_timer			: integer	:= '0';
	
begin

	ns_clk <= not ns_clk after ClockPeriod/2;	-- Clock to keep track of acquisition time
	
	-- Process to register start of conversion
	process is
	begin
	
		if (rising_edge(cnv) and sdi = '1' and working = '0') then
			working <= '1';
			wait for t_conv(conversion_counter) ns;
			conversion_counter <= conversion_counter + 1;
			acquisition <= '1';
		elsif (data_counter = 16) then
			working <= '0';
			acquisition <= '0';
		end if;
		
		if (conversion_counter = 100) then
		
			conversion_counter <= 0;
			
		end if;
			
	end process;
	
	-- Process to register start of acquisition phase
	process is
	begin
	
		if acquisition = '1' and data_readout = '0' then
			wait until rising_edge(sck)
			data_readout <= '1';
		elsif (data_counter < 16) then
			data_readout <= '0';
		end if;
		
	end process;
	
	-- Process to start transmitting data
	process(rising_edge(sck)) is
	begin
	
		if data_readout = '1' and data_counter < 16 then
			sdo <= data_out(data_counter);
			data_counter <= data_counter + 1;
		elsif data_counter = 16 then
			data_counter <= 0;
		end if;
		
	end process;
	
	-- Process to ensure acquisition time is not too short
	process(rising_edge(ns_clk)) is
	begin
	
		if acquisition = '1' then
			acq_timer <= acq_timer + 1;
		end if;
		
		if data_counter = 16 then
			assert acq_timer > 290 report "Hold Acquisition state for longer" severity error;
			acq_timer <= 0;
		end if;
		
	end process;
	
	data_out <= to_unsigned(video_in);
	
	-- t(conv) random values, between 500 and 800 ns
	t_conv <= (775, 532, 700, 521, 525, 797, 773, 571, 739, 560, 
			701, 669, 738, 799, 681, 686, 709, 779, 522, 622, 683, 
			758, 565, 575, 669, 504, 745, 782, 650, 573, 521, 721, 
			625, 592, 605, 559, 722, 519, 548, 647, 761, 727, 678, 
			504, 501, 604, 744, 537, 660, 707, 778, 610, 632, 732, 
			533, 710, 702, 528, 675, 701, 773, 651, 796, 560, 704, 
			520, 575, 681, 564, 610, 593, 618, 533, 515, 679, 795, 
			617, 549, 642, 687, 727, 677, 657, 576, 636, 529, 653, 
			687, 650, 707, 682, 762, 668, 768, 520, 701, 651, 560, 
			683, 731);
	
end architecture;