library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

use WORK.TOP_HEADER.ALL;

entity TI_TFT_CTRL is
generic ( GNR_MODEL : string  := "EXT1616R" );
port (
    imain_clk           : in    std_logic;
    imain_rstn          : in    std_logic;
    
    ireg_grab_en        : in    std_logic;
    ireg_gate_en        : in    std_logic_vector(7 downto 0);
    ireg_img_mode       : in    std_logic_vector(2 downto 0);                   
    ireg_rst_mode       : in    std_logic_vector(1 downto 0);                   
    ireg_rst_num        : in    std_logic_vector(3 downto 0);                   
    ireg_shutter        : in    std_logic;          
    ireg_trig_mode      : in    std_logic_vector(1 downto 0);
    ireg_trig_valid     : in    std_logic;
    
    ireg_roic_tp_sel    : in    std_logic;
    ireg_roic_cds1      : in    std_logic_vector(15 downto 0);
    ireg_roic_cds2      : in    std_logic_vector(15 downto 0);
    ireg_roic_intrst    : in    std_logic_vector(15 downto 0);
    ireg_gate_oe        : in    std_logic_vector(15 downto 0);
    ireg_gate_xon       : in    std_logic_vector(31 downto 0);
    ireg_gate_xon_flk   : in    std_logic_vector(31 downto 0);
    ireg_gate_flk       : in    std_logic_vector(31 downto 0);
    ireg_gate_rst_cycle : in    std_logic_vector(31 downto 0);

    ireg_timing_mode    : in    std_logic_vector( 1 downto 0); --* jhkim

    ireg_frame_num      : in    std_logic_vector(15 downto 0);      
    ireg_frame_val      : in    std_logic_vector(15 downto 0);      
    oreg_frame_cnt      : out   std_logic_vector(31 downto 0);
    
    ireg_sexp_time      : in    std_logic_vector(31 downto 0);
    ireg_exp_time       : in    std_logic_vector(31 downto 0);
    ireg_frame_time     : in    std_logic_vector(31 downto 0);
    
    ireg_offsetx        : in    std_logic_vector(11 downto 0);
    ireg_offsety        : in    std_logic_vector(11 downto 0);
    ireg_width          : in    std_logic_vector(11 downto 0);
    ireg_height         : in    std_logic_vector(11 downto 0);

    iext_trig           : in    std_logic;              
    oext_trig           : out   std_logic;              

    otft_busy           : out   std_logic;
    ograb_done          : out   std_logic;
    
    oroic_dvalid        : out   std_logic;

    oroic_sync          : out   std_logic;
    oroic_tp_sel        : out   std_logic;
    
    ogate_cpv           : out   std_logic;
    ogate_dio1          : out   std_logic_vector(GATE_NUM(GNR_MODEL)-1 downto 0);   
    ogate_dio2          : out   std_logic_vector(GATE_NUM(GNR_MODEL)-1 downto 0);   
    ogate_oe1           : out   std_logic;
    ogate_oe2           : out   std_logic;
    ogate_xon           : out   std_logic;
    ogate_flk           : out   std_logic;  

    --# d2m port 
    ireg_d2m_en         : in std_logic;
    ireg_d2m_exp_in     : in std_logic;
    ireg_d2m_sexp_time  : in std_logic_vector(32-1 downto 0);
    ireg_d2m_frame_time : in std_logic_vector(32-1 downto 0);
    ireg_d2m_xrst_num   : in std_logic_vector(16-1 downto 0);
    ireg_d2m_drst_num   : in std_logic_vector(16-1 downto 0);
    od2m_xray           : out std_logic;
    od2m_dark           : out std_logic;

    ireg_ExtTrigEn      : in std_logic;
    ireg_ExtRst_MODE    : in std_logic_vector( 7 downto 0);
    ireg_ExtRst_DetTime : in std_logic_vector(31 downto 0);
    oExtTrig_Srst       : out std_logic;
    --# 220511 bcal speed
    ireg_req_align      : in    std_logic;
    iroic_spi_sdi       : in    std_logic; --# 240122

    ostate_tftd         : out   tstate_tft;
    ostate_grab         : out   tstate_grab;        
    ostate_tft          : out   tstate_tft;
    ostate_roic         : out   tstate_roic;
    ostate_gate         : out   tstate_gate
);  
end TI_TFT_CTRL;

architecture Behavioral of TI_TFT_CTRL is

--*     type tstate_grab            is (
--*                                         s_IDLE,         -- 0
--*                                         s_DATA,         -- 1
--*                                         s_WAIT          -- 2
--*                                     );
--* 
--*     type tstate_tft             is (
--*                                         s_IDLE,         -- 0
--*                                         s_TRST,         -- 1
--*                                         s_SRST,         -- 2
--*                                         s_EWT,          -- 3
--*                                         s_SCAN,         -- 4
--*                                         s_FINISH        -- 5
--*                                         s_GRST          -- 6
--*                                         s_RstFINISH     -- 7
--*                                     );
--* 
--*     type tstate_roic            is (
--*                                         s_IDLE,         -- 0
--*                                         s_OFFSET,       -- 1
--*                                         s_DUMMY,        -- 2    
--*                                         s_INTRST,       -- 4
--*                                         s_CDS1,         -- 5
--*                                         s_GATE_OPEN,    -- 6
--*                                         s_CDS2,         -- 7
--*                                         s_LDEAD,        -- 8
--*                                         s_FWAIT         -- 9
--*                                     );
--* 
--*     type tstate_gate            is (
--*                                         s_IDLE,         -- 0
--*                                         s_DUMMY,        -- 1
--*                                         s_READY,        -- 2
--*                                         s_DIO_CPV,      -- 3
--*                                         s_CPV,          -- 4
--*                                         s_XON,          -- 5
--*                                         s_OE,           -- 6
--*                                         s_XON_FLK,      -- 7
--*                                         s_FLK,          -- 8
--*                                         s_CHECK,        -- 9
--*                                         s_OE_READY,     -- A
--*                                         s_LWAIT,        -- B
--*                                         s_FWAIT         -- C
--*                                     );

    signal state_grab               : tstate_grab;
    signal state_tft                : tstate_tft;
    signal state_roic               : tstate_roic;
    signal state_gate               : tstate_gate;

            
    signal state_cpv                : std_logic_vector(3 downto 0);

    signal sgrab_en_tmp             : std_logic;
    signal sgrab_en_tmp0            : std_logic; --# 230707
    signal sm_grab_trig             : std_logic; --# 230707

    signal sgrab_en                 : std_logic;
    signal sframe_cnt               : std_logic_vector(16 downto 0);
    signal sgrab_done               : std_logic;
    signal sreg_RstFrCnt            : std_logic_vector(16 downto 0);

    signal stft_cnt                 : std_logic_vector(32 downto 0);
    signal srst_cnt                 : std_logic_vector(3 downto 0);
    signal sexp_time                : std_logic_vector(31 downto 0);
    signal sframe_time              : std_logic_vector(31 downto 0);
    signal srst_time                : std_logic_vector(31 downto 0);

    signal sext_trig_out            : std_logic;

    signal sfirst_rst               : std_logic;
    signal sfirst_tft               : std_logic;

    signal sroic_bank               : std_logic;
    signal sroic_cnt                : std_logic_vector(7 downto 0);
    signal sroic_sync               : std_logic;
    signal sroic_sync_s0            : std_logic;
    signal sroic_tp_sel             : std_logic;
    signal sroic_dvalid             : std_logic;
    signal sroic_line_cnt           : std_logic_vector(11 downto 0);

    signal sroic_cds1_time          : std_logic_vector(15 downto 0);
    signal sroic_cds2_time          : std_logic_vector(15 downto 0);
    signal sroic_intrst_time        : std_logic_vector(15 downto 0);

    signal sgate_line_cnt           : std_logic_vector(11 downto 0);
    signal sgate_ch_cnt             : integer range 0 to GATE_MAX_CH(GNR_MODEL)-1;
    signal sgate_num                : integer range 0 to GATE_NUM(GNR_MODEL)-1;
    signal sgate_cnt                : std_logic_vector(31 downto 0);
    signal sgate_oe_cnt             : std_logic_vector(2 downto 0);

    signal sgate_oe_num             : integer range 0 to 4;
    signal sgate_oe_end             : std_logic;
    signal sgate_end                : std_logic;

    signal sgate_cpv                : std_logic;
    signal sgate_dio                : std_logic_vector(GATE_NUM(GNR_MODEL)-1 downto 0);
    signal sgate_dio_rev            : std_logic_vector(GATE_NUM(GNR_MODEL)-1 downto 0);
    signal sgate_dio_conv           : std_logic_vector(GATE_NUM(GNR_MODEL)-1 downto 0);
    signal sgate_oe                 : std_logic;
    signal sgate_xon                : std_logic;
    signal sgate_flk                : std_logic;
    signal sgate_dummy_en           : std_logic;
    signal sgate_dummy_num          : integer range 0 to MAX_HEIGHT(GNR_MODEL)-1;
    signal sgate_dummy_cnt          : std_logic_vector(11 downto 0);
    signal sgate_dummy_add          : integer range 0 to 3; -- update 210126 

    signal stft_busy                : std_logic;

    signal sgate_dio1_cpv1          : std_logic_vector(15 downto 0);
    signal sgate_cpv1_cpv2          : std_logic_vector(15 downto 0);
    signal sgate_cpv2_dio2          : std_logic_vector(15 downto 0);
    signal sgate_dio2_cpv1          : std_logic_vector(15 downto 0);

    signal sreg_grab_en             : std_logic;
    signal sreg_gate_en             : std_logic;
    signal sreg_gate_reverse        : std_logic; --# 240122
    signal sreg_gate_roe            : std_logic; --# 240122 roic out oe signale
    signal sreg_img_mode            : std_logic_vector(2 downto 0);                 
    signal sreg_rst_mode            : std_logic_vector(1 downto 0);                 
    signal sreg_rst_num             : std_logic_vector(3 downto 0);                 
    signal sreg_shutter             : std_logic;            
    signal sreg_trig_mode           : std_logic_vector(1 downto 0);
    signal sreg_trig_valid          : std_logic;

    signal sreg_roic_cds1           : std_logic_vector(15 downto 0);
    signal sreg_roic_cds2           : std_logic_vector(15 downto 0);
    signal sreg_roic_intrst         : std_logic_vector(15 downto 0);
    signal sreg_gate_oe             : std_logic_vector(15 downto 0);
    signal sreg_gate_xon            : std_logic_vector(31 downto 0);
    signal sreg_gate_xon_flk        : std_logic_vector(31 downto 0);
    signal sreg_gate_flk            : std_logic_vector(31 downto 0);
    signal sreg_gate_rst_cycle      : std_logic_vector(31 downto 0);

    signal sreg_frame_num           : std_logic_vector(15 downto 0);        
    signal sreg_frame_val           : std_logic_vector(15 downto 0);        

    signal sreg_sexp_time           : std_logic_vector(31 downto 0);
    signal sreg_exp_time            : std_logic_vector(31 downto 0);
    signal sreg_frame_time          : std_logic_vector(31 downto 0);

    signal sreg_offsety             : std_logic_vector(11 downto 0);
    signal sreg_height              : std_logic_vector(11 downto 0);

    signal sreg_timing_mode         : std_logic_vector( 1 downto 0); --* jhkim




    signal sroic_cnt_1d             : std_logic_vector(7 downto 0);
    signal sext_trig_1d             : std_logic;
    signal sext_trig_2d             : std_logic;
    signal sext_trig_3d             : std_logic;
    signal sext_trig                : std_logic;
    signal sext_trig1               : std_logic;
    signal sreg_grab_en_1d          : std_logic;
    signal sreg_grab_en_2d          : std_logic;
    signal sreg_grab_en_3d          : std_logic;
    signal sreg_gate_en_1d          : std_logic_vector(7 downto 0);
    signal sreg_gate_en_2d          : std_logic_vector(7 downto 0);
    signal sreg_gate_en_3d          : std_logic_vector(7 downto 0);
    signal sreg_img_mode_1d         : std_logic_vector(2 downto 0);                 
    signal sreg_img_mode_2d         : std_logic_vector(2 downto 0);                 
    signal sreg_img_mode_3d         : std_logic_vector(2 downto 0);                 
    signal sreg_rst_mode_1d         : std_logic_vector(1 downto 0);                 
    signal sreg_rst_mode_2d         : std_logic_vector(1 downto 0);                 
    signal sreg_rst_mode_3d         : std_logic_vector(1 downto 0);                 
    signal sreg_rst_num_1d          : std_logic_vector(3 downto 0);                 
    signal sreg_rst_num_2d          : std_logic_vector(3 downto 0);                 
    signal sreg_rst_num_3d          : std_logic_vector(3 downto 0);                 
    signal sreg_shutter_1d          : std_logic;            
    signal sreg_shutter_2d          : std_logic;            
    signal sreg_shutter_3d          : std_logic;            
    signal sreg_trig_mode_1d        : std_logic_vector(1 downto 0);
    signal sreg_trig_mode_2d        : std_logic_vector(1 downto 0);
    signal sreg_trig_mode_3d        : std_logic_vector(1 downto 0);
    signal sreg_trig_valid_1d       : std_logic;
    signal sreg_trig_valid_2d       : std_logic;
    signal sreg_trig_valid_3d       : std_logic;
    signal sreg_roic_tp_sel_1d      : std_logic;
    signal sreg_roic_tp_sel_2d      : std_logic;
    signal sreg_roic_tp_sel_3d      : std_logic;
    signal sreg_roic_tp_sel_4d      : std_logic;
    signal sreg_roic_cds1_1d        : std_logic_vector(15 downto 0);
    signal sreg_roic_cds1_2d        : std_logic_vector(15 downto 0);
    signal sreg_roic_cds1_3d        : std_logic_vector(15 downto 0);
    signal sreg_roic_cds2_1d        : std_logic_vector(15 downto 0);
    signal sreg_roic_cds2_2d        : std_logic_vector(15 downto 0);
    signal sreg_roic_cds2_3d        : std_logic_vector(15 downto 0);
    signal sreg_roic_intrst_1d      : std_logic_vector(15 downto 0);
    signal sreg_roic_intrst_2d      : std_logic_vector(15 downto 0);
    signal sreg_roic_intrst_3d      : std_logic_vector(15 downto 0);
    signal sreg_gate_oe_1d          : std_logic_vector(15 downto 0);
    signal sreg_gate_oe_2d          : std_logic_vector(15 downto 0);
    signal sreg_gate_oe_3d          : std_logic_vector(15 downto 0);
    signal sreg_gate_xon_1d         : std_logic_vector(31 downto 0);
    signal sreg_gate_xon_2d         : std_logic_vector(31 downto 0);
    signal sreg_gate_xon_3d         : std_logic_vector(31 downto 0);
    signal sreg_gate_xon_flk_1d     : std_logic_vector(31 downto 0);
    signal sreg_gate_xon_flk_2d     : std_logic_vector(31 downto 0);
    signal sreg_gate_xon_flk_3d     : std_logic_vector(31 downto 0);
    signal sreg_gate_flk_1d         : std_logic_vector(31 downto 0);
    signal sreg_gate_flk_2d         : std_logic_vector(31 downto 0);
    signal sreg_gate_flk_3d         : std_logic_vector(31 downto 0);
    signal sreg_gate_rst_cycle_1d   : std_logic_vector(31 downto 0);
    signal sreg_gate_rst_cycle_2d   : std_logic_vector(31 downto 0);
    signal sreg_gate_rst_cycle_3d   : std_logic_vector(31 downto 0);
    signal sreg_frame_num_1d        : std_logic_vector(15 downto 0);        
    signal sreg_frame_num_2d        : std_logic_vector(15 downto 0);        
    signal sreg_frame_num_3d        : std_logic_vector(15 downto 0);        
    signal sreg_frame_val_1d        : std_logic_vector(15 downto 0);        
    signal sreg_frame_val_2d        : std_logic_vector(15 downto 0);        
    signal sreg_frame_val_3d        : std_logic_vector(15 downto 0);        
    signal sreg_sexp_time_1d        : std_logic_vector(31 downto 0);
    signal sreg_sexp_time_2d        : std_logic_vector(31 downto 0);
    signal sreg_sexp_time_3d        : std_logic_vector(31 downto 0);
    signal sreg_exp_time_1d         : std_logic_vector(31 downto 0);
    signal sreg_exp_time_2d         : std_logic_vector(31 downto 0);
    signal sreg_exp_time_3d         : std_logic_vector(31 downto 0);
    signal sreg_frame_time_1d       : std_logic_vector(31 downto 0);
    signal sreg_frame_time_2d       : std_logic_vector(31 downto 0);
    signal sreg_frame_time_3d       : std_logic_vector(31 downto 0);
    signal sreg_offsety_1d          : std_logic_vector(11 downto 0);
    signal sreg_offsety_2d          : std_logic_vector(11 downto 0);
    signal sreg_offsety_3d          : std_logic_vector(11 downto 0);
    signal sreg_height_1d           : std_logic_vector(11 downto 0);
    signal sreg_height_2d           : std_logic_vector(11 downto 0);
    signal sreg_height_3d           : std_logic_vector(11 downto 0);

    signal sreg_timing_mode_1d      : std_logic_vector( 1 downto 0); --* jhkim
    signal sreg_timing_mode_2d      : std_logic_vector( 1 downto 0); --* jhkim
    signal sreg_timing_mode_3d      : std_logic_vector( 1 downto 0); --* jhkim


    -- # d2m cdc reg
    signal sreg_d2m_en_d1 : std_logic := '0';  -- 1
    signal sreg_d2m_en_d2 : std_logic := '0';  -- 1
    signal sreg_d2m_en_d3 : std_logic := '0';  -- 1
    signal sreg_d2m_en    : std_logic := '0';  -- 1

    signal sreg_d2m_exp_in_d1  : std_logic := '0';  -- 1
    signal sreg_d2m_exp_in_d2  : std_logic := '0';  -- 1
    signal sreg_d2m_exp_in_d3  : std_logic := '0';  -- 1
    signal sreg_d2m_exp_in     : std_logic := '0';  -- 1
    signal sreg_d2m_exp_in0    : std_logic := '0';  -- 1
    signal sreg_d2m_exp_in1    : std_logic := '0';  -- 1
    signal sreg_d2m_exp_in_lat : std_logic := '0';  -- 1

    signal sreg_d2m_sexp_time_1d    : std_logic_vector(31 downto 0);
    signal sreg_d2m_sexp_time_2d    : std_logic_vector(31 downto 0);
    signal sreg_d2m_sexp_time_3d    : std_logic_vector(31 downto 0);
    signal sreg_d2m_sexp_time       : std_logic_vector(31 downto 0);

    signal sreg_d2m_frame_time_1d   : std_logic_vector(31 downto 0);
    signal sreg_d2m_frame_time_2d   : std_logic_vector(31 downto 0);
    signal sreg_d2m_frame_time_3d   : std_logic_vector(31 downto 0);
    signal sreg_d2m_frame_time      : std_logic_vector(31 downto 0);

    signal sreg_d2m_xrst_num_1d : std_logic_vector(15 downto 0);
    signal sreg_d2m_xrst_num_2d : std_logic_vector(15 downto 0);
    signal sreg_d2m_xrst_num_3d : std_logic_vector(15 downto 0);
    signal sreg_d2m_xrst_num    : std_logic_vector(15 downto 0);
            
    signal sreg_d2m_drst_num_1d : std_logic_vector(15 downto 0);
    signal sreg_d2m_drst_num_2d : std_logic_vector(15 downto 0);
    signal sreg_d2m_drst_num_3d : std_logic_vector(15 downto 0);
    signal sreg_d2m_drst_num    : std_logic_vector(15 downto 0);

    signal sreg_ExtTrigEn_d1 : std_logic := '0';
    signal sreg_ExtTrigEn_d2 : std_logic := '0';
    signal sreg_ExtTrigEn_d3 : std_logic := '0';
    signal sreg_ExtTrigEn    : std_logic := '0';

    signal sreg_ExtRst_Mode_1d : std_logic_vector(7 downto 0);
    signal sreg_ExtRst_Mode_2d : std_logic_vector(7 downto 0);
    signal sreg_ExtRst_Mode_3d : std_logic_vector(7 downto 0);
    signal sreg_ExtRst_Mode    : std_logic_vector(7 downto 0);

    signal sreg_ExtRst_DetTime_1d : std_logic_vector(31 downto 0);
    signal sreg_ExtRst_DetTime_2d : std_logic_vector(31 downto 0);
    signal sreg_ExtRst_DetTime_3d : std_logic_vector(31 downto 0);
    signal sreg_ExtRst_DetTime    : std_logic_vector(31 downto 0);
    signal sExt_TimeRstCnt        : std_logic_vector(31 downto 0);
    signal sExt_TimeRst           : std_logic;
           
    signal sd2m_xrst_cnt    : std_logic_vector(15 downto 0) := (others=> '0');
    signal sd2m_drst_cnt    : std_logic_vector(15 downto 0) := (others=> '0');

    signal sd2m_xexp_time           : std_logic_vector(31 downto 0);
                   
