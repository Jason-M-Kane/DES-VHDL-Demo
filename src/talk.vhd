LIBRARY IEEE;
library altera_mf;
USE IEEE.std_logic_1164.all;
USE IEEE.std_logic_unsigned.all;
use altera_mf.altera_mf_components.all;

ENTITY talk IS
	PORT(
			CLOCK_50: IN std_logic;
			KEY: IN std_logic_vector(3 downto 0);
			SW: IN std_logic_vector(17 downto 0);
			VGA_R, VGA_G, VGA_B : OUT std_logic_vector(9 downto 0);
			VGA_HS : OUT std_logic;
			VGA_VS : OUT std_logic;
			VGA_CLK, VGA_BLANK: OUT STD_LOGIC;
			HEX0, HEX1, HEX2, HEX3, HEX4, HEX5, HEX6, HEX7: OUT std_logic_vector(6 DOWNTO 0);
			uart_rxd: in std_logic;
			uart_txd: out std_logic;
			ps2_clk:  in std_logic;
			ps2_dat: in std_logic
			);
END talk;



ARCHITECTURE talk of talk IS 
	signal mem_in, mem_out, data: std_logic_vector(11 downto 0);
	signal char_in: std_logic_vector(5 downto 0);
	signal mem_adr: std_logic_vector(12 downto 0);
	signal mem_wr: std_logic;
	signal x, saveX, x1, x2 : std_logic_vector (6 downto 0);
	signal y, saveY, y1, y2 : std_logic_vector (5 downto 0);
	signal scan_code, new_scan_code, ascii: std_logic_vector(7 downto 0);
	signal code_buf: std_logic_vector(23 downto 0);
	signal ready, ack: std_logic;
	
	--Serial Port Variables
	signal rx_data, new_rx_data, tx_data: std_logic_vector(7 downto 0);
	signal rx_rdy, rx_ack, tx_rdy, tx_ack: std_logic;
	
	--Display Text Variables
   	signal textPtr	: std_logic_vector(6 downto 0);
	signal displayText : std_logic_vector(11 downto 0);
	
	--Encryption/Decryption/Line Clear
	signal encryptAndSend,clrMsg : std_logic;
	signal decryptedMsgAvail,decryptedMsgAck: std_logic;
	
	signal DES_KEY: std_logic_vector(0 to 63);
	signal nibbleVal: std_logic_vector(0 to 3);

    --Local Ram for unencrypted data msgs
    signal localAddr,savedLocalAddr: std_logic_vector(5 downto 0);
    signal asciiIn,userOutput : std_logic_vector(7 downto 0);
    signal userInputWen: std_logic;

	--Spare ram inputs
	signal spareAddr1,spareAddr2,spareAddr3: std_logic_vector(5 downto 0);
    signal spareasciiIn1,spareOutput1,spareasciiIn2,spareOutput2,spareasciiIn3,spareOutput3 : std_logic_vector(7 downto 0);
    signal spareuserInputWen1,spareuserInputWen2,spareuserInputWen3: std_logic;

    --Local Ram for data encryption
    signal elocalAddr: std_logic_vector(5 downto 0);
    signal easciiIn,euserOutput : std_logic_vector(7 downto 0);
    signal euserInputWen: std_logic;

    --Remote Ram to be decrypted
    signal remoteAddr,remoteAddrB,d_remoteAddr: std_logic_vector(5 downto 0);
    signal rasciiIn,ruserOutput,rasciiInB,ruserOutputB,d_rasciiIn,d_ruserOutput : std_logic_vector(7 downto 0);
    signal ruserInputWen,ruserInputWenB,d_ruserInputWen: std_logic;
   
	signal clear_single_clock, encrypt_single_clock: std_logic;
    
	-- DES Unit Signals
   	signal blockData: std_logic_vector(0 to 63);
	signal outputData: std_logic_vector(0 to 63);
	signal outputValid,startDESCalc,rx_disabled,encrypt_h: std_logic;
	
	--Signals used to output user encrypted data to screen
	signal hiNibble,lowNibble: std_logic_vector(7 downto 0);
	signal color: std_logic_vector(3 downto 0);	
	
	TYPE RECVstate IS (wait_for_RX_ready,RS_received,saveRxData,
				waitSaveState,rxSaveComplete,checkForLastData
				);
	SIGNAL rxState : RECVstate;
	
	TYPE state IS ( clean0, clean1, clean2, clean3, 
					line0, line1, line2, line3,
					wait_for_KB_ready, 
					shift_code, new_key, wait_convert, 
					host, new0, new1, new2, new3,
					RS_received,
					text0,text1,text1a,text1b,text1c,text1d,
					key0,key0a,key1,key2,key3,wait_for_KEY_KB_ready,KEY_shift_code,KEY_new_key,KEY_wait_convert,
					KEY_new1,KEY_new2,KEY_new3,KEY_new4,KEY_new5,
					msgEntry,msgEntry0a,msgEntry1,msgEntry2,msgEntry3,
					Msgclean0,Msgclean1,Msgclean2,Msgclean3,
					checkForEncryptRequest,checkForIncomingMsgDisp,checkForClearInput,
					encryptMessage, readWaitState, ReadDataFromRAM, checkOffset, encryptData, waitForCalcDone, waitForOutputValidLow, 
					saveEncryptedData0, saveEncryptedData1,saveEncryptedData2,saveEncryptedData3,checkForDoneEncrypt,
					displayEncryptedData, displayEncrypted0,displayEncrypted1,displayEncrypted2,displayEncrypted3,displayEncrypted4,
					displayEncrypted5,displayEncrypted6,displayEncrypted7,displayEncrypted8,displayEncrypted9,displayEncrypted10,
					checkEncrDisplayDone,TXSetupWait,TXdata,wait_for_tx_done,displayRXMsg,
					displayEncryptedData_Remote, displayEncrypted0_Remote,displayEncrypted1_Remote,displayEncrypted2_Remote,
					displayEncrypted3_Remote,displayEncrypted4_Remote,displayEncrypted5_Remote,displayEncrypted6_Remote,
					displayEncrypted7_Remote,displayEncrypted8_Remote,displayEncrypted9_Remote,
					displayEncrypted10_Remote,checkEncrDisplayDone_Remote,DecryptData,
					decrypt_readWaitState,decrypt_ReadDataFromRAM,decrypt_checkOffset,decrypt_the_Data,decrypt_waitForCalcDone,
					decrypt_waitForOutputValidLow,displayDecryptedData0,displayDecryptedData1,displayDecryptedData2,displayDecryptedData3,
					displayDecryptedData4,displayDecryptedData5,checkForDoneDecrypt,
					DecryptDataWait1,DecryptDataWait2,DecryptDataWait3			
					);
	SIGNAL SV : state;
	
	TYPE BUTTONstate IS (checkClr, checkClrHi, checkEncry, checkEncryHi,waitState);
	SIGNAL bState : BUTTONstate;
	
