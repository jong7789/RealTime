library IEEE;
    use IEEE.STD_LOGIC_1164.ALL;
    use IEEE.STD_LOGIC_UNSIGNED.ALL;
    use IEEE.STD_LOGIC_ARITH.ALL;
    use WORK.TOP_HEADER.ALL;

entity IMG_PROC_PARA4 is
    generic ( GNR_MODEL : string  := "EXT1616R" );
    port (
        idata_clk  : in    std_logic;
        idata_rstn : in    std_logic;

        ireg_iproc_mode  : in    std_logic_vector(3 downto 0);
        ireg_bright      : in    std_logic_vector(16 downto 0);
        ireg_contrast    : in    std_logic_vector(15 downto 0);
        ireg_DnrCtrl     : in    std_logic_vector(16 - 1 downto 0);
        ireg_SobelCoeff0 : in    std_logic_vector(16 - 1 downto 0);
        ireg_SobelCoeff1 : in    std_logic_vector(16 - 1 downto 0);
        ireg_SobelCoeff2 : in    std_logic_vector(16 - 1 downto 0);
        ireg_BlurOffset  : in    std_logic_vector(16 - 1 downto 0);

        ireg_width  : in    std_logic_vector(11 downto 0);
        ireg_height : in    std_logic_vector(11 downto 0);
        --# OSD
        isys_clk       : in    std_logic;
        iext_trig_in   : in    std_logic;
        ireg_osd_ctrl  : in    std_logic_vector(16 - 1 downto 0);
        oreg_trigcnt   : out   std_logic_vector(16 - 1 downto 0);
        ireg_sync_rcnt : in    std_logic_vector(32*30 - 1 downto 0);

        ichgdet_osd_en : in std_logic;
        ichgdet_osd_da : in std_logic_vector(16 - 1 downto 0);
        --# edge
        ireg_edge_ctrl   : in  std_logic_vector(16-1 downto 0);
        ireg_edge_value  : in  std_logic_vector(16-1 downto 0);
        ireg_edge_top    : in  std_logic_vector(16-1 downto 0);
        ireg_edge_left   : in  std_logic_vector(16-1 downto 0);
        ireg_edge_right  : in  std_logic_vector(16-1 downto 0);
        ireg_edge_bottom : in  std_logic_vector(16-1 downto 0);

        --# B&C
        ireg_bnc_ctrl    : in  std_logic_vector(16-1 downto 0);
        ireg_bnc_high    : in  std_logic_vector(16-1 downto 0);
        --# EQ
        ireg_EqCtrl      : in std_logic_vector(15 downto 0);
        ireg_EqTopVal    : in std_logic_vector(15 downto 0);

        ihsync : in    std_logic;
        ivsync : in    std_logic;
        ihcnt  : in    std_logic_vector(11 downto 0);
        ivcnt  : in    std_logic_vector(11 downto 0);
        idata  : in    std_logic_vector(16*4-1 downto 0);

        ohsync : out   std_logic;
        ovsync : out   std_logic;
        ohcnt  : out   std_logic_vector(11 downto 0);
        ovcnt  : out   std_logic_vector(11 downto 0);
        odata  : out   std_logic_vector(16*4-1 downto 0)
    );
end entity IMG_PROC_PARA4;

architecture behavioral of IMG_PROC_PARA4 is

