library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- This simulates the ADAQ7980 ADC, in 4-wire CS mode with busy indicator, with VIO above 1.7V
-- From data sheet: t(cyc) >= 1200 ns
--					t(acq) >= 290 ns
--					500 <= t(conv) <= 800 ns
-- Additionally, note: sck max speed 45 MHz

entity tb_adc is
	 port (
		sdi				: in std_logic;
		sck				: in std_logic;
		cnv				: in std_logic;
		sdo				: out std_logic		:= '1';  -- default high impedance
		
		video_in		: in integer
    );
end entity;

architecture sim of tb_adc is

	signal conversion_counter	:	integer	:= 0;
	signal conversion_timer		:	integer	:= 0;
	signal data_counter			:	integer := 0;
	signal acq_timer			:	integer	:= 0;
	signal conversion_trigger	:	std_logic := '0';
	
	signal data_out				:	unsigned(15 downto 0);
	
	type timing_array is array(0 to 99) of integer;
	signal t_conv 				:	timing_array;
	
	type adc_state is (conversion, acquisition, idle, errors);
	signal state_reg, state_next:	adc_state	:= idle;
	
	constant ClockPeriod 		:	time := 2 ns;  -- ModelSim problems if a 1 ns clock is used
	signal ns_clk 				:	std_logic := '1';
	
begin

	ns_clk <= not ns_clk after ClockPeriod/2;	-- Clock to keep track of conversion and acquisition times
	
	-- Process to assign state of main adc FSM
	-- sck is used as FSM clock
	process(sck, cnv) is
	begin
		
		if rising_edge(cnv) and sdi = '1' then
			state_reg	<=	conversion;
			if state_next /= idle then
				report "move to conversion state too early!" severity error;
			end if;
		elsif rising_edge(cnv) and sdi = '0' then
			state_reg	<= errors;
			
		elsif rising_edge(sck) then
			state_reg	<= state_next;
		end if;
		
	end process;
	
	
	-- Main ADC FSM
	process(state_reg, cnv, sdi, sck, conversion_trigger) is
	begin
		--state_next <= state_reg;
		
		case state_reg is 
			when conversion =>
				sdo <= '1';  -- sdo is in high impedance state, '1' due to pull-up resistor
				
				-- If conversion time has elapsed, ensure cnv is high and sdi is low
				if conversion_trigger = '1' and cnv = '1' and sdi = '0' then
				
					-- increment conversion_counter to get another random value for conversion time
					if conversion_counter = 99 then
						conversion_counter <= 0;
					else
						conversion_counter <= conversion_counter + 1;
					end if;
					
					sdo <= '0';  -- Output a low for one cycle (interrupt)
					
					state_next <= acquisition;
					
				-- cnv must remain high throughout conversion time, and sdi must be low at end of conversion time 
				elsif cnv = '0' or (conversion_trigger = '1' and sdi = '1') then
					data_counter <=	0;
					sdo <= 'X';
					report "sdi or cnv Error!" severity error;
				
					state_next <= errors;
					
				else
					state_next <= conversion;
					
				end if;
	
			-- Data output state - output 16 bits
			when acquisition =>
				if data_counter = 16 and rising_edge(sck) then					
					state_next <= idle;
					sdo <= '1';
					
				-- Although in reality data is valid on both rising and falling edges of sck,
				--  circuit under test will be designed to only capture on falling edge for greater speed and simplicity
				elsif cnv = '1' and rising_edge(sck) then
					sdo <= data_out(15 - data_counter);  -- output data in reverse order (MSB first)
					data_counter <= data_counter + 1;
				
				end if;
			
			-- Wait for another conversion initiation
			when idle =>
				data_counter <=	0;

			
			-- A state to indicate incorrect value for sdi or cnv if 4 wire CS mode w/ busy indicator is desired
			when errors =>  
				null;
				
		end case;
	end process;
	
	
	-- Process to ensure count acquisition time in ns
	process(ns_clk) is
	begin
		if rising_edge(ns_clk) or falling_edge(ns_clk) then  -- Since clk period is 2 ns, scan on both rising and falling edges
			if state_next = acquisition then
				acq_timer <= acq_timer + 1;
			end if;
			
			if state_reg /= acquisition  then
				acq_timer <= 0;
			end if;
		end if;
		
	end process;
	
	-- Process to ensure acquisition time is not too short
	process(sck) is
	begin
		if falling_edge(sck) then  -- data_counter = 16 and state = acquisition will be valid on one falling edge of sck (while state is transitioning)
			if data_counter = 16 and state_reg = acquisition then
				assert acq_timer > 290 report "Hold Acquisition state for longer" severity error;  -- 290 ns taken from ADC datasheet (min acquisition time)
			end if;
		end if;
	end process;
	
	
	-- Process to count conversion time
	process(ns_clk) is
	begin
		if rising_edge(ns_clk) or falling_edge(ns_clk) then
			if state_reg = conversion then
				conversion_timer <= conversion_timer + 1;
			else
				conversion_timer <= 0;
			end if;
			
			if conversion_timer = t_conv(conversion_counter) then
				conversion_trigger <= '1';
			elsif state_reg = acquisition then
				conversion_trigger <= '0';
			end if;
		end if;
		
	end process;
	
	
	data_out <= to_unsigned(video_in, 16);
	
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