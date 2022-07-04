-------------------------------------------------------------------------------
-- Jason Kane
--
-- DES VHDL Routine
--
-- Input/Output:
-- Encrypts or Decrypts the given 64-bit block of Data using DES
-- The signal encrypt will determine the action

-- User sets beginDES high to begin calculation.
-- Hardware sets DES_outputValid when done.  Output in DES_dataOut.
-- DES_outputValid goes low again when beginDES input is set low. 
--
-------------------------------------------------------------------------------
LIBRARY IEEE;
USE IEEE.std_logic_1164.all;
USE IEEE.std_logic_unsigned.all;


entity DES is 
	port (
		reset:		   in  std_logic;
		clock:		   in  std_logic;
		beginDES:      in  std_logic;
		encrypt:	   in  std_logic; --When high, encrypt.  When low, decrypt.
		Key:	       in  std_logic_vector(0 to 63);
		inputBlock:	   in  std_logic_vector(0 to 63); 
		DES_dataOut:	   out std_logic_vector(0 to 63);
		DES_outputValid:   out std_logic
	);
end DES;

architecture encrypt_decrypt of DES is
	signal R,RP: std_logic_vector(0 to 31);
	signal L,LP: std_logic_vector(0 to 31);
	signal initPerm,preOutput: std_logic_vector(0 to 63);
	signal count:    std_logic_vector(0 to 3);
	signal subkey:   std_logic_vector(0 to 47);

	signal subkValid,keyStart: std_logic;
	
	signal F_RTN: std_logic_vector (0 to 31);
	signal F_begin, f_validout : std_logic;
	
	TYPE desStateMachine IS (waitForStart,initPermutation,firstAssignRandL,
	getSubKey,waitForSubkey,perform_F_Function,waitForF,checkIteration,
	assignRandL,inverseInitPerm,waitForBeginLow,waitForFInvalid,waitForKeyInvalid,
	assignPreOutput
	);
	SIGNAL desState: desStateMachine;
	