--  component MASKING_PROC is
--      port (
--          idata_clk  : in    std_logic;
--          idata_rstn : in    std_logic;
--
--          ireg_iproc_mode : in    std_logic_vector(3 downto 0);
--
--          ireg_width  : in    std_logic_vector(11 downto 0);
--          ireg_height : in    std_logic_vector(11 downto 0);
--
--          ihsync : in    std_logic;
--          ivsync : in    std_logic;
--          ihcnt  : in    std_logic_vector(11 downto 0);
--          ivcnt  : in    std_logic_vector(11 downto 0);
--          idata  : in    std_logic_vector(15 downto 0);
--
--          ohsync : out   std_logic;
--          ovsync : out   std_logic;
--          ohcnt  : out   std_logic_vector(11 downto 0);
--          ovcnt  : out   std_logic_vector(11 downto 0);
--          odata  : out   std_logic_vector(15 downto 0)
--      );
--  end component;
--

    component BritCont_master is
        port (
            i_clk   : in  std_logic;
            i_hsync : in  std_logic;
            i_vsync : in  std_logic;
            i_hcnt  : in  std_logic_vector(12-1 downto 0);
            i_vcnt  : in  std_logic_vector(12-1 downto 0);
            i_data  : in  std_logic_vector(16-1 downto 0);
                  
            i_reg_width    : in  std_logic_vector(12-1 downto 0);
            i_reg_height   : in  std_logic_vector(12-1 downto 0);
            i_reg_BNC_high : in std_logic_vector(16-1 downto 0);

            o_brit  : out std_logic_vector(17-1 downto 0);
            o_cont  : out std_logic_vector(16-1 downto 0)
        );
    end component;

    component BRIGHT_CTRL is
        port (
            idata_clk  : in    std_logic;
            idata_rstn : in    std_logic;
  
            ireg_bright : in    std_logic_vector(16 downto 0);
  
            ihsync : in    std_logic;
            ivsync : in    std_logic;
            ihcnt  : in    std_logic_vector(11 downto 0);
            ivcnt  : in    std_logic_vector(11 downto 0);
            idata  : in    std_logic_vector(15 downto 0);
  
            ohsync : out   std_logic;
            ovsync : out   std_logic;
            ohcnt  : out   std_logic_vector(11 downto 0);
            ovcnt  : out   std_logic_vector(11 downto 0);
            odata  : out   std_logic_vector(15 downto 0)
        );
    end component;
  
    component CONTRAST_CTRL is
        port (
            idata_clk  : in    std_logic;
            idata_rstn : in    std_logic;
  
            ireg_contrast : in    std_logic_vector(15 downto 0);
  
            ihsync : in    std_logic;
            ivsync : in    std_logic;
            ihcnt  : in    std_logic_vector(11 downto 0);
            ivcnt  : in    std_logic_vector(11 downto 0);
            idata  : in    std_logic_vector(15 downto 0);
  
            ohsync : out   std_logic;
            ovsync : out   std_logic;
            ohcnt  : out   std_logic_vector(11 downto 0);
            ovcnt  : out   std_logic_vector(11 downto 0);
            odata  : out   std_logic_vector(15 downto 0)
        );
    end component;

    component EQ_CTRL_1x1_para4 is
        port (
            clk  : in  std_logic;
            rstn : in  std_logic;

            i_regHActive  : in std_logic_vector(12-1 downto 0);
            i_regVActive  : in std_logic_vector(12-1 downto 0);
            i_regEqCtrl   : in std_logic_vector(16-1 downto 0);
            i_regEqTopVal : in std_logic_vector(16-1 downto 0); 
        
            i_hsyn : in  std_logic;
            i_vsyn : in  std_logic;
            i_hcnt : in  std_logic_vector(11 downto 0);
            i_vcnt : in  std_logic_vector(11 downto 0);
            i_data : in  std_logic_vector(63 downto 0);
                   
            o_hsyn : out std_logic;
            o_vsyn : out std_logic;
            o_hcnt : out std_logic_vector(11 downto 0);
            o_vcnt : out std_logic_vector(11 downto 0);
            o_data : out std_logic_vector(63 downto 0)
        );
    end component;
