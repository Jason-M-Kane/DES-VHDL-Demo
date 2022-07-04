-------------------------------------------------------------------------------
-- Jason Kane
--
-- keyscheduler VHDL Routine
--
-- Input/Output:
-- Determines the current subkey (1 to 16)
-- User sets beginConvert high to begin calculation.
-- Hardware sets subkeyValid when done.
-- subkeyValid goes low again when beginConvert input is set low. 
--
-- How it works:
-- When a conversion is requested, the original key is permuted (PC-1)
-- Next the data is broken up into C and D buffers.
-- The proper amount of left shifts are then made.
-- Finally, C and D are recombined.  Then the final permutation occurs (PC-2)
-------------------------------------------------------------------------------
LIBRARY IEEE;
USE IEEE.std_logic_1164.all;
USE IEEE.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity keyscheduler is 
	port (
		reset:		  in  std_logic;
		clock:		  in  std_logic;
		beginConvert: in  std_logic;
		key:		  in  std_logic_vector(0 to 63);
		subkeyNum: 	  in  std_logic_vector(0 to 3);
		subkey: 	  out std_logic_vector(0 to 47);
		subkeyValid:  out std_logic
	);
end keyscheduler;

architecture scheduler of keyscheduler is
	signal C: std_logic_vector(0 to 27);
	signal D: std_logic_vector(0 to 27);
	signal tempCombine: std_logic_vector(0 to 55);
	
	TYPE subkeyStateMachine IS (waitForSignal,shiftKey,recombine,
	                            permutedChoice2,waitForConvLow);
	SIGNAL keyState: subkeyStateMachine;
	
	
