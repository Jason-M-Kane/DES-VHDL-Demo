library ieee; use ieee.std_logic_1164.all;


entity debounce is
   generic(
      CYCLES: natural := 8
   );
   port(
      pin:        in       std_logic;
      output:     buffer   std_logic;
      clock:      in       std_logic
   );
end debounce;

architecture debounce of debounce is
   signal shift:     std_logic_vector(CYCLES - 1 downto 0);
begin
   process(clock) is
      variable is_zero: boolean;
      variable is_one: boolean;
   begin
      if(clock'event and clock = '1') then
         shift <= shift(CYCLES - 2 downto 0) & pin;
         
         is_zero := true;
         is_one := true;
         
         for i in CYCLES - 1 downto 0 loop
            if(shift(i) = '1') then
               is_zero := false;
            elsif(shift(i) = '0') then
               is_one := false;
            end if;
         end loop;

         if(is_zero) then
            output <= '0';
         elsif(is_one) then
            output <= '1';
         end if;
      end if;
   end process;
end architecture debounce;
