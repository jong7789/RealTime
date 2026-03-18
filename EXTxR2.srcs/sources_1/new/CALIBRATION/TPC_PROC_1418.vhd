-- code clean & d2mode_signal : v1.16.1 mbh 210617

library IEEE;
    use IEEE.STD_LOGIC_1164.ALL;
    use IEEE.STD_LOGIC_UNSIGNED.ALL;
    use IEEE.STD_LOGIC_ARITH.ALL;
    use WORK.TOP_HEADER.ALL;

entity TPC_PROC_1418 is
    port (
        idata_clk  : in std_logic;
        idata_rstn : in std_logic;

        ireg_gain_cal   : in std_logic;
        ireg_offset_cal : in std_logic;
        ireg_ofga_lim   : in std_logic_vector(16-1 downto 0);

        --* GCAL POINT AREA
        ireg_mpc_ctrl      : in std_logic_vector( 4-1 downto 0);
        ireg_mpc_num       : in std_logic_vector( 4-1 downto 0);
        ireg_mpc_point0    : in std_logic_vector(16-1 downto 0);
        ireg_mpc_point1    : in std_logic_vector(16-1 downto 0);
        ireg_mpc_point2    : in std_logic_vector(16-1 downto 0);
        ireg_mpc_point3    : in std_logic_vector(16-1 downto 0);
        ireg_mpc_posoffset : in std_logic_vector(16-1 downto 0);
        id2m_xray          : in std_logic;
        id2m_dark          : in std_logic;

        --* FROM. DDR3_TOP
        itpc_rdata : in std_logic_vector(128-1 downto 0);
        iavg_rinfo : in std_logic_vector( 32-1 downto 0);
        iofs_rinfo : in std_logic_vector( 32-1 downto 0);

        --* FROM. DDR3_SYNC
        ihsync : in std_logic;
        ivsync : in std_logic;
        ivcnt  : in std_logic_vector(12-1 downto 0);
        ihcnt  : in std_logic_vector(12-1 downto 0);
        idata  : in std_logic_vector(16-1 downto 0);

        --* TO. DGAIN_PROC
        ohsync : out std_logic;
        ovsync : out std_logic;
        ovcnt  : out std_logic_vector(12-1 downto 0);
        ohcnt  : out std_logic_vector(12-1 downto 0);
        odata  : out std_logic_vector(24-1 downto 0)
    );
end entity tpc_proc_1418;

