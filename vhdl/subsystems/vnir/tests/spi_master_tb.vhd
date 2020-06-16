

LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_arith.all;
USE ieee.std_logic_unsigned.all;
USE ieee.numeric_std.all;


entity spi_master_tb is

end entity;

architecture rtl of spi_master_tb is	
	
	constant	clockPeriod : time := 20 ns;
	
	constant	dataWidth	: INTEGER := 4;
	constant	numSlaves	: INTEGER := 1;
	
	signal clock	:	STD_LOGIC := '0';
	signal reset_n	:	STD_LOGIC := '1';
	signal enable	:	STD_LOGIC := '0';
	signal cpol		:	STD_LOGIC := '0';
	signal cpha		:	STD_LOGIC := '0';
	signal cont		:	STD_LOGIC := '0';
	signal clk_div	:	INTEGER := 0;
	signal addr		:	INTEGER := 0;
	signal tx_data	:	STD_LOGIC_VECTOR(dataWidth-1 downto 0);
	signal miso		:	STD_LOGIC;
	signal sclk		:	STD_LOGIC;
	signal ss_n		:	STD_LOGIC_VECTOR(numSlaves-1 downto 0);
	signal mosi		:	STD_LOGIC;
	signal busy		:	STD_LOGIC;
	signal rx_data	:	STD_LOGIC_VECTOR(dataWidth-1 downto 0);

	COMPONENT spi_master IS
	  GENERIC(
		slaves  : INTEGER := 4;  
		d_width : INTEGER := 2); 
	  PORT(
		clock   : IN     STD_LOGIC;                             
		reset_n : IN     STD_LOGIC;                             
		enable  : IN     STD_LOGIC;                             
		cpol    : IN     STD_LOGIC;                             
		cpha    : IN     STD_LOGIC;                             
		cont    : IN     STD_LOGIC;                             
		clk_div : IN     INTEGER;                               
		addr    : IN     INTEGER;                               
		tx_data : IN     STD_LOGIC_VECTOR(d_width-1 DOWNTO 0);  
		miso    : IN     STD_LOGIC;                             
		sclk    : BUFFER STD_LOGIC;                             
		ss_n    : BUFFER STD_LOGIC_VECTOR(slaves-1 DOWNTO 0);   
		mosi    : OUT    STD_LOGIC;                             
		busy    : OUT    STD_LOGIC;                             
		rx_data : OUT    STD_LOGIC_VECTOR(d_width-1 DOWNTO 0)); 
	END COMPONENT;


begin


	clockGen : process
	begin
		wait for clockPeriod / 2;
		clock <= not clock;
	end process clockGen;
	
	
	
	test : process
	begin
		
		-- Basic Test, send '1001'
		tx_data <= "1001";
		enable <= '1';
		wait for 20 ns;
		enable <= '0';
		
		-- Wait for last transfer to finish
		wait until busy = '0';
		wait for 20 ns;
		
		-- Send '1010', recieve '0110'
		tx_data <= "1010";
		enable <= '1';
		wait until ss_n(0) = '0';       -- delays to properly align incoming data with the
		wait for clockPeriod / 2;       -- proper edges of sclk 
		miso <= '0';
		wait until falling_edge(sclk);
		miso <= '1';
		enable <= '0';
		wait until falling_edge(sclk);
		miso <= '1';
		wait until falling_edge(sclk);
		miso <= '0';
		
		-- Wait for last transfer to finish
		wait until busy = '0';
		wait for 20 ns;
		
		-- Continuous mode, send '1100','1000','1001'
		tx_data <= "1100";
		enable <= '1';
		cont <= '1';
		wait until busy = '1';
		wait for clockPeriod;
		tx_data <= "1000";
		wait until busy = '0';
		wait for clockPeriod;       -- additional delay to stop module from latching new value
		tx_data <= "1001";
		wait until busy = '0';
		wait for clockPeriod;
		cont <= '0';
		
		wait;
	end process test;

	dut : spi_master
		generic map(
			slaves		=>	numSlaves,
			d_width		=>	dataWidth)
		port map(
			clock		=>	clock,
			reset_n		=>	reset_n,
			enable		=>	enable,
			cpol		=>	cpol,
			cpha		=>	cpha,
			cont		=>	cont,
			clk_div		=>	clk_div,
			addr		=>	addr,
			tx_data		=>	tx_data,
			miso		=>	miso,
			sclk		=>	sclk,
			ss_n		=>	ss_n,
			mosi		=>	mosi,
			busy		=>	busy,
			rx_data		=>	rx_data
		);
		
		
end rtl;
