--
--  component DNR is
--      port (
--          i_clk            : in    std_logic;
--          i_RegHActive     : in    std_logic_vector(12 - 1 downto 0);
--          i_RegVActive     : in    std_logic_vector(12 - 1 downto 0);
--          i_regDnrCtrl     : in    std_logic_vector(16 - 1 downto 0);
--          i_regSobelCoeff0 : in    std_logic_vector(16 - 1 downto 0);
--          i_regSobelCoeff1 : in    std_logic_vector(16 - 1 downto 0);
--          i_regSobelCoeff2 : in    std_logic_vector(16 - 1 downto 0);
--          i_regBlurOffset  : in    std_logic_vector(16 - 1 downto 0);
--
--          i_hsyn : in    std_logic;
--          i_vsyn : in    std_logic;
--          i_hcnt : in    std_logic_vector(12 - 1 downto 0);
--          i_vcnt : in    std_logic_vector(12 - 1 downto 0);
--          i_data : in    std_logic_vector(16 - 1 downto 0);
--
--          o_hsyn : out   std_logic;
--          o_vsyn : out   std_logic;
--          o_hcnt : out   std_logic_vector(12 - 1 downto 0);
--          o_vcnt : out   std_logic_vector(12 - 1 downto 0);
--          o_data : out   std_logic_vector(16 - 1 downto 0)
--      );
--  end component dnr;

    component OSD is
        generic ( GNR_MODEL : string  := "EXT1616R" );
        port (
            i_sclk          : in    std_logic;
            i_ext_trig_in   : in    std_logic;
            i_reg_osd_ctrl  : in    std_logic_vector(16 - 1 downto 0);
            o_reg_trigcnt   : out   std_logic_vector(16 - 1 downto 0);
            i_reg_sync_rcnt : in    std_logic_vector(32*30 - 1 downto 0);

            i_chgdet_osd_en : in    std_logic;
            i_chgdet_osd_da : in    std_logic_vector(16 - 1 downto 0);

            i_dclk : in    std_logic;
            i_hsyn : in    std_logic;
            i_vsyn : in    std_logic;
            i_hcnt : in    std_logic_vector(12 - 1 downto 0);
            i_vcnt : in    std_logic_vector(12 - 1 downto 0);
            i_data : in    std_logic_vector(16 - 1 downto 0);

            o_hsyn : out   std_logic;
            o_vsyn : out   std_logic;
            o_hcnt : out   std_logic_vector(12 - 1 downto 0);
            o_vcnt : out   std_logic_vector(12 - 1 downto 0);
            o_data : out   std_logic_vector(16 - 1 downto 0)
        );
    end component osd;

    component EDGE is
    port (
        clk : in std_logic;

        i_reg_width  : in std_logic_vector(11 downto 0);
        i_reg_height : in std_logic_vector(11 downto 0);

        i_reg_edge_ctrl   : in  std_logic_vector(16-1 downto 0);
        i_reg_edge_value  : in  std_logic_vector(16-1 downto 0);
        i_reg_edge_top    : in  std_logic_vector(16-1 downto 0);
        i_reg_edge_left   : in  std_logic_vector(16-1 downto 0);
        i_reg_edge_right  : in  std_logic_vector(16-1 downto 0);
        i_reg_edge_bottom : in  std_logic_vector(16-1 downto 0);

        i_hsyn  : in  std_logic;
        i_vsyn  : in  std_logic;
        i_hcnt  : in  std_logic_vector(12-1 downto 0);
        i_vcnt  : in  std_logic_vector(12-1 downto 0);
        i_data  : in  std_logic_vector(16-1 downto 0);

        o_hsyn  : out std_logic;
        o_vsyn  : out std_logic;
        o_hcnt  : out std_logic_vector(12-1 downto 0);
        o_vcnt  : out std_logic_vector(12-1 downto 0);
        o_data  : out std_logic_vector(16-1 downto 0)
    );
    end component EDGE;

    constant PARA : integer := 4;
    type ty_para_syn  is array (PARA-1 downto 0) of std_logic;
    type ty_para_cnt  is array (PARA-1 downto 0) of std_logic_vector(12-1 downto 0);
    type ty_para_edge is array (PARA-1 downto 0) of std_logic_vector(16-1 downto 0);

    signal shsync_masking  : std_logic;
    signal svsync_masking  : std_logic;
    signal  shcnt_masking  : std_logic_vector(11 downto 0);
    signal  svcnt_masking  : std_logic_vector(11 downto 0);
    signal  sdata_masking  : std_logic_vector(64-1 downto 0);

    signal shsync_bright   : ty_para_syn; --std_logic;
    signal svsync_bright   : ty_para_syn; --std_logic;
    signal  shcnt_bright   : ty_para_cnt; --std_logic_vector(11 downto 0);
    signal  svcnt_bright   : ty_para_cnt; --std_logic_vector(11 downto 0);
    signal  sdata_bright   : std_logic_vector(64-1 downto 0);

    signal shsync_contrast : ty_para_syn; --std_logic;
    signal svsync_contrast : ty_para_syn; --std_logic;
    signal  shcnt_contrast : ty_para_cnt; --std_logic_vector(11 downto 0);
    signal  svcnt_contrast : ty_para_cnt; --std_logic_vector(11 downto 0);
    signal  sdata_contrast : std_logic_vector(64-1 downto 0);

    signal shsync_dnr      : std_logic;
    signal svsync_dnr      : std_logic;
    signal  shcnt_dnr      : std_logic_vector(11 downto 0);
    signal  svcnt_dnr      : std_logic_vector(11 downto 0);
    signal  sdata_dnr      : std_logic_vector(64-1 downto 0);

    signal shsync_eq       : std_logic;
    signal svsync_eq       : std_logic;
    signal  shcnt_eq       : std_logic_vector(11 downto 0);
    signal  svcnt_eq       : std_logic_vector(11 downto 0);
    signal  sdata_eq       : std_logic_vector(64-1 downto 0);


    signal shsync_osd      : ty_para_syn; -- : std_logic;
    signal svsync_osd      : ty_para_syn; -- : std_logic;
    signal  shcnt_osd      : ty_para_cnt; -- : std_logic_vector(11 downto 0);
    signal  svcnt_osd      : ty_para_cnt; -- : std_logic_vector(11 downto 0);
    signal  sdata_osd      : std_logic_vector(64-1 downto 0);

    signal shsync_edge     : ty_para_syn; -- : std_logic;
    signal svsync_edge     : ty_para_syn; -- : std_logic;
    signal  shcnt_edge     : ty_para_cnt; -- : std_logic_vector(11 downto 0);
    signal  svcnt_edge     : ty_para_cnt; -- : std_logic_vector(11 downto 0);
    signal  sdata_edge     : std_logic_vector(64-1 downto 0);

    signal sreg_bnc_en       : std_logic;
    signal sreg_bnc_high     : std_logic_vector(16-1 downto 0);
    signal bnc_bright        : std_logic_vector(17-1 downto 0);
    signal bnc_contrast      : std_logic_vector(16-1 downto 0);
    signal sreg_sel_bright   : std_logic_vector(17-1 downto 0);
    signal sreg_sel_contrast : std_logic_vector(16-1 downto 0);
    
    signal sreg_edge_ctrl    : std_logic_vector(16-1 downto 0);
    signal sreg_edge_remainder_left  : std_logic_vector(4-1 downto 0);
    signal sreg_edge_remainder_right : std_logic_vector(4-1 downto 0);
    signal sreg_edge_left    : ty_para_edge;
    signal sreg_edge_right   : ty_para_edge;