architecture behavioral of tpc_proc_1418 is

    constant DN100 : std_logic_vector(15 downto 0) := conv_std_logic_vector(100, 16);

    -- component SUB_U16_U16
    --     port (
    --         A   : in    std_logic_vector(15 downto 0);
    --         B   : in    std_logic_vector(15 downto 0);
    --         CLK : in    std_logic;
    --         S   : out   std_logic_vector(16 downto 0)
    --     );
    -- end component;
    component SUB_U17_U16
        port (
            A   : in  std_logic_vector(16 downto 0);
            B   : in  std_logic_vector(15 downto 0);
            CLK : in  std_logic;
            S   : out std_logic_vector(17 downto 0)
        );
    end component;

    component MULTI_16x14
        port (
            clk : in  std_logic;
            ce  : in  std_logic;
            a   : in  std_logic_vector(15 downto 0);
            b   : in  std_logic_vector(13 downto 0);
            p   : out std_logic_vector(29 downto 0)
        );
    end component;

    component SUB_18x18
        port (
            clk : in  std_logic;
            ce  : in  std_logic;
            a   : in  std_logic_vector(17 downto 0);
            b   : in  std_logic_vector(17 downto 0);
            s   : out std_logic_vector(19 downto 0)
        );
    end component;

    --# 230718
    COMPONENT ADD_U16_S16_S18
      PORT (
        A : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
        B : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
        CLK : IN STD_LOGIC;
        S : OUT STD_LOGIC_VECTOR(17 DOWNTO 0)
      );
    END COMPONENT;

    -- ### reg ###
    signal sreg_gain_cal_shft   : std_logic_vector(3 downto 1);
    signal sreg_offset_cal_shft : std_logic_vector(3 downto 1);
    signal sd2m_xray_shft       : std_logic_vector(3 downto 1);
    signal sd2m_dark_shft       : std_logic_vector(3 downto 1);

    type   ty_3shft_4b is array (3 downto 1) of std_logic_vector(4 - 1 downto 0);
    signal sreg_mpc_ctrl_shft : ty_3shft_4b;
    signal sreg_mpc_num_shft  : ty_3shft_4b;

    type   ty_3shft_16b is array (3 downto 1) of std_logic_vector(16 - 1 downto 0);
    signal sreg_mpc_point0_shft    : ty_3shft_16b;
    signal sreg_mpc_point1_shft    : ty_3shft_16b;
    signal sreg_mpc_point2_shft    : ty_3shft_16b;
    signal sreg_mpc_point3_shft    : ty_3shft_16b;
    signal sreg_mpc_posoffset_shft : ty_3shft_16b;
    signal sgain_cal               : std_logic;
    signal soffset_cal             : std_logic;
    signal smpc_ctrl               : std_logic_vector(4 - 1 downto 0);
    signal smpc_num                : std_logic_vector(4 - 1 downto 0);
    signal smpc_point0             : std_logic_vector(16 - 1 downto 0);
    signal smpc_point1             : std_logic_vector(16 - 1 downto 0);
    signal smpc_point2             : std_logic_vector(16 - 1 downto 0);
    signal smpc_point3             : std_logic_vector(16 - 1 downto 0);
    signal sreg_mpc_posoffset      : std_logic_vector(16 - 1 downto 0);
    signal sreg_mpc_posoffset_minus: std_logic_vector(16 - 1 downto 0);
    signal sd2m_xray               : std_logic;
    signal sd2m_dark               : std_logic;
    signal sreg_Ref0MinusEn        : std_logic;
    signal sreg_mpc_bypss          : std_logic;
    signal sreg_D2DarkXraySel      : std_logic;
    signal sreg_ofga_lim_shft      : ty_3shft_16b; --# 230725
            
    -- ### coeff ###
    signal scoeff_gain   : std_logic_vector(14 - 1 downto 0);
    signal scoeff_offset : std_logic_vector(18 - 1 downto 0);

    constant inv_arrnum : integer := 16;

    type   ty_invshft_14b is array (inv_arrnum downto 2) of std_logic_vector(14 - 1 downto 0);
    signal scoeff_gain_shft : ty_invshft_14b;

    type   ty_invshft_18b is array (inv_arrnum downto 2) of std_logic_vector(18 - 1 downto 0);
    signal scoeff_offset_shft : ty_invshft_18b;

    --# offset gain limite reg #230725
    signal scoeff_gain_limsel8    : std_logic_vector(14 - 1 downto 0); --# 230725
    signal scoeff_offset_limsel12 : std_logic_vector(18 - 1 downto 0); --# 230725
    signal sreg_ofga_lim          : std_logic_vector(16 - 1 downto 0) := (others=> '0');

    -- ### -reg ###
    signal shsync_shft : std_logic_vector(inv_arrnum downto 1);
    signal svsync_shft : std_logic_vector(inv_arrnum downto 1);

    type   ty_cnt_shft is array (inv_arrnum downto 1) of std_logic_vector(12 - 1 downto 0);
    signal shcnt_shft : ty_cnt_shft;
    signal svcnt_shft : ty_cnt_shft;

    type   ty_data_shft is array (inv_arrnum downto 1) of std_logic_vector(16 - 1 downto 0);
    signal sdata_shft : ty_data_shft;

    type   ty_xdata_shft is array (inv_arrnum downto 3) of std_logic_vector(16 - 1 downto 0);
    signal sdark_shft : ty_xdata_shft;
    signal sxray_shft : ty_xdata_shft;

    signal mmry_data_1d       : std_logic_vector(16 - 1 downto 0) := (others=> '0');
    signal live_data_1d       : std_logic_vector(16 - 1 downto 0) := (others=> '0');
    signal dark_data_2d       : std_logic_vector(16 - 1 downto 0) := (others=> '0');
    signal xray_data_2d       : std_logic_vector(16 - 1 downto 0) := (others=> '0');
    signal dark_data_3d       : std_logic_vector(16 - 1 downto 0) := (others=> '0');
    signal xray_offset_3d     : std_logic_vector(17 - 1 downto 0) := (others=> '0');
    signal xray_offset18_3d   : std_logic_vector(18 - 1 downto 0) := (others=> '0');
    signal dark_data_4d       : std_logic_vector(16 - 1 downto 0) := (others=> '0');
    signal xray_offcut_4d     : std_logic_vector(17 - 1 downto 0) := (others=> '0');
    signal sXraySubRef_5d     : std_logic_vector(18 - 1 downto 0) := (others=> '0');
    signal sXraySubRef_cut_6d : std_logic_vector(16 - 1 downto 0) := (others=> '0');
    signal sXraySubRef_sel_7d : std_logic_vector(16 - 1 downto 0) := (others=> '0');
    signal sXraySubRef_8d     : std_logic_vector(16 - 1 downto 0) := (others=> '0');
     
    type   ty_8shft_16b is array (inv_arrnum downto 9) of std_logic_vector(16 - 1 downto 0);
    signal sXraySubRef_shft : ty_8shft_16b;

    -- ### nuc* ###
    signal smulti_data_11d    : std_logic_vector(30 - 1 downto 0);
    signal sdata_gain_cal_12d : std_logic_vector(18 - 1 downto 0);
    signal sdata_gain_cal_13d : std_logic_vector(18 - 1 downto 0);
    signal sdata_gain_cal_14d : std_logic_vector(18 - 1 downto 0);

    -- ### nuc- ###
    signal ssub_data_14d        : std_logic_vector(20 - 1 downto 0);
    signal sdata_offset_cal_15d : std_logic_vector(18 - 1 downto 0);

    -- ### out ###
    signal shsync_out : std_logic;
    signal svsync_out : std_logic;
    signal svcnt_out  : std_logic_vector(12 - 1 downto 0);
    signal shcnt_out  : std_logic_vector(12 - 1 downto 0);
    signal sdata_out  : std_logic_vector(24 - 1 downto 0);

    -- ### debug ###
    signal sreg_dark_sel : std_logic;
    signal sreg_xray_sel : std_logic;
   