begin

	getSubkey: process(reset, clock, subkeyNum, beginConvert) is

	begin
		if(reset = '0') then
			subkeyValid <= '0';
			subkey <= X"000000000000";
			keystate <= waitForSignal;
		elsif(clock'event and clock = '1') then 	
			case keyState is
	
				when waitForSignal =>
					if(beginConvert = '1') then
						subkeyValid <= '0';
						
						-- Permuted Choice 1
						C(0) <= key(57-1);
						C(1) <= key(49-1);
						C(2) <= key(41-1);
						C(3) <= key(33-1);
						C(4) <= key(25-1);
						C(5) <= key(17-1);
						C(6) <= key(9-1);
						
						C(7) <= key(1-1);
						C(8) <= key(58-1);
						C(9) <= key(50-1);
						C(10) <= key(42-1);
						C(11) <= key(34-1);
						C(12) <= key(26-1);
						C(13) <= key(18-1);
						
						C(14) <= key(10-1);
						C(15) <= key(2-1);
						C(16) <= key(59-1);
						C(17) <= key(51-1);
						C(18) <= key(43-1);
						C(19) <= key(35-1);
						C(20) <= key(27-1);
						
						C(21) <= key(19-1);
						C(22) <= key(11-1);
						C(23) <= key(3-1);
						C(24) <= key(60-1);
						C(25) <= key(52-1);
						C(26) <= key(44-1);
						C(27) <= key(36-1);
						
												
						D(0) <= key(63-1);
						D(1) <= key(55-1);
						D(2) <= key(47-1);
						D(3) <= key(39-1);
						D(4) <= key(31-1);
						D(5) <= key(23-1);
						D(6) <= key(15-1);
						
						D(7) <= key(7-1);
						D(8) <= key(62-1);
						D(9) <= key(54-1);
						D(10) <= key(46-1);
						D(11) <= key(38-1);
						D(12) <= key(30-1);
						D(13) <= key(22-1);
						
						D(14) <= key(14-1);
						D(15) <= key(6-1);
						D(16) <= key(61-1);
						D(17) <= key(53-1);
						D(18) <= key(45-1);
						D(19) <= key(37-1);
						D(20) <= key(29-1);
						
						D(21) <= key(21-1);
						D(22) <= key(13-1);
						D(23) <= key(5-1);
						D(24) <= key(28-1);
						D(25) <= key(20-1);
						D(26) <= key(12-1);
						D(27) <= key(4-1);
						
						keyState <= shiftKey;
					end if;
					
				when shiftKey =>
					if(subkeyNum = X"0") then
						C <= std_logic_vector(unsigned(C) rol 1); -- C <= C(1 to 31) & C(0);
						D <= std_logic_vector(unsigned(D) rol 1); -- D <= D(1 to 31) & C(0);
					elsif(subkeyNum = X"1") then
						C <= std_logic_vector(unsigned(C) rol 2);
						D <= std_logic_vector(unsigned(D) rol 2);
					elsif(subkeyNum = X"2") then
						C <= std_logic_vector(unsigned(C) rol 4);
						D <= std_logic_vector(unsigned(D) rol 4);
					elsif(subkeyNum = X"3") then
						C <= std_logic_vector(unsigned(C) rol 6);
						D <= std_logic_vector(unsigned(D) rol 6);
					elsif(subkeyNum = X"4") then
						C <= std_logic_vector(unsigned(C) rol 8);
						D <= std_logic_vector(unsigned(D) rol 8);
					elsif(subkeyNum = X"5") then
						C <= std_logic_vector(unsigned(C) rol 10);
						D <= std_logic_vector(unsigned(D) rol 10);
					elsif(subkeyNum = X"6") then
						C <= std_logic_vector(unsigned(C) rol 12);
						D <= std_logic_vector(unsigned(D) rol 12);
					elsif(subkeyNum = X"7") then
						C <= std_logic_vector(unsigned(C) rol 14);
						D <= std_logic_vector(unsigned(D) rol 14);
					elsif(subkeyNum = X"8") then
						C <= std_logic_vector(unsigned(C) rol 15);
						D <= std_logic_vector(unsigned(D) rol 15);
					elsif(subkeyNum = X"9") then
						C <= std_logic_vector(unsigned(C) rol 17);
						D <= std_logic_vector(unsigned(D) rol 17);
					elsif(subkeyNum = X"A") then
						C <= std_logic_vector(unsigned(C) rol 19);
						D <= std_logic_vector(unsigned(D) rol 19);						
					elsif(subkeyNum = X"B") then
						C <= std_logic_vector(unsigned(C) rol 21);
						D <= std_logic_vector(unsigned(D) rol 21);						
					elsif(subkeyNum = X"C") then
						C <= std_logic_vector(unsigned(C) rol 23);
						D <= std_logic_vector(unsigned(D) rol 23);						
					elsif(subkeyNum = X"D") then
						C <= std_logic_vector(unsigned(C) rol 25);
						D <= std_logic_vector(unsigned(D) rol 25);						
					elsif(subkeyNum = X"E") then
						C <= std_logic_vector(unsigned(C) rol 27);
						D <= std_logic_vector(unsigned(D) rol 27);						
					else -- subkeyNum = X"F"
						C <= std_logic_vector(unsigned(C) rol 28);
						D <= std_logic_vector(unsigned(D) rol 28);
					end if;
					keystate <= recombine;

				when recombine =>
					tempCombine <= C & D;
					keystate <= permutedChoice2;

				when permutedChoice2 =>
				
					subkey(0) <= tempCombine(14-1);
					subkey(1) <= tempCombine(17-1);
					subkey(2) <= tempCombine(11-1);
					subkey(3) <= tempCombine(24-1);
					subkey(4) <= tempCombine(1-1);
					subkey(5) <= tempCombine(5-1);
					
					subkey(6) <= tempCombine(3-1);
					subkey(7) <= tempCombine(28-1);
					subkey(8) <= tempCombine(15-1);
					subkey(9) <= tempCombine(6-1);
					subkey(10) <= tempCombine(21-1);
					subkey(11) <= tempCombine(10-1);
					
					subkey(12) <= tempCombine(23-1);
					subkey(13) <= tempCombine(19-1);
					subkey(14) <= tempCombine(12-1);
					subkey(15) <= tempCombine(4-1);
					subkey(16) <= tempCombine(26-1);
					subkey(17) <= tempCombine(8-1);

					subkey(18) <= tempCombine(16-1);
					subkey(19) <= tempCombine(7-1);
					subkey(20) <= tempCombine(27-1);
					subkey(21) <= tempCombine(20-1);
					subkey(22) <= tempCombine(13-1);
					subkey(23) <= tempCombine(2-1);

					subkey(24) <= tempCombine(41-1);
					subkey(25) <= tempCombine(52-1);
					subkey(26) <= tempCombine(31-1);
					subkey(27) <= tempCombine(37-1);
					subkey(28) <= tempCombine(47-1);
					subkey(29) <= tempCombine(55-1);
					
					subkey(30) <= tempCombine(30-1);
					subkey(31) <= tempCombine(40-1);
					subkey(32) <= tempCombine(51-1);
					subkey(33) <= tempCombine(45-1);
					subkey(34) <= tempCombine(33-1);
					subkey(35) <= tempCombine(48-1);

					subkey(36) <= tempCombine(44-1);
					subkey(37) <= tempCombine(49-1);
					subkey(38) <= tempCombine(39-1);
					subkey(39) <= tempCombine(56-1);
					subkey(40) <= tempCombine(34-1);
					subkey(41) <= tempCombine(53-1);

					subkey(42) <= tempCombine(46-1);
					subkey(43) <= tempCombine(42-1);
					subkey(44) <= tempCombine(50-1);
					subkey(45) <= tempCombine(36-1);
					subkey(46) <= tempCombine(29-1);
					subkey(47) <= tempCombine(32-1);
					keystate <= waitForConvLow;
					
				when waitForConvLow =>
					subkeyValid <= '1';
					if(beginConvert = '0') then
						subkeyValid <= '0';
						keystate <= waitForSignal;
					end if;
					
				when others =>
					subkeyValid <= '0';
					subkey <= X"000000000000";
					keystate <= waitForSignal;
			end case;
		end if;
	end process;



end architecture scheduler;