begin

--  U0_MASKING_PROC : MASKING_PROC
--      port map (
--          idata_clk  => idata_clk,
--          idata_rstn => idata_rstn,
--
--          ireg_iproc_mode => ireg_iproc_mode,
--
--          ireg_width  => ireg_width,
--          ireg_height => ireg_height,
--
--          ihsync => ihsync,
--          ivsync => ivsync,
--          ihcnt  => ihcnt,
--          ivcnt  => ivcnt,
--          idata  => idata,
--
--          ohsync => shsync_masking,
--          ovsync => svsync_masking,
--          ohcnt  => shcnt_masking,
--          ovcnt  => svcnt_masking,
--          odata  => sdata_masking
--      );
--
--  U0_BRIGHT_CTRL : BRIGHT_CTRL
--      port map (
--          idata_clk  => idata_clk,
--          idata_rstn => idata_rstn,
--
--          ireg_bright => ireg_bright,
--
--          ihsync => shsync_masking,
--          ivsync => svsync_masking,
--          ihcnt  => shcnt_masking,
--          ivcnt  => svcnt_masking,
--          idata  => sdata_masking,
--
--          ohsync => shsync_bright,
--          ovsync => svsync_bright,
--          ohcnt  => shcnt_bright,
--          ovcnt  => svcnt_bright,
--          odata  => sdata_bright
--      );
--
--  U0_CONTRAST_CTRL : CONTRAST_CTRL
--      port map (
--          idata_clk  => idata_clk,
--          idata_rstn => idata_rstn,
--
--          ireg_contrast => ireg_contrast,
--
--          ihsync => shsync_bright,
--          ivsync => svsync_bright,
--          ihcnt  => shcnt_bright,
--          ivcnt  => svcnt_bright,
--          idata  => sdata_bright,
--
--          ohsync => shsync_contrast,
--          ovsync => svsync_contrast,
--          ohcnt  => shcnt_contrast,
--          ovcnt  => svcnt_contrast,
--          odata  => sdata_contrast
--      );
--
--  gen_dnr_on : if(GEN_2DDNR = '1') generate
--  begin
--      u_dnr : DNR
--          port map (
--              i_clk            => idata_clk,
--              i_RegHActive     => ireg_width,
--              i_RegVActive     => ireg_height,
--              i_regDnrCtrl     => ireg_DnrCtrl,
--              i_regSobelCoeff0 => ireg_SobelCoeff0,
--              i_regSobelCoeff1 => ireg_SobelCoeff1,
--              i_regSobelCoeff2 => ireg_SobelCoeff2,
--              i_regBlurOffset  => ireg_BlurOffset,
--
--              i_hsyn => shsync_contrast,
--              i_vsyn => svsync_contrast,
--              i_hcnt => shcnt_contrast,
--              i_vcnt => svcnt_contrast,
--              i_data => sdata_contrast,
--
--              o_hsyn => shsync_dnr,
--              o_vsyn => svsync_dnr,
--              o_hcnt => shcnt_dnr,
--              o_vcnt => svcnt_dnr,
--              o_data => sdata_dnr
--          );
--  end generate gen_dnr_on;
--
--  gen_dnr_off : if(GEN_2DDNR = '0') generate
--      shsync_dnr <= shsync_contrast;
--      svsync_dnr <= svsync_contrast;
--      shcnt_dnr  <= shcnt_contrast;
--      svcnt_dnr  <= svcnt_contrast;
--      sdata_dnr  <= sdata_contrast;
--  end generate gen_dnr_off;

