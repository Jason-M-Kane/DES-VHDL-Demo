-------------------------------------------------------------------------------
-- Jason Kane
--
-- F Function VHDL Routine
--
-- Input/Output:
-- Determines the function f(R,K)
-- User sets beginFunction high to begin calculation.
-- Hardware sets outputValid when done.  Output in dataOut.
-- outputValid goes low again when beginFunction input is set low. 
--
-- How it works:
-- Takes R and K (48-bit subkey) as input.
-- It extends R to 48 bits and XORS it with K.
-- Next the 8 substitution lookup tables are used to determine the output.
-- Finally a permutation P is performed.  32 bits are output.
-------------------------------------------------------------------------------
LIBRARY IEEE;
library altera_mf;
USE IEEE.std_logic_1164.all;
USE IEEE.std_logic_unsigned.all;
use altera_mf.altera_mf_components.all;


entity f_function is 
	port (
		reset:		   in  std_logic;
		clock:		   in  std_logic;
		beginFunction: in  std_logic;
		K_subkey:	   in  std_logic_vector(0 to 47);
		R:			   in  std_logic_vector(0 to 31);
		dataOut:	   out std_logic_vector(0 to 31);
		outputValid:   out std_logic
	);
end f_function;

architecture calculation of f_function is
	signal R_Extended: std_logic_vector(0 to 47);
	signal sboxInput:  std_logic_vector(0 to 47);
	signal sboxOutput: std_logic_vector(0 to 31);
	signal sbox1Addr, sbox2Addr, sbox3Addr, sbox4Addr,
			sbox5Addr, sbox6Addr, sbox7Addr, sbox8Addr:
			std_logic_vector(0 to 5);
	signal sbox_clk: std_logic;
	
	TYPE fctnStateMachine IS (waitForSignal,extend,sboxAddrCalc,
							xorEandK,sboxOutputStrobeA,sboxOutputStrobeB,
							sboxOutputPerm, waitForBeginLow);
	SIGNAL funcState: fctnStateMachine;
	
	
