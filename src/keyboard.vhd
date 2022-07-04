library ieee;
use ieee.std_logic_1164.all;

entity keyboard is
   port(
      clock                   :  in       std_logic;
      reset                   :  in       std_logic;
      
      scan_code               :  out      std_logic_vector(7 downto 0);
      ready                   :  out      std_logic;
      ack                     :  in       std_logic;
      
      ps2clk                  :  in       std_logic;
      ps2data                 :  in       std_logic
   );
end;

architecture keyboard of keyboard is
   signal rxbuf      :  std_logic_vector(7 downto 0);
   signal done	     :  std_logic;
   signal ps2clkd    :  std_logic;
begin
   -----------------------------------------------
   -- The PS2 clock is filtered through a
   -- debounce circuit with 8 cycles delay.
   -----------------------------------------------
   clk_debounce : entity work.debounce generic map(
      CYCLES => 8
   )
   port map(
      pin => ps2clk,
      output => ps2clkd,
      clock => clock
   );

   -----------------------------------------------
   -- Handshaking signal handling
   -- READY goes high when a new byte is received.
   -- READY goes low when ack goes high.
   -----------------------------------------------
   handshaking : process(ack, done) is 
   begin
      if(ack = '1') then
         ready <= '0';
      elsif(done'event and done = '1') then
         ready <= '1';
      end if;
   end process handshaking;


   receiver : process(ps2clkd, reset) is
      -- -1 => start bit, 0-7 => data bits, 8 => parity bit, 9 => stop bit
      variable index : integer range -1 to 9;
      variable phase : std_logic;
   begin
      if(reset = '1') then
         index := -1;
         rxbuf <= (others => '0');
         scan_code <= (others => '0');
         done <= '0';
      elsif(ps2clkd'event and ps2clkd = '1') then
         if(index = -1) then -- idle condition
            if(ps2data = '0') then --start bit=0
               index := index + 1;
            end if;
            done <= '0';
         elsif(index >= 0 and index < 8) then
               rxbuf(index) <= ps2data;
               index := index + 1;
         elsif(index = 8) then
				index := index + 1;
				--parity bit ignore
		 elsif(index = 9) then
				if(ps2data='1') then --stop bit=1
					done <= '1';
					scan_code <= rxbuf;
					index := -1;
				end if;
         end if;
      end if;
   end process receiver;
end keyboard;
