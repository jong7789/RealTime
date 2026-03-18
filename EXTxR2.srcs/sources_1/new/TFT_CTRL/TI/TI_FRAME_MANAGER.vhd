library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

use WORK.TOP_HEADER.ALL;

entity TI_FRAME_MANAGER is
generic ( GNR_MODEL : string  := "EXT1616R" );
port (
	imain_clk			: in	std_logic;
	imain_rstn			: in	std_logic;

	ireg_grab_en		: in	std_logic;
	ireg_gate_en		: in	std_logic_vector(7 downto 0);					
	ireg_img_mode		: in	std_logic_vector(2 downto 0);					
	ireg_rst_mode		: in	std_logic_vector(1 downto 0);					
	ireg_rst_num		: in	std_logic_vector(3 downto 0);					
	ireg_shutter		: in	std_logic;				

	ireg_trig_mode		: in	std_logic_vector(1 downto 0);
	ireg_trig_delay		: in	std_logic_vector(15 downto 0);
	ireg_trig_filt		: in	std_logic_vector(7 downto 0);
	ireg_trig_valid		: in	std_logic;

	ireg_roic_tp_sel	: in	std_logic;
	ireg_roic_cds1		: in	std_logic_vector(15 downto 0);
	ireg_roic_cds2		: in	std_logic_vector(15 downto 0);
	ireg_roic_intrst	: in	std_logic_vector(15 downto 0);
	ireg_gate_oe		: in	std_logic_vector(15 downto 0);
	ireg_gate_xon		: in	std_logic_vector(31 downto 0);
	ireg_gate_xon_flk	: in	std_logic_vector(31 downto 0);
	ireg_gate_flk		: in	std_logic_vector(31 downto 0);
	ireg_gate_rst_cycle	: in	std_logic_vector(31 downto 0);

	ireg_timing_mode	: in	std_logic_vector( 1 downto 0); --* jhkim

	ireg_sexp_time		: in	std_logic_vector(31 downto 0);
	ireg_exp_time		: in	std_logic_vector(31 downto 0);
	ireg_frame_time		: in	std_logic_vector(31 downto 0);
	ireg_frame_num		: in	std_logic_vector(15 downto 0);		
	ireg_frame_val		: in	std_logic_vector(15 downto 0);		
	oreg_frame_cnt   	: out   std_logic_vector(31 downto 0);
	oreg_ext_exp_time	: out	std_logic_vector(31 downto 0);
	oreg_ext_frame_time	: out	std_logic_vector(31 downto 0);

	ireg_offsetx		: in	std_logic_vector(11 downto 0);
	ireg_offsety		: in	std_logic_vector(11 downto 0);
	ireg_width			: in	std_logic_vector(11 downto 0);
	ireg_height			: in	std_logic_vector(11 downto 0);

	iext_trig			: in	std_logic;
	oext_trig			: out	std_logic;

	otft_busy			: out	std_logic;
	ograb_done			: out	std_logic;

	oroic_dvalid		: out	std_logic;

	oroic_sync			: out	std_logic;
	oroic_tp_sel		: out	std_logic;
	
	ogate_cpv			: out	std_logic;
	ogate_dio1			: out	std_logic_vector(GATE_NUM(GNR_MODEL)-1 downto 0);	
	ogate_dio2			: out	std_logic_vector(GATE_NUM(GNR_MODEL)-1 downto 0);	
	ogate_oe1			: out	std_logic;
	ogate_oe2			: out	std_logic;
	ogate_xon			: out	std_logic;
	ogate_flk			: out	std_logic;	

	--# d2m port 
	ireg_d2m_en			: in std_logic;
	ireg_d2m_exp_in		: in std_logic;
	ireg_d2m_sexp_time	: in std_logic_vector(32-1 downto 0);
	ireg_d2m_frame_time : in std_logic_vector(32-1 downto 0);
	ireg_d2m_xrst_num	: in std_logic_vector(16-1 downto 0);
	ireg_d2m_drst_num	: in std_logic_vector(16-1 downto 0);
	od2m_xray  			: out std_logic;
	od2m_dark  			: out std_logic;

	ireg_ExtTrigEn		: in std_logic;
	ireg_ExtRst_MODE 	: in std_logic_vector( 7 downto 0);
	ireg_ExtRst_DetTime : in std_logic_vector(31 downto 0);
	oExtTrig_Srst		: out std_logic;
    --# 220511 bcal speed
    ireg_req_align      : in    std_logic;
    iroic_spi_sdi       : in    std_logic; --# 240122

	sstate_tftd			: out tstate_tft 	;
	sstate_grab			: out	tstate_grab	;		
	sstate_tft 			: out	tstate_tft 	;
	sstate_roic			: out	tstate_roic	;
	sstate_gate			: out	tstate_gate	
);
end TI_FRAME_MANAGER;