-- !begin

begin
            
-- █▀█ █▀▀ █▀▀
-- █▀▄ ██▄ █▄█
-- !reg
    process (idata_clk, idata_rstn)
    begin
        if (idata_clk'event and idata_clk = '1') then
            sreg_gain_cal_shft      <= sreg_gain_cal_shft     (sreg_gain_cal_shft     'left - 1 downto 1) & ireg_gain_cal;
            sreg_offset_cal_shft    <= sreg_offset_cal_shft   (sreg_offset_cal_shft   'left - 1 downto 1) & ireg_offset_cal;
            sreg_mpc_ctrl_shft      <= sreg_mpc_ctrl_shft     (sreg_mpc_ctrl_shft     'left - 1 downto 1) & ireg_mpc_ctrl;
            sreg_mpc_num_shft       <= sreg_mpc_num_shft      (sreg_mpc_num_shft      'left - 1 downto 1) & ireg_mpc_num;
            sreg_mpc_point0_shft    <= sreg_mpc_point0_shft   (sreg_mpc_point0_shft   'left - 1 downto 1) & ireg_mpc_point0;
            sreg_mpc_point1_shft    <= sreg_mpc_point1_shft   (sreg_mpc_point1_shft   'left - 1 downto 1) & ireg_mpc_point1;
            sreg_mpc_point2_shft    <= sreg_mpc_point2_shft   (sreg_mpc_point2_shft   'left - 1 downto 1) & ireg_mpc_point2;
            sreg_mpc_point3_shft    <= sreg_mpc_point3_shft   (sreg_mpc_point3_shft   'left - 1 downto 1) & ireg_mpc_point3;
            sreg_mpc_posoffset_shft <= sreg_mpc_posoffset_shft(sreg_mpc_posoffset_shft'left - 1 downto 1) & ireg_mpc_posoffset;
            sd2m_xray_shft          <= sd2m_xray_shft         (sd2m_xray_shft         'left - 1 downto 1) & id2m_xray;
            sd2m_dark_shft          <= sd2m_dark_shft         (sd2m_dark_shft         'left - 1 downto 1) & id2m_dark;
            sreg_ofga_lim_shft      <= sreg_ofga_lim_shft     (sreg_ofga_lim_shft     'left - 1 downto 1) & ireg_ofga_lim; 
            -- # vsync latch
            if(svsync_shft(1)  = '0') then
                sgain_cal   <= sreg_gain_cal_shft     (sreg_gain_cal_shft     'left);
                soffset_cal <= sreg_offset_cal_shft   (sreg_offset_cal_shft   'left);
            end if;
            smpc_ctrl          <= sreg_mpc_ctrl_shft     (sreg_mpc_ctrl_shft     'left);
            smpc_num           <= sreg_mpc_num_shft      (sreg_mpc_num_shft      'left);
            smpc_point0        <= sreg_mpc_point0_shft   (sreg_mpc_point0_shft   'left);
            smpc_point1        <= sreg_mpc_point1_shft   (sreg_mpc_point1_shft   'left);
            smpc_point2        <= sreg_mpc_point2_shft   (sreg_mpc_point2_shft   'left);
            smpc_point3        <= sreg_mpc_point3_shft   (sreg_mpc_point3_shft   'left);
            sreg_mpc_posoffset <= sreg_mpc_posoffset_shft(sreg_mpc_posoffset_shft'left);
            sd2m_xray          <= sd2m_xray_shft         (sd2m_xray_shft         'left);
            sd2m_dark          <= sd2m_dark_shft         (sd2m_dark_shft         'left);
            sreg_ofga_lim      <= sreg_ofga_lim_shft     (sreg_ofga_lim_shft     'left);

            -- ### rename
            sreg_Ref0MinusEn   <= smpc_ctrl(0) or sd2m_dark; -- d2 dark = offset enable , 210629
            sreg_mpc_bypss     <= smpc_ctrl(1) or sd2m_xray; -- d2 xray data gonna bypass.
            sreg_dark_sel      <= smpc_ctrl(2);              -- debug
            sreg_xray_sel      <= smpc_ctrl(3);              -- debug
            sreg_D2DarkXraySel <= sd2m_dark;                 -- d2 xray <= ddr, dark <= current
        end if;
    end process;

-- █▀▀ █▀█ █▀▀ ▄▄ █▀▀ ▄▀█ █ █▄░█
-- █▄▄ █▄█ ██▄ ░░ █▄█ █▀█ █ █░▀█
-- !coegain
    process (idata_clk, idata_rstn)
    begin
        if(idata_rstn = '0') then
            scoeff_gain <= (others => '0');
        elsif (idata_clk'event and idata_clk = '1') then
        --
            -- # phase 1
            case smpc_num is
                when x"2" =>
                    scoeff_gain <= itpc_rdata(31 downto 18);
                when x"3" =>
                    if(idata < smpc_point0) then scoeff_gain <= itpc_rdata(31 downto 18);
                    else                         scoeff_gain <= itpc_rdata(63 downto 50); end if;
                when x"4" =>
                    if    (idata < smpc_point0) then scoeff_gain <= itpc_rdata(31 downto 18);
                    elsif (idata < smpc_point1) then scoeff_gain <= itpc_rdata(63 downto 50);
                    else                             scoeff_gain <= itpc_rdata(95 downto 82); end if;
                when x"5" =>
                    if    (idata < smpc_point0) then scoeff_gain <= itpc_rdata(31 downto 18);
                    elsif (idata < smpc_point1) then scoeff_gain <= itpc_rdata(63 downto 50);
                    elsif (idata < smpc_point2) then scoeff_gain <= itpc_rdata(95 downto 82);
                    else                             scoeff_gain <= itpc_rdata(127 downto 114); end if;
                -- when x"6" =>
                --     if    (idata < smpc_point0) then scoeff_gain <= itpc_rdata(31 downto 18);
                --     elsif (idata < smpc_point1) then scoeff_gain <= itpc_rdata(63 downto 50);
                --     elsif (idata < smpc_point2) then scoeff_gain <= itpc_rdata(95 downto 82);
                --     elsif (idata < smpc_point3) then scoeff_gain <= itpc_rdata(127 downto 114);
                --     else                             scoeff_gain <= itpc_rdata(159 downto 146); end if;
                when others =>
                    scoeff_gain <= (others => '0');
            end case;

            -- # phase 2
            scoeff_gain_shft <= scoeff_gain_shft(scoeff_gain_shft'left - 1 downto scoeff_gain_shft'right) & scoeff_gain;
        --
        end if;
    end process;
                              
-- █▀▀ █▀█ █▀▀ ▄▄ █▀█ █▀▀ █▀▀ █▀
-- █▄▄ █▄█ ██▄ ░░ █▄█ █▀░ █▀░ ▄█
-- !coeoffset
    process (idata_clk, idata_rstn)
    begin
        if(idata_rstn = '0') then
            scoeff_offset <= (others => '0');
        elsif (idata_clk'event and idata_clk = '1') then
            if(sgain_cal = '0' and sreg_Ref0MinusEn = '0') then -- mbh 210222
                scoeff_offset <= ("00" & iavg_rinfo(31 downto 16)) - DN100;
            else
                -- # phase 1
                case smpc_num is
                    when x"2" =>
                        scoeff_offset <= itpc_rdata(17 downto 0);
                    when x"3" =>
                        if(idata < smpc_point0) then scoeff_offset <= itpc_rdata(17 downto 0);
                        else                         scoeff_offset <= itpc_rdata(49 downto 32); end if;
                    when x"4" =>
                        if    (idata < smpc_point0) then scoeff_offset <= itpc_rdata(17 downto 0);
                        elsif (idata < smpc_point1) then scoeff_offset <= itpc_rdata(49 downto 32);
                        else                             scoeff_offset <= itpc_rdata(81 downto 64); end if;
                    when x"5" =>
                        if    (idata < smpc_point0) then scoeff_offset <= itpc_rdata(17 downto 0);
                        elsif (idata < smpc_point1) then scoeff_offset <= itpc_rdata(49 downto 32);
                        elsif (idata < smpc_point2) then scoeff_offset <= itpc_rdata(81 downto 64);
                        else                             scoeff_offset <= itpc_rdata(113 downto 96); end if;
                    -- when x"6"  =>
                    --     if   (idata < smpc_point0) then scoeff_offset <= itpc_rdata(17 downto 0);
                    --     elsif(idata < smpc_point1) then scoeff_offset <= itpc_rdata(49 downto 32);
                    --     elsif(idata < smpc_point2) then scoeff_offset <= itpc_rdata(81 downto 64);
                    --     elsif(idata < smpc_point3) then scoeff_offset <= itpc_rdata(113 downto 96);
                    --     else                            scoeff_offset <= itpc_rdata(145 downto 128); end if;
                    when others =>
                        scoeff_offset <= (others => '0');
                end case;

                -- # phase 2
                scoeff_offset_shft <= scoeff_offset_shft(scoeff_offset_shft'left - 1 downto scoeff_offset_shft'right) & scoeff_offset;
            end if;
        end if;
    end process;
                
-- ▄▄ █▀█ █▀▀ █▀▀
-- ░░ █▀▄ ██▄ █▀░
-- !inref
    process (idata_clk)
    begin
        if idata_clk'event and idata_clk='1' then
        --
            -- ### in video array shift
            shsync_shft <= shsync_shft(shsync_shft'left - 1 downto 1) & ihsync;
            svsync_shft <= svsync_shft(svsync_shft'left - 1 downto 1) & ivsync;
            shcnt_shft  <= shcnt_shft (shcnt_shft'left - 1  downto 1) & ihcnt;
            svcnt_shft  <= svcnt_shft (svcnt_shft'left - 1  downto 1) & ivcnt;
            sdata_shft  <= sdata_shft (sdata_shft'left - 1  downto 1) & idata;

            -- ### phase.1 : in
            if sreg_D2DarkXraySel='0' then --: normal
                mmry_data_1d <= iavg_rinfo(31 downto 16);
            else                            --: D2mode
                mmry_data_1d <= iofs_rinfo(31 downto 16);
            end if;
            live_data_1d <= idata;

            -- ### phase.2 : dark, xray selection
            if sreg_D2DarkXraySel='0' then --: normal
                xray_data_2d <= live_data_1d;
                dark_data_2d <= mmry_data_1d;
            else                           --: D2mode
                xray_data_2d <= mmry_data_1d;
                dark_data_2d <= live_data_1d;
            end if;
            sdark_shft <= sdark_shft (sdark_shft'left - 1  downto 3) & dark_data_2d;
            sxray_shft <= sxray_shft (sxray_shft'left - 1  downto 3) & xray_data_2d;
        --
        end if;
    end process;
    
----#### minus plus make dark flat
--    process (idata_clk)
--    begin
--        if idata_clk'event and idata_clk='1' then
--        --
--            -- ### phase.3 : xray + offset
--            dark_data_3d   <= dark_data_2d;
----            xray_offset_3d <= '0' & xray_data_2d + sreg_mpc_posoffset;
--            sreg_mpc_posoffset_minus <= (not sreg_mpc_posoffset)+'1'; 
--        --
--        end if;
--    end process;
-- --# phase 3
--  u_ADD_U16_S16_S18 : ADD_U16_S16_S18
--  PORT MAP (
--    A => xray_data_2d, --u16
--    B => sreg_mpc_posoffset_minus, --s16
--    CLK => idata_clk, --s18
--    S => xray_offset18_3d
--  );
--  --# phase 4
--    process (idata_clk)
--    begin
--        if idata_clk'event and idata_clk='1' then
--            -- ### phase.4 : xray bit cut
--            dark_data_4d <= dark_data_3d;
--            if xray_offset18_3d(18 - 1)='1' then -- minus to zero
--                xray_offcut_4d <= (others=> '0');
--            else
--                xray_offcut_4d <= xray_offset18_3d(17 - 1 downto 0);
--            end if;
--        --
--        end if;
--    end process;
  
    process (idata_clk)
    begin
        if idata_clk'event and idata_clk='1' then
        --
              -- ### phase.3 : xray + offset
            dark_data_3d   <= dark_data_2d;
            xray_offset_3d <= '0' & xray_data_2d + sreg_mpc_posoffset;

            -- ### phase.4 : xray bit cut
            --# value limit --# remove, should do offset
--          if xray_offset_3d > sreg_ofga_lim then --# over lim, do not -offset
--              dark_data_4d <= (others=>'0');     --# 230725
--          else
--              dark_data_4d <= dark_data_3d;
--          end if;
            dark_data_4d <= dark_data_3d;
            xray_offcut_4d <= xray_offset_3d;
        --
        end if;
    end process;   
    
  -- ### 17'b <=1d= 16'video - 16'ref_video
    -- U_SUB_U16_U16 : SUB_U16_U16 -- # 1 delay
    U_SUB_U17_U16 : SUB_U17_U16 -- # 1 delay
        port map (
            CLK => idata_clk,
            A   => xray_offcut_4d,
            B   => dark_data_4d,
            S   => sXraySubRef_5d
        );

    process (idata_clk)
    begin
        if idata_clk'event and idata_clk='1' then
        --
            -- ### phase.6 : minus cut
            if sXraySubRef_5d(18 - 1)='1' then -- minus to zero
                sXraySubRef_cut_6d <= (others=> '0');
			elsif sXraySubRef_5d(17 - 1)='1' then -- over 16b
                sXraySubRef_cut_6d <= (others=> '1');
            else
                sXraySubRef_cut_6d <= sXraySubRef_5d(16 - 1 downto 0);
            end if;

            -- ### phase.7 : substraction select
            if sreg_dark_sel = '1' then              -- ### its for debug 210705
                sXraySubRef_sel_7d <= sdark_shft(6); -- ### its for debug
            elsif sreg_xray_sel = '1' then           -- ### its for debug
                sXraySubRef_sel_7d <= sxray_shft(6); -- ### its for debug
            elsif sreg_Ref0MinusEn = '1' then
                sXraySubRef_sel_7d <= sXraySubRef_cut_6d;
--              sXraySubRef_sel_7d <= sXraySubRef_cut_6d + sreg_mpc_posoffset; --# 230720 + sreg_mpc_posoffset
            else
                sXraySubRef_sel_7d <= sdata_shft(6);
            end if;

            -- ### phase.8
            sXraySubRef_8d <= sXraySubRef_sel_7d;
            if sXraySubRef_sel_7d > sreg_ofga_lim then       --# over lim, do not -offset
                scoeff_gain_limsel8 <= b"01_0000_0000_0000"; --# 230725
            else
                scoeff_gain_limsel8 <= scoeff_gain_shft(7);
            end if;
            
            -- ### shift
            sXraySubRef_shft <= sXraySubRef_shft(sXraySubRef_shft'left - 1 downto 9) & sXraySubRef_8d;
        --
        end if;
    end process;


                 
-- █▄░█ █░█ █▀▀   ▀▄▀
-- █░▀█ █▄█ █▄▄   █░█
-- !nuc*
    -- ### 3 Delay
    U0_MULTI_16x14 : MULTI_16x14
        port map (
            clk => idata_clk,
            ce  => idata_rstn,
            a   => sXraySubRef_8d,
--          b   => scoeff_gain_shft(8),
            b   => scoeff_gain_limsel8, --# 230725
            p   => smulti_data_11d
        );

    -- ### 12d <= 11d
    process (idata_clk, idata_rstn)
    begin
        if(idata_rstn = '0') then
            sdata_gain_cal_12d <= (others => '0');
        elsif (idata_clk'event and idata_clk = '1') then
            -- # -offset *gain
            if(sgain_cal = '1') then
                sdata_gain_cal_12d <= smulti_data_11d(29 downto 12) + smulti_data_11d(11);
            -- # -offset
            elsif sreg_Ref0MinusEn = '1' then
                sdata_gain_cal_12d <= "00" & sXraySubRef_shft(11);
            -- # bypass
            else
                sdata_gain_cal_12d <= ("00" & sdata_shft(11));
            end if;
            sdata_gain_cal_13d <= sdata_gain_cal_12d;
            sdata_gain_cal_14d <= sdata_gain_cal_13d;
        end if;
    end process;
                
-- █▄░█ █░█ █▀▀ ▄▄
-- █░▀█ █▄█ █▄▄ ░░
-- !nuc-
  -- ### 14d <= 12d
    U0_SUB_18x18 : SUB_18x18 -- 2 Delay
        port map (
            clk => idata_clk,
            ce  => idata_rstn,
            a   => sdata_gain_cal_12d,
--          b   => scoeff_offset_shft(12),
            b   => scoeff_offset_limsel12,
            s   => ssub_data_14d
        );
    scoeff_offset_limsel12 <= (others=>'0') when sdata_gain_cal_12d > sreg_ofga_lim else --# 230725
                              scoeff_offset_shft(12);
  -- ### offset 15d <= 14d
    process (idata_clk, idata_rstn)
    begin
        if(idata_rstn = '0') then
            sdata_offset_cal_15d <= (others => '0');
        elsif (idata_clk'event and idata_clk = '1') then
            -- ### sub result 18b -> 20 for overflow mbh 201215
            if(soffset_cal = '1') then
                if(ssub_data_14d(19) = '1') then                            -- # miunus
                    sdata_offset_cal_15d <= (others => '0');
                elsif (ssub_data_14d(18)='1' or ssub_data_14d(17)='1') then -- # over
                    sdata_offset_cal_15d <= "01" & x"FFFF";
                else
                    sdata_offset_cal_15d <= '0' & ssub_data_14d(16 downto 0);
                end if;
            else
                sdata_offset_cal_15d <= sdata_gain_cal_14d;
            end if;
        end if;
    end process;
            
-- █▀█ █░█ ▀█▀
-- █▄█ █▄█ ░█░
-- !out
  -- ### 16d <= 15d
    process (idata_clk, idata_rstn)
    begin
        if(idata_rstn = '0') then
            shsync_out <= '0';
            svsync_out <= '0';
            svcnt_out  <= (others => '0');
            shcnt_out  <= (others => '0');
            sdata_out  <= (others => '0');
        elsif (idata_clk'event and idata_clk = '1') then
            if sreg_mpc_bypss = '1' then              -- :bypass
                shsync_out <= shsync_shft(15);
                svsync_out <= svsync_shft(15);
                shcnt_out  <= shcnt_shft(15);
                svcnt_out  <= svcnt_shft(15);
                sdata_out  <= x"00" & sdata_shft(15); -- :indata
            else
                shsync_out <= shsync_shft(15);
                svsync_out <= svsync_shft(15);
                shcnt_out  <= shcnt_shft(15);
                svcnt_out  <= svcnt_shft(15);
				if x"FFFF" < sdata_offset_cal_15d then -- 16bit cut 211210 mbh
					sdata_out  <= x"00FFFF" ;
				else
					sdata_out  <= x"00" & sdata_offset_cal_15d(16-1 downto 0);
				end if;
            end if;
        end if;
    end process;

    ohsync <= shsync_out;
    ovsync <= svsync_out;
    ovcnt  <= svcnt_out;
    ohcnt  <= shcnt_out;
    odata  <= sdata_out;
                    
-- █▀▄ █▀▀ █▄▄ █░█ █▀▀
-- █▄▀ ██▄ █▄█ █▄█ █▄█
-- !debug
ILA_DEBUG1 : if(GEN_ILA_tpc_proc = "ON") generate

    COMPONENT ila_tpc_offset
    PORT (
        clk : IN STD_LOGIC;
        probe0 : IN STD_LOGIC_VECTOR(15 DOWNTO 0); 
        probe1 : IN STD_LOGIC_VECTOR(16 DOWNTO 0); 
        probe2 : IN STD_LOGIC_VECTOR(0 DOWNTO 0); 
        probe3 : IN STD_LOGIC_VECTOR(0 DOWNTO 0); 
        probe4 : IN STD_LOGIC_VECTOR(11 DOWNTO 0); 
        probe5 : IN STD_LOGIC_VECTOR(11 DOWNTO 0); 
        probe6 : IN STD_LOGIC_VECTOR(16 DOWNTO 0); 
        probe7 : IN STD_LOGIC_VECTOR(15 DOWNTO 0); 
        probe8 : IN STD_LOGIC_VECTOR(17 DOWNTO 0);
        probe9 : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
        probe10: IN STD_LOGIC_VECTOR(15 DOWNTO 0)
    );
    END COMPONENT  ;

begin

u_ila_tpc_offset : ila_tpc_offset
PORT MAP (
    clk       => idata_clk          ,
    probe0    => dark_data_3d       , -- 16 
    probe1    => xray_offset_3d     , -- 17 
    probe2(0) => shsync_shft(4)     , --  1 
    probe3(0) => svsync_shft(4)     , --  1 
    probe4    => shcnt_shft(4)      , -- 12 
    probe5    => svcnt_shft(4)      , -- 12 
    probe6    => xray_offcut_4d     , -- 17 
    probe7    => dark_data_4d       , -- 16 
    probe8    => sXraySubRef_5d     , -- 18 
    probe9    => sXraySubRef_cut_6d , -- 16 
    probe10   => iavg_rinfo(31 downto 16)   -- 16 
);

end generate ila_debug1;

-- mmry_data_1d, -- 16
-- live_data_1d, -- 16

end architecture behavioral;

