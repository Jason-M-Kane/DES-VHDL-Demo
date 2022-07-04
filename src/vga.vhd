library ieee;
library altera_mf;	-- Altera's own library for their "megafunction"
use ieee.std_logic_1164.all, ieee.std_logic_arith.all;
use altera_mf.altera_mf_components.all;

entity vga is
   port(
      clock                   :  in       std_logic;
      refclock                :  in       std_logic;
      reset                   :  in       std_logic;

      mem_adr                 :  in       std_logic_vector(12 downto 0);
      mem_out                 :  out      std_logic_vector(11 downto 0);
      mem_in                  :  in       std_logic_vector(11 downto 0);
      mem_wr                  :  in       std_logic;

      pclock                  :  buffer   std_logic;
      vga_hs                  :  out      std_logic;
      vga_vs                  :  out      std_logic;
      r, g, b                 :  out      std_logic_vector(9 downto 0);
      blank                   :  out      std_logic
   );
end;

architecture vga of vga is
   signal pdata               :  std_logic_vector(11 downto 0);
   signal paddr, p1           :  std_logic_vector(18 downto 0);
   signal char_out			  :  std_logic_vector(7 downto 0);
   signal hsync, vsync		  :  std_logic;
   signal h1, h2, v1, v2, b0, b1, b2	  :  std_logic;

begin

   -----------------------------------------------------------------
   -- The video memory is constructed by the Altera's Megafunction.
   -- This will invoke the memory inside the FPGA.
   -- The "altsyncram" is a synchronous RAM with two set of
   -- independently operated read/write ports.
   -----------------------------------------------------------------
   video_memory : altsyncram generic map(
      WIDTH_A => 12,
      WIDTHAD_A => 13,			-- The screen size 640 x 480
      NUMWORDS_A => 64 * 128, 	-- but VideoRAM is for 80 x 60
      WIDTH_B => 12,				-- characters each in an 8 x 8	
      WIDTHAD_B => 13,			-- font defined in the ROM	
      NUMWORDS_B => 64 * 128
   )
   port map(
      clock0 => pclock,
      clock1 => clock,
      address_a => paddr(18 downto 13)&paddr(9 downto 3),
      address_b => mem_adr,
      q_a => pdata,
      q_b => mem_out,
      data_a => (others => '-'),	
      data_b => mem_in,
      wren_a => '0',
      wren_b => mem_wr
   );

   font_table: altsyncram generic map(
      WIDTH_A => 8,
      WIDTHAD_A => 9,
      NUMWORDS_A => 512,
      operation_mode => "ROM",
	  init_file => "tcgrom.mif"
   )
   port map(
      clock0 => clock,
      address_a => pdata(9 downto 4) & p1(12 downto 10),
      q_a => char_out
   );
   
   process(pclock, reset) is
      variable hcount : integer range 0 to 800;
      variable vcount : integer range 0 to 525;
   begin
      if(reset = '1') then
         hcount := 0;
         vcount := 0;
         paddr <= (others => '0');
         hsync <= '1';
         vsync <= '1';
      elsif(pclock'event and pclock = '1') then
         if(hcount >= 0 and hcount <= 639 and vcount >= 0 and vcount <= 479) then
            paddr <=  conv_std_logic_vector(vcount, 9) & conv_std_logic_vector(hcount, 10);
         end if;
         
         if(hcount >= 0 and hcount <= 639 and vcount >= 0 and vcount <= 479) then
            b0 <= '1';	-- don't blank the screen when in the zone
         else
            b0 <= '0';	-- blank the screen when not in range
         end if;
         
         hcount := hcount + 1;
         if(hcount = 656) then
            hsync <= '0';
         elsif(hcount = 752) then
            hsync <= '1';
         elsif(hcount = 799) then
            vcount := vcount + 1;
            hcount := 0;
         end if;

         if(vcount = 490) then
            vsync <= '0';
         elsif(vcount = 492) then
            vsync <= '1';
         elsif(vcount = 524) then
            vcount := 0;
         end if;
         
         h1 <= hsync;		-- hsync, vsync and blank signals
         v1 <= vsync;		-- are delayed by three clock cycles
         b1 <= b0;			-- to compensate for the two registered
         h2 <= h1;			-- memory interface delays and one
         v2 <= v1;			-- more cycle of delay from the
         b2 <= b1;			-- registered interface of DAC
         vga_hs <= h2;		
         vga_vs <= v2;		
         blank <= b2;	
         p1 <= paddr;
         p1 <= paddr;	
 
		 r <= (others => (char_out(7- conv_integer(unsigned(p1(2 downto 0)))) AND pdata(2))  );
 		 g <= (others => (char_out(7- conv_integer(unsigned(p1(2 downto 0)))) AND pdata(1))  );
 		 b <= (others => (char_out(7- conv_integer(unsigned(p1(2 downto 0)))) AND pdata(0))  );
        
      end if;
   end process;
           
  ---------------------------------------------
  		
  pll : altpll generic map(
      clk0_divide_by => 128,
      clk0_multiply_by => 65,
      inclk0_input_frequency => 20000,
      inclk1_input_frequency => 20000,
      operation_mode => "NORMAL"
   )
   port map(
      inclk => '0' & refclock,
      clk(0) => pclock
   );
   
end vga;