architecture Behavioral of TI_FRAME_MANAGER is

	component TRIG_DELAY 
	port (
		imain_clk			: in	std_logic;
		imain_rstn			: in	std_logic;
	
		ireg_grab_en		: in	std_logic;
		ireg_trig_delay		: in	std_logic_vector(15 downto 0);
		ireg_trig_filt		: in	std_logic_vector(7 downto 0);

		itft_busy			: in	std_logic;

		iext_trig			: in	std_logic;
		oext_trig			: out	std_logic
	);
	end component;

	component TI_TFT_CTRL 
  generic ( GNR_MODEL : string  := "EXT1616R" );
	port (
		imain_clk			: in	std_logic;
		imain_rstn			: in	std_logic;
	
		ireg_grab_en		: in	std_logic;
		ireg_gate_en		: in	std_logic_vector(7 downto 0);					
		ireg_img_mode		: in	std_logic_vector(2 downto 0);					
		ireg_rst_mode		: in	std_logic_vector(1 downto 0);					
		ireg_rst_num		: in	std_logic_vector(3 downto 0);					
		ireg_shutter		: in	std_logic;				
		ireg_trig_mode		: in	std_logic_vector(1 downto 0);
		ireg_trig_valid		: in	std_logic;

		ireg_roic_tp_sel	: in	std_logic;
		ireg_roic_cds1		: in	std_logic_vector(15 downto 0);
		ireg_roic_cds2		: in	std_logic_vector(15 downto 0);
		ireg_roic_intrst	: in	std_logic_vector(15 downto 0);
		ireg_gate_oe		: in	std_logic_vector(15 downto 0);
		ireg_gate_xon		: in	std_logic_vector(31 downto 0);
		ireg_gate_xon_flk	: in	std_logic_vector(31 downto 0);
		ireg_gate_flk		: in	std_logic_vector(31 downto 0);
		ireg_gate_rst_cycle	: in	std_logic_vector(31 downto 0);
		
		ireg_timing_mode	: in	std_logic_vector( 1 downto 0); --* jhkim
		
		ireg_frame_num		: in	std_logic_vector(15 downto 0);		
		ireg_frame_val		: in	std_logic_vector(15 downto 0);		
		oreg_frame_cnt   	: out   std_logic_vector(31 downto 0);

		ireg_sexp_time		: in	std_logic_vector(31 downto 0);
		ireg_exp_time		: in	std_logic_vector(31 downto 0);
		ireg_frame_time		: in	std_logic_vector(31 downto 0);
		
		ireg_offsetx		: in	std_logic_vector(11 downto 0);
		ireg_offsety		: in	std_logic_vector(11 downto 0);
		ireg_width			: in	std_logic_vector(11 downto 0);
		ireg_height			: in	std_logic_vector(11 downto 0);

		iext_trig			: in	std_logic;
		oext_trig			: out	std_logic;

		otft_busy			: out	std_logic;
		ograb_done			: out	std_logic;

		oroic_dvalid		: out	std_logic;
		
		oroic_sync			: out	std_logic;
		oroic_tp_sel		: out	std_logic;
		
		ogate_cpv			: out	std_logic;
		ogate_dio1			: out	std_logic_vector(GATE_NUM(GNR_MODEL)-1 downto 0);	
		ogate_dio2			: out	std_logic_vector(GATE_NUM(GNR_MODEL)-1 downto 0);	
		ogate_oe1			: out	std_logic;
		ogate_oe2			: out	std_logic;
		ogate_xon			: out	std_logic;
		ogate_flk			: out	std_logic;	

		--# d2m port 
		ireg_d2m_en			: in std_logic;
		ireg_d2m_exp_in		: in std_logic;
		ireg_d2m_sexp_time	: in std_logic_vector(32-1 downto 0);
		ireg_d2m_frame_time : in std_logic_vector(32-1 downto 0);
		ireg_d2m_xrst_num	: in std_logic_vector(16-1 downto 0);
		ireg_d2m_drst_num	: in std_logic_vector(16-1 downto 0);
		od2m_xray  			: out std_logic;
		od2m_dark   		: out std_logic;

		ireg_ExtTrigEn		: in std_logic;
		ireg_ExtRst_MODE 	: in std_logic_vector( 7 downto 0);
		ireg_ExtRst_DetTime : in std_logic_vector(31 downto 0);
		oExtTrig_Srst		: out std_logic;
        --# 220511 bcal speed
        ireg_req_align      : in std_logic;

        ostate_tftd 		: out tstate_tft ;
        iroic_spi_sdi       : in    std_logic; --# 240122

		--* test point
		ostate_grab			: out tstate_grab;				
        ostate_tft  		: out tstate_tft ;
        ostate_roic 		: out tstate_roic;
        ostate_gate 		: out tstate_gate
	);
	end component;

	component CAL_FPS is
  generic ( GNR_MODEL : string  := "EXT1616R" );
	port (
		imain_clk			: in	std_logic;
		imain_rstn			: in	std_logic;
	
		iext_trig			: in	std_logic;
		
		oreg_ext_exp_time	: out	std_logic_vector(31 downto 0);
		oreg_ext_frame_time	: out	std_logic_vector(31 downto 0)
	);
	end component;

	signal stft_busy			: std_logic;
	signal sext_trig_in			: std_logic;
	signal sext_trig_out		: std_logic;

	--* test point
	signal state_tftd  		: tstate_tft ;
	signal state_grab		: tstate_grab;	
	signal state_tft  		: tstate_tft ;
	signal state_roic 		: tstate_roic;
	signal state_gate 		: tstate_gate;