--  type type_state_d2m is ( 
--      sm_idle,         
--      sm_d2m_xray_start,
--      sm_d2m_xray,     
--      sm_d2m_xrayrst,  
--      sm_d2m_dark_start,
--      sm_d2m_dark,     
--      sm_d2m_darkrst,  
--      sm_d2m_end       
--  );
    signal state_d2m : type_state_d2m := sm_idle;
    signal sxon_cnt  : std_logic_vector(8-1 downto 0);
    signal state_tft_d2m_sel : tstate_tft;
    signal sGrstHCnt     : std_logic_vector(8-1 downto 0):= (others=>'0');
    signal sGrstVCnt     : std_logic_vector(9-1 downto 0):= (others=>'0'); 
                                                          
COMPONENT vio_gate_test
  PORT (
    clk : IN STD_LOGIC;
    probe_out0 : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    probe_out1 : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    probe_out2 : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    probe_out3 : OUT STD_LOGIC_VECTOR(8 DOWNTO 0);
    probe_out4 : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    probe_out5 : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    probe_out6 : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    probe_out7 : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    probe_out8 : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    probe_out9 : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    probe_out10 : OUT STD_LOGIC_VECTOR(0 DOWNTO 0)
  );
END COMPONENT;
    signal vio_xonflk_oe   : std_logic_vector(8-1 downto 0) := x"00";
    signal vio_XonCntLimt  : std_logic_vector(8-1 downto 0) := x"ff";
    signal vio_GrstHLim    : std_logic_vector(8-1 downto 0) := x"ff";
    signal vio_GrstVLim    : std_logic_vector(9-1 downto 0) := '1'& x"ff";
    signal vio_dioRise     : std_logic_vector(8-1 downto 0) := x"01";
    signal vio_dioFall     : std_logic_vector(8-1 downto 0) := x"20";
    signal vio_cpvRise     : std_logic_vector(8-1 downto 0) := x"10";
    signal vio_cpvFall     : std_logic_vector(8-1 downto 0) := x"32";
    signal vio_oeRise      : std_logic_vector(8-1 downto 0) := x"33";
    signal vio_oeFall      : std_logic_vector(8-1 downto 0) := x"4c";
    signal vio_syncEdgeSel : std_logic                      :=    '0';

    signal sTpSelForce      : std_logic := '0';
    signal sTpSelForceTp    : std_logic := '0';
    signal sTpSelForceSync  : std_logic := '0';
    signal sTpSelChangedCnt : std_logic_vector(8-1 downto 0) := (others=>'0');
    signal sExtTrigCnt : std_logic_vector(16-1 downto 0) := (others=>'0'); 

    signal debugnum : std_logic_vector(8-1 downto 0) := (others=>'0');
    signal sroic_dvalid_d0 : std_logic := '0';
    signal state_tft0   : tstate_tft;

    --# 220511 bcal speed 
    signal sreg_req_align_1d : std_logic := '0';
    signal sreg_req_align_2d : std_logic := '0';
    signal sreg_req_align_3d : std_logic := '0';
    signal sreg_req_align : std_logic := '0';
    
    --# 220728 sync edge test
    signal sroic_sync_rise : std_logic;
    signal sroic_sync_fall : std_logic;

    signal sm_grab    : std_logic_vector(4-1 downto 0) := (others=>'0');
    signal sm_tft     : std_logic_vector(4-1 downto 0) := (others=>'0');
    signal sm_roic    : std_logic_vector(4-1 downto 0) := (others=>'0');
    signal sm_gate    : std_logic_vector(4-1 downto 0) := (others=>'0');

    --# 230512
    signal vioo_cpv_period    : std_logic_vector(8-1 downto 0) := (others=>'0');
     
-- !begin
begin