BEGIN

   --RS-232 Module
   rs232 : entity work.rs232 generic map(
      CLOCK_FREQUENCY => 50 * 1000 * 1000,
      BAUD_RATE => 9600
   )
   port map(
      clock => clock_50,
      reset => not key(0),
      rx_data => rx_data,
      tx_data => tx_data,
      rx_rdy => rx_rdy,
      rx_ack => rx_ack,
      tx_rdy => tx_rdy,
      tx_ack => tx_ack,
      rx => uart_rxd,
      tx => uart_txd
   );
 
    --VGA Output Module
    vga : entity work.vga port map(	--This declares the module that generates
      clock => clock_50,			--VGA horizontal and vertical synchronization
      refclock => clock_50,			--signals. It also contains a video memory
      reset => not key(0),			--which can be accessed here.
      mem_adr => mem_adr,
      mem_out => mem_out,
      mem_in => mem_in,
      mem_wr => mem_wr,   
      pclock => vga_clk,
      vga_hs => vga_hs,
      vga_vs => vga_vs,
      r => vga_r,
      g => vga_g,
      b => vga_b,
      blank => vga_blank
   );
   
   --Text ROM used for displaying Static Text
   DisplayTextRom: altsyncram generic map(
        WIDTH_A => 12,
        WIDTHAD_A => 7,
        NUMWORDS_A => 128,
        operation_mode => "ROM",
	    init_file => "textRom.mif"
    )
    port map(
        clock0 => clock_50,
        address_a => textPtr(6 downto 0),
        q_a => displayText
    );
    

	--Keyboard Module
	ps2keyboard: entity work.keyboard port map(
		clock => clock_50,
		reset => not key(0),     
		scan_code => scan_code,
		ready => ready,
		ack => ack,     
		ps2clk => ps2_clk,
		ps2data => ps2_dat
	);
    Scan_code_to_ASCII_table: altsyncram generic map(
        WIDTH_A => 8,
        WIDTHAD_A => 7,
        NUMWORDS_A => 128,
        operation_mode => "ROM",
	    init_file => "k2a.mif"
    )
    port map(
        clock0 => clock_50,
        address_a => new_scan_code(6 downto 0),
        q_a => ascii
    );
    


	
    --RAM for storing unencrypted msgs	
	localMsgRam : altsyncram generic map(
      WIDTH_A => 8,
      WIDTHAD_A => 6,		
      NUMWORDS_A => 56, 	
      WIDTH_B => 8,
      WIDTHAD_B => 6,		
      NUMWORDS_B => 56 	
   )
   port map(
      clock0 => clock_50,
      address_a => localAddr,
      q_a => userOutput,
      data_a => asciiIn,	
      wren_a => userInputWen,
      clock1 => clock_50,
      address_b => spareAddr1,
      q_b => spareOutput1,
      data_b => spareasciiIn1,	
      wren_b => spareuserInputWen1
   );
    
    --RAM for sending encrypted msgs
	localMsgRamEncrypted : altsyncram generic map(
      WIDTH_A => 8,
      WIDTHAD_A => 6,		
      NUMWORDS_A => 56, 	
      WIDTH_B => 8,
      WIDTHAD_B => 6,			
      NUMWORDS_B => 56 	
   )
   port map(
      clock0 => clock_50,
      address_a => elocalAddr,
      q_a => euserOutput,
      data_a => easciiIn,	
      wren_a => euserInputWen,
      clock1 => clock_50,
      address_b => spareAddr2,
      q_b => spareOutput2,
      data_b => spareasciiIn2,	
      wren_b => spareuserInputWen2
   );


    --RAM for recving encrypted msgs
	remoteMsgRamEncrypted : altsyncram generic map(
      WIDTH_A => 8,
      WIDTHAD_A => 6,		
      NUMWORDS_A => 56, 	
      WIDTH_B => 8,
      WIDTHAD_B => 6,		
      NUMWORDS_B => 56 	
   )
   port map(
      clock0 => clock_50,
      address_a => remoteAddr,
      q_a => ruserOutput,
      data_a => rasciiIn,	
      wren_a => ruserInputWen,
      clock1 => clock_50,
      address_b => remoteAddrB,
      q_b => ruserOutputB,
      data_b => rasciiInB,	
      wren_b => ruserInputWenB
   );
   
   
