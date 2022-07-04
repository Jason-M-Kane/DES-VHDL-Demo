library ieee;
use ieee.std_logic_1164.all;

--------------------------------------------------------------------------------------
-- Serial Port Code	Usage															--
--																					--
-- Receiving																		--
-- rx_rdy set when data Received.  User read rx_data and set rx_ack to get new data --
-- User should clear rx_ack as soon as possible to get more data.                   --
--																					--
-- Transmitting																		--
-- User sets tx_data and tx_rdy to send data.  tx_ack set when data sent.           --
-- To send more data user must toggle tx_rdy to 0 and back to 1.                    --
--                                                                                  --
--------------------------------------------------------------------------------------


entity rs232 is
   generic(
      CLOCK_FREQUENCY         :  natural; -- in Hz
      BAUD_RATE               :  natural -- in bits/sec
   );
   port(
      clock		: in	std_logic;
      reset		: in	std_logic;

      rx_data	: out	std_logic_vector(7 downto 0);
      tx_data	: in	std_logic_vector(7 downto 0);
      
      rx_rdy	: out	std_logic;
      rx_ack	: in	std_logic;
      tx_rdy	: in	std_logic;
      tx_ack	: out	std_logic;	

      rx		: in	std_logic;
      tx		: out	std_logic
   );
end;

architecture rs232 of rs232 is
   constant BAUD_DIVIDER      :  natural := CLOCK_FREQUENCY / BAUD_RATE;
   signal rxbuf, txbuf        :  std_logic_vector(8 downto 0);
   signal rxd                 :  std_logic; -- debounced rx

begin

   assert BAUD_DIVIDER > 15
      report "BAUD_DIVIDER too small; BAUD_RATE is too high or CLOCK_FREQUENCY is too low"
      severity error;

   rx_debounce : entity work.debounce generic map(
      CYCLES => 4
   )
   port map(
      pin => rx,
      output => rxd,
      clock => clock
   );

   RX_handshaking : process(rxbuf(8), rx_ack) is 
   begin
      if(rx_ack = '1') then
         rx_rdy <= '0';
      elsif(rxbuf(8)'event and rxbuf(8) = '1') then
         rx_rdy <= '1';
      end if;
   end process RX_handshaking;
   
   receiver : process(clock, reset) is
      -- -1 => start bit, 0-7 => data bits, 8 => stop bit
      variable index : integer range -1 to 8;
      variable counter : integer range 0 to 2 * BAUD_DIVIDER;
   begin
      if(reset = '1') then
         index := -1;
         counter := 0;
         rxbuf <= (others => '0');
      elsif(clock'event and clock = '1') then
         if(counter > 0) then -- make counter "stick" at 0
            counter := counter - 1;
         end if;

         if(index = -1) then -- idle condition
            rxbuf(8) <= '0';
            if(rxd = '0') then -- wait for start bit
               index := index + 1;
               counter := BAUD_DIVIDER + BAUD_DIVIDER / 2; -- middle of next bit
            end if;
         elsif(index < 8) then -- data bits
            if(counter = 0) then
               rxbuf(index) <= rxd;
               index := index + 1;
               counter := BAUD_DIVIDER;
            end if;
         else
            if(counter = 0) then
               if(rxd = '1') then -- stop bit
                  rxbuf(8) <= '1';
                  rx_data <= rxbuf(7 downto 0);
               else
                  null; -- frame error
               end if;
               index := -1; -- return to idle
            end if;
         end if;
      end if;
   end process receiver;

   transmitter : process(clock, tx_rdy) is
      -- -1 => start bit, 0-7 => data bits, 8 => stop bit, 9 => end of stop bit
      variable index : integer range -1 to 9;
      variable counter : integer range 0 to BAUD_DIVIDER;
   begin
      if(tx_rdy = '0') then
         index := -1;
         counter := 0;
         txbuf <= (others => '0');
         tx_ack <= '0';
         tx <= '1'; -- idle line state
      elsif(clock'event and clock = '1') then
         if(counter > 0) then -- make counter "stick" at 0
            counter := counter - 1;
         end if;

         if(index = -1) then
            txbuf <= '1'& tx_data;
            index := index + 1;
            counter := BAUD_DIVIDER;
            tx <= '0'; -- start bit
			tx_ack <= '0';
         end if;

         if(index > -1 and counter = 0) then
            if(index < 8) then
               tx <= txbuf(index); -- data bits
               index := index + 1;
               counter := BAUD_DIVIDER;
            elsif(index = 8) then
               tx <= '1'; -- stop bit
               tx_ack <= '1';
               index := index + 1;
               counter := BAUD_DIVIDER;
            else
               index := -1; -- finished stop bit
            end if;
         end if;
      end if;
   end process transmitter;
   
end rs232;