--u_vio_gate_test : vio_gate_test
--  PORT MAP (
--    clk             => imain_clk,
--    probe_out0      => vio_xonflk_oe,  -- 0x0
--    probe_out1      => vio_XonCntLimt, -- 0xff
--    probe_out2      => vio_GrstHLim,   -- 0xff
--    probe_out3      => vio_GrstVLim,   -- 0x1ff
--    probe_out4      => vio_dioRise ,   -- 0x01
--    probe_out5      => vio_dioFall ,   -- 0x20
--    probe_out6      => vio_cpvRise ,   -- 0x10
--    probe_out7      => vio_cpvFall ,   -- 0x32
--    probe_out8      => vio_oeRise  ,   -- 0x33
--    probe_out9      => vio_oeFall  ,   -- 0x4c
--    probe_out10(0)  => vio_syncEdgeSel -- 0x0
--  );

    process(imain_clk, imain_rstn)
    begin
        if(imain_rstn = '0') then
            sroic_intrst_time   <= (others => '0');
            sroic_cds1_time     <= (others => '0');
            sroic_cds2_time     <= (others => '0');

            sgate_dio1_cpv1     <= (others => '0');
            sgate_cpv1_cpv2     <= (others => '0');
            sgate_cpv2_dio2     <= (others => '0');
            sgate_dio2_cpv1     <= (others => '0');
        elsif(imain_clk'event and imain_clk = '1') then
            sroic_intrst_time   <= sreg_roic_intrst + '1';
            sroic_cds1_time     <= sroic_intrst_time    + sreg_roic_cds1;
            sroic_cds2_time     <= sroic_cds1_time      + sreg_roic_cds2 + '1';

            sgate_dio1_cpv1     <= conv_std_logic_vector(0, 16); -- not use mbh 210503 -- conv_std_logic_vector(GATE_DIO_CPV, 16) - 1; -- 2-1
            sgate_cpv1_cpv2     <= sgate_dio1_cpv1      + conv_std_logic_vector(GATE_CPV_PERIOD(GNR_MODEL) / 2, 16) - 1 ;  -- 1+33 = 34
            sgate_cpv2_dio2     <= sgate_cpv1_cpv2      + conv_std_logic_vector(GATE_DIO_CPV(GNR_MODEL), 16); -- 36
            sgate_dio2_cpv1     <= sgate_cpv2_dio2      + conv_std_logic_vector(GATE_CPV_PERIOD(GNR_MODEL) / 2, 16);
        end if;
    end process;

    process(imain_clk, imain_rstn)
    begin
        if(imain_rstn = '0') then
            sgrab_en_tmp        <= '0';
        elsif(imain_clk'event and imain_clk = '1') then
        --
            if(sreg_shutter = '0') then -- ### rolling shutter
                sgrab_en_tmp     <= sreg_grab_en;
            else
                -- prevent 1 pulse out when trigger mode changed
                if(sreg_trig_mode = 0) then    -- ### global shutter - freerun
                    sgrab_en_tmp <= sreg_grab_en and sext_trig;
                elsif(sreg_trig_mode = 1) then -- ### global shutter - external1
                    -- ##### it makes 1 more continuous trigger, required by sec ###
                    if sgrab_en = '1' then
                        if sreg_grab_en = '1' and sext_trig='1' and sext_trig1 = '0' then
                            sgrab_en_tmp <= '1';
                        elsif(state_tft = s_FINISH) then
                            sgrab_en_tmp <= '0';
                        end if;
                    else
                        sgrab_en_tmp <= sreg_grab_en and sext_trig and not sext_trig1;
                    end if;
                elsif(sreg_trig_mode = 2) then -- ### global shutter - external2
                    sgrab_en_tmp <= sreg_grab_en and sext_trig and not sext_trig1;
                else
                    sgrab_en_tmp <= '0';
                end if;
            end if;

            -- # for trig debug, trig insert to sm_tft
            sgrab_en_tmp0 <= sgrab_en_tmp;
            if sgrab_en_tmp0='0' and sgrab_en_tmp='1' then
                sm_grab_trig <= '1';
            else
                sm_grab_trig <= '0';
            end if;
        --
        end if;
    end process;

    process(imain_clk, imain_rstn)
    begin
        if(imain_rstn = '0') then
            state_grab      <= s_IDLE;
            sgrab_en        <= '0';
            sframe_cnt      <= (others => '0');
        elsif(imain_clk'event and imain_clk = '1') then

            -- ### Ext Auto rst ###
            if state_grab  =  s_IDLE then
                if sExt_TimeRstCnt < sreg_ExtRst_DetTime then
                  sExt_TimeRstCnt <=  sExt_TimeRstCnt + '1';
                    sExt_TimeRst <= '0';
                else
                    sExt_TimeRst <= '1'; -- it is effective in global ext 1.
                end if;
            else
                sExt_TimeRstCnt <= (others => '0');
                sExt_TimeRst <= '0';
            end if;

            case (state_grab) is
                when s_IDLE     =>
                                    if(sgrab_en_tmp = '1') then
                                        state_grab      <= s_DATA;
                                        sgrab_en        <= '1';
                                    else
                                        sgrab_en        <= '0';
                                    end if;

                                    if(sreg_grab_en = '0') then
                                        sframe_cnt      <= (others => '0');
                                    end if;
                                    
                                    
                                    if (sreg_RstFrCnt = 0) then --# 1 is meaning ready #221121 
                                        sreg_RstFrCnt <= sreg_RstFrCnt + '1';
                                    elsif(state_tft=s_RstFinish)then -- 211221mbh
                                        sreg_RstFrCnt <= sreg_RstFrCnt + '1';
                                    end if;

                when s_DATA     =>
                                    sreg_RstFrCnt <= (others => '0');

                                    if(state_tft = s_EWT) then
                                        if(sreg_grab_en = '0') then
                                            state_grab      <= s_IDLE;
                                            sgrab_en        <= '0';
                                        end if;
                                    elsif(state_tft = s_FINISH) then
                                        if(sreg_frame_num = 0) then
                                            if(sgrab_en_tmp = '0') then
                                                state_grab      <= s_IDLE;
                                                sgrab_en        <= '0';
                                            end if;

                                            if(sframe_cnt < sreg_frame_val) then
                                                sframe_cnt      <= sframe_cnt + '1';
                                            end if;
                                        elsif(sframe_cnt >= sreg_frame_num + sreg_frame_val - 1) then
                                            -- state_grab       <= s_WAIT;
                                            state_grab      <= s_IDLE; -- 211217mbh s_WAIT;
                                            sgrab_en        <= '0';
                                        else
                                            sframe_cnt      <= sframe_cnt + '1';
                                        end if;
                                    -- elsif(sreg_shutter = '1' and state_tft = s_IDLE) then
                                    --  state_grab      <= s_IDLE;
                                    --  sgrab_en        <= '0';
                                    end if;
                when s_WAIT     =>
                                    if(sreg_grab_en = '0') then
                                        state_grab      <= s_IDLE;
                                    end if;

                                    NULL;
                when others     =>  NULL;               
            end case;
        end if;
    end process;
    
    sm_grab <= x"0" when state_grab = s_IDLE else
               x"1" when state_grab = s_DATA else
               x"2" when state_grab = s_WAIT else
               x"F";

    sm_tft  <= -- x"E" when sm_grab_trig = '1'       else --# not work #230707
               x"0" when state_tft = s_IDLE       else
               x"1" when state_tft = s_TRST       else
               x"2" when state_tft = s_SRST       else
               x"3" when state_tft = s_EWT        else
               x"4" when state_tft = s_SCAN       else
               x"5" when state_tft = s_FINISH     else
               x"6" when state_tft = s_GRST       else
               x"7" when state_tft = s_RstFINISH  else
               x"8" when state_tft = s_ScanFrWait else
               x"9" when state_tft = s_RstFrWait  else
               x"F";
                
    sm_roic <= x"0" when state_roic = s_IDLE      else
               x"1" when state_roic = s_OFFSET    else
               x"2" when state_roic = s_DUMMY     else
               x"4" when state_roic = s_INTRST    else
               x"5" when state_roic = s_CDS1      else
               x"6" when state_roic = s_GATE_OPEN else
               x"7" when state_roic = s_CDS2      else
               x"8" when state_roic = s_LDEAD     else
               x"9" when state_roic = s_FWAIT     else
               x"F";
                
    sm_gate <=  x"0" when state_gate = s_IDLE      else 
                x"1" when state_gate = s_DUMMY     else 
                x"2" when state_gate = s_READY     else 
                x"3" when state_gate = s_DIO_CPV   else 
                x"4" when state_gate = s_CPV       else 
                x"5" when state_gate = s_XON       else 
                x"6" when state_gate = s_OE        else 
                x"7" when state_gate = s_XON_FLK   else 
                x"8" when state_gate = s_FLK       else 
                x"9" when state_gate = s_CHECK     else 
                x"A" when state_gate = s_OE_READY  else 
                x"B" when state_gate = s_LWAIT     else 
                x"C" when state_gate = s_FWAIT     else 
                x"D" when state_gate = s_GRST_G    else 
                x"E" when state_gate = s_GRST_GEnd else 
                x"F";
                                    
--  slv_state <= conv_integer(state_tft);
    oreg_frame_cnt <= sreg_RstFrCnt(16-1 downto 0) & sframe_cnt(16-1 downto 0);
--    oreg_frame_cnt <= sreg_RstFrCnt(16-1 downto 0) & sm_gate & sm_roic & sm_tft & sm_grab;

--          probe0          => state_grab       ,   --* 2
--          probe1          => state_tft        ,   --* 3
--          probe2          => state_roic       ,   --* 4
--          probe3          => state_gate       ,   --* 4



    process(imain_clk, imain_rstn)
    begin
        if(imain_rstn = '0') then
            state_tft       <= s_IDLE;

            sexp_time       <= (others => '0');
            sframe_time     <= (others => '0');
            srst_time       <= (others => '0');

            stft_cnt        <= (others => '0');
            srst_cnt        <= (others => '0');
            
            sext_trig_out   <= '0';
            sfirst_rst      <= '0';
            sfirst_tft      <= '0';
            sgrab_done      <= '1';
        elsif(imain_clk'event and imain_clk = '1') then
            sreg_d2m_exp_in0 <= sreg_d2m_exp_in;
            sreg_d2m_exp_in1 <= sreg_d2m_exp_in0;
            if sreg_d2m_en = '0' then
                sreg_d2m_exp_in_lat <= '0';
            elsif vio_xonflk_oe(2) = '1' then -- d2m continouse trigger
                sreg_d2m_exp_in_lat <= '1';
            -- ### added condition of "state_d2m = sm_idle" is for preventing double d2 trigger input mbh 210728
            elsif sreg_d2m_exp_in1='0' and sreg_d2m_exp_in0='1' and state_d2m = sm_idle then 
                sreg_d2m_exp_in_lat <= '1';
            elsif state_tft = s_EWT then
                sreg_d2m_exp_in_lat <= '0';
            end if;

            if state_d2m = sm_d2m_xray_start or 
               state_d2m = sm_d2m_xray or 
               state_d2m = sm_d2m_xrayrst then
                od2m_xray   <= '1';
            else
                od2m_xray   <= '0';
            end if;

            if state_d2m = sm_d2m_dark_start or
               state_d2m = sm_d2m_dark or
               state_d2m = sm_d2m_darkrst then
                od2m_dark   <= '1';
            else
                od2m_dark   <= '0';
            end if;

            if  sreg_ExtTrigEn = '1' and
                state_tft = s_SRST then -- srst take a offset 211019 mbh
                oExtTrig_Srst <= '1';
            else
                oExtTrig_Srst <= '0';
            end if;

            if vio_xonflk_oe(1 downto 0) = 0 then
               state_tft_d2m_sel <= s_TRST; -- default
            elsif vio_xonflk_oe(1 downto 0) = 1 then
               state_tft_d2m_sel <= s_SRST;
            else
               state_tft_d2m_sel <= s_GRST; -- 2
            end if;

             sroic_dvalid_d0 <= sroic_dvalid;
             state_tft0 <= state_tft;
            if sroic_dvalid_d0 = '1' and sroic_dvalid='0' then -- fall
--                if sm_grab_trig = '1' then --# 230707 trig
--                    ostate_tftd <=  s_Trig;
--                else
--                    ostate_tftd <=  state_tft0;
--                end if;
              ostate_tftd <=  state_tft0;
            end if;


            case (state_tft) is
                when s_IDLE     => 
                                    -- ################
                                    -- ### !d2 mode ###
                                    if(sreg_d2m_en = '1') then
                                        stft_cnt  <= (others => '0');
                                        -- # idle -> xray(ewt,scan) -> xray trst -> dark(ewt, scan) -> dark trst
                                        --           save to ddr                    calc to out
                                        case (state_d2m) is
                                            when sm_idle => 
--                                              state_tft <= state_tft_d2m_sel; -- s_TRST;      
                                                if(sreg_d2m_exp_in_lat = '1') then
                                                    state_d2m       <= sm_d2m_xray_start;
                                                    sexp_time       <= sreg_d2m_sexp_time;  -- sreg_sexp_time  0x21c
                                                    sframe_time     <= sreg_d2m_frame_time; -- sreg_frame_time 0x74
                                                    stft_cnt        <= (others => '0');
                                                else 
                                                    state_tft <= state_tft_d2m_sel; -- ver33 test 210723
                                                end if;
                                            when sm_d2m_xray_start =>
                                                state_d2m       <= sm_d2m_xray;
                                                state_tft       <= s_EWT; -- it gose to ewt -> scan 
                                            when sm_d2m_xray =>
                                                state_d2m       <= sm_d2m_xrayrst;
                                            when sm_d2m_xrayrst =>
                                                if sd2m_xrst_cnt < sreg_d2m_xrst_num then
                                                    state_tft       <= state_tft_d2m_sel; -- s_TRST;
                                                    sd2m_xrst_cnt   <= sd2m_xrst_cnt + '1'; 
                                                else
                                                    state_d2m       <= sm_d2m_dark_start;
                                                    sd2m_xrst_cnt   <= (others=>'0'); 
                                                end if;
                                            when sm_d2m_dark_start =>
                                                state_tft       <= s_EWT; -- it gose to ewt -> scan  
                                                state_d2m       <= sm_d2m_dark;
                                            when sm_d2m_dark =>
                                                state_d2m       <= sm_d2m_darkrst;
                                            when sm_d2m_darkrst =>
                                                if sd2m_drst_cnt < sreg_d2m_drst_num then
                                                    state_tft         <= state_tft_d2m_sel; -- s_TRST;
                                                    sd2m_drst_cnt     <= sd2m_drst_cnt + '1'; 
                                                else
                                                    state_d2m       <= sm_d2m_end;
                                                    sd2m_drst_cnt   <= (others=>'0'); 
                                                end if;
                                            when sm_d2m_end =>
                                                state_d2m       <= sm_idle;
                                            when others => 
                                                state_d2m       <= sm_idle;
                                        end case;
                                    -- #############
                                    -- ### first ### after total reset
                                    elsif(sfirst_tft = '1') then
                                        if(sreg_rst_mode(1) = '1') then
                                            state_tft       <= s_EWT;
                                            sexp_time       <= sreg_sexp_time;
                                            sframe_time     <= sreg_frame_time;
                                            stft_cnt        <= (others => '0');
                                        else
                                            if(sreg_shutter = '1') then
                                                state_tft       <= s_EWT;
                                                sexp_time       <= sreg_exp_time + srst_time;
                                                sframe_time     <= sreg_frame_time;
                                            else
                                                state_tft       <= s_SCAN;
                                                sexp_time       <= sreg_exp_time;
                                                sframe_time     <= sreg_frame_time;
                                            end if;
                                            stft_cnt        <= stft_cnt + '1';
                                        end if;
                                        sfirst_tft      <= '0';
                                        sgrab_done      <= '0';
                                        srst_time       <= (others => '0');
                                    elsif(sgrab_en = '1') then
                                        state_d2m       <= sm_idle; -- d2m rst 210726 mbh
                                        stft_cnt        <= (others => '0');
                                        -- #################################
                                        -- ### rolling + Shutter Freerun ###
                                        if(sreg_trig_mode = 0) then -- ### grab rolling mode
                                            -- ### global shutter mode use a ewt ; mbh 210512
                                            if(sreg_frame_num = 0 or sframe_cnt < sreg_frame_num) then
                                                -- ### Shutter Freerun ###
                                                if sreg_shutter = '1' then
                                                    sexp_time       <= sreg_sexp_time;  --move up #240416
                                                    sframe_time     <= sreg_frame_time; -- 220124mbh go upper if
                                                    if sext_trig = '1'  then 
                                                        -- global freerun needs a trig in. 211020 mbh
                                                        state_tft       <= s_EWT;
--                                                        sexp_time       <= sreg_sexp_time;
--                                                        sframe_time     <= sreg_frame_time; -- 220124mbh go upper if
                                                        stft_cnt        <= (others => '0');
                                                        sfirst_rst      <= '0'; -- not use 211021 mbh
                                                        debugnum <= x"01";
                                                    else
                                                        if(sreg_rst_mode(0) = '0') then
                                                            state_tft   <= s_TRST;      
                                                        else
                                                            state_tft   <= s_SRST_EWT; --# 240416 s_SRST;      
                                                        end if;
                                                        debugnum <= x"11";
                                                    end if;
                                                elsif(sfirst_rst = '1') then
                                                    sexp_time       <= sreg_sexp_time;  --move up #240416
                                                    sframe_time     <= sreg_frame_time; -- 220124mbh go upper if
                                                    if(sreg_rst_mode(1) = '0') then
                                                        state_tft   <= s_TRST;      
                                                    else
                                                        state_tft   <= s_SRST_EWT; --# 240416 s_SRST;      
                                                    end if;
                                                    sfirst_rst      <= '0'; -- ? 1?
                                                    debugnum <= x"02";
                                                -- ### rolling ###
                                                else
                                                  state_tft       <= s_SCAN;
                                                  sexp_time       <= sreg_exp_time;
                                                    
                                                    sframe_time     <= sreg_frame_time;
                                                    sfirst_rst      <= '0';
                                                    debugnum <= x"03";
                                                end if;
                                            else 
                                                    debugnum <= x"04";
                                                if(sreg_rst_mode(0) = '0') then
                                                    state_tft   <= s_TRST;      
                                                else
                                                    state_tft   <= s_SRST_EWT; --# 240416 s_SRST;      
                                                end if;
                                            end if;
                                             -- ################################
                                        else -- ### grab global/trigger mode ###
                                            if(sreg_frame_num = 0 or sframe_cnt < sreg_frame_num) then 
                                                -- (sext_trig = '1' and sext_trig1 = '0') then
                                                -- if(sreg_shutter = '1' or sfirst_rst = '1') then
                                                if sfirst_rst = '1' then
                                                    if(sreg_rst_mode(1) = '0') then
                                                        state_tft   <= s_TRST;      
                                                    else
                                                        state_tft   <= s_SRST_EWT; --# 240416 s_SRST;      
                                                    end if;
                                                    sfirst_rst      <= '0';
                                                    debugnum <= x"25";
                                                else
                                                    if sreg_trig_mode = 2 and sext_trig = '0' then 
                                                       -- ### external2 cancel if trig low before ewt
                                                        state_tft <= s_FINISH;
                                                    else
                                                        state_tft       <= s_EWT; -- 211022mbh
                                                        sfirst_rst      <= '0';
                                                        stft_cnt        <= (others => '0'); -- 211027mbh
                                                    end if;
                                                    debugnum <= x"55";
                                                end if;
                                            else
                                                debugnum <= x"06";
                                                if(sreg_rst_mode(0) = '0') then
                                                    state_tft   <= s_TRST;      
                                                else
                                                    state_tft   <= s_SRST_EWT; --# 240416 s_SRST;      
                                                end if;
                                            end if;
                                            sexp_time       <= sreg_sexp_time;
                                            sframe_time     <= sreg_frame_time;
                                        end if;
                                        sgrab_done      <= '0';
                                    else 
                                    -- ###################
                                    -- ##### NO GRAB #####  
                                        sexp_time       <= sreg_sexp_time; --# srst need to update to srst_ewt # 240417
                                        sframe_time     <= sreg_frame_time; -- frame time latch by mode, even if not grab 220124mbh
                                        state_d2m       <= sm_idle; -- d2m rst 210726 mbh
                                        stft_cnt        <= (others => '0');
                                        if sreg_shutter = '1' and sreg_trig_mode = 1 then --### global ext1 220115mbh
                                            case(sreg_ExtRst_MODE) is --ext normal rst mode
                                                when x"00"=>
                                                    if(sreg_rst_mode(0) = '0') then
                                                        state_tft   <= s_TRST;      
                                                    else
                                                        state_tft   <= s_SRST_EWT; --# 240416 s_SRST;      
                                                    end if;
                                                when x"01"=> -- ext no rst mode
                                                    state_tft   <= s_IDLE; -- wait      
                                                when x"02"=>
                                                    if sExt_TimeRst = '1' then
                                                        if(sreg_rst_mode(0) = '0') then
                                                            state_tft   <= s_TRST;
                                                        else
                                                            state_tft   <= s_SRST_EWT; --# 240416 s_SRST;
                                                        end if;
                                                    else
                                                        state_tft   <= s_IDLE;
                                                    end if;
                                                when others => 
                                                    state_tft   <= s_IDLE;
                                            end case;
                                        else
                                            if(sreg_rst_mode(0) = '0') then
                                                state_tft   <= s_TRST;      
                                            else
                                                state_tft   <= s_SRST_EWT; --# 240416 s_SRST;      
                                            end if;
                                        end if;
                                        sgrab_done      <= '1';
                                    end if;
                                     sext_trig_out  <= '0';

                when s_TRST     => 
                                    if(sreg_d2m_en = '1') then
                                        if(sreg_d2m_exp_in_lat = '1' and state_gate = s_FWAIT) then -- if trigger detected, finish a TRST. mbh210719
                                            state_tft   <= s_IDLE;
                                        elsif(stft_cnt >= sreg_gate_rst_cycle) then
                                            state_tft   <= s_IDLE;
                                        end if;

                                    elsif(sfirst_rst = '0') then                -- Wait Reset
                                        if(sgrab_en = '1' and state_gate = s_FWAIT) then
                                            state_tft       <= s_IDLE;
                                            sfirst_rst      <= '1';
                                        else
                                            if(stft_cnt >= sreg_gate_rst_cycle) then
                                                state_tft   <= s_IDLE;
                                            end if;
                                        end if;
                                        sgrab_done      <= '1';
                                    else
                                        if(srst_cnt >= sreg_rst_num and state_gate = s_FWAIT) then
                                            state_tft       <= s_IDLE;
                                            sfirst_rst      <= '0';
                                            sfirst_tft      <= '1';
                                            srst_cnt        <= (others => '0');
                                            srst_time       <= srst_time + stft_cnt(31 downto 0);
                                        else
                                            sfirst_tft      <= '0';

                                            if(stft_cnt >= sreg_gate_rst_cycle) then
                                                state_tft   <= s_IDLE;
                                                srst_cnt    <= srst_cnt + '1';
                                            end if;
                                        end if;
                                        sgrab_done      <= '0';
                                    end if;

                                    stft_cnt        <= stft_cnt + '1';
                                     sext_trig_out  <= '0';

                when s_SRST_EWT     => --# SRST_FRONT_WAIT  
--                                     state_tft       <= s_SRST_SCAN;

                                        if sreg_req_align = '1' then
                                            state_tft       <= s_SRST;
                                        elsif(stft_cnt >= sexp_time) then
                                            state_tft       <= s_SRST;
                                        end if;
                                        
                                    sfirst_rst      <= '0';
                                    stft_cnt        <= stft_cnt + '1';
                                    sext_trig_out  <= '0';
                when s_SRST   => --# 240415  
                                    if(state_gate = s_FWAIT and state_roic = s_FWAIT) then
--                                      if(stft_cnt >= sframe_time - 2 or sframe_time = 0) then -- serial reset needs a frame time delay 211019 mbh 211220comment   

                                            -- state_tft        <= s_IDLE;
                                            state_tft       <= s_RstFrWait; -- mbh 211216
                                            debugnum    <= x"21"; -- #### -----------------------------------------------
                                            if(sgrab_en = '1') then
                                                -- sfirst_tft       <= '1';
                                                sfirst_tft      <= '0'; -- not use 211021mbh
                                                sgrab_done      <= '0';
                                            else
                                                sfirst_tft      <= '0';
                                                sgrab_done      <= '1';
                                            end if;

--                                      end if;
                                    end if;
                                    sfirst_rst      <= '0';
                                    stft_cnt        <= stft_cnt + '1';
                                     sext_trig_out  <= '0';
                when s_GRST     =>  
                                    if(state_gate = s_GRST_GEnd) then -- d2m grst mbh210714
                                        state_tft       <= s_IDLE;
                                    end if;

                when s_EWT      => 
                                    -- ######################
                                    -- ### bcal EWT STOP #### 220511mbh
                                    if sreg_req_align = '1' then
                                        sext_trig_out   <= '0';
                                        state_tft       <= s_FINISH;
                                    -- #################
                                    -- ### EWT STOP #### mbh 211206
                                    elsif(sgrab_en = '0') then
                                        sext_trig_out   <= '0';
                                        state_tft       <= s_FINISH;
                                    -- ###########
                                    -- ### d2m ### mbh 210624
                                    elsif state_d2m = sm_d2m_xray then
                                        if(sreg_d2m_exp_in1 = '0' or stft_cnt >= sexp_time ) then
                                            state_tft       <= s_SCAN;
                                            sext_trig_out   <= '0';
                                            sd2m_xexp_time <= stft_cnt(31 downto 0); --# save xray ewt time
                                        else
                                            sext_trig_out   <= '1';
                                        end if;
                                    elsif state_d2m = sm_d2m_dark then
                                        if(stft_cnt >= sd2m_xexp_time ) then
                                            state_tft       <= s_SCAN;
                                            sext_trig_out   <= '0';
                                        else
                                            sext_trig_out   <= '0'; -- no ext out for dark
                                        end if;
                                    -- #############
                                    -- ### Ext2 ####
                                    elsif(sreg_trig_mode = 2) then
                                       -- ### trig 2 mode has a limitation time; if(sext_trig = '0') then mbh 210512
                                        if(sext_trig = '0' or stft_cnt >= sexp_time ) then
                                            state_tft       <= s_SCAN;
                                            sext_trig_out   <= '0';
                                        else
                                            sext_trig_out   <= '1';
                                        end if;
                                    -- #########################
                                    -- ### Rolling, FreeRun ####
                                    else
                                        if(stft_cnt >= sexp_time) then
                                            state_tft       <= s_SCAN;
                                            sext_trig_out   <= '0';
                                        else
                                            sext_trig_out   <= '1';
                                        end if;
                                    end if;

                                    stft_cnt        <= stft_cnt + '1';

                                    sgrab_done      <= '0';

                when s_SCAN     =>
                                    -- if(stft_cnt >= sframe_time - 2 or sframe_time = 0) then  
                                        if(state_roic = s_FWAIT and state_gate = s_FWAIT) then
                                            state_tft       <= s_ScanFrWait;
                                        end if;
                                    -- end if;
                                    stft_cnt        <= stft_cnt + '1';
                                    sext_trig_out   <= '0';
                                    sgrab_done      <= '0';
                when s_ScanFrWait =>
                                    if sreg_req_align = '1' then  --# 220511mbh bcal speed
                                        state_tft   <= s_FINISH;
                                    elsif(stft_cnt >= sframe_time - 2 or sframe_time = 0) then  
                                        state_tft   <= s_FINISH;
                                    end if;
                                    stft_cnt        <= stft_cnt + '1';
                when s_RstFrWait =>
                                    if sreg_req_align = '1' then  --# 220511mbh bcal speed
                                        state_tft   <= s_RstFINISH;
                                    elsif(stft_cnt >= sframe_time - 2 or sframe_time = 0) then -- or -- then -- serial reset needs a frame time delay 211019 mbh 211220comment
                                      -- sgrab_en = '1' then -- 211224mbh immediately pass waiting if should do scan next 211227 rollback   
                                        state_tft   <= s_RstFINISH;
                                    end if;
                                    stft_cnt        <= stft_cnt + '1';
                when s_FINISH | s_RstFINISH => 
                                    state_tft       <= s_IDLE;
                                    stft_cnt        <= (others => '0');
                                    sext_trig_out   <= '0';

                when others     => 
                                    NULL;
            end case;
        end if;
    end process;





    process(imain_clk, imain_rstn)
    begin
        if(imain_rstn = '0') then
            state_roic          <= s_IDLE;

            sroic_sync          <= '0';
            sroic_tp_sel        <= '0';
            sroic_bank          <= '0';
            sroic_cnt           <= (others => '0');
            sroic_dvalid        <= '0';

            sroic_line_cnt      <= (others => '0');
        elsif(imain_clk'event and imain_clk = '1') then
             if (state_roic = s_OFFSET) and -- 211215mbh 
                (state_gate = s_READY)  then
                sroic_bank      <= '1';
                sroic_cnt       <= (others => '0');
            elsif(sroic_cnt = 255) then
            -- if(sroic_cnt = 255) then
                sroic_bank      <= not sroic_bank;
                sroic_cnt       <= (others => '0');
            else
                sroic_cnt       <= sroic_cnt + '1';
            end if;

            -- ------------------------------------
            -- ### tp_sel with roic_sync ### 210812 ## comments 231025
            sreg_roic_tp_sel_4d <= sreg_roic_tp_sel_3d;
            if sreg_roic_tp_sel_4d  /= sreg_roic_tp_sel_3d then
                sTpSelChangedCnt <= (others=> '0');
            elsif sTpSelChangedCnt < 256-1 then
                sTpSelChangedCnt <= sTpSelChangedCnt + '1';
            end if;

            if sTpSelChangedCnt < 128-1 then
               sTpSelForce <= '1';
--               sTpSelForceTp <= sreg_roic_tp_sel_3d;
            else
               sTpSelForce <= '0';
--               sTpSelForceTp <= '0';
            end if;
                
            if 32 <= sTpSelChangedCnt      and 
                     sTpSelChangedCnt < 96 then
               sTpSelForceSync <= '1';
            else 
               sTpSelForceSync <= '0';
            end if;
            -- ------------------------------------
            sroic_tp_sel    <= sreg_roic_tp_sel_3d;


            case (state_roic) is
                when s_IDLE     =>  
                                    if(state_tft = s_SCAN or state_tft = s_SRST) then
                                        state_roic      <= s_OFFSET;
--                                        sroic_tp_sel    <= sreg_roic_tp_sel_3d;
                                    elsif vio_xonflk_oe(4) = '1'  and sreg_d2m_en = '1' and (state_tft = s_TRST or state_tft = s_GRST) then
                                        state_roic      <= s_IDLE;
--                                        sroic_tp_sel    <= '1'; -- sreg_roic_tp_sel_3d;
                                    else
                                        state_roic      <= s_IDLE;
                                    end if;

                                    sroic_sync          <= '0';
                                    sroic_line_cnt      <= (others => '0');

                when s_OFFSET   =>
                                    if(state_gate = s_READY) then
                                        -- if(sroic_cnt = 255 and sroic_bank = '0') then -- 211215mbh
--                                      if(sroic_cnt = 255 and sroic_bank = '0') then
                                            state_roic      <= s_DUMMY;
                                            sroic_sync      <= '1';
--                                      end if;
                                    end if;

                when s_DUMMY    =>
                                    state_roic      <= s_INTRST;
                                    sroic_sync      <= '0';
                                    
                                    -- ### ( d2 mode or trigger mode ) dose not give a video during serial reset(srst). 210706 mbh 
                                    --if sreg_d2m_en = '1' or sreg_shutter = '1' then
                                    if sreg_d2m_en = '1' then -- shutter mode serial reset use as a offset.
                                        if ( sroic_line_cnt > ROIC_DUMMY_LINE(GNR_MODEL) and state_tft = s_scan ) then 
                                            sroic_dvalid        <= '1';
                                        else
                                            sroic_dvalid        <= '0';
                                        end if;
                                    elsif(sroic_line_cnt > ROIC_DUMMY_LINE(GNR_MODEL)) then
                                        sroic_dvalid        <= '1';
                                    else
                                        sroic_dvalid        <= '0';
                                    end if;

                when s_INTRST   =>
                                    if(sroic_cnt >= sroic_intrst_time) then
                                        state_roic      <= s_CDS1;
                                    end if;
                                        
                when s_CDS1     =>
                                    if(sroic_cnt >= sroic_cds1_time) then
                                        state_roic      <= s_GATE_OPEN;
                                    end if;

                when s_GATE_OPEN => 
                                    state_roic      <= s_CDS2;      -- Response Immediately

                when s_CDS2     =>
                                    if(sroic_cnt >= sroic_cds2_time) then
                                        state_roic      <= s_LDEAD;
                                    end if;
                when s_LDEAD    => 
                                    if(sroic_cnt = 255) then
                                        if(sroic_line_cnt >= sreg_height + ROIC_DUMMY_LINE(GNR_MODEL)) then
                                            state_roic      <= s_FWAIT;
                                            sroic_line_cnt  <= (others => '0');
                                        else
                                            state_roic      <= s_DUMMY;
                                            sroic_line_cnt  <= sroic_line_cnt + ROIC_DUAL_BY_MODEL(GNR_MODEL);
                                        end if;
                                    end if;
                when s_FWAIT    =>
                                    if(state_tft = s_IDLE) then
                                        state_roic      <= s_IDLE;
                                    end if;

                                    sroic_dvalid    <= '0';

                when others     => 
                                    NULL;

            end case;
        end if;
    end process;



    process(imain_clk, imain_rstn)
    begin
        if(imain_rstn = '0') then
            state_gate          <= s_IDLE;
            state_cpv           <= (others => '0');

            sgate_ch_cnt        <= 0;
            sgate_line_cnt      <= (others => '0');
            sgate_cnt           <= (others => '0');
            sgate_oe_cnt        <= (others => '0');

            sgate_end           <= '0';
            sgate_oe_end        <= '0';

            sgate_num           <= 0;
            sgate_oe_num        <= 0;

            sgate_cpv           <= '0';
            sgate_dio           <= (others => '0');
            sgate_oe            <= '0';
            sgate_xon           <= '1';
            sgate_flk           <= '1';

            sgate_dummy_en      <= '0';
            sgate_dummy_num     <= 0;
            sgate_dummy_cnt     <= (others => '0');
            sgate_dummy_add     <= 0;  -- update 210126 
        elsif(imain_clk'event and imain_clk = '1') then
            case (state_gate) is
                when s_IDLE     =>  
                                    if(state_tft = s_SCAN or state_tft = s_SRST) then
                                        for i in 0 to GATE_NUM(GNR_MODEL)-1 loop
                                            if(sreg_offsety >= (GATE_CH(GNR_MODEL)*i) and sreg_offsety < (GATE_CH(GNR_MODEL)*(i+1))) then
                                                sgate_num           <= i;
                                                if(sreg_offsety = (GATE_CH(GNR_MODEL)*i) and GATE_DUMMY_LINE(GNR_MODEL) = 0) then
                                                    state_gate          <= s_READY;
                                                else
                                                    state_gate          <= s_DIO_CPV;
                                                    sgate_dio(i)        <= '1';
                                                    sgate_dummy_en      <= '1';
--                                                    sgate_dummy_num     <= (conv_integer(sreg_offsety) - (GATE_CH(GNR_MODEL)*i) + GATE_DUMMY_LINE(GNR_MODEL)) *ROIC_DUAL_BY_MODEL(GNR_MODEL); --$ 260220 dual roic offset
                                                    sgate_dummy_num     <= (conv_integer(sreg_offsety) - (GATE_CH(GNR_MODEL)*i) + GATE_DUMMY_LINE(GNR_MODEL)) *(ROIC_DUAL_BY_MODEL(GNR_MODEL)+ sgate_dummy_add) / (1 + sgate_dummy_add); --$ 260223 dual roic 2x2 binning error
                                                    --sgate_dummy_num     <= conv_integer(sreg_offsety) - (GATE_CH(GNR_MODEL)*i) + GATE_DUMMY_LINE(GNR_MODEL);
--                                                    if  GATE_DUMMY_LINE(GNR_MODEL) mod 2 = 1 then --# dummy is odd --# 230920 
--                                                        sgate_dummy_num     <= conv_integer(sreg_offsety) - (GATE_CH(GNR_MODEL)*i) + GATE_DUMMY_LINE(GNR_MODEL) - sgate_dummy_add; --# 230920 test only 2430
--                                                    else 
--                                                        sgate_dummy_num     <= conv_integer(sreg_offsety) - (GATE_CH(GNR_MODEL)*i) + GATE_DUMMY_LINE(GNR_MODEL);
--                                                    end if;
                                                end if;
                                            end if;
                                        end loop;

                                        sgate_xon           <= '1';
                                        sgate_flk           <= '0';
                                    elsif(state_tft = s_TRST) then
                                        state_gate          <= s_XON;
                                        sgate_cnt           <= (others => '0');

                                        sgate_xon           <= '0';
                                        sgate_flk           <= '0';
                                    elsif(state_tft = s_GRST) then
                                        state_gate          <= s_GRST_G;
                                        sgate_cnt           <= (others => '0');
                                    else
                                        state_gate          <= s_IDLE;
                                        sgate_cnt           <= (others => '0');

                                        sgate_xon           <= '1';
                                        sgate_flk           <= '0';
                                    end if;

                when s_DUMMY    =>  
                                    if(sgate_dummy_cnt >= sgate_dummy_num - ROIC_DUAL_BY_MODEL(GNR_MODEL) - sgate_dummy_add) then  -- update 210126 
                                        if(sgate_end = '1') then
                                            state_gate      <= s_FWAIT;
                                            sgate_end       <= '0';
                                            sgate_oe_cnt    <= (others => '0'); --* v0.00.03  -- update 210126 

                                        else
                                            state_gate      <= s_READY;
                                        end if;
                                        sgate_dummy_en      <= '0';
                                        sgate_dummy_cnt     <= (others => '0');
                                    else
                                        if(sgate_ch_cnt = 0) then
                                            state_gate          <= s_DIO_CPV;
                                            sgate_dio(sgate_num)<= '1';
                                        else
                                            state_gate          <= s_CPV;
                                            sgate_cpv           <= '1';
                                        end if;

                                        sgate_dummy_cnt     <= sgate_dummy_cnt + ROIC_DUAL_BY_MODEL(GNR_MODEL) + sgate_dummy_add;  -- update 210126 
                                    end if;

                                    sgate_cnt           <= (others => '0');

                when s_READY    =>  
                                    --###  DIO (start)
                                    if state_roic = S_INTRST then
                                        if(sgate_ch_cnt = 0) then
                                             sgate_dio(sgate_num) <= '1';
                                        end if;                                 
                                    end if;

                                    --###  CPV (shift clk)
                                    if state_roic = S_CDS1 then
                                        sgate_cpv <= '1';
                                    end if;

                                    --###  OE
                                    if state_roic = s_GATE_OPEN then
                                        sgate_oe <= '1';
                                    end if; 

                                    --### state
                                    if state_roic = s_GATE_OPEN then
                                        if(sgate_ch_cnt = 0) then
                                            state_gate <= s_DIO_CPV;
                                        else
                                            state_gate <= s_CPV;
                                        end if;
                                    end if;

                                    case (sreg_img_mode) is -- 210126 update
                                            when "000"  =>  sgate_dummy_add <= 0;   sgate_oe_num    <= 1;
                                            when "001"  =>  sgate_dummy_add <= 1;   sgate_oe_num    <= 1;
                                            when "010"  =>  sgate_dummy_add <= 1;   sgate_oe_num    <= 1;
                                            when "011"  =>  sgate_dummy_add <= 1;   sgate_oe_num    <= 1; -- 2x2 binn #230920
                                            when "100"  =>  sgate_dummy_add <= 0;   sgate_oe_num    <= 3;
                                            when "101"  =>  sgate_dummy_add <= 0;   sgate_oe_num    <= 3;
                                            when "110"  =>  sgate_dummy_add <= 1;   sgate_oe_num    <= 2;
                                            when "111"  =>  sgate_dummy_add <= 1;   sgate_oe_num    <= 2;
                                            when others =>  NULL;
                                    end case;
                                    
                                    sgate_cnt           <= (others => '0');

                when s_DIO_CPV  =>
                                    sgate_cnt       <= sgate_cnt + '1';

                                    case (state_cpv) is
                                        when x"0"   =>  
--                                                      if(sgate_cnt >= sgate_dio1_cpv1) then -- sgate_dio1_cpv1 not use
                                                            state_cpv   <= x"1";
                                                            sgate_cpv   <= '1';
                                                            if(sgate_dummy_en = '0') then
                                                                sgate_oe    <= '1';
                                                            end if;
--                                                      end if;

                                        when x"1"   =>  
--                                                      if(sgate_cnt >= sgate_cpv1_cpv2) then
--                                                          state_cpv   <= x"2";
--                                                          sgate_cpv   <= '0';
--                                                      end if;

                                                        if(sgate_cnt >= sgate_cpv1_cpv2) then
                                                            sgate_cpv   <= '0';
                                                            sgate_dio       <= (others => '0');
                                                            if(sgate_dummy_en = '1') then
                                                            state_cpv   <= x"2";
                                                            elsif(sgate_oe_num > 1) then -- 3x3binn dio width abnormal, mbh 210615
                                                                state_cpv       <= x"3"; 
                                                            else
                                                                state_gate      <= s_OE;
                                                                state_cpv       <= x"0";
                                                            end if;
                                                        end if;

                                        when x"2"   => 
                                                        if(sgate_cnt >= sgate_cpv2_dio2) then
                                                            if(sgate_dummy_en = '1') then
                                                                state_cpv       <= x"3";
                                                            elsif(sgate_oe_num > 1) then 
                                                                state_cpv       <= x"3";
                                                            else
                                                                state_gate      <= s_OE;
                                                                state_cpv       <= x"0";
                                                            end if;
                                                            sgate_dio       <= (others => '0');
                                                        end if;

                                        when x"3"   =>  
                                                        if(sgate_cnt >= sgate_dio2_cpv1) then
                                                            if(sgate_dummy_en = '1') then
                                                                state_gate      <= s_DUMMY;
                                                                if(sgate_num < (GATE_NUM(GNR_MODEL) / ROIC_DUAL_BY_MODEL(GNR_MODEL)) - 1 and sgate_ch_cnt >= GATE_CH(GNR_MODEL) - sgate_dummy_add - 1) then  -- update 210126 
                                                                    sgate_ch_cnt    <= 0;
                                                                    sgate_num       <= sgate_num + 1;
                                                                else
                                                                    sgate_ch_cnt    <= sgate_ch_cnt + sgate_dummy_add + 1;  -- update 210126 
                                                                end if;
                                                            else
                                                                state_gate      <= s_OE;
                                                            end if;
                                                            state_cpv       <= x"0";
                                                        end if;

                                        when others => 
                                                        NULL;
                                    end case;

                when s_CPV      =>  
                                    sgate_cnt       <= sgate_cnt + '1';
--                                            sgate_oe        <= '0'; --# 230925

                                    case (state_cpv) is
                                        when x"0"   =>  
                                                        --# 230512 test
                                                        --# if(sgate_cnt >= vioo_cpv_period(7 downto 1) - 1) then
                                                        if(sgate_cnt >= (GATE_CPV_PERIOD(GNR_MODEL) / 2) - 1) then
                                                            sgate_cpv       <= '0';
                                                            if(sgate_dummy_en = '1') then
                                                                state_cpv       <= x"1";
                                                            elsif(sgate_oe_num > 1) then 
                                                                state_cpv       <= x"1";
                                                            else
                                                                state_gate      <= s_OE;
                                                                state_cpv       <= x"0";
                                                            end if;
                                                        else
                                                            sgate_cpv       <= '1';
                                                        end if;

                                        when x"1"   =>
                                                        --# 230512 test
                                                        --#if(sgate_cnt >= vioo_cpv_period - 1) then
                                                        if(sgate_cnt >= GATE_CPV_PERIOD(GNR_MODEL) - 1) then
                                                            if(sgate_dummy_en = '1') then
                                                                state_gate      <= s_DUMMY;

                                                                if(sgate_num < (GATE_NUM(GNR_MODEL) / ROIC_DUAL_BY_MODEL(GNR_MODEL)) - 1 and sgate_ch_cnt >= GATE_CH(GNR_MODEL) - sgate_dummy_add - 1) then  -- update 210126 
                                                                    sgate_ch_cnt    <= 0;
                                                                    sgate_num       <= sgate_num + 1;
                                                                else
                                                                    sgate_ch_cnt    <= sgate_ch_cnt + sgate_dummy_add + 1;  -- update 210126 
                                                                end if;
                                                            else
                                                                state_gate      <= s_OE;
                                                            end if;
                                                            state_cpv       <= x"0";
                                                        end if;

                                        when others => 
                                                        NULL;
                                    end case;

                when s_OE       =>  
--                                            sgate_oe        <= '1'; --# 230925 # 3x3binn 0 test
--                                    if(sgate_cnt >= sreg_gate_oe - 1) then --# 240104
                                    if(sgate_cnt >= sreg_gate_oe(14 downto 0) - 1) then
                                        state_gate      <= s_CHECK;
                                        sgate_cnt       <= (others => '0');

                                        if(sgate_oe_cnt = sgate_oe_num - 1) then 
                                            sgate_oe        <= '0';
                                            sgate_oe_end    <= '1';
                                        else
                                            sgate_oe_end    <= '0';
                                        end if;
                                    else
                                        sgate_cnt       <= sgate_cnt + '1';
                                    end if;

                when s_XON      =>  -- XON
                                    if(sgate_cnt >= sreg_gate_xon - sreg_gate_xon_flk) then
                                        state_gate      <= s_XON_FLK;
                                        sgate_flk       <= '1';
                                    end if;

                                    sgate_cnt       <= sgate_cnt + '1';

                when s_XON_FLK  =>  -- XON and FLK
                                    if(sgate_cnt >= sreg_gate_xon) then
                                        state_gate      <= s_FLK;
                                        sgate_xon       <= '1';
                                    end if;

                                    sgate_cnt       <= sgate_cnt + '1';

                when s_FLK      =>  -- FLK
                                    if(sgate_cnt >= sreg_gate_xon + sreg_gate_flk) then
                                        state_gate      <= s_CHECK;
                                        sgate_cnt       <= (others => '0');
                                        sgate_flk       <= '0';
                                    else
                                        sgate_cnt       <= sgate_cnt + '1';
                                    end if;

                when s_CHECK    =>  
                                    if((state_tft = s_SCAN or state_tft = s_SRST) and (sgate_line_cnt >= sreg_height - ROIC_DUAL_BY_MODEL(GNR_MODEL) and sgate_oe_cnt = sgate_oe_num - 1)) then
                                        if(sgate_ch_cnt = GATE_MAX_CH(GNR_MODEL) - 1) then
                                            state_gate          <= s_FWAIT;
                                            sgate_oe_cnt    <= (others => '0'); --* v0.00.03  -- update 210126 
                                        else
                                            state_gate          <= s_LWAIT;

                                            sgate_end           <= '1';
                                            sgate_dummy_en      <= '1';
                                            sgate_dummy_num     <= GATE_MAX_CH(GNR_MODEL) - sgate_ch_cnt - 1;
                                        end if;
                                    elsif(state_tft = s_TRST) then
                                        state_gate          <= s_FWAIT;
                                    else
                                        if(sgate_oe_cnt = sgate_oe_num - 1) then
                                            state_gate      <= s_LWAIT;
                                            sgate_oe_cnt    <= (others => '0');
                                            sgate_line_cnt  <= sgate_line_cnt + ROIC_DUAL_BY_MODEL(GNR_MODEL);
                                        else
                                            state_gate      <= s_OE_READY;
                                            sgate_oe_cnt    <= sgate_oe_cnt + '1';
                                        end if;
                                    end if;

                                  if(sgate_num < (GATE_NUM(GNR_MODEL) / ROIC_DUAL_BY_MODEL(GNR_MODEL)) - 1 and sgate_ch_cnt >= GATE_CH(GNR_MODEL) - sgate_dummy_add - 1) then  -- update 210126 
--                                    if(sgate_num < (GATE_NUM(GNR_MODEL) / ROIC_DUAL_BY_MODEL(GNR_MODEL)) - 1 and sgate_ch_cnt >= GATE_MAX_CH(GNR_MODEL) - sgate_dummy_add - 1) then  -- update 230515 
                                        sgate_ch_cnt    <= 0;
                                        sgate_num       <= sgate_num + 1;
                                    else
                                        sgate_ch_cnt    <= sgate_ch_cnt + sgate_dummy_add + 1;  -- update 210126 
                                    end if;

                when s_OE_READY =>   
                                    if(sgate_ch_cnt = 0) then
                                        state_gate          <= s_DIO_CPV;
                                        sgate_dio(sgate_num)<= '1';
                                    else
                                        state_gate          <= s_CPV;
                                        sgate_cpv           <= '1';
                                    end if;
                                    sgate_oe            <= '1';

                when s_LWAIT    =>   
                                    if(state_roic = s_DUMMY) then
                                        if(sgate_dummy_en = '1') then
                                            state_gate      <= s_CPV;
                                        else
                                            state_gate      <= s_READY;
                                        end if;
                                    end if;

                when s_FWAIT    =>  -- WAIT UNTIL ALL OF TFT OPERATION IS FINISHED
                                    if(state_tft = s_IDLE) then
                                        state_gate      <= s_IDLE;
                                    end if;

                                    sgate_dummy_en      <= '0';
                                    sgate_line_cnt      <= (others => '0');
                                    sgate_ch_cnt        <= 0;
                                    sgate_num           <= 0;
                                    sgate_oe            <= '0';

                when s_GRST_G   =>  
                                    -- ####################
                                    -- ### counter & sm ###
                                    if sGrstHCnt < vio_GrstHLim then
                                        sGrstHCnt <= sGrstHCnt + '1';
                                    else
                                        sGrstHCnt <= (others => '0');
                                        if sGrstVCnt < vio_GrstVLim + 2 then -- # margin
                                            sGrstVCnt <= sGrstVCnt + '1';
                                        else
                                            sGrstVCnt  <= (others => '0');
                                            state_gate <= s_GRST_Gend;
                                        end if;
                                    end if;
                                    -- ####################

                                    -- ############## 
                                    -- ### signal ###
                                    if  sGrstVCnt = 0 and  
                                        vio_dioRise < sGrstHCnt and sGrstHCnt <= vio_dioFall then
                                        sgate_dio   <= (others => '1');
                                    else
                                        sgate_dio   <= (others => '0');
                                    end if;

                                    if  sGrstVCnt = 0 then -- first gate time, no cpv 
                                        sgate_cpv   <= '0';
                                    elsif   vio_cpvRise < sGrstHCnt and sGrstHCnt <= vio_cpvFall then
                                        sgate_cpv   <= '1';
                                    else
                                        sgate_cpv   <= '0';
                                    end if;

                                    if  vio_oeRise < sGrstHCnt and sGrstHCnt <= vio_oeFall then
                                        sgate_oe    <= '1';
                                    else
                                        sgate_oe    <= '0';
                                    end if;
                                    -- ##############

                when s_GRST_Gend    =>  
                                    state_gate <= s_IDLE;
                                    sGrstHCnt  <= (others => '0');
                                    sGrstVCnt  <= (others => '0');
                                    sgate_dio  <= (others => '0');
                                    sgate_cpv  <= '0';
                                    sgate_oe   <= '0';
                                         
                when others     =>
                                    NULL;
            end case;

            -- d2m roic_sync ctrl cnt
            if state_gate = s_XON or 
               state_gate = s_XON_FLK or 
               state_gate = s_FLK then
                if sxon_cnt <= vio_XonCntLimt then
                    sxon_cnt <= sxon_cnt + '1';
                else
                    sxon_cnt <= (others=> '0');
                end if;
            else
                sxon_cnt <= (others=> '0');
            end if;

        --
        end if;
    end process;

    process(imain_clk, imain_rstn)
    begin
        if(imain_rstn = '0') then
            sreg_grab_en            <= '0';
        sreg_gate_en            <= '0';
        sreg_gate_reverse       <= '0';
        sreg_gate_roe           <= '0';
        sreg_img_mode           <= (others => '0');
        sreg_rst_mode           <= (others => '0');
        sreg_rst_num            <= (others => '0');
        sreg_shutter            <= '0';
        sreg_trig_mode          <= (others => '0');
        sreg_trig_valid         <= '0';
        
        sreg_roic_cds1          <= (others => '0');
        sreg_roic_cds2          <= (others => '0');
        sreg_roic_intrst        <= (others => '0');
        sreg_gate_oe            <= (others => '0');
        sreg_gate_xon           <= (others => '0');
        sreg_gate_xon_flk       <= (others => '0');
        sreg_gate_flk           <= (others => '0');
        sreg_gate_rst_cycle     <= (others => '0');
        
        sreg_frame_num          <= (others => '0');
        sreg_frame_val          <= (others => '0');
        
        sreg_sexp_time          <= (others => '0');
        sreg_exp_time           <= (others => '0');
        sreg_frame_time         <= (others => '0');
        
        sreg_offsety            <= (others => '0');
        sreg_height             <= (others => '0');
        elsif(imain_clk'event and imain_clk = '1') then
            sreg_grab_en            <= sreg_grab_en_3d;

        if(state_tft = s_IDLE) then
            sreg_gate_en            <= sreg_gate_en_3d(0); --# 1bit map, reg_gate_en 1bit -> 8bit 240122  
            sreg_gate_reverse       <= sreg_gate_en_3d(1); --# new 240122  
            sreg_gate_roe           <= sreg_gate_en_3d(2); --# new 240122  
            sreg_img_mode           <= sreg_img_mode_3d; 
            sreg_rst_mode           <= sreg_rst_mode_3d;
            sreg_rst_num            <= sreg_rst_num_3d;
            sreg_shutter            <= sreg_shutter_3d;
            sreg_trig_mode          <= sreg_trig_mode_3d;
            sreg_trig_valid         <= sreg_trig_valid_3d;

            sreg_roic_cds1          <= sreg_roic_cds1_3d;
            sreg_roic_cds2          <= sreg_roic_cds2_3d;
            sreg_roic_intrst        <= sreg_roic_intrst_3d;

            sreg_gate_oe            <= sreg_gate_oe_3d;
            sreg_gate_xon           <= sreg_gate_xon_3d;
            sreg_gate_xon_flk       <= sreg_gate_xon_flk_3d;
            sreg_gate_flk           <= sreg_gate_flk_3d;
            sreg_gate_rst_cycle     <= sreg_gate_rst_cycle_3d;


            sreg_sexp_time          <= sreg_sexp_time_3d; 
            sreg_exp_time           <= sreg_exp_time_3d; 
            sreg_frame_time         <= sreg_frame_time_3d;

            sreg_offsety            <= sreg_offsety_3d;
            sreg_height             <= sreg_height_3d;

            sreg_d2m_sexp_time      <= sreg_d2m_sexp_time_3d; 
            sreg_d2m_frame_time     <= sreg_d2m_frame_time_3d;  
            sreg_d2m_xrst_num       <= sreg_d2m_xrst_num_3d;
            sreg_d2m_drst_num       <= sreg_d2m_drst_num_3d;

            sreg_ExtTrigEn <= sreg_ExtTrigEn_d3;
              sreg_ExtRst_Mode    <= sreg_ExtRst_Mode_3d;  
              sreg_ExtRst_DetTime <= sreg_ExtRst_DetTime_3d;

        end if;

            sreg_frame_num          <= sreg_frame_num_3d; -- 211216
            sreg_frame_val          <= sreg_frame_val_3d;

            sreg_d2m_en             <= sreg_d2m_en_d3;
            sreg_d2m_exp_in         <= sreg_d2m_exp_in_d3 or sext_trig; -- # d2m trig by ( reg or external trig)
            sreg_req_align          <= sreg_req_align_3d;
        --
        end if;
    end process;

    --# assign 220511 --# rollback 220603
--    process(state_tft)
--    begin
--        if(state_tft = s_IDLE) then
--            sreg_gate_en      <= sreg_gate_en_3d; 
--            sreg_img_mode     <= sreg_img_mode_3d; 
--            sreg_rst_mode     <= sreg_rst_mode_3d;
--            sreg_rst_num      <= sreg_rst_num_3d;
--            sreg_shutter      <= sreg_shutter_3d;
--            sreg_trig_mode        <= sreg_trig_mode_3d;
--            sreg_trig_valid       <= sreg_trig_valid_3d;

--            sreg_roic_cds1        <= sreg_roic_cds1_3d;
--            sreg_roic_cds2        <= sreg_roic_cds2_3d;
--            sreg_roic_intrst  <= sreg_roic_intrst_3d;

--            sreg_gate_oe      <= sreg_gate_oe_3d;
--            sreg_gate_xon     <= sreg_gate_xon_3d;
--            sreg_gate_xon_flk <= sreg_gate_xon_flk_3d;
--            sreg_gate_flk     <= sreg_gate_flk_3d;
--            sreg_gate_rst_cycle   <= sreg_gate_rst_cycle_3d;


--            sreg_sexp_time        <= sreg_sexp_time_3d; 
--            sreg_exp_time     <= sreg_exp_time_3d; 
--            sreg_frame_time       <= sreg_frame_time_3d;

--            sreg_offsety      <= sreg_offsety_3d;
--            sreg_height           <= sreg_height_3d;

--            sreg_d2m_sexp_time    <= sreg_d2m_sexp_time_3d; 
--            sreg_d2m_frame_time   <= sreg_d2m_frame_time_3d;  
--            sreg_d2m_xrst_num <= sreg_d2m_xrst_num_3d;
--            sreg_d2m_drst_num <= sreg_d2m_drst_num_3d;

--            sreg_ExtTrigEn      <= sreg_ExtTrigEn_d3;
--            sreg_ExtRst_Mode    <= sreg_ExtRst_Mode_3d;  
--            sreg_ExtRst_DetTime <= sreg_ExtRst_DetTime_3d;
--        end if;
--    end process;

    oroic_dvalid        <= sroic_dvalid;
                     
--    sroic_sync_s0       <=  sTpSelForceSync when sTpSelForce = '1' else -- sTpSelForce is triggered when tpsel is changed. 210812mbh
    sroic_sync_s0       <=  '1' when sTpSelForce = '1' else -- sTpSelForce is triggered when tpsel is changed. 210812mbh
                            '1' when vio_xonflk_oe(3) = '1' and -- almost drive 'high' during TotalReset : d2m mbh210714
                                    sreg_d2m_en = '1'      and
                                    (state_gate = s_XON or state_gate = s_XON_FLK or  state_gate = s_FLK) else 
                           '1' when state_gate = s_GRST_G and sGrstHCnt = 1 and sreg_d2m_en = '1' else -- GRst drive : d2m test 210714 mbh 
                           '1' when sxon_cnt = 1 and sreg_d2m_en = '1' else                            -- frequently drive by xon_cnt : d2m mbh210708
                           '1' when state_gate = s_XON and sgate_cnt = 1 and sreg_d2m_en = '1' else    -- once high at start of TReset 210708 mbh 
                           sroic_sync   when state_tft = s_SCAN or 
--                                          (state_tft = s_SRST and sreg_ExtTrigEn = '1') else '0'; -- s_SRST for serial reset need save data 211020 mbh
                                            (state_tft = s_SRST) else '0';  -- srst use sync
    oroic_sync <= sroic_sync_s0; --# not this point, code rollback 220728
    --# 220728 roic sync test
--  process(imain_clk)
--  begin
--        if(imain_clk'event and imain_clk = '1') then                                          
--         sroic_sync_rise <= sroic_sync_s0;
--      end if;
--  end process;
--  process(imain_clk)
--  begin
--        if(imain_clk'event and imain_clk = '0') then                                          
--         sroic_sync_fall <= sroic_sync_s0;
--      end if;
--  end process;
--  oroic_sync <= sroic_sync_rise when vio_syncEdgeSel='0' else
--                sroic_sync_fall;
                       
    
    oroic_tp_sel        <=  --# 231025 no use // sTpSelForceTp when sTpSelForce = '1' else
                            sroic_tp_sel;

    dio_rev_gen : for i in 0 to GATE_NUM(GNR_MODEL)-1 generate
        sgate_dio_rev(GATE_NUM(GNR_MODEL)-1-i)  <= sgate_dio(i);
        -- sgate_dio_rev(GATE_NUM(GNR_MODEL)-1-i)       <= sgate_dio(i) when vio_dioctrl(i) = '0' else '0';
    end generate;

-- %gateout
    sgate_dio_conv      <= sgate_dio_rev    when ROIC_DUAL_BY_MODEL(GNR_MODEL) = 1 else
                           sgate_dio_rev or sgate_dio;  
                           
    ogate_cpv           <= sgate_cpv        when sreg_gate_en = '1'     else '0';   
--  ogate_dio1          <= sgate_dio_conv   when sreg_gate_en = '1'     else (others => '0');
--  ogate_dio2          <= sgate_dio_conv   when sreg_gate_en = '1'     else (others => '0');   
    ogate_dio1          <= sgate_dio_conv   when (sreg_gate_en = '1' and sgate_end = '0')   else (others => '0');
    ogate_dio2          <= sgate_dio_conv   when (sreg_gate_en = '1' and sgate_end = '0')   else (others => '0');
    
--    ogate_oe1           <= sgate_oe         when sreg_gate_en = '1'     else '0';   
--    ogate_oe2           <= sgate_oe         when sreg_gate_en = '1'     else '0';   --# critical #230925
    ogate_oe1           <= --# '1'              when state_roic=s_INTRST else --# 240105 test
                           sgate_oe         when sreg_gate_en = '1' and sreg_gate_oe(15)='0'  else  --# 240105 test 
                       not sgate_oe         when sreg_gate_en = '1' and sreg_gate_oe(15)='1'  else --# 240104
                           '0';   
    ogate_oe2           <= --# '1'              when state_roic=s_INTRST else --# 240105 test
                           sgate_oe         when sreg_gate_en = '1' and sreg_gate_oe(15)='0'  else
                       not sgate_oe         when sreg_gate_en = '1' and sreg_gate_oe(15)='1'  else  --# 240104 
                           '0';   --# critical #230925
                        
    
    ogate_xon           <= sgate_xon        when sreg_gate_en = '1'     else '1';   
    ogate_flk           <= sgate_flk        when sreg_gate_en = '1'     else '0';


    stft_busy           <= '0' when state_tft = s_TRST or 
                                    state_tft = s_SRST or
                                    ((state_roic = s_FWAIT or state_roic = s_IDLE) and 
                                     (state_gate = s_FWAIT or state_gate = s_IDLE)) else
                           '1';

    ograb_done          <= sgrab_done;

    otft_busy           <= stft_busy;
    oext_trig           <= '0' when sreg_trig_valid = '0' else sext_trig_out;

    -- test point
     ostate_grab        <= state_grab   ;   
     ostate_tft         <= s_Trig   when sm_grab_trig = '1' else --# 230707
                           state_tft;   
     ostate_roic        <= state_roic   ;       
     ostate_gate        <= state_gate   ;       

    process(imain_clk, imain_rstn)
    begin
        if(imain_rstn = '0') then
            sreg_grab_en_1d         <= '0';
            sreg_grab_en_2d         <= '0';
            sreg_grab_en_3d         <= '0';
            sreg_gate_en_1d         <= (others => '0');
            sreg_gate_en_2d         <= (others => '0');
            sreg_gate_en_3d         <= (others => '0');
            sreg_img_mode_1d        <= (others => '0');
            sreg_img_mode_2d        <= (others => '0');
            sreg_img_mode_3d        <= (others => '0');
            sreg_rst_mode_1d        <= (others => '0');
            sreg_rst_mode_2d        <= (others => '0');
            sreg_rst_mode_3d        <= (others => '0');
            sreg_rst_num_1d         <= (others => '0');
            sreg_rst_num_2d         <= (others => '0');
            sreg_rst_num_3d         <= (others => '0');
            sreg_shutter_1d         <= '0';
            sreg_shutter_2d         <= '0';
            sreg_shutter_3d         <= '0';
            sreg_trig_mode_1d       <= (others => '0');
            sreg_trig_mode_2d       <= (others => '0');
            sreg_trig_mode_3d       <= (others => '0');
            sreg_trig_valid_1d      <= '0';
            sreg_trig_valid_2d      <= '0';
            sreg_trig_valid_3d      <= '0';
            sreg_roic_tp_sel_1d     <= '0';
            sreg_roic_tp_sel_2d     <= '0';
            sreg_roic_tp_sel_3d     <= '0';
            sreg_roic_cds1_1d       <= (others => '0');
            sreg_roic_cds1_2d       <= (others => '0');
            sreg_roic_cds1_3d       <= (others => '0');
            sreg_roic_cds2_1d       <= (others => '0');
            sreg_roic_cds2_2d       <= (others => '0');
            sreg_roic_cds2_3d       <= (others => '0');
            sreg_roic_intrst_1d     <= (others => '0');
            sreg_roic_intrst_2d     <= (others => '0');
            sreg_roic_intrst_3d     <= (others => '0');
            sreg_gate_oe_1d         <= (others => '0');
            sreg_gate_oe_2d         <= (others => '0');
            sreg_gate_oe_3d         <= (others => '0');
            sreg_gate_xon_1d        <= (others => '0');
            sreg_gate_xon_2d        <= (others => '0');
            sreg_gate_xon_3d        <= (others => '0');
            sreg_gate_xon_flk_1d    <= (others => '0');
            sreg_gate_xon_flk_2d    <= (others => '0');
            sreg_gate_xon_flk_3d    <= (others => '0');
            sreg_gate_flk_1d        <= (others => '0');
            sreg_gate_flk_2d        <= (others => '0');
            sreg_gate_flk_3d        <= (others => '0');
            sreg_gate_rst_cycle_1d  <= (others => '0');
            sreg_gate_rst_cycle_2d  <= (others => '0');
            sreg_gate_rst_cycle_3d  <= (others => '0');
            sreg_frame_num_1d       <= (others => '0');
            sreg_frame_num_2d       <= (others => '0');
            sreg_frame_num_3d       <= (others => '0');
            sreg_frame_val_1d       <= (others => '0');
            sreg_frame_val_2d       <= (others => '0');
            sreg_frame_val_3d       <= (others => '0');
            sreg_sexp_time_1d       <= (others => '0');
            sreg_sexp_time_2d       <= (others => '0');
            sreg_sexp_time_3d       <= (others => '0');
            sreg_exp_time_1d        <= (others => '0');
            sreg_exp_time_2d        <= (others => '0');
            sreg_exp_time_3d        <= (others => '0');
            sreg_frame_time_1d      <= (others => '0');
            sreg_frame_time_2d      <= (others => '0');
            sreg_frame_time_3d      <= (others => '0');
            sreg_offsety_1d         <= (others => '0');
            sreg_offsety_2d         <= (others => '0');
            sreg_offsety_3d         <= (others => '0');
            sreg_height_1d          <= (others => '0');
            sreg_height_2d          <= (others => '0');
            sreg_height_3d          <= (others => '0');
            sroic_cnt_1d            <= (others => '0');
            sext_trig_1d            <= '0';

            sreg_timing_mode_1d     <= (others => '0');
            sreg_timing_mode_2d     <= (others => '0');
            sreg_timing_mode_3d     <= (others => '0');
        elsif(imain_clk'event and imain_clk = '1') then
            sreg_grab_en_1d         <= ireg_grab_en;
            sreg_grab_en_2d         <= sreg_grab_en_1d;
            sreg_grab_en_3d         <= sreg_grab_en_2d;
            sreg_gate_en_1d         <= ireg_gate_en;
            sreg_gate_en_2d         <= sreg_gate_en_1d;
            sreg_gate_en_3d         <= sreg_gate_en_2d;
            sreg_img_mode_1d        <= ireg_img_mode;
            sreg_img_mode_2d        <= sreg_img_mode_1d;
            sreg_img_mode_3d        <= sreg_img_mode_2d;
            sreg_rst_mode_1d        <= ireg_rst_mode;
            sreg_rst_mode_2d        <= sreg_rst_mode_1d;
            sreg_rst_mode_3d        <= sreg_rst_mode_2d;
            sreg_rst_num_1d         <= ireg_rst_num;
            sreg_rst_num_2d         <= sreg_rst_num_1d;
            sreg_rst_num_3d         <= sreg_rst_num_2d;
            sreg_shutter_1d         <= ireg_shutter;
            sreg_shutter_2d         <= sreg_shutter_1d;
            sreg_shutter_3d         <= sreg_shutter_2d;
            sreg_trig_mode_1d       <= ireg_trig_mode;
            sreg_trig_mode_2d       <= sreg_trig_mode_1d;
            sreg_trig_mode_3d       <= sreg_trig_mode_2d;
            sreg_trig_valid_1d      <= ireg_trig_valid;
            sreg_trig_valid_2d      <= sreg_trig_valid_1d;
            sreg_trig_valid_3d      <= sreg_trig_valid_2d;
            sreg_roic_tp_sel_1d     <= ireg_roic_tp_sel;
            sreg_roic_tp_sel_2d     <= sreg_roic_tp_sel_1d;
            sreg_roic_tp_sel_3d     <= sreg_roic_tp_sel_2d;
            sreg_roic_cds1_1d       <= ireg_roic_cds1;
            sreg_roic_cds1_2d       <= sreg_roic_cds1_1d;
            sreg_roic_cds1_3d       <= sreg_roic_cds1_2d;
            sreg_roic_cds2_1d       <= ireg_roic_cds2;
            sreg_roic_cds2_2d       <= sreg_roic_cds2_1d;
            sreg_roic_cds2_3d       <= sreg_roic_cds2_2d;
            sreg_roic_intrst_1d     <= ireg_roic_intrst;
            sreg_roic_intrst_2d     <= sreg_roic_intrst_1d;
            sreg_roic_intrst_3d     <= sreg_roic_intrst_2d;
            sreg_gate_oe_1d         <= ireg_gate_oe;
            sreg_gate_oe_2d         <= sreg_gate_oe_1d;
            sreg_gate_oe_3d         <= sreg_gate_oe_2d;
            sreg_gate_xon_1d        <= ireg_gate_xon;
            sreg_gate_xon_2d        <= sreg_gate_xon_1d;
            sreg_gate_xon_3d        <= sreg_gate_xon_2d;
            sreg_gate_xon_flk_1d    <= ireg_gate_xon_flk;
            sreg_gate_xon_flk_2d    <= sreg_gate_xon_flk_1d;
            sreg_gate_xon_flk_3d    <= sreg_gate_xon_flk_2d;
            sreg_gate_flk_1d        <= ireg_gate_flk;
            sreg_gate_flk_2d        <= sreg_gate_flk_1d;
            sreg_gate_flk_3d        <= sreg_gate_flk_2d;
            sreg_gate_rst_cycle_1d  <= ireg_gate_rst_cycle;
            sreg_gate_rst_cycle_2d  <= sreg_gate_rst_cycle_1d;
            sreg_gate_rst_cycle_3d  <= sreg_gate_rst_cycle_2d;
            sreg_frame_num_1d       <= ireg_frame_num;
            sreg_frame_num_2d       <= sreg_frame_num_1d;
            sreg_frame_num_3d       <= sreg_frame_num_2d;
            sreg_frame_val_1d       <= ireg_frame_val;
            sreg_frame_val_2d       <= sreg_frame_val_1d;
            sreg_frame_val_3d       <= sreg_frame_val_2d;
            sreg_sexp_time_1d       <= ireg_sexp_time;
            sreg_sexp_time_2d       <= sreg_sexp_time_1d;
            sreg_sexp_time_3d       <= sreg_sexp_time_2d;
            sreg_exp_time_1d        <= ireg_exp_time;
            sreg_exp_time_2d        <= sreg_exp_time_1d;
            sreg_exp_time_3d        <= sreg_exp_time_2d;
            sreg_frame_time_1d      <= ireg_frame_time; 
            sreg_frame_time_2d      <= sreg_frame_time_1d;
            sreg_frame_time_3d      <= sreg_frame_time_2d;
            sreg_offsety_1d         <= ireg_offsety;
            sreg_offsety_2d         <= sreg_offsety_1d;
            sreg_offsety_3d         <= sreg_offsety_2d;
            sreg_height_1d          <= ireg_height;
            sreg_height_2d          <= sreg_height_1d;
            sreg_height_3d          <= sreg_height_2d;
            sroic_cnt_1d            <= sroic_cnt;
            sext_trig_1d            <= iext_trig;
            sext_trig_2d            <= sext_trig_1d;
            sext_trig_3d            <= sext_trig_2d;
            -- sext_trig                <= sext_trig_3d;
            if sext_trig_3d = '1' then -- ext. trigger in debounce/limitation 211019 mbh
                if SIMULATION="ON" then
                    if sExtTrigCnt < EXT_TRIG_DEBO_PERIOD_SIM(GNR_MODEL) then
                        sExtTrigCnt <= sExtTrigCnt + '1';
                    end if;
                else
                    if sExtTrigCnt < EXT_TRIG_DEBO_PERIOD(GNR_MODEL) then
                        sExtTrigCnt <= sExtTrigCnt + '1';
                    end if;
                end if;
            else
                sExtTrigCnt <= (others=> '0');
            end if;

            if SIMULATION="ON" then
                if sExtTrigCnt >= EXT_TRIG_DEBO_PERIOD_SIM(GNR_MODEL) then
                    sext_trig <= '1';
                else
                    sext_trig <= '0';
                end if;
            else
                if sExtTrigCnt >= EXT_TRIG_DEBO_PERIOD(GNR_MODEL) then
                    sext_trig <= '1';
                else
                    sext_trig <= '0';
                end if;
            end if;
            sext_trig1              <= sext_trig;

            sreg_timing_mode_1d     <= sreg_timing_mode     ;   
            sreg_timing_mode_2d     <= sreg_timing_mode_1d  ;   
            sreg_timing_mode_3d     <= sreg_timing_mode_2d  ;   

            sreg_d2m_en_d1 <= ireg_d2m_en;
            sreg_d2m_en_d2 <= sreg_d2m_en_d1;
            sreg_d2m_en_d3 <= sreg_d2m_en_d2;

            sreg_d2m_exp_in_d1 <= ireg_d2m_exp_in;
            sreg_d2m_exp_in_d2 <= sreg_d2m_exp_in_d1;
            sreg_d2m_exp_in_d3 <= sreg_d2m_exp_in_d2;

            sreg_d2m_sexp_time_1d <= ireg_d2m_sexp_time; 
            sreg_d2m_sexp_time_2d <= sreg_d2m_sexp_time_1d; 
            sreg_d2m_sexp_time_3d <= sreg_d2m_sexp_time_2d; 

            sreg_d2m_frame_time_1d <= ireg_d2m_frame_time;  
            sreg_d2m_frame_time_2d <= sreg_d2m_frame_time_1d;  
            sreg_d2m_frame_time_3d <= sreg_d2m_frame_time_2d;  

            sreg_d2m_xrst_num_1d <= ireg_d2m_xrst_num;  
            sreg_d2m_xrst_num_2d <= sreg_d2m_xrst_num_1d;  
            sreg_d2m_xrst_num_3d <= sreg_d2m_xrst_num_2d;  

            sreg_d2m_drst_num_1d <= ireg_d2m_drst_num;  
            sreg_d2m_drst_num_2d <= sreg_d2m_drst_num_1d;  
            sreg_d2m_drst_num_3d <= sreg_d2m_drst_num_2d;  

            sreg_ExtTrigEn_d1 <= ireg_ExtTrigEn;
            sreg_ExtTrigEn_d2 <= sreg_ExtTrigEn_d1;
            sreg_ExtTrigEn_d3 <= sreg_ExtTrigEn_d2;

            sreg_ExtRst_Mode_1d <= ireg_ExtRst_Mode;
            sreg_ExtRst_Mode_2d <= sreg_ExtRst_Mode_1d;
            sreg_ExtRst_Mode_3d <= sreg_ExtRst_Mode_2d;

            sreg_ExtRst_DetTime_1d <= ireg_ExtRst_DetTime;
            sreg_ExtRst_DetTime_2d <= sreg_ExtRst_DetTime_1d;
            sreg_ExtRst_DetTime_3d <= sreg_ExtRst_DetTime_2d;

            sreg_req_align_1d <= ireg_req_align;
            sreg_req_align_2d <= sreg_req_align_1d;
            sreg_req_align_3d <= sreg_req_align_2d;
        end if;
    end process;


    ILA_DEBUG : if(GEN_ILA_tft_ctrl = "ON") generate
        component ILA_TFT_CTRL
        port (
            clk             : in    std_logic                       ; 
            probe0          : in    tstate_grab                     ; --* 2     
            probe1          : in    tstate_tft                      ; --* 3
            probe2          : in    tstate_roic                     ; --* 4
            probe3          : in    tstate_gate                     ; --* 4

            probe4          : in    std_logic                       ; --* 1
            probe5          : in    std_logic                       ; --* 1     
            probe6          : in    std_logic                       ; --* 1
            probe7          : in    std_logic                       ; --* 1
            probe8          : in    std_logic_vector(5 downto 0)    ; --* 6
            probe9          : in    std_logic                       ; --* 1
                                                                     
            probe10         : in    std_logic_vector(11 downto 0)   ; --* 12
            probe11         : in    std_logic_vector(11 downto 0)   ; --* 12     
            probe12         : in    std_logic_vector(5 downto 0) ; -- integer range 0 to 5          ; --* 6 
            probe13         : in    std_logic_vector(7 downto 0)    ; --* 8 
            probe14         : in    type_state_d2m;                   -- 3
            probe15         : in    std_logic;                        --* 1
            probe16         : in    std_logic_vector(16 downto 0)   ; --* 17     
            probe17         : in    std_logic_vector(7 downto 0)    ; --# 8  
            probe18         : in    std_logic_vector(31 downto 0)   ; --# 31     
            probe19         : in    std_logic_vector(31 downto 0)   ; --# 31     
            probe20         : in    std_logic                       ; --# 1  
            probe21         : in    std_logic_vector(11 downto 0)   ;  --# 12
            probe22         : in    std_logic_vector(11 downto 0)   ;  --# 12
            probe23         : in    std_logic_vector(11 downto 0)   ;  --# 12
            probe24         : in    std_logic_vector(2  downto 0)       --$ 3 
        );                                                          
        end component;  

        COMPONENT vio_cpv_period
          PORT (
            clk : IN STD_LOGIC;
            probe_out0 : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
          );
        END COMPONENT;

    -- COMPONENT ila_tft_ctrl_grab
    -- PORT (
    --  clk : IN STD_LOGIC;
    --  probe0 : IN tstate_grab; -- STD_LOGIC_VECTOR(1 DOWNTO 0); 
    --  probe1 : IN tstate_tft ; -- STD_LOGIC_VECTOR(2 DOWNTO 0); 
    --  probe2 : IN tstate_roic; -- STD_LOGIC_VECTOR(3 DOWNTO 0); 
    --  probe3 : IN tstate_gate; -- STD_LOGIC_VECTOR(3 DOWNTO 0); 
    --  probe4 : IN STD_LOGIC_VECTOR(0 DOWNTO 0); 
    --  probe5 : IN STD_LOGIC_VECTOR(0 DOWNTO 0); 
    --  probe6 : IN STD_LOGIC_VECTOR(0 DOWNTO 0); 
    --  probe7 : IN STD_LOGIC_VECTOR(15 DOWNTO 0); 
    --  probe8 : IN STD_LOGIC_VECTOR(15 DOWNTO 0); 
    --  probe9 : IN STD_LOGIC_VECTOR(0 DOWNTO 0); 
    --  probe10 : IN STD_LOGIC_VECTOR(1 DOWNTO 0); 
    --  probe11 : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    --  probe12 : IN STD_LOGIC_VECTOR(1 DOWNTO 0)
    -- );
    -- END COMPONENT  ;
signal probe8_pm  : STD_LOGIC_VECTOR(6-1 DOWNTO 0);
signal probe12_pm : STD_LOGIC_VECTOR(6-1 DOWNTO 0);
signal probe22_pm : STD_LOGIC_VECTOR(12-1 DOWNTO 0);
signal probe23_pm : STD_LOGIC_VECTOR(12-1 DOWNTO 0);
    begin
 
 probe8_pm  <= "00" & sgate_dio_conv(3 downto 0); --# compile error due to GNR_MODEL no conn
-- probe8_pm  <= b"0_0000" & sgate_dio_conv(0); --# compile error
 probe12_pm <= conv_std_logic_vector(sgate_num,6);
 probe22_pm <=  conv_std_logic_vector(sgate_dummy_num,12);
 probe23_pm <= conv_std_logic_vector(sgate_ch_cnt,12);
 
        U_ILA_TFT_CTRL : ILA_TFT_CTRL
        port map (
            clk     => imain_clk        ,   --*         

            probe0  => state_grab       ,   --* 2
            probe1  => state_tft        ,   --* 3
            probe2  => state_roic       ,   --* 4
            probe3  => state_gate       ,   --* 4

            probe4  => sroic_sync_s0    ,   --* 1
            probe5  => sroic_tp_sel     ,   --* 1
            probe6  => sroic_dvalid     ,   --* 1
            probe7  => sgate_cpv        ,   --* 1
            probe8  => probe8_pm, -- "00" & sgate_dio_conv(3 downto 0)   ,    --* 6
--          probe8  => b"0_0000" & sgate_dio_conv(0)   ,    --* 6
--            probe8  => sgate_dio_conv(5 downto 0),   --* 6
            probe9  => sgate_oe         ,   --* 1

            probe10 => sgate_line_cnt   ,   --* 12    
            probe11 => sroic_line_cnt   ,   --* 12      
            probe12 => probe12_pm , -- conv_std_logic_vector(sgate_num,6),  --* 6   
            probe13 => sroic_cnt,           --* 8   
            probe14 => state_d2m,           --* 3   
            probe15 => sreg_d2m_exp_in_lat, --* 1   
            probe16 => sframe_cnt         , --* 17  

            probe17 => sreg_ExtRst_Mode     ,   --# 8    
            probe18 => sreg_ExtRst_DetTime  ,   --# 31 
            probe19 => sExt_TimeRstCnt      ,   --# 31 
            probe20 => sExt_TimeRst         , --# 1    

            probe21 => sgate_dummy_cnt      , --# 12
            probe22 => probe22_pm, -- conv_std_logic_vector(sgate_dummy_num,12), --# 12
            probe23 => probe23_pm,  -- conv_std_logic_vector(sgate_ch_cnt,12) --# 12
            probe24 => sreg_img_mode --$ 3
        );

--        u_vio_cpv_period : vio_cpv_period
--        PORT MAP (
--            clk => imain_clk,
--            probe_out0 => vioo_cpv_period
--        );
    -- u_ila_tft_ctrl_grab : ila_tft_ctrl_grab
    -- PORT MAP (
    --  clk         => imain_clk       ,  --           
    --  probe0      => state_grab      ,  -- 2         
    --  probe1      => state_tft       ,  -- 3         
    --  probe2      => state_roic      ,  -- 4         
    --  probe3      => state_gate      ,  -- 4         
    --  probe4  (0) => sext_trig       ,  -- 1         
    --  probe5  (0) => sreg_grab_en    ,  -- 1         
    --  probe6  (0) => sgrab_en_tmp    ,  -- 1         
    --  probe7      => sExtTrigCnt  ,  -- 16   00     
    --  probe8      => sframe_cnt(15 downto 0),  -- 16        
    --  probe9  (0) => sgrab_en        ,  -- 1         
    --  probe10     => sreg_trig_mode  ,  -- 2         
    --  probe11 (0) => sext_trig_3d    ,  -- 1 00         
    --  probe12     => sreg_rst_mode      -- 2         
    -- );

    end generate;
    
    ILA_DEBUG2 : if(GEN_ILA_gate_ctrl = "ON") generate
        component ILA_GATE_CTRL 
        port (
            clk     : in std_logic;
            
            probe0  : in tstate_grab;
            probe1  : in tstate_tft;
            probe2  : in tstate_roic;
            probe3  : in tstate_gate;
            
            probe4  : in std_logic_vector( 3 downto 0);
            probe5  : in std_logic_vector( 0 downto 0);
            probe6  : in std_logic_vector(11 downto 0);
            probe7  : in std_logic_vector(31 downto 0);
            probe8  : in std_logic_vector( 0 downto 0);
            probe9  : in std_logic_vector( 5 downto 0); --$ if you wanst to this ILA, you have to setting probe9 size.
            probe10 : in std_logic_vector( 0 downto 0);  
            probe11 : in std_logic_vector( 0 downto 0);
            probe12 : in std_logic_vector( 0 downto 0);
            probe13 : in std_logic_vector( 0 downto 0);
            probe14 : in std_logic_vector( 2 downto 0);
            probe15 : in std_logic_vector( 2 downto 0);
            probe16 : in std_logic_vector( 0 downto 0);
            probe17 : in std_logic_vector( 0 downto 0);
            probe18 : in std_logic_vector( 5 downto 0);
            probe19 : in std_logic_vector(11 downto 0);
            probe20 : in std_logic_vector(11 downto 0)
        );
        end component;
    signal probe18_pm : STD_LOGIC_VECTOR(6-1 DOWNTO 0);
    signal probe19_pm : STD_LOGIC_VECTOR(12-1 DOWNTO 0);
 

    begin
    probe18_pm <= conv_std_logic_vector(sgate_num,6);
    probe19_pm <= conv_std_logic_vector(sgate_ch_cnt,12);
        
    U_ILA_GATE_CTRL : ILA_GATE_CTRL
    PORT MAP (
	       clk => imain_clk,


	       probe0     => state_grab,          --$2
	       probe1     => state_tft,           --$3
	       probe2     => state_roic,          --$4
	       probe3     => state_gate,          --$4
	       probe4     => state_cpv,           --$4
	       probe5(0)  => sgrab_en,            --$1 
	       probe6     => sgate_line_cnt,      --$12
	       probe7     => sgate_cnt,           --$32
	       probe8(0)  => sgate_cpv,           --$1
	       probe9     => sgate_dio,           --$?
	       probe10(0) => sgate_dummy_en,      --$1
	       probe11(0) => sgate_oe,            --$1
	       probe12(0) => sgate_oe_end,        --$1
	       probe13(0) => sgate_xon,           --$1
	       probe14    => sreg_img_mode,       --$3
	       probe15    => sgate_oe_cnt,        --$3
	       probe16(0) => sgate_end,           --$1
	       probe17(0) => sgate_flk,           --$1
	       probe18    => probe18_pm,          --$6  sgate_num
	       probe19    => probe19_pm,          --$12 sgate_ch_cnt
	       probe20    => sreg_offsety         --$12
    );
    end generate; 

end Behavioral;