begin

	-------  S Boxes (8 total) -------
	sbox1: altsyncram generic map(
		WIDTH_A => 4,
		WIDTHAD_A => 6,
		NUMWORDS_A => 64,
		operation_mode => "ROM",
		init_file => "sbox1.mif"
	)
	port map(
		clock0 => sbox_clk,
		address_a => sbox1Addr,
		q_a => sboxOutput(0 to 3)
	);
	
	sbox2: altsyncram generic map(
		WIDTH_A => 4,
		WIDTHAD_A => 6,
		NUMWORDS_A => 64,
		operation_mode => "ROM",
		init_file => "sbox2.mif"
	)
	port map(
		clock0 => sbox_clk,
		address_a => sbox2Addr,
		q_a => sboxOutput(4 to 7)
	);
	
	sbox3: altsyncram generic map(
		WIDTH_A => 4,
		WIDTHAD_A => 6,
		NUMWORDS_A => 64,
		operation_mode => "ROM",
		init_file => "sbox3.mif"
	)
	port map(
		clock0 => sbox_clk,
		address_a => sbox3Addr,
		q_a => sboxOutput(8 to 11)
	);	
	
	sbox4: altsyncram generic map(
		WIDTH_A => 4,
		WIDTHAD_A => 6,
		NUMWORDS_A => 64,
		operation_mode => "ROM",
		init_file => "sbox4.mif"
	)
	port map(
		clock0 => sbox_clk,
		address_a => sbox4Addr,
		q_a => sboxOutput(12 to 15)
	);
	
	sbox5: altsyncram generic map(
		WIDTH_A => 4,
		WIDTHAD_A => 6,
		NUMWORDS_A => 64,
		operation_mode => "ROM",
		init_file => "sbox5.mif"
	)
	port map(
		clock0 => sbox_clk,
		address_a => sbox5Addr,
		q_a => sboxOutput(16 to 19)
	);
	
	sbox6: altsyncram generic map(
		WIDTH_A => 4,
		WIDTHAD_A => 6,
		NUMWORDS_A => 64,
		operation_mode => "ROM",
		init_file => "sbox6.mif"
	)
	port map(
		clock0 => sbox_clk,
		address_a => sbox6Addr,
		q_a => sboxOutput(20 to 23)
	);
	
	sbox7: altsyncram generic map(
		WIDTH_A => 4,
		WIDTHAD_A => 6,
		NUMWORDS_A => 64,
		operation_mode => "ROM",
		init_file => "sbox7.mif"
	)
	port map(
		clock0 => sbox_clk,
		address_a => sbox7Addr,
		q_a => sboxOutput(24 to 27)
	);
	
	sbox8: altsyncram generic map(
		WIDTH_A => 4,
		WIDTHAD_A => 6,
		NUMWORDS_A => 64,
		operation_mode => "ROM",
		init_file => "sbox8.mif"
	)
	port map(
		clock0 => sbox_clk,
		address_a => sbox8Addr,
		q_a => sboxOutput(28 to 31)
	);
	
	--------- End of S Boxes ---------


	performFunctionF: process(reset,clock,beginFunction) is

	begin
		if(reset = '0') then
			outputValid <= '0';
			sbox_clk <= '0';
			funcState <= waitForSignal;
		elsif(clock'event and clock = '1') then 	
			case funcState is
	
				when waitForSignal =>
					if(beginFunction = '1') then
						outputValid <= '0';
						funcState <= extend;
					end if;
								
				when extend=>
					R_Extended(0) <= R(32-1);
					R_Extended(1) <= R(1-1);
					R_Extended(2) <= R(2-1);
					R_Extended(3) <= R(3-1);
					R_Extended(4) <= R(4-1);
					R_Extended(5) <= R(5-1);
					
					R_Extended(6) <= R(4-1);
					R_Extended(7) <= R(5-1);
					R_Extended(8) <= R(6-1);
					R_Extended(9) <= R(7-1);
					R_Extended(10) <= R(8-1);
					R_Extended(11) <= R(9-1);
					
					R_Extended(12) <= R(8-1);
					R_Extended(13) <= R(9-1);
					R_Extended(14) <= R(10-1);
					R_Extended(15) <= R(11-1);
					R_Extended(16) <= R(12-1);
					R_Extended(17) <= R(13-1);
					
					R_Extended(18) <= R(12-1);
					R_Extended(19) <= R(13-1);
					R_Extended(20) <= R(14-1);
					R_Extended(21) <= R(15-1);
					R_Extended(22) <= R(16-1);
					R_Extended(23) <= R(17-1);
					
					R_Extended(24) <= R(16-1);
					R_Extended(25) <= R(17-1);
					R_Extended(26) <= R(18-1);
					R_Extended(27) <= R(19-1);
					R_Extended(28) <= R(20-1);
					R_Extended(29) <= R(21-1);
					
					R_Extended(30) <= R(20-1);
					R_Extended(31) <= R(21-1);
					R_Extended(32) <= R(22-1);
					R_Extended(33) <= R(23-1);
					R_Extended(34) <= R(24-1);
					R_Extended(35) <= R(25-1);
					
					R_Extended(36) <= R(24-1);
					R_Extended(37) <= R(25-1);
					R_Extended(38) <= R(26-1);
					R_Extended(39) <= R(27-1);
					R_Extended(40) <= R(28-1);
					R_Extended(41) <= R(29-1);
					
					R_Extended(42) <= R(28-1);
					R_Extended(43) <= R(29-1);
					R_Extended(44) <= R(30-1);
					R_Extended(45) <= R(31-1);
					R_Extended(46) <= R(32-1);
					R_Extended(47) <= R(1-1);
					funcState <= xorEandK;

				when xorEandK =>
					sboxInput <= R_Extended XOR K_subkey;
					funcState <= sboxAddrCalc;
					
				when sboxAddrCalc =>
					sbox1Addr <= sboxInput(0) & sboxInput(5) & sboxInput(1 to 4);
					sbox2Addr <= sboxInput(6) & sboxInput(11) & sboxInput(7 to 10);
					sbox3Addr <= sboxInput(12) & sboxInput(17) & sboxInput(13 to 16);
					sbox4Addr <= sboxInput(18) & sboxInput(23) & sboxInput(19 to 22);
					sbox5Addr <= sboxInput(24) & sboxInput(29) & sboxInput(25 to 28);
					sbox6Addr <= sboxInput(30) & sboxInput(35) & sboxInput(31 to 34);
					sbox7Addr <= sboxInput(36) & sboxInput(41) & sboxInput(37 to 40);
					sbox8Addr <= sboxInput(42) & sboxInput(47) & sboxInput(43 to 46);
					funcState <= sboxOutputStrobeA;
					
				when sboxOutputStrobeA =>
					sbox_clk <= '1';
					funcState <= sboxOutputStrobeB;

				when sboxOutputStrobeB =>
					sbox_clk <= '0';
					funcState <= sboxOutputPerm;
										
				when sboxOutputPerm =>
					dataOut(0) <= sboxOutput(16-1);
					dataOut(1) <= sboxOutput(7-1);
					dataOut(2) <= sboxOutput(20-1);
					dataOut(3) <= sboxOutput(21-1);
					
					dataOut(4) <= sboxOutput(29-1);
					dataOut(5) <= sboxOutput(12-1);
					dataOut(6) <= sboxOutput(28-1);
					dataOut(7) <= sboxOutput(17-1);
					
					dataOut(8) <= sboxOutput(1-1);
					dataOut(9) <= sboxOutput(15-1);
					dataOut(10) <= sboxOutput(23-1);
					dataOut(11) <= sboxOutput(26-1);
					
					dataOut(12) <= sboxOutput(5-1);
					dataOut(13) <= sboxOutput(18-1);
					dataOut(14) <= sboxOutput(31-1);
					dataOut(15) <= sboxOutput(10-1);
					
					dataOut(16) <= sboxOutput(2-1);
					dataOut(17) <= sboxOutput(8-1);
					dataOut(18) <= sboxOutput(24-1);
					dataOut(19) <= sboxOutput(14-1);
					
					dataOut(20) <= sboxOutput(32-1);
					dataOut(21) <= sboxOutput(27-1);
					dataOut(22) <= sboxOutput(3-1);
					dataOut(23) <= sboxOutput(9-1);
					
					dataOut(24) <= sboxOutput(19-1);
					dataOut(25) <= sboxOutput(13-1);
					dataOut(26) <= sboxOutput(30-1);
					dataOut(27) <= sboxOutput(6-1);
					
					dataOut(28) <= sboxOutput(22-1);
					dataOut(29) <= sboxOutput(11-1);
					dataOut(30) <= sboxOutput(4-1);
					dataOut(31) <= sboxOutput(25-1);
					
					funcState <= waitForBeginLow;
					
				when waitForBeginLow =>
					outputValid <= '1';
					if(beginFunction = '0') then
						outputValid <= '0';
						funcState <= waitForSignal;
					end if;

				
				when others =>
					outputValid <= '0';
					sbox_clk <= '0';
					funcState <= waitForSignal;
			end case;
							
		end if;
	end process;
end architecture calculation;

