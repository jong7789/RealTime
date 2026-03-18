
library IEEE;
	use IEEE.STD_LOGIC_1164.ALL;
	use IEEE.STD_LOGIC_UNSIGNED.ALL;
	use IEEE.STD_LOGIC_ARITH.ALL;
	use WORK.TOP_HEADER.ALL;

entity IMG_OUT_TOP is
	port (
		idata_clk  : in    std_logic;
		idata_rstn : in    std_logic;
		igev_clk   : in    std_logic;
		igev_rstn  : in    std_logic;

		ireg_out_en   : in	  std_logic;
		ireg_out_mode : in	  std_logic_vector(3 downto 0);
		ireg_width	  : in	  std_logic_vector(11 downto 0);
		ireg_height   : in	  std_logic_vector(11 downto 0);

		ihsync : in    std_logic;
		ivsync : in    std_logic;
		ihcnt  : in    std_logic_vector(11 downto 0);
		ivcnt  : in    std_logic_vector(11 downto 0);
		idata  : in    std_logic_vector(15 downto 0);
		
		ofb_frame : out   std_logic;
		ofb_dv	  : out   std_logic;
		ofb_data  : out   std_logic_vector(63 downto 0);
		ofb_width : out   std_logic_vector( 2 downto 0)
	);
end entity img_out_top;

architecture behavioral of img_out_top is

	component GEV_IF
		port (
			idata_clk  : in    std_logic;
			idata_rstn : in    std_logic;
			igev_clk   : in    std_logic;
			igev_rstn  : in    std_logic;

			ireg_out_en : in	std_logic;
			ireg_width	: in	std_logic_vector(11 downto 0);
			ireg_height : in	std_logic_vector(11 downto 0);

			ihsync : in    std_logic;
			ivsync : in    std_logic;
			ihcnt  : in    std_logic_vector(11 downto 0);
			ivcnt  : in    std_logic_vector(11 downto 0);
			idata  : in    std_logic_vector(15 downto 0);

			ofb_frame : out   std_logic;
			ofb_dv	  : out   std_logic;
			ofb_data  : out   std_logic_vector(63 downto 0);
			ofb_width : out   std_logic_vector( 2 downto 0)
		);
	end component;

	signal sout_mode : std_logic_vector(3 downto 0);

	signal shsync_gev : std_logic;
	signal svsync_gev : std_logic;
	signal shcnt_gev  : std_logic_vector(11 downto 0);
	signal svcnt_gev  : std_logic_vector(11 downto 0);
	signal sdata_gev  : std_logic_vector(15 downto 0);

	signal sreg_out_mode	: std_logic_vector(3 downto 0);
	signal sreg_out_mode_1d : std_logic_vector(3 downto 0);
	signal sreg_out_mode_2d : std_logic_vector(3 downto 0);
	signal sreg_out_mode_3d : std_logic_vector(3 downto 0);

	signal sfb_frame : std_logic;
	signal sfb_dv	 : std_logic;
	signal sfb_data  : std_logic_vector(63 downto 0);
	signal sfb_data_remap  : std_logic_vector(63 downto 0);
	signal sfb_width : std_logic_vector( 2 downto 0);
    
    -- ##### img_avg #####
--	constant para : integer := 4; -- b'64 =4 or b'16=1
	component IMG_AVG
 	    generic (
 	    	para : integer -- := 4 -- 4 or 1
 	    );
		port (
			iclk   : in    std_logic;
			ivsync : in    std_logic;
			ihsync : in    std_logic;
			idata  : in    std_logic_vector((para*16)-1 downto 0);

			oreg_img_avg : out	 std_logic_vector(32 - 1 downto 0)
		);
	end component;
	