begin

	--Key Scheduler
	keySch: entity work.keyscheduler port map(
		reset => reset,
		clock => clock,
		beginConvert => keyStart,
		key => Key,
		subkeyNum => count,
		subkey => subkey,
		subkeyValid => subkValid
	);
	
	--F Function
	ffunc: entity work.f_function port map(
		reset => reset,
		clock => clock,
		beginFunction => F_begin,
		K_subkey => subkey,
		R => R,
		dataOut => F_RTN,
		outputValid => f_validout
	);


	
	performDES: process(reset, clock) is
		variable countUp: boolean;
	
	begin
		if(reset = '0') then
			DES_outputValid <= '0';
			count <= X"0";
	        keyStart <= '0';
	        F_begin <= '0';
			desState <= waitForStart;
		elsif(clock'event and clock = '1') then 	
			case desState is
	
				when waitForStart =>
					if(beginDES = '1') then
						DES_outputValid <= '0';
						if(encrypt = '1') then
							count <= X"0";
							countUp := true;
						else
							count <= X"F";
							countUp := false;
						end if;
						desState <= initPermutation;
					end if;
					
				when initPermutation=>
					--Perform Initial Permutation on Data
					initPerm(0)  <= inputBlock(58-1);
					initPerm(1)  <= inputBlock(50-1);
					initPerm(2)  <= inputBlock(42-1);
					initPerm(3)  <= inputBlock(34-1);
					initPerm(4)  <= inputBlock(26-1);
					initPerm(5)  <= inputBlock(18-1);
					initPerm(6)  <= inputBlock(10-1);
					initPerm(7)  <= inputBlock(2-1);
					
					initPerm(8)  <= inputBlock(60-1);
					initPerm(9)  <= inputBlock(52-1);
					initPerm(10) <= inputBlock(44-1);
					initPerm(11) <= inputBlock(36-1);
					initPerm(12) <= inputBlock(28-1);
					initPerm(13) <= inputBlock(20-1);
					initPerm(14) <= inputBlock(12-1);
					initPerm(15) <= inputBlock(4-1);
					
					initPerm(16) <= inputBlock(62-1);
					initPerm(17) <= inputBlock(54-1);
					initPerm(18) <= inputBlock(46-1);
					initPerm(19) <= inputBlock(38-1);
					initPerm(20) <= inputBlock(30-1);
					initPerm(21) <= inputBlock(22-1);
					initPerm(22) <= inputBlock(14-1);
					initPerm(23) <= inputBlock(6-1);
					
					initPerm(24) <= inputBlock(64-1);
					initPerm(25) <= inputBlock(56-1);
					initPerm(26) <= inputBlock(48-1);
					initPerm(27) <= inputBlock(40-1);
					initPerm(28) <= inputBlock(32-1);
					initPerm(29) <= inputBlock(24-1);
					initPerm(30) <= inputBlock(16-1);
					initPerm(31) <= inputBlock(8-1);
					
					initPerm(32) <= inputBlock(57-1);
					initPerm(33) <= inputBlock(49-1);
					initPerm(34) <= inputBlock(41-1);
					initPerm(35) <= inputBlock(33-1);
					initPerm(36) <= inputBlock(25-1);
					initPerm(37) <= inputBlock(17-1);
					initPerm(38) <= inputBlock(9-1);
					initPerm(39) <= inputBlock(1-1);
					
					initPerm(40) <= inputBlock(59-1);
					initPerm(41) <= inputBlock(51-1);
					initPerm(42) <= inputBlock(43-1);
					initPerm(43) <= inputBlock(35-1);
					initPerm(44) <= inputBlock(27-1);
					initPerm(45) <= inputBlock(19-1);
					initPerm(46) <= inputBlock(11-1);
					initPerm(47) <= inputBlock(3-1);
					
					initPerm(48) <= inputBlock(61-1);
					initPerm(49) <= inputBlock(53-1);
					initPerm(50) <= inputBlock(45-1);
					initPerm(51) <= inputBlock(37-1);
					initPerm(52) <= inputBlock(29-1);
					initPerm(53) <= inputBlock(21-1);
					initPerm(54) <= inputBlock(13-1);
					initPerm(55) <= inputBlock(5-1);
					
					initPerm(56) <= inputBlock(63-1);
					initPerm(57) <= inputBlock(55-1);
					initPerm(58) <= inputBlock(47-1);
					initPerm(59) <= inputBlock(39-1);
					initPerm(60) <= inputBlock(31-1);
					initPerm(61) <= inputBlock(23-1);
					initPerm(62) <= inputBlock(15-1);
					initPerm(63) <= inputBlock(7-1);
					
					desState <= firstAssignRandL;

				when firstAssignRandL =>
					L <= initPerm(0 to 31);
					R <= initPerm(32 to 63);
					desState <= getSubKey;
					
				when getSubKey =>
					keyStart <= '1';
					desState <= waitForSubkey;
					
				when waitForSubkey =>
					if(subkValid = '1') then
						keyStart <= '0';
						desState <= perform_F_Function;
					end if;
					
				when waitForKeyInvalid =>
					if(subkValid = '0') then
						desState <= perform_F_Function;
					end if;
					
				when perform_F_Function =>
					F_begin <= '1';
					desState <= waitForF;
					
				when waitForF =>
					if(f_validout = '1') then
						F_begin <= '0';
						LP <= R;
						RP <= L XOR F_RTN;
						desState <= waitForFInvalid;
					end if;
					
				when waitForFInvalid =>
					if(f_validout = '0') then
						desState <= checkIteration;
					end if;
					
				when checkIteration =>
							
					--Determine next state
				    if(countUp = true) then
						if(count = X"F") then						
							desState <= assignPreOutput;
						else
							count <= count + 1;
							desState <= assignRandL;
						end if;
					else
						if(count = X"0") then
							desState <= assignPreOutput;
						else
							count <= count - 1;
							desState <= assignRandL;
						end if;
					end if;

					
				when assignRandL =>
					L <= LP;
					R <= RP;
					desState <= getSubKey;
					
				when assignPreOutput =>
					preOutput(0 to 31) <=  RP;
					preOutput(32 to 63) <= LP;
					desState <= inverseInitPerm;

				when inverseInitPerm =>
					--Perform Inverse Permutation on Data
					DES_dataOut(0)  <= preOutput(40-1);
					DES_dataOut(1)  <= preOutput(8-1);
					DES_dataOut(2)  <= preOutput(48-1);
					DES_dataOut(3)  <= preOutput(16-1);
					DES_dataOut(4)  <= preOutput(56-1);
					DES_dataOut(5)  <= preOutput(24-1);
					DES_dataOut(6)  <= preOutput(64-1);
					DES_dataOut(7)  <= preOutput(32-1);
					
					DES_dataOut(8)  <= preOutput(39-1);
					DES_dataOut(9)  <= preOutput(7-1);
					DES_dataOut(10) <= preOutput(47-1);
					DES_dataOut(11) <= preOutput(15-1);
					DES_dataOut(12) <= preOutput(55-1);
					DES_dataOut(13) <= preOutput(23-1);
					DES_dataOut(14) <= preOutput(63-1);
					DES_dataOut(15) <= preOutput(31-1);
					
					DES_dataOut(16) <= preOutput(38-1);
					DES_dataOut(17) <= preOutput(6-1);
					DES_dataOut(18) <= preOutput(46-1);
					DES_dataOut(19) <= preOutput(14-1);
					DES_dataOut(20) <= preOutput(54-1);
					DES_dataOut(21) <= preOutput(22-1);
					DES_dataOut(22) <= preOutput(62-1);
					DES_dataOut(23) <= preOutput(30-1);
					
					DES_dataOut(24) <= preOutput(37-1);
					DES_dataOut(25) <= preOutput(5-1);
					DES_dataOut(26) <= preOutput(45-1);
					DES_dataOut(27) <= preOutput(13-1);
					DES_dataOut(28) <= preOutput(53-1);
					DES_dataOut(29) <= preOutput(21-1);
					DES_dataOut(30) <= preOutput(61-1);
					DES_dataOut(31) <= preOutput(29-1);
					
					DES_dataOut(32) <= preOutput(36-1);
					DES_dataOut(33) <= preOutput(4-1);
					DES_dataOut(34) <= preOutput(44-1);
					DES_dataOut(35) <= preOutput(12-1);
					DES_dataOut(36) <= preOutput(52-1);
					DES_dataOut(37) <= preOutput(20-1);
					DES_dataOut(38) <= preOutput(60-1);
					DES_dataOut(39) <= preOutput(28-1);
					
					DES_dataOut(40) <= preOutput(35-1);
					DES_dataOut(41) <= preOutput(3-1);
					DES_dataOut(42) <= preOutput(43-1);
					DES_dataOut(43) <= preOutput(11-1);
					DES_dataOut(44) <= preOutput(51-1);
					DES_dataOut(45) <= preOutput(19-1);
					DES_dataOut(46) <= preOutput(59-1);
					DES_dataOut(47) <= preOutput(27-1);
					
					DES_dataOut(48) <= preOutput(34-1);
					DES_dataOut(49) <= preOutput(2-1);
					DES_dataOut(50) <= preOutput(42-1);
					DES_dataOut(51) <= preOutput(10-1);
					DES_dataOut(52) <= preOutput(50-1);
					DES_dataOut(53) <= preOutput(18-1);
					DES_dataOut(54) <= preOutput(58-1);
					DES_dataOut(55) <= preOutput(26-1);
					
					DES_dataOut(56) <= preOutput(33-1);
					DES_dataOut(57) <= preOutput(1-1);
					DES_dataOut(58) <= preOutput(41-1);
					DES_dataOut(59) <= preOutput(9-1);
					DES_dataOut(60) <= preOutput(49-1);
					DES_dataOut(61) <= preOutput(17-1);
					DES_dataOut(62) <= preOutput(57-1);
					DES_dataOut(63) <= preOutput(25-1);

					desState <=	waitForBeginLow;				

					
				when waitForBeginLow =>
					DES_outputValid <= '1';
					if(beginDES = '0') then
						DES_outputValid <= '0';
						desState <= waitForStart;
					end if;

				
				when others =>
					DES_outputValid <= '0';
					count <= X"0";
					countUp := true;
			        keyStart <= '0';
			        F_begin <= '0';
					desState <= waitForStart;
			end case;
							
		end if;
	end process;



	 
end architecture encrypt_decrypt;