--    --RAM for decrypting recvd msgs
--	remoteMsgRamEncrypted : altsyncram generic map(
--      WIDTH_A => 8,
--      WIDTHAD_A => 6,		
--      NUMWORDS_A => 56, 	
--      WIDTH_B => 8,
--      WIDTHAD_B => 6,		
--      NUMWORDS_B => 56 	
--   )
--   port map(
--      clock0 => clock_50,
--      address_a => d_remoteAddr,
--      q_a => d_ruserOutput,
--      data_a => d_rasciiIn,	
--      wren_a => d_ruserInputWen,
--      clock1 => clock_50,
--      address_b => spareAddr3,
--      q_b => spareOutput3,
--      data_b => spareasciiIn3,	
--      wren_b => spareuserInputWen3
--   );


	
	
	--DES Encryption Unit
	desEncryptionUnit: entity work.DES port map(
		reset => key(0),
		clock => CLOCK_50,
		beginDES => startDESCalc,
		encrypt => encrypt_h,
		key => DES_KEY,
		inputBlock => blockData,
		DES_dataOut => outputData,
		DES_outputValid => outputValid
	);
    
    --HEX LED Displays
	display0:	entity work.sevenseg port map (blockData(28 to 31),   HEX0);
	display1:	entity work.sevenseg port map (blockData(24 to 27),   HEX1);
	display2:	entity work.sevenseg port map (blockData(20 to 23),  HEX2);
	display3:	entity work.sevenseg port map (blockData(16 to 19), HEX3);
	display4:	entity work.sevenseg port map (blockData(12 to 15), HEX4);
	display5:	entity work.sevenseg port map (blockData(8 to 11), HEX5);
	display6:	entity work.sevenseg port map (remoteAddr(3 downto 0), HEX6);
	display7:	entity work.sevenseg port map ("00" & remoteAddr(5 downto 4), HEX7);


	
	mem_adr <= y & x;	--The address to video memory 


	clear_debounce : entity work.debounce generic map(
      CYCLES => 50
    )
	port map(
      pin => SW(0),
      output => clear_single_clock,
      clock => clock_50
	);
	encrypt_debounce : entity work.debounce generic map(
      CYCLES => 50
    )
	port map(
      pin => SW(1),
      output => encrypt_single_clock,
      clock => clock_50
	);



	
	
	BUTTON_CMDS: PROCESS(CLOCK_50, KEY(0),clear_single_clock,encrypt_single_clock)
	variable waitCntr: integer range 0 to 50;
	BEGIN
		IF(KEY(0) = '0') THEN		--Reset
			encryptAndSend <= '0';
			clrMsg <= '0';
			waitCntr:=0;
			bState <= checkClr;
		elsif(clock_50'event and clock_50 = '1') then
			CASE bState IS
				WHEN checkClr =>
					if(clear_single_clock = '0') then
						bState <= checkClrHi;
					else
						bState <= checkEncry;
					end if;
				WHEN checkClrHi =>
					if(clear_single_clock = '1') then
						clrMsg <= '1';
						waitCntr:=0;
						bState <= waitState;
					end if;
				WHEN checkEncry =>
					if(encrypt_single_clock = '0') then
						bState <= checkEncryHi;
					else
						bState <= checkClr;
					end if;
				WHEN checkEncryHi =>
					if(encrypt_single_clock = '1') then
						encryptAndSend <= '1';
						waitCntr:=0;
						bState <= waitState;
					end if;
				WHEN waitState =>
					if(waitCntr = 20) then
						clrMsg <= '0';
						encryptAndSend <= '0';
						bState <= checkClr;
					else
						waitCntr := waitCntr + 1;
					end if;
				WHEN others =>
					encryptAndSend <= '0';
					clrMsg <= '0';
					waitCntr:=0;
					bState <= checkClr;
			end case;
		end if;
	END PROCESS;
	
	
	Receive_from_Keyboard: PROCESS(CLOCK_50, KEY(0))
	variable hexCnter: integer range 0 to 80; 
	variable dataCnter: integer range 0 to 10;
	variable offsetCnter: integer range 0 to 80;
	variable txDelay : integer range 0 to 5000000;
	
	BEGIN
		IF(KEY(0) = '0') THEN		
			code_buf <= "--------11110000--------";
			startDESCalc <= '0';
			ack <= '0';
			hexCnter := 0;
			tx_rdy <= '0';
			decryptedMsgAck <= '0';
			userInputWen <= '0';
			euserInputWen <= '0';
			mem_wr <= '0';		------------------------------
			x <= "0000000";		--initialization
			y <= "000000";		-- x=0 and y=0
			SV <= clean0;	
			
		ELSIF(CLOCK_50'event AND CLOCK_50 = '1') THEN
			CASE SV IS
				WHEN clean0 =>			--------------------------
					mem_wr <= '1';		--clear the entire screen
					mem_in <= "001000000000";	--screen size is 80x60
					SV <= clean1;
				WHEN clean1 =>
					x <= x+1;
					SV <= clean2;
				WHEN clean2 =>
					mem_wr <= '0';		-- disable the write enable
					if(x> 79) then 
						x<= "0000000";
						y <= y+1;
						SV <= clean3;
					else
						SV <= clean0;
					end if;
				WHEN clean3 =>
					if(y > 59) then	
						SV <= line0;		-- Done cleaning screen
					else
						SV <= clean0;
					end if;
				
				-----------------------------------------------
				-- Draw a line in the middle of the screen.
				-----------------------------------------------
				WHEN line0 =>
					x <= "0000000";
					y <= "011111";
					SV <= line1;
				WHEN line1 =>			
					mem_wr <= '1';		
					mem_in <= "001011010011";  -- "-" as separator line	
					SV <= line2;
				WHEN line2 =>
					x <= x+1;
					SV <= line3;
				WHEN line3 =>
					mem_wr <= '0';		
					if(x> 79) then 
						x<= "0000000";
						y <= y+1;
						SV <= text0;
					else
						SV <= line1;
					end if;

				---------------------------------------------
				-- Draw Default Screen Text
				---------------------------------------------
				WHEN text0 =>
					x <= "0000000";
					y <= "00" & X"4";
					textPtr <= "0000000"; --Write: Mode=DES
					SV <= text1;
					
				WHEN text1 =>			
					mem_wr <= '1';		
					mem_in <= displayText;
					
					SV <= text1a;
				WHEN text1a =>
					SV <= text1b;
					
				WHEN text1b =>
					mem_wr <= '0';
					SV <= text1c;
					
				WHEN text1c =>
					textPtr <= textPtr + 1;
					SV <= text1d;
					
				WHEN text1d =>

					if(textPtr = X"0E") then -- Write: Key
						x <= "000" & X"0";
						y <= "00" & X"A"; --0xA
						SV <= text1;
					elsif(textPtr = X"12") then -- Write: Msg To Send
						x <= "000" & X"0";
						y <= "00" & X"F"; -- 0x0F
						SV <= text1;
					elsif(textPtr = X"22") then -- Write: Encrypted
						x <= "000" & X"0";
						y <= "01" & X"5"; --0x15
						SV <= text1;
					elsif(textPtr = X"2C") then -- Write: Recvd Msg
						x <= "000" & X"0";
						y <= "10" & X"5"; --0x25
						SV <= text1;
					elsif(textPtr = X"3D") then -- Write: Decrypted
						x <= "000" & X"0";
						y <= "11" & X"2"; --0x32
						SV <= text1;
					elsif(textPtr = X"47") then
						x <= "000" & X"0";
						y <= "00" & X"0";
						SV <= key0;
					else
						x <= x + 1;
						SV <= text1;
					end if;

				----------------------------------------------
				-- Enter Key Prior to Start
				----------------------------------------------
				WHEN key0 =>
					hexCnter := 0;
					x <= "000" & X"4";
					y <= "00" & X"A";
					SV <= key0a;
				WHEN key0a =>
					x <= x+1;
					SV <= key1;
				WHEN key1 =>			-- draw cursor
					mem_wr <= '1';		
					mem_in <= "000111101111";	-- "_" cursor
					SV <= key2;
				WHEN key2 =>
					SV <= key3;
				WHEN key3 =>
					mem_wr <= '0';
					SV <= wait_for_KEY_KB_ready;
				WHEN wait_for_KEY_KB_ready =>	
					if (ready = '1') then
						SV <= KEY_shift_code;
					else
						ack <= '0';
					end if;
					
				
				-------------------------------------------------
				-- Filter and convert scan code from keyboard
				-------------------------------------------------	
				WHEN KEY_shift_code =>
					code_buf <= code_buf(15 downto 0) & scan_code;
					SV <= KEY_new_key;
				WHEN KEY_new_key =>
					ack <= '1';
					if(code_buf(15 downto 8)/= X"F0" and 
						code_buf(7 downto 0) /= X"E0" and
						code_buf(7 downto 0) /= X"F0") then
						new_scan_code <= scan_code;
						SV <= KEY_wait_convert;
					else
						SV <= wait_for_KEY_KB_ready; -- non-printable code
					end if;
				WHEN KEY_wait_convert =>
					SV <= KEY_new1;

				
				------------------------------------------------
				-- Display the printable ASCII codes on screen
				------------------------------------------------	
				WHEN KEY_new1 =>

					--Check that valid hex data is being entered
					if( ((ascii >= X"30") AND (ascii <= X"39")) OR 
						((ascii >= X"41") AND (ascii <= X"46")) ) then
						SV <= KEY_new2;
					else
						SV <= wait_for_KEY_KB_ready;
					end if;
				WHEN KEY_new2 =>			
					--Write Ascii Code
					mem_wr <= '1';		
					mem_in <= "00" & ascii(5 downto 0) & "1111";
					
					--Determine Nibble Value for the Key
					if(ascii <= X"39") then
						nibbleVal <= ascii(3 downto 0);
					else
						nibbleVal <= ascii(3 downto 0) + X"9";
					end if;
					
					SV <= KEY_new3;
				WHEN KEY_new3 =>
					--Assign Key nibble value
					DES_KEY(hexCnter to (hexCnter+3)) <= nibbleVal;
					SV <= KEY_new4;
				WHEN KEY_new4 =>
					hexCnter := hexCnter + 4;
					mem_wr <= '0';
					SV <= KEY_new5;
				WHEN KEY_new5 =>
					if(hexCnter = 64) then
						SV <= msgEntry;
					else
						SV <= key0a;
					end if;
				
				
				
				
				----------------------------------------------
				-- Text Msg Entry
				----------------------------------------------
				WHEN msgEntry =>
					--Init RAM
					userInputWen <= '0';
					localAddr <= "000000";
					
					hexCnter := 0;
					x <= "000" & X"0";
					y <= "01" & X"2";
					SV <= Msgclean0;
					
				WHEN Msgclean0 =>			
					mem_wr <= '1';				--clear the msg line
					mem_in <= "001000000000";	--screen width is 80
					userInputWen <= '1';
					asciiIn <= "00100000";
					SV <= Msgclean1;
				WHEN Msgclean1 =>
					SV <= Msgclean2;
				WHEN Msgclean2 =>
					mem_wr <= '0';		-- disable the write enable
					userInputWen <= '0';
					if(x = 58) then 
						localAddr <= "000000";
						x <= "000" & X"0";
						SV <= msgEntry0a;
					else
						SV <= Msgclean3;
					end if;
				WHEN Msgclean3 =>
					x <= x+1;
					localAddr <= localAddr + 1;
					SV <= Msgclean0;
					
					
				WHEN msgEntry0a =>
					x <= x+1;
					SV <= msgEntry1;
				WHEN msgEntry1 =>			-- draw cursor
					mem_wr <= '1';		
					mem_in <= "000111101111";	-- "_" cursor
					SV <= msgEntry2;
				WHEN msgEntry2 =>
					SV <= msgEntry3;
				WHEN msgEntry3 =>
					mem_wr <= '0';
					SV <= wait_for_KB_ready;
					

				------------------------------------------
				-- Scan through KB, RS232 RX and TX
				------------------------------------------	
				WHEN wait_for_KB_ready =>	
					if (ready = '1') then
						SV <= shift_code;
					else
						ack <= '0';
						SV <= checkForEncryptRequest;
					end if;
				
				WHEN checkForEncryptRequest =>
					if(encryptAndSend = '1') then
						savedLocalAddr <= localAddr;
						SV <= encryptMessage;
					else
						SV <= checkForIncomingMsgDisp;
					end if;
					
				WHEN checkForIncomingMsgDisp =>
					if(decryptedMsgAvail = '1') then
						SV <= displayRXMsg;
					else
						SV <= checkForClearInput;
					end if;
					
			
				WHEN checkForClearInput =>
					if(clrMsg = '1') then
						SV <= msgEntry;
					else
						SV <= wait_for_KB_ready;
					end if;
				

				-------------------------------------------------
				-- Filter and convert scan code from keyboard
				-------------------------------------------------	
				WHEN shift_code =>
					code_buf <= code_buf(15 downto 0) & scan_code;
					SV <= new_key;
				WHEN new_key =>
					ack <= '1';
					if(code_buf(15 downto 8)/= X"F0" and 
						code_buf(7 downto 0) /= X"E0" and
						code_buf(7 downto 0) /= X"F0") then
						new_scan_code <= scan_code;
						SV <= wait_convert;
					else
						SV <= wait_for_KB_ready; -- non-printable code
					end if;
				WHEN wait_convert =>
					SV <= new0;
				--------------------------------------------------------
				-- Display the printable ASCII codes on screen And Save
				--------------------------------------------------------	
				WHEN new0 =>		
					if(hexCnter < 56) then
						--Write Ascii Code
						mem_wr <= '1';		
						mem_in <= "00" & ascii(5 downto 0) & "1111";
					
						asciiIn <= ascii; --Copy to RAM
						userInputWen <= '1';
						
						SV <= new1;
					else
						SV <= wait_for_KB_ready;
					end if;
				WHEN new1 =>
					SV <= new2;
				WHEN new2 =>
					mem_wr <= '0';
					userInputWen <= '0';
					SV <= new3;
					
				WHEN new3 =>
					hexCnter := hexCnter + 1;
					localAddr <= localAddr + 1;
					SV <= msgEntry0a;



				----------------------------------------------
				-- Encrypt Message, display to screen, and TX
				----------------------------------------------
				WHEN encryptMessage =>
					dataCnter := 0;
					offsetCnter := 0;
					encrypt_h <= '1';
					localAddr <= "000000";
					elocalAddr <= "000000";
					SV <= readWaitState;
				WHEN readWaitState =>
					SV <= ReadDataFromRAM;
				WHEN ReadDataFromRAM =>
					blockData(offsetCnter to offsetCnter+7) <= userOutput;
					SV <= checkOffset;
				WHEN checkOffset =>
					if(offsetCnter+7 = 63) then
						dataCnter := dataCnter + 1;
						SV <= encryptData;
					else
						offsetCnter := offsetCnter + 8;
						localAddr <= localAddr + 1;
						SV <= readWaitState;
					end if;
				WHEN encryptData =>
					startDESCalc <= '1';
					SV <= waitForCalcDone;
				when waitForCalcDone =>
					if(outputValid  = '1') then
						startDESCalc <= '0';
						SV <= waitForOutputValidLow;
					end if;
				when waitForOutputValidLow =>
					if(outputValid = '0') then
						SV <= saveEncryptedData0;
					end if;
				
				when saveEncryptedData0 =>
					offsetCnter := 0;
					SV <= saveEncryptedData1;
					
				when saveEncryptedData1 =>
					euserInputWen <= '1';
					easciiIn <= outputData(offsetCnter to offsetCnter+7);
					SV <= saveEncryptedData2;
					
				when saveEncryptedData2 =>
					SV <= saveEncryptedData3;
				
				when saveEncryptedData3 =>
					euserInputWen <= '0';
					elocalAddr <= elocalAddr + 1;
					if(offsetCnter+7 = 63) then
						SV <= checkForDoneEncrypt;
					else
						offsetCnter := offsetCnter + 8;
						SV <= saveEncryptedData1;
					end if;
					
				when checkForDoneEncrypt =>
					if(dataCnter = 7) then --56 words
						saveX <= x;
						saveY <= y;
						SV <= displayEncryptedData;
					else
						offsetCnter := 0;
						localAddr <= localAddr + 1;
						SV <= readWaitState;
					end if;

					
				when displayEncryptedData =>
					
					if(encrypt_single_clock = '1') then
						elocalAddr <= "000000";
						x <= "0000000";
						y <= "01" & X"7";
						SV <= displayEncrypted0;
					end if;
					
				when displayEncrypted0 =>
					SV <= displayEncrypted1;
				
				when displayEncrypted1 =>
					hiNibble <= X"0" & euserOutput(7 downto 4);
					lowNibble <= X"0" & euserOutput(3 downto 0);
					color <= "00" & y(1 downto 0);
					SV <= displayEncrypted2;
				
				when displayEncrypted2 =>
					if(hiNibble >= X"0A") then
						hiNibble <= hiNibble + x"37";
					else
						hiNibble <= hiNibble + x"30";
					end if;
					if(lowNibble >= X"0A") then
						lowNibble <= lowNibble + x"37";
					else
						lowNibble <= lowNibble + x"30";
					end if;
					SV <= displayEncrypted3;
				
				when displayEncrypted3 =>
					mem_wr <= '1';		
					mem_in <= hiNibble & NOT(color);
					SV <= displayEncrypted4;
					
				when displayEncrypted4 =>		
					SV <= displayEncrypted5;
				
				when displayEncrypted5 =>
					mem_wr <= '0';
					SV <= displayEncrypted6;
				
				when displayEncrypted6 =>
					x <= x + 1;
					SV <= displayEncrypted7;
				
				when displayEncrypted7 =>
					mem_wr <= '1';
					mem_in <= lowNibble & NOT(color);
					SV <= displayEncrypted8;
					
				when displayEncrypted8 =>		
					SV <= displayEncrypted9;
				
				when displayEncrypted9 =>
					mem_wr <= '0';
					SV <= displayEncrypted10;
					
				when displayEncrypted10 =>
					x <= x + 2;
					elocalAddr <= elocalAddr+1;
					SV <= checkEncrDisplayDone;
				
				when checkEncrDisplayDone =>
					if(elocalAddr >= "111000") then
						localAddr <= "00" & X"0";
						elocalAddr <= "00" & X"0";
						txDelay := 0;
						SV <= TXSetupWait;
					else
						if(x > 75) then
							x <= "0000000";
							y <= y+1;
						end if;
						SV <= displayEncrypted0;
					end if;
	
				--Transmit all 56 bytes of encrypted data
				--Format is: FEED followed by 56 data bytes
				when TXSetupWait =>
				    if(txDelay = 5000000) then
						SV <= TXdata;
					else
						txDelay := txDelay + 1;
					end if;
		
				when TXdata =>
					tx_data <= euserOutput;  -- Send out hex data
					tx_rdy <= '1';		     -- via RS232 TX
					SV <= wait_for_tx_done;
					
				WHEN wait_for_tx_done =>
					if(tx_ack = '1') then
					    if(elocalAddr < 55) then
							elocalAddr <= elocalAddr+1;
							txDelay := 0;
							SV <= TXSetupWait;
						else
							x <= saveX;
							y <= saveY;
							elocalAddr <= "00" & X"0";
							localAddr <= savedLocalAddr;
							SV <= wait_for_KB_ready;
						end if;
						tx_rdy <= '0';
						tx_data <= (others => '0');	
					end if;	
					


				------------------------------------------------------------
				-- Display the Received Encrypted Msg in hex
				-- As well as the decrypted version of that msg in plaintext
				------------------------------------------------------------
				WHEN displayRXMsg =>
					saveX <= x;
					saveY <= y;
					SV <= displayEncryptedData_Remote;
					
				when displayEncryptedData_Remote =>
					remoteAddrB <= "000000";
					x <= "0000000";
					y <= "10" & X"7";
					SV <= displayEncrypted0_Remote;
					
				when displayEncrypted0_Remote =>
					SV <= displayEncrypted1_Remote;
				
				when displayEncrypted1_Remote =>
					hiNibble <= X"0" & ruserOutputB(7 downto 4);
					lowNibble <= X"0" & ruserOutputB(3 downto 0);
					color <= "00" & y(1 downto 0);
					SV <= displayEncrypted2_Remote;
				
				when displayEncrypted2_Remote =>
					if(hiNibble >= X"0A") then
						hiNibble <= hiNibble + x"37";
					else
						hiNibble <= hiNibble + x"30";
					end if;
					if(lowNibble >= X"0A") then
						lowNibble <= lowNibble + x"37";
					else
						lowNibble <= lowNibble + x"30";
					end if;
					SV <= displayEncrypted3_Remote;
				
				when displayEncrypted3_Remote =>
					mem_wr <= '1';		
					mem_in <= hiNibble & NOT(color);
					SV <= displayEncrypted4_Remote;
					
				when displayEncrypted4_Remote =>		
					SV <= displayEncrypted5_Remote;
				
				when displayEncrypted5_Remote =>
					mem_wr <= '0';
					SV <= displayEncrypted6_Remote;
				
				when displayEncrypted6_Remote =>
					x <= x + 1;
					SV <= displayEncrypted7_Remote;
				
				when displayEncrypted7_Remote =>
					mem_wr <= '1';
					mem_in <= lowNibble & NOT(color);
					SV <= displayEncrypted8_Remote;
					
				when displayEncrypted8_Remote =>		
					SV <= displayEncrypted9_Remote;
				
				when displayEncrypted9_Remote =>
					mem_wr <= '0';
					SV <= displayEncrypted10_Remote;
					
				when displayEncrypted10_Remote =>
					x <= x + 2;
					remoteAddrB <= remoteAddrB+1;
					SV <= checkEncrDisplayDone_Remote;
				
				when checkEncrDisplayDone_Remote =>
					if(remoteAddrB >= "111000") then
						SV <= DecryptData;
					else
						if(x > 75) then
							x <= "0000000";
							y <= y+1;
						end if;
						SV <= displayEncrypted0_Remote;
					end if;



				----------------------------------------
				-- Perform Data Decryption
				----------------------------------------
				when DecryptData =>
					remoteAddrB <= "00" & X"0";
					encrypt_h <= '0';
					dataCnter := 0;
					offsetCnter := 0;
					x <= "0000000";
					y <= "11" & X"4";
					SV <= decrypt_readWaitState;
				WHEN decrypt_readWaitState =>
					SV <= decrypt_ReadDataFromRAM;
				WHEN decrypt_ReadDataFromRAM =>
					blockData(offsetCnter to offsetCnter+7) <= ruserOutputB;
					SV <= decrypt_checkOffset;
				WHEN decrypt_checkOffset =>
					if(offsetCnter+7 = 63) then
						dataCnter := dataCnter + 1;
						SV <= decrypt_the_Data;
					else
						offsetCnter := offsetCnter + 8;
						remoteAddrB <= remoteAddrB + 1;
						SV <= decrypt_readWaitState;
					end if;
				WHEN decrypt_the_Data =>
					startDESCalc <= '1';
					SV <= decrypt_waitForCalcDone;
				when decrypt_waitForCalcDone =>
					if(outputValid  = '1') then
						startDESCalc <= '0';
						SV <= decrypt_waitForOutputValidLow;
					end if;
				when decrypt_waitForOutputValidLow =>
					if(outputValid = '0') then
						SV <= displayDecryptedData0;
					end if;

				when displayDecryptedData0 =>
					offsetCnter:=0;
					SV <= displayDecryptedData1;
					
				when displayDecryptedData1 =>
					mem_wr <= '1';
					mem_in <= outputData(offsetCnter to offsetCnter+7) & X"F";
					SV <= displayDecryptedData2;
					
				when displayDecryptedData2 =>
					SV <= displayDecryptedData3;
					
				when displayDecryptedData3 =>	
					mem_wr <= '0';
					SV <= displayDecryptedData4;
				
				when displayDecryptedData4 =>
					x <= x+1;
					offsetCnter := offsetCnter+8;
					SV <= displayDecryptedData5;
					
				when displayDecryptedData5 =>
					if(offsetCnter < 64) then 
						SV <= displayDecryptedData1;
					else
						SV <= checkForDoneDecrypt;
					end if;
					
				when checkForDoneDecrypt =>
					if(dataCnter = 7) then --56 words
						x <= saveX;
						y <= saveY;
						SV <= DecryptDataWait1;
					else
						offsetCnter := 0;
						remoteAddrB <= remoteAddrB + 1;
						SV <= decrypt_readWaitState;
					end if;
				
				when DecryptDataWait1 =>
					decryptedMsgAck <= '1';
					SV <= DecryptDataWait2;
					
				when DecryptDataWait2 =>
					SV <= DecryptDataWait3;
					
				when DecryptDataWait3 =>
					decryptedMsgAck <= '0';
					SV <= wait_for_KB_ready;

				WHEN OTHERS =>
					decryptedMsgAck <= '0';
					code_buf <= "--------11110000--------";
					startDESCalc <= '0';
					ack <= '0';
					hexCnter := 0;
					tx_rdy <= '0';
					userInputWen <= '0';
					euserInputWen <= '0';
					mem_wr <= '0';		------------------------------
					x <= "0000000";		--initialization
					y <= "000000";		-- x=0 and y=0
					SV <= clean0;
			END CASE;
		END IF;		
	END PROCESS;
	
	
	
	
	
	

	
	
	Receive_Encrypted_Serial_Data: PROCESS(CLOCK_50, KEY(0))
	variable inputCnter: integer range 0 to 80; 
	BEGIN
		IF(KEY(0) = '0') THEN
			inputCnter := 0;		
			decryptedMsgAvail <= '0';
			rxState <= wait_for_RX_ready;
			ruserInputWen <= '0';
			remoteAddr <= "000000";
			rx_ack <= '0';
			rx_disabled <= '0';
		ELSIF(CLOCK_50'event AND CLOCK_50 = '1') THEN
			CASE rxState IS

				WHEN wait_for_RX_ready =>
					if(rx_rdy = '1') then --AND (rx_disabled /= '1') then
						rxState <= RS_received;
					else
						rx_ack <= '0';
					end if;
					
					if(decryptedMsgAck = '1') then
						decryptedMsgAvail <= '0';
					end if;
	
				WHEN RS_received =>
					inputCnter := inputCnter + 1;
					new_rx_data <= rx_data;	-- Save the ASCII code
					rx_ack <= '1';			-- Send acknowledgement
					rxState <= saveRxData;
					
				WHEN saveRxData =>
					rasciiIn <= new_rx_data;
					ruserInputWen <= '1';
					rxState <= waitSaveState;
					
				WHEN waitSaveState =>
					rxState <= rxSaveComplete;
					
				WHEN rxSaveComplete =>
					ruserInputWen <= '0';
					rxState <= checkForLastData;
					
				WHEN checkForLastData =>
				    if(inputCnter = 56) then
						inputCnter := 0;
						decryptedMsgAvail <= '1';
						--rx_disabled <= '1';
						remoteAddr <= "000000";
					else
						remoteAddr <= remoteAddr + 1;
					end if;
					rxState <= wait_for_RX_ready;
					
				WHEN others =>
					rx_disabled <= '0';
					inputCnter := 0;		
					decryptedMsgAvail <= '0';
					rxState <= wait_for_RX_ready;
					ruserInputWen <= '0';
					remoteAddr <= "000000";
					rx_ack <= '0';
			end case;
		end if;
	end process;
	
	

END ARCHITECTURE talk;