begin

	U0_TRIG_DELAY : TRIG_DELAY 
	port map (
		imain_clk			=> imain_clk,
		imain_rstn			=> imain_rstn,

		ireg_grab_en		=> ireg_grab_en,
		ireg_trig_delay		=> ireg_trig_delay,
		ireg_trig_filt		=> ireg_trig_filt,

		itft_busy			=> stft_busy,
	
		iext_trig			=> iext_trig,
		oext_trig			=> sext_trig_in
	);
	
	U0_TI_TFT_CTRL : TI_TFT_CTRL 
    generic map( GNR_MODEL => GNR_MODEL)
	port map (
		imain_clk			=> imain_clk,
		imain_rstn			=> imain_rstn,			
	
		ireg_grab_en		=> ireg_grab_en,	
		ireg_gate_en		=> ireg_gate_en,	
		ireg_img_mode		=> ireg_img_mode,	
		ireg_rst_mode		=> ireg_rst_mode,	
		ireg_rst_num		=> ireg_rst_num,	
		ireg_shutter		=> ireg_shutter,
		ireg_trig_mode		=> ireg_trig_mode,
		ireg_trig_valid		=> ireg_trig_valid,

		ireg_roic_tp_sel	=> ireg_roic_tp_sel,
		ireg_roic_cds1		=> ireg_roic_cds1,		
		ireg_roic_cds2		=> ireg_roic_cds2,		
		ireg_roic_intrst	=> ireg_roic_intrst,	
		ireg_gate_oe		=> ireg_gate_oe,		
		ireg_gate_xon		=> ireg_gate_xon,		
		ireg_gate_xon_flk	=> ireg_gate_xon_flk,	
		ireg_gate_flk		=> ireg_gate_flk,		
		ireg_gate_rst_cycle	=> ireg_gate_rst_cycle,		

		ireg_timing_mode	=> ireg_timing_mode, --* jhkim
		
		ireg_frame_num		=> ireg_frame_num,	
		ireg_frame_val		=> ireg_frame_val,	
		oreg_frame_cnt   	=> oreg_frame_cnt,

		ireg_sexp_time		=> ireg_sexp_time,
		ireg_exp_time		=> ireg_exp_time,	
		ireg_frame_time		=> ireg_frame_time,	
		                       
		ireg_offsetx		=> ireg_offsetx,	
		ireg_offsety		=> ireg_offsety,	
		ireg_width			=> ireg_width,		
		ireg_height			=> ireg_height,		

		iext_trig			=> sext_trig_in,
		oext_trig			=> sext_trig_out,  

		otft_busy			=> stft_busy, 
		ograb_done			=> ograb_done,

		oroic_dvalid		=> oroic_dvalid,

		oroic_sync			=> oroic_sync, 
		oroic_tp_sel		=> oroic_tp_sel, 
		                       
		ogate_cpv			=> ogate_cpv,  
		ogate_dio1			=> ogate_dio1,  
		ogate_dio2			=> ogate_dio2,  
		ogate_oe1			=> ogate_oe1,   
		ogate_oe2			=> ogate_oe2,   
		ogate_xon			=> ogate_xon,  
		ogate_flk			=> ogate_flk,

        ireg_d2m_en		    => ireg_d2m_en		  ,
        ireg_d2m_exp_in	    => ireg_d2m_exp_in	  ,
        ireg_d2m_sexp_time  => ireg_d2m_sexp_time ,
        ireg_d2m_frame_time => ireg_d2m_frame_time,
        ireg_d2m_xrst_num   => ireg_d2m_xrst_num  ,
        ireg_d2m_drst_num   => ireg_d2m_drst_num  ,
        od2m_xray           => od2m_xray          ,
        od2m_dark           => od2m_dark          ,

		ireg_ExtTrigEn		=> ireg_ExtTrigEn,
		ireg_ExtRst_MODE   	=> ireg_ExtRst_MODE,
		ireg_ExtRst_DetTime	=> ireg_ExtRst_DetTime,
		oExtTrig_Srst		=> oExtTrig_Srst ,
        ireg_req_align      => ireg_req_align,

        iroic_spi_sdi       => iroic_spi_sdi,
        
		ostate_tftd			=> state_tftd	,
		--* test point 
		ostate_grab			=> state_grab	,			
		ostate_tft 			=> state_tft 	,
		ostate_roic			=> state_roic	,
		ostate_gate			=> state_gate	
	);

	U0_CAL_FPS : CAL_FPS 
    generic map( GNR_MODEL => GNR_MODEL)
	port map (
		imain_clk			=> imain_clk,
		imain_rstn			=> imain_rstn,

		iext_trig			=> sext_trig_out,
		
		oreg_ext_exp_time	=> oreg_ext_exp_time,  
		oreg_ext_frame_time	=> oreg_ext_frame_time
	);

	otft_busy		<= stft_busy;
	oext_trig		<= sext_trig_out;

	--* tft_ctrl state
	 sstate_tftd 	<= state_tftd	;
	 sstate_grab 	<= state_grab	; 
	 sstate_tft  	<= state_tft 	;
	 sstate_roic 	<= state_roic	;
	 sstate_gate 	<= state_gate	;
	
end Behavioral;