shsync_dnr <= ihsync;
svsync_dnr <= ivsync;
shcnt_dnr  <= ihcnt ;
svcnt_dnr  <= ivcnt ;
sdata_dnr  <= idata ;


    BNC_MinMax : BritCont_master
        port map
        (
          i_clk   => idata_clk,
          i_hsync => ihsync,
          i_vsync => ivsync,
          i_hcnt  => ihcnt,
          i_vcnt  => ivcnt,
          i_data  => idata(16*2-1 downto 16*1), --# mid data

          i_reg_width    => ireg_width,
          i_reg_height   => ireg_height,
          i_reg_bnc_high => sreg_bnc_high,

          o_Brit  => bnc_bright,
          o_Cont  => bnc_contrast
        );

sreg_bnc_en       <= ireg_bnc_ctrl(0);
sreg_bnc_high     <= ireg_bnc_high(16-1 downto 0);
sreg_sel_bright   <= bnc_bright   when sreg_bnc_En='1' else ireg_bright;
sreg_sel_contrast <= bnc_contrast when sreg_bnc_En='1' else ireg_contrast;

gen_bnc4: for i in 0 to 4-1 generate
begin

    U0_BRIGHT_CTRL : BRIGHT_CTRL
        port map (
            idata_clk  => idata_clk,
            idata_rstn => idata_rstn,

--          ireg_bright => ireg_bright,
            ireg_bright => sreg_sel_bright, --#230721

            ihsync => ihsync,
            ivsync => ivsync,
            ihcnt  =>  ihcnt,
            ivcnt  =>  ivcnt,
            idata  =>  idata(16*(i+1)-1 downto 16*i),

            ohsync => shsync_bright(i),
            ovsync => svsync_bright(i),
            ohcnt  =>  shcnt_bright(i),
            ovcnt  =>  svcnt_bright(i),
            odata  =>  sdata_bright(16*(i+1)-1 downto 16*i)
        );

    U0_CONTRAST_CTRL : CONTRAST_CTRL
        port map (
            idata_clk  => idata_clk,
            idata_rstn => idata_rstn,

--          ireg_contrast => ireg_contrast,
            ireg_contrast => sreg_sel_contrast, --#230721

            ihsync => shsync_bright(i),
            ivsync => svsync_bright(i),
            ihcnt  =>  shcnt_bright(i),
            ivcnt  =>  svcnt_bright(i),
            idata  =>  sdata_bright(16*(i+1)-1 downto 16*i),

            ohsync => shsync_contrast(i),
            ovsync => svsync_contrast(i),
            ohcnt  =>  shcnt_contrast(i),
            ovcnt  =>  svcnt_contrast(i),
            odata  =>  sdata_contrast(16*(i+1)-1 downto 16*i)
        );

end generate gen_bnc4;