begin

	process (idata_clk, idata_rstn)
	begin
		if(idata_rstn = '0') then
			sout_mode <= (others => '0');
		elsif (idata_clk'event and idata_clk = '1') then
			if(ivsync = '0') then
				sout_mode <= sreg_out_mode_3d;
			end if;
		end if;
	end process;

	process (idata_clk, idata_rstn)
	begin
		if(idata_rstn = '0') then
			shsync_gev <= '0';
			svsync_gev <= '0';
			shcnt_gev  <= (others => '0');
			svcnt_gev  <= (others => '0');
			sdata_gev  <= (others => '0');
		elsif (idata_clk'event and idata_clk = '1') then
			if(sout_mode = 0) then
				shsync_gev <= ihsync;
				svsync_gev <= ivsync;
				shcnt_gev  <= ihcnt;
				svcnt_gev  <= ivcnt;
				sdata_gev  <= idata;
			end if;
		end if;
	end process;

	U0_GEV_IF : GEV_IF
		port map (
			idata_clk  => idata_clk,
			idata_rstn => idata_rstn,
			igev_clk   => igev_clk,
			igev_rstn  => igev_rstn,

			ireg_out_en => ireg_out_en,
			ireg_width	=> ireg_width,
			ireg_height => ireg_height,

			ihsync => shsync_gev,
			ivsync => svsync_gev,
			ihcnt  => shcnt_gev,
			ivcnt  => svcnt_gev,
			idata  => sdata_gev,

			ofb_frame => sfb_frame,
			ofb_dv	  => sfb_dv,
			ofb_data  => sfb_data,
			ofb_width => sfb_width
		);
	ofb_frame <= sfb_frame;
	ofb_dv	  <= sfb_dv;
	ofb_data  <= sfb_data;
	ofb_width <= sfb_width;

	process (idata_clk, idata_rstn)
	begin
		if(idata_rstn = '0') then
			sreg_out_mode	 <= (others => '0');
			sreg_out_mode_1d <= (others => '0');
			sreg_out_mode_2d <= (others => '0');
			sreg_out_mode_3d <= (others => '0');
		elsif (idata_clk'event and idata_clk = '1') then
			sreg_out_mode	 <= ireg_out_mode;
			sreg_out_mode_1d <= sreg_out_mode;
			sreg_out_mode_2d <= sreg_out_mode_1d;
			sreg_out_mode_3d <= sreg_out_mode_2d;
		end if;
	end process;

	-- ###################
	-- ##### IMG AVG #####
--	c_IMG_AVG0 : IMG_AVG
-- 		generic map (
-- 			para => 1 -- 4 or 1
-- 		)
--		port map (
--			iclk		 => idata_clk,
--			ivsync		 => svsync_gev,
--			ihsync		 => shsync_gev,
--			idata		 => sdata_gev,
--			oreg_img_avg => oreg_img_avg0
--		);
	
--	sfb_data_remap 	<= sfb_data_remap(8*7-1 downto 8*6) & sfb_data_remap(8*8-1 downto 8*7) &
--	                   sfb_data_remap(8*5-1 downto 8*4) & sfb_data_remap(8*6-1 downto 8*5) &
--	                   sfb_data_remap(8*3-1 downto 8*2) & sfb_data_remap(8*4-1 downto 8*3) &
--	                   sfb_data_remap(8*1-1 downto 8*0) & sfb_data_remap(8*2-1 downto 8*1) ;
--	c_IMG_AVG1 : IMG_AVG
-- 		generic map (
-- 			para => 4 -- 4 or 1
-- 		)
--		port map (
--			iclk		 => igev_clk,
--			ivsync		 => sfb_frame,
--			ihsync		 => sfb_dv,
--			idata		 => sfb_data_remap,
--			oreg_img_avg => oreg_img_avg1
--		);
	-- ###################
		
	ILA_DEBUG : if(GEN_ILA_img_out_top = "ON") generate    
		component ila_img_out_top
		port (
			clk    : in    std_logic;
			probe0 : in    std_logic; --_vector(0 downto 0);
			probe1 : in    std_logic; --_vector(0 downto 0);
			probe2 : in    std_logic_vector(11 downto 0);
			probe3 : in    std_logic_vector(11 downto 0);
			probe4 : in    std_logic_vector(15 downto 0);
			probe5 : in    std_logic; --_vector(0 downto 0);
			probe6 : in    std_logic; --_vector(0 downto 0);
			probe7 : in    std_logic_vector(15 downto 0);
			probe8 : in    std_logic_vector(2 downto 0)
		);
	end component;
	begin
	u_ila_img_out_top : ila_img_out_top
		port map (
			clk    => idata_clk,
			probe0 => ihsync,					 -- 1
			probe1 => ivsync,					 -- 1
			probe2 => ihcnt,					 -- 12
			probe3 => ivcnt,					 -- 12
			probe4 => idata,					 -- 16
			probe5 => sfb_frame,				 -- 1
			probe6 => sfb_dv,					 -- 1
			probe7 => sfb_data(16 - 1 downto 0), -- 16/64
			probe8 => sfb_width					 -- 3
		);
end generate;
end architecture behavioral;