-- █▀█ █▀ █▀▄
-- █▄█ ▄█ █▄▀ %osd
    gen_OSD_on: if(GEN_OSD = '1') generate
    begin

        gen_osd4: for i in 0 to 4-1 generate
            u_osd : OSD
                generic map( GNR_MODEL => GNR_MODEL)
                port map (
                    i_sclk         => isys_clk,
                    i_ext_trig_in  => iext_trig_in,
                    i_reg_osd_ctrl => ireg_osd_ctrl,
                    o_reg_trigcnt  => OPEN, -- oreg_trigcnt,
                    i_reg_sync_rcnt=> ireg_sync_rcnt,

                    i_chgdet_osd_en => ichgdet_osd_en,
                    i_chgdet_osd_da => ichgdet_osd_da,

                    i_dclk => idata_clk,
                    i_hsyn => shsync_contrast(i),
                    i_vsyn => svsync_contrast(i),
                    i_hcnt =>  shcnt_contrast(i),
                    i_vcnt =>  svcnt_contrast(i),
                    i_data =>  sdata_contrast(16*(i+1)-1 downto 16*i),

                    o_hsyn => shsync_osd(i),
                    o_vsyn => svsync_osd(i),
                    o_hcnt => shcnt_osd (i),
                    o_vcnt => svcnt_osd (i),
                    o_data => sdata_osd(16*(i+1)-1 downto 16*i)
                );
        end generate gen_osd4;

    end generate gen_osd_on;

    gen_OSD_off : if(GEN_OSD = '0') generate
    begin
        gen_osd_off_para4: for i in 0 to 4-1 generate
            shsync_osd(i)                     <= shsync_contrast(i);
            svsync_osd(i)                     <= svsync_contrast(i);
            shcnt_osd (i)                     <=  shcnt_contrast(i);
            svcnt_osd (i)                     <=  svcnt_contrast(i);
            sdata_osd(16*(i+1)-1 downto 16*i) <=  sdata_contrast(16*(i+1)-1 downto 16*i);
        end generate gen_osd_off_para4;
    end generate gen_osd_off;

-- █▀▀ █▀▄ █▀▀ █▀▀
-- ██▄ █▄▀ █▄█ ██▄ %edge
    gen_EDGE_1: if(GEN_EDGE = '1') generate
    begin

        gen_edge4: for i in 0 to 4-1 generate
            u_edge : EDGE
                port map (
                    clk               => idata_clk,
                    i_reg_width       => ireg_width ,
                    i_reg_height      => ireg_height,
                    i_reg_edge_ctrl   => ireg_edge_ctrl,
                    i_reg_edge_value  => ireg_edge_value,
                    i_reg_edge_top    => ireg_edge_top,
--                    i_reg_edge_left   => ireg_edge_left,
--                    i_reg_edge_right  => ireg_edge_right,
                    i_reg_edge_left   => sreg_edge_left(i),
                    i_reg_edge_right  => sreg_edge_right(i),
                    i_reg_edge_bottom => ireg_edge_bottom,

                    i_hsyn => shsync_osd(i),
                    i_vsyn => svsync_osd(i),
                    i_hcnt =>  shcnt_osd(i),
                    i_vcnt =>  svcnt_osd(i),
                    i_data =>  sdata_osd(16*(i+1)-1 downto 16*i),

                    o_hsyn => shsync_edge(i),
                    o_vsyn => svsync_edge(i),
                    o_hcnt =>  shcnt_edge(i),
                    o_vcnt =>  svcnt_edge(i),
                    o_data =>  sdata_edge(16*(i+1)-1 downto 16*i)
                );
        end generate gen_edge4;

    end generate gen_EDGE_1;
    --$ 260304 10G Edge cut
    process(idata_clk)
    begin
        if(idata_clk'event and idata_clk = '1') then
        
        sreg_edge_ctrl <= ireg_edge_ctrl;
        sreg_edge_remainder_left  <= sreg_edge_ctrl (8 downto 5);
        sreg_edge_remainder_right <= sreg_edge_ctrl (4 downto 1);       
         
            for i in 0 to PARA - 1 loop                                    
                sreg_edge_left (i)  <= ireg_edge_left  + sreg_edge_remainder_left (i);
                sreg_edge_right(i)  <= ireg_edge_right + sreg_edge_remainder_right(i);
            end loop;
        end if;
    end process;
    

    gen_EDGE_0 : if(GEN_EDGE = '0') generate
        gen_edge_0_para4: for i in 0 to 4-1 generate
            shsync_edge(i) <= shsync_osd(i);
            svsync_edge(i) <= svsync_osd(i);
             shcnt_edge(i) <=  shcnt_osd(i);
             svcnt_edge(i) <=  svcnt_osd(i);
             sdata_edge(16*(i+1)-1 downto 16*i) <= 
              sdata_osd(16*(i+1)-1 downto 16*i);
        end generate gen_edge_0_para4;
    end generate gen_EDGE_0;

    ohsync <= shsync_edge(0);
    ovsync <= svsync_edge(0);
    ohcnt  <=  shcnt_edge(0);
    ovcnt  <=  svcnt_edge(0);
    odata  <=  sdata_edge;
end architecture behavioral;
