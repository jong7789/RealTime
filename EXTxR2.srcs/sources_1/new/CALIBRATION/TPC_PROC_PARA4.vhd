-- code clean & d2mode_signal : v1.16.1 mbh 210617

library IEEE;
    use IEEE.STD_LOGIC_1164.ALL;
    use IEEE.STD_LOGIC_UNSIGNED.ALL;
    use IEEE.STD_LOGIC_ARITH.ALL;
    use WORK.TOP_HEADER.ALL;

entity TPC_PROC_PARA4 is
    port (
        idata_clk       : in std_logic;
        idata_rstn      : in std_logic;

        ireg_gain_cal   : in std_logic;
        ireg_offset_cal : in std_logic;

        --* GCAL POINT AREA
        ireg_mpc_ctrl      : in std_logic_vector( 3 downto 0);
        ireg_mpc_num       : in std_logic_vector( 3 downto 0);
        ireg_mpc_point0    : in std_logic_vector(15 downto 0);
--      ireg_mpc_point1    : in std_logic_vector(15 downto 0);
--      ireg_mpc_point2    : in std_logic_vector(15 downto 0);
--      ireg_mpc_point3    : in std_logic_vector(15 downto 0);
        ireg_mpc_posoffset : in std_logic_vector(16 - 1 downto 0);
--      id2m_xray          : in std_logic;
--      id2m_dark          : in std_logic;

        --* FROM. DDR3_TOP
--        itpc_rdata : in  std_logic_vector(64-1 downto 0);
        itpc_rdata : in  std_logic_vector(128 - 1 downto 0);
        iavg_rinfo : in  std_logic_vector(64 - 1 downto 0);
--      iofs_rinfo : in  std_logic_vector(64-1 downto 0);

        --* FROM. DDR3_SYNC
        ihsync : in  std_logic;
        ivsync : in  std_logic;
        ivcnt  : in  std_logic_vector(12 - 1 downto 0);
        ihcnt  : in  std_logic_vector(12 - 1 downto 0);
        idata  : in  std_logic_vector(64 - 1 downto 0);

        --* TO. DGAIN_PROC
        ohsync : out std_logic;
        ovsync : out std_logic;
        ovcnt  : out std_logic_vector(12 - 1 downto 0);
        ohcnt  : out std_logic_vector(12 - 1 downto 0);
        odata  : out std_logic_vector(64 - 1 downto 0)
    );
end entity TPC_PROC_PARA4;

architecture behavioral of TPC_PROC_PARA4 is

    constant DN100 : std_logic_vector(15 downto 0) := conv_std_logic_vector(100, 16);

    component SUB_U17_U16
        port (
            A   : in  std_logic_vector(16 downto 0);
            B   : in  std_logic_vector(15 downto 0);
            CLK : in  std_logic;
            S   : out std_logic_vector(17 downto 0)
        );
    end component;

    component MULTI_16x16
        port (
            clk : in  std_logic;
            ce  : in  std_logic;
            a   : in  std_logic_vector(15 downto 0);
            b   : in  std_logic_vector(15 downto 0);
            p   : out std_logic_vector(31 downto 0)
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
    signal sd2m_xray               : std_logic;
    signal sd2m_dark               : std_logic;
    signal sreg_Ref0MinusEn        : std_logic;
    signal sreg_mpc_bypss          : std_logic;
    signal sreg_D2DarkXraySel      : std_logic;

    -- ### coeff ###
    constant PARA4 : integer := 4;
    constant SHIFT : integer := 32;

    type type_4_16b is array (PARA4 - 1 downto 0) of std_logic_vector(16 - 1 downto 0);
    type type_4_18b is array (PARA4 - 1 downto 0) of std_logic_vector(18 - 1 downto 0);
    type type_4_20b is array (PARA4 - 1 downto 0) of std_logic_vector(20 - 1 downto 0);
    type type_4_32b is array (PARA4 - 1 downto 0) of std_logic_vector(32 - 1 downto 0);

    signal smulti_data_11d : type_4_32b;

    signal shsync_shft : std_logic_vector(SHIFT downto 1);
    signal svsync_shft : std_logic_vector(SHIFT downto 1);

    type   ty_cnt_shft is array (SHIFT downto 1) of std_logic_vector(12 - 1 downto 0);
    signal shcnt_shft : ty_cnt_shft;
    signal svcnt_shft : ty_cnt_shft;

    type   ty_data_shft is array (SHIFT downto 1) of std_logic_vector(64 - 1 downto 0);
    signal sdata_shft : ty_data_shft;
    signal soffs_shft : ty_data_shft;
    signal gain_shft  : ty_data_shft;
    signal goff_shft  : ty_data_shft;

    signal xray_offset_3d     : std_logic_vector(17 * 4 - 1 downto 0) := (others => '0');
    signal xray_offcut_4d     : std_logic_vector(17 * 4 - 1 downto 0) := (others => '0');
    signal sXraySubRef_5d     : std_logic_vector(18 * 4 - 1 downto 0) := (others => '0');
    signal sXraySubRef_cut_6d : std_logic_vector(64 - 1 downto 0)     := (others => '0');
    signal sXraySubRef_sel_7d : std_logic_vector(64 - 1 downto 0)     := (others => '0');
    signal sXraySubRef_8d     : std_logic_vector(64 - 1 downto 0)     := (others => '0');

    signal offs : std_logic_vector(64 - 1 downto 0) := (others => '0');
    signal gain : std_logic_vector(64 - 1 downto 0) := (others => '0');
    signal goff : std_logic_vector(64 - 1 downto 0) := (others => '0');

    type   ty_8shft_64b is array (SHIFT downto 9) of std_logic_vector(64 - 1 downto 0);
    signal sXraySubRef_shft : ty_8shft_64b;

    -- ### nuc* ###
    signal sdata_gain_cal_12d : type_4_16b;
    signal sdata_gain_cal_13d : type_4_16b;
    signal sdata_gain_cal_14d : type_4_16b;

    -- ### nuc- ###
    signal sub_a_12d            : type_4_18b;
    signal sub_b_12d            : type_4_18b;
    signal ssub_data_14d        : type_4_20b;
    signal sdata_offset_cal_15d : type_4_16b;

    -- ### out ###
    signal shsync_out : std_logic;
    signal svsync_out : std_logic;
    signal svcnt_out  : std_logic_vector(12 - 1 downto 0);
    signal shcnt_out  : std_logic_vector(12 - 1 downto 0);
    signal sdata_out  : std_logic_vector(64 - 1 downto 0);

    -- ### debug ###
    signal sreg_dark_sel : std_logic;
    signal sreg_xray_sel : std_logic;

    COMPONENT ila_gain_para4
    PORT (
        clk    : IN STD_LOGIC;
        probe0 : IN STD_LOGIC_VECTOR( 0 DOWNTO 0);
        probe1 : IN STD_LOGIC_VECTOR( 0 DOWNTO 0);
        probe2 : IN STD_LOGIC_VECTOR(11 DOWNTO 0);
        probe3 : IN STD_LOGIC_VECTOR(11 DOWNTO 0);
        probe4 : IN STD_LOGIC_VECTOR(63 DOWNTO 0);
        probe5 : IN STD_LOGIC_VECTOR(63 DOWNTO 0);
        probe6 : IN STD_LOGIC_VECTOR(63 DOWNTO 0);
        probe7 : IN STD_LOGIC_VECTOR(63 DOWNTO 0);
        probe8 : IN STD_LOGIC_VECTOR(63 DOWNTO 0)
    );
    END COMPONENT;

    COMPONENT ila_1pgain
    PORT (
        clk     : IN STD_LOGIC;
        probe0  : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
        probe1  : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
        probe2  : IN STD_LOGIC_VECTOR(11 DOWNTO 0);
        probe3  : IN STD_LOGIC_VECTOR(11 DOWNTO 0);
        probe4  : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
        probe5  : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
        probe6  : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
        probe7  : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        probe8  : IN STD_LOGIC_VECTOR(17 DOWNTO 0);
        probe9  : IN STD_LOGIC_VECTOR(17 DOWNTO 0);
        probe10 : IN STD_LOGIC_VECTOR(19 DOWNTO 0);
        probe11 : IN STD_LOGIC_VECTOR(15 DOWNTO 0)
    );
    END COMPONENT;

    constant PARA : integer := 4;

    type ty_para_16b is array (PARA - 1 downto 0) of std_logic_vector(16 - 1 downto 0);
    type ty_para_17b is array (PARA - 1 downto 0) of std_logic_vector(17 - 1 downto 0);
    type ty_para_32b is array (PARA - 1 downto 0) of std_logic_vector(32 - 1 downto 0);
    type ty_para_33b is array (PARA - 1 downto 0) of std_logic_vector(33 - 1 downto 0);

    type ty_shf_16b      is array (80 - 1 downto 0) of std_logic_vector(16 - 1 downto 0);
    type ty_para_shf_16b is array (PARA - 1 downto 0) of ty_shf_16b;

    --### Interpolation ###
    signal itp_en        : std_logic := '0';
    signal itp_whiteNofs : ty_para_16b := (others => (others => '0'));
    signal itp_whiteavg  : std_logic_vector(16 - 1 downto 0) := (others => '0');
    signal itp_whitegain : ty_para_16b := (others => (others => '0'));

    signal itp_a     : ty_para_17b := (others => (others => '0'));
    signal itp_a_cut : ty_para_16b := (others => (others => '0'));

    signal itp_b0_en  : std_logic_vector(4 - 1 downto 0) := (others => '0');
    signal itp_b0     : ty_para_32b := (others => (others => '0'));
    signal itp_b0_cut : ty_para_16b := (others => (others => '0'));
    signal itp_b_en   : std_logic_vector(4 - 1 downto 0) := (others => '0');
    signal itp_b      : ty_para_17b := (others => (others => '0'));
    signal itp_b_cut  : ty_para_16b := (others => (others => '0'));

    signal shf_itp_a         : ty_para_shf_16b;
    signal shf_itp_whitegain : ty_para_shf_16b;

    signal itp_ab_en  : std_logic_vector(4 - 1 downto 0) := (others => '0');
    signal itp_ab_en1 : std_logic_vector(4 - 1 downto 0) := (others => '0');
    signal itp_ab_en2 : std_logic_vector(4 - 1 downto 0) := (others => '0');
    signal itp_ab_en3 : std_logic_vector(4 - 1 downto 0) := (others => '0');
    signal itp_ab     : ty_para_32b := (others => (others => '0'));
    signal itp_ab_cut : ty_para_16b := (others => (others => '0'));

    signal itp_c : ty_para_17b := (others => (others => '0'));

    signal itp_abc    : ty_para_33b := (others => (others => '0'));
    signal itp_abc_en : std_logic_vector(4 - 1 downto 0) := (others => '0');

    signal itp_abcd    : ty_para_16b := (others => (others => '0'));
    signal itp_abcd_en : std_logic_vector(4 - 1 downto 0) := (others => '0');
    signal sreg_itp_en : std_logic;

    signal gain_sel : ty_para_16b := (others => (others => '0'));

    COMPONENT ila_10g_gain
    PORT (
        clk    : IN STD_LOGIC;
        probe0 : IN STD_LOGIC_VECTOR(63 DOWNTO 0);
        probe1 : IN STD_LOGIC_VECTOR(63 DOWNTO 0);
        probe2 : IN STD_LOGIC_VECTOR(71 DOWNTO 0);
        probe3 : IN STD_LOGIC_VECTOR(71 DOWNTO 0);
        probe4 : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
        probe5 : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
        probe6 : IN STD_LOGIC_VECTOR(11 DOWNTO 0);
        probe7 : IN STD_LOGIC_VECTOR(11 DOWNTO 0);
        probe8 : IN STD_LOGIC_VECTOR(63 DOWNTO 0)
    );
    END COMPONENT;

-- █▄▄ █▀▀ █▄░█
-- █▄█ █▄█ █░▀█ %bgn
begin
-- █▀█ █▀▀ █▀▀
-- █▀▄ ██▄ █▄█ %reg
    --# register shift and vsync latch process
    process (idata_clk)
    begin
        if (idata_clk'event and idata_clk = '1') then
            sreg_gain_cal_shft      <= sreg_gain_cal_shft(sreg_gain_cal_shft'left - 1 downto 1) & ireg_gain_cal;
            sreg_offset_cal_shft    <= sreg_offset_cal_shft(sreg_offset_cal_shft'left - 1 downto 1) & ireg_offset_cal;
            sreg_mpc_ctrl_shft      <= sreg_mpc_ctrl_shft(sreg_mpc_ctrl_shft'left - 1 downto 1) & ireg_mpc_ctrl;
            sreg_mpc_num_shft       <= sreg_mpc_num_shft(sreg_mpc_num_shft'left - 1 downto 1) & ireg_mpc_num;
            sreg_mpc_point0_shft    <= sreg_mpc_point0_shft(sreg_mpc_point0_shft'left - 1 downto 1) & ireg_mpc_point0;
--          sreg_mpc_point1_shft    <= sreg_mpc_point1_shft(sreg_mpc_point1_shft'left - 1 downto 1) & ireg_mpc_point1;
--          sreg_mpc_point2_shft    <= sreg_mpc_point2_shft(sreg_mpc_point2_shft'left - 1 downto 1) & ireg_mpc_point2;
--          sreg_mpc_point3_shft    <= sreg_mpc_point3_shft(sreg_mpc_point3_shft'left - 1 downto 1) & ireg_mpc_point3;
            sreg_mpc_posoffset_shft <= sreg_mpc_posoffset_shft(sreg_mpc_posoffset_shft'left - 1 downto 1) & ireg_mpc_posoffset;
--          sd2m_xray_shft          <= sd2m_xray_shft(sd2m_xray_shft'left - 1 downto 1) & id2m_xray;
--          sd2m_dark_shft          <= sd2m_dark_shft(sd2m_dark_shft'left - 1 downto 1) & id2m_dark;

            -- # vsync latch
            if (svsync_shft(1) = '0') then
                sgain_cal   <= sreg_gain_cal_shft(sreg_gain_cal_shft'left);
                soffset_cal <= sreg_offset_cal_shft(sreg_offset_cal_shft'left);
            end if;
            smpc_ctrl          <= sreg_mpc_ctrl_shft(sreg_mpc_ctrl_shft'left);
            smpc_num           <= sreg_mpc_num_shft(sreg_mpc_num_shft'left);
            smpc_point0        <= sreg_mpc_point0_shft(sreg_mpc_point0_shft'left);
--          smpc_point1        <= sreg_mpc_point1_shft(sreg_mpc_point1_shft'left);
--          smpc_point2        <= sreg_mpc_point2_shft(sreg_mpc_point2_shft'left);
--          smpc_point3        <= sreg_mpc_point3_shft(sreg_mpc_point3_shft'left);
            sreg_mpc_posoffset <= sreg_mpc_posoffset_shft(sreg_mpc_posoffset_shft'left);
--          sd2m_xray          <= sd2m_xray_shft(sd2m_xray_shft'left);
--          sd2m_dark          <= sd2m_dark_shft(sd2m_dark_shft'left);

            -- ### rename
            sreg_Ref0MinusEn <= smpc_ctrl(0) or sd2m_dark;  -- d2 dark = offset enable , 210629
            sreg_mpc_bypss   <= smpc_ctrl(1) or sd2m_xray;  -- d2 xray data gonna bypass.
            sreg_dark_sel    <= smpc_ctrl(2);                -- debug
--          sreg_xray_sel    <= smpc_ctrl(3);                -- debug
            sreg_itp_en      <= smpc_ctrl(3);                -- #230130
--          sreg_D2DarkXraySel <= sd2m_dark;                 -- d2 xray <= ddr, dark <= current
        end if;
    end process;

-- █ █▄░█ ▄▄ █▀█ █▀▀ █▀▀
-- █ █░▀█ ░░ █▀▄ ██▄ █▀░

    offs <= iavg_rinfo;

--   offset = gainoffset6bit msb & offset10bit
--   gain   = gainoffset4bit lsb & gain12bit

--# offset 10bit
--offs   <= b"00_0000" & iavg_rinfo(16*3+10-1 downto 16*3) &
--          b"00_0000" & iavg_rinfo(16*2+10-1 downto 16*2) &
--          b"00_0000" & iavg_rinfo(16*1+10-1 downto 16*1) &
--          b"00_0000" & iavg_rinfo(16*0+10-1 downto 16*0) ;
--# gain 12bit << 2
--gain   <=  "00" & itpc_rdata(16*3+12-1 downto 16*3) & "00" &
--           "00" & itpc_rdata(16*2+12-1 downto 16*2) & "00" &
--           "00" & itpc_rdata(16*1+12-1 downto 16*1) & "00" &
--           "00" & itpc_rdata(16*0+12-1 downto 16*0) & "00" ;
    gain <= itpc_rdata(32 * 4 - 1 downto 32 * 3 + 16) &
            itpc_rdata(32 * 3 - 1 downto 32 * 2 + 16) &
            itpc_rdata(32 * 2 - 1 downto 32 * 1 + 16) &
            itpc_rdata(32 * 1 - 1 downto 32 * 0 + 16);

--   gain_offset = 6'b0 & gainoffset6bit & gainoffset4bit
--goff   <=  iavg_rinfo(63) & iavg_rinfo(63) & iavg_rinfo(63) & iavg_rinfo(63) & iavg_rinfo(63) & iavg_rinfo(63) & iavg_rinfo(16*3+16-1 downto 16*3+10) & itpc_rdata(16*3+16-1 downto 16*3+12) &
--           iavg_rinfo(47) & iavg_rinfo(47) & iavg_rinfo(47) & iavg_rinfo(47) & iavg_rinfo(47) & iavg_rinfo(47) & iavg_rinfo(16*2+16-1 downto 16*2+10) & itpc_rdata(16*2+16-1 downto 16*2+12) &
--           iavg_rinfo(32) & iavg_rinfo(32) & iavg_rinfo(32) & iavg_rinfo(32) & iavg_rinfo(32) & iavg_rinfo(32) & iavg_rinfo(16*1+16-1 downto 16*1+10) & itpc_rdata(16*1+16-1 downto 16*1+12) &
--           iavg_rinfo(16) & iavg_rinfo(16) & iavg_rinfo(16) & iavg_rinfo(16) & iavg_rinfo(16) & iavg_rinfo(16) & iavg_rinfo(16*0+16-1 downto 16*0+10) & itpc_rdata(16*0+16-1 downto 16*0+12) ;

--goff   <=  iavg_rinfo(63) & iavg_rinfo(63) & iavg_rinfo(63) & iavg_rinfo(63) & iavg_rinfo(63) & iavg_rinfo(63) & iavg_rinfo(16*3+16-1 downto 16*3+10) & itpc_rdata(16*3+16-1 downto 16*3+12) &
--           iavg_rinfo(47) & iavg_rinfo(47) & iavg_rinfo(47) & iavg_rinfo(47) & iavg_rinfo(47) & iavg_rinfo(47) & iavg_rinfo(16*2+16-1 downto 16*2+10) & itpc_rdata(16*2+16-1 downto 16*2+12) &
--           iavg_rinfo(32) & iavg_rinfo(32) & iavg_rinfo(32) & iavg_rinfo(32) & iavg_rinfo(32) & iavg_rinfo(32) & iavg_rinfo(16*1+16-1 downto 16*1+10) & itpc_rdata(16*1+16-1 downto 16*1+12) &
--           iavg_rinfo(16) & iavg_rinfo(16) & iavg_rinfo(16) & iavg_rinfo(16) & iavg_rinfo(16) & iavg_rinfo(16) & iavg_rinfo(16*0+16-1 downto 16*0+10) & itpc_rdata(16*0+16-1 downto 16*0+12) ;

    goff <= itpc_rdata(32 * 3 + 16 - 1 downto 32 * 3) &
            itpc_rdata(32 * 2 + 16 - 1 downto 32 * 2) &
            itpc_rdata(32 * 1 + 16 - 1 downto 32 * 1) &
            itpc_rdata(32 * 0 + 16 - 1 downto 32 * 0);

    --# video array shift and xray offset process
    process (idata_clk)
    begin
        if idata_clk'event and idata_clk = '1' then
        --
            -- ### in video array shift
            shsync_shft <= shsync_shft(shsync_shft'left - 1 downto 1) & ihsync;
            svsync_shft <= svsync_shft(svsync_shft'left - 1 downto 1) & ivsync;
            shcnt_shft  <= shcnt_shft(shcnt_shft'left - 1 downto 1) & ihcnt;
            svcnt_shft  <= svcnt_shft(svcnt_shft'left - 1 downto 1) & ivcnt;
            sdata_shft  <= sdata_shft(sdata_shft'left - 1 downto 1) & idata;
            soffs_shft  <= soffs_shft(soffs_shft'left - 1 downto 1) & offs;

            gain_shft <= gain_shft(gain_shft'left - 1 downto 1) & gain;
            goff_shft <= goff_shft(goff_shft'left - 1 downto 1) & goff;

            -- ▄█▄ █▀█ █▀▀ █▀▀ █▀ █▀▀ ▀█▀ █░█ █▀█ █▀█
            -- ░▀░ █▄█ █▀░ █▀░ ▄█ ██▄ ░█░ ▀▀█ █▄█ █▄█
            -- ### phase.3 : xray + offset
            -- b'17 <= '1'+b'16 + reg (default 400)
            xray_offset_3d(17 * 4 - 1 downto 17 * 3) <= '0' & sdata_shft(2)(16 * 4 - 1 downto 16 * 3) + sreg_mpc_posoffset;
            xray_offset_3d(17 * 3 - 1 downto 17 * 2) <= '0' & sdata_shft(2)(16 * 3 - 1 downto 16 * 2) + sreg_mpc_posoffset;
            xray_offset_3d(17 * 2 - 1 downto 17 * 1) <= '0' & sdata_shft(2)(16 * 2 - 1 downto 16 * 1) + sreg_mpc_posoffset;
            xray_offset_3d(17 * 1 - 1 downto 17 * 0) <= '0' & sdata_shft(2)(16 * 1 - 1 downto 16 * 0) + sreg_mpc_posoffset;

            -- ### phase.4 : xray bit cut
            xray_offcut_4d <= xray_offset_3d;
        --
        end if;
    end process;

    -- ### 17'b <=1d= 16'video - 16'ref_video
    GEN_SUB4 : for i in 0 to 3 generate
        U_SUB_U17_U16 : SUB_U17_U16 -- # 1 delay
            port map (
                CLK => idata_clk,
                A   => xray_offcut_4d(17 * (i + 1) - 1 downto 17 * i),
                B   => soffs_shft(4)(16 * (i + 1) - 1 downto 16 * i),
                S   => sXraySubRef_5d(18 * (i + 1) - 1 downto 18 * i)
            );

        --# xray subtraction bit cut process
        process (idata_clk)
        begin
            if idata_clk'event and idata_clk = '1' then
            --
                -- ### phase.6 : minus cut
                if sXraySubRef_5d(18 * (i + 1) - 1) = '1' then    -- minus to zero
                    sXraySubRef_cut_6d(16 * (i + 1) - 1 downto 16 * i) <= (others => '0');
                elsif sXraySubRef_5d(18 * (i + 1) - 2) = '1' then -- over 16b
                    sXraySubRef_cut_6d(16 * (i + 1) - 1 downto 16 * i) <= (others => '1');
                else
                    sXraySubRef_cut_6d(16 * (i + 1) - 1 downto 16 * i) <= sXraySubRef_5d(18 * (i + 1) - 3 downto 18 * i);
                end if;
            --
            end if;
        end process;
    end generate GEN_SUB4;

    --# subtraction select and shift process
    process (idata_clk)
    begin
        if idata_clk'event and idata_clk = '1' then
        --
            -- ### phase.7 : substraction select
            if sreg_dark_sel = '1' then              -- ### its for debug 210705
                sXraySubRef_sel_7d <= soffs_shft(6); -- ### its for debug
            elsif sreg_xray_sel = '1' then           -- ### its for debug
                sXraySubRef_sel_7d <= sdata_shft(6); -- ### its for debug
            elsif sreg_Ref0MinusEn = '1' then
                sXraySubRef_sel_7d <= sXraySubRef_cut_6d;
            else
                sXraySubRef_sel_7d <= sdata_shft(6);
            end if;

            -- ### phase.8
            sXraySubRef_8d <= sXraySubRef_sel_7d;

            -- ### shift
            sXraySubRef_shft <= sXraySubRef_shft(sXraySubRef_shft'left - 1 downto 9) & sXraySubRef_8d;
        --
        end if;
    end process;

--u_ila_1pgain : ila_1pgain
--PORT MAP (
--    clk       => idata_clk                             ,
--    probe0(0) => ihsync                                , -- 1b
--    probe1(0) => ivsync                                , -- 1b
--    probe2    => ihcnt                                 , -- 12b
--    probe3    => ivcnt                                 , -- 12b
--    probe4    => idata(16-1 downto 0)                  , -- 16b
--    probe5    => sXraySubRef_8d(16*(0+1)-1 downto 16*0), -- 16b
--    probe6    => gain_shft(8)(16*(0+1)-1 downto 16*0)  , -- 16b
--    probe7    => smulti_data_11d(0)                    , -- 32b
--    probe8    => sub_a_12d(0)                          , -- 18b
--    probe9    => sub_b_12d(0)                          , -- 18b
--    probe10   => ssub_data_14d(0)                      , -- 20b
--    probe11   => sdata_offset_cal_15d(0)                 -- 16b
--);

-- █▀▀ ▄▀█ █ █▄░█   ▀▄▀
-- █▄█ █▀█ █ █░▀█   █░█ %gainx

    gen4_nuc : for i in 0 to 4 - 1 generate
    begin

        U0_MULTI_16x16 : MULTI_16x16
            port map ( -- ### 3 Delay
                clk => idata_clk,
                ce  => idata_rstn,
                a   => sXraySubRef_8d(16 * (i + 1) - 1 downto 16 * i),
                b   => gain_shft(8)(16 * (i + 1) - 1 downto 16 * i),
                p   => smulti_data_11d(i)
            );

        -- ### phase 14<=11
        --# gain calibration bit cut and shift process
        process (idata_clk)
        begin
            if (idata_clk'event and idata_clk = '1') then

                --# phase 12<=11
                --# in 32b, cut 12b, get 16b
                if (sgain_cal = '1') then
                    if smulti_data_11d(i)(32 - 1 downto 28) > 0 then
                        sdata_gain_cal_12d(i) <= (others => '1');
                    else
                        sdata_gain_cal_12d(i) <= smulti_data_11d(i)(16 + 12 - 1 downto 12) +
                                                 smulti_data_11d(i)(11); --# 0.5 round
                    end if;
                else
                    sdata_gain_cal_12d(i) <= sXraySubRef_shft(11)(16 * (i + 1) - 1 downto 16 * i);
                end if;

                sdata_gain_cal_13d(i) <= sdata_gain_cal_12d(i);
                sdata_gain_cal_14d(i) <= sdata_gain_cal_13d(i);

            end if;
        end process;

        sub_a_12d(i) <= "00" & sdata_gain_cal_12d(i);
        sub_b_12d(i) <= goff_shft(12)(16 * (i + 1) - 1) &
                        goff_shft(12)(16 * (i + 1) - 1) &
                        goff_shft(12)(16 * (i + 1) - 1 downto 16 * i);

        U0_SUB_18x18 : SUB_18x18 -- 2 Delay
            port map (
                clk => idata_clk,
                ce  => idata_rstn,
                a   => sub_a_12d(i),
                b   => sub_b_12d(i),
                s   => ssub_data_14d(i)
            );

        -- 6b to 18

        --# offset calibration result cut process (async->sync reset)
        process (idata_clk)
        begin
            if (idata_clk'event and idata_clk = '1') then
                if (idata_rstn = '0') then
                    sdata_offset_cal_15d(i) <= (others => '0');
                else
                    -- ### sub result 18b -> 20 for overflow mbh 201215
                    if (soffset_cal = '1') then
                        if (ssub_data_14d(i)(19) = '1') then                  -- # miunus
                            sdata_offset_cal_15d(i) <= (others => '0');
                        elsif (ssub_data_14d(i)(18) = '1' or
                               ssub_data_14d(i)(17) = '1' or
                               ssub_data_14d(i)(16) = '1') then               -- # over
                            sdata_offset_cal_15d(i) <= x"FFFF";
                        else
                            sdata_offset_cal_15d(i) <= ssub_data_14d(i)(16 - 1 downto 0);
                        end if;
                    else
                        sdata_offset_cal_15d(i) <= sdata_gain_cal_14d(i);
                    end if;
                end if;
            end if;
        end process;

    end generate gen4_nuc;

-- █▀█ █░█ ▀█▀
-- █▄█ █▄█ ░█░ %out
    -- ### 16d <= 15d
    --# output mux process (async->sync reset)
    process (idata_clk)
    begin
        if (idata_clk'event and idata_clk = '1') then
            if (idata_rstn = '0') then
                shsync_out <= '0';
                svsync_out <= '0';
                svcnt_out  <= (others => '0');
                shcnt_out  <= (others => '0');
                sdata_out  <= (others => '0');
            else
                if sreg_mpc_bypss = '1' then -- :bypass
                    shsync_out <= shsync_shft(15);
                    svsync_out <= svsync_shft(15);
                    shcnt_out  <= shcnt_shft(15);
                    svcnt_out  <= svcnt_shft(15);
                    sdata_out  <= sdata_shft(15); -- :indata
                else
                    shsync_out <= shsync_shft(15);
                    svsync_out <= svsync_shft(15);
                    shcnt_out  <= shcnt_shft(15);
                    svcnt_out  <= svcnt_shft(15);
                    sdata_out  <= sdata_offset_cal_15d(3) &
                                  sdata_offset_cal_15d(2) &
                                  sdata_offset_cal_15d(1) &
                                  sdata_offset_cal_15d(0);
                end if;
            end if;
        end if;
    end process;

    ohsync <= shsync_out;
    ovsync <= svsync_out;
    ovcnt  <= svcnt_out;
    ohcnt  <= shcnt_out;
    odata  <= sdata_out;

---- u_ila_10g_gain : ila_10g_gain
----PORT MAP (
----	clk      => idata_clk,
----	probe0   => sXraySubRef_8d, --64
----	probe1   => gain_shft(8),   --64
--	probe2   => sub_a_12d(3) & sub_a_12d(2) & sub_a_12d(1) & sub_a_12d(0), --18*4 72 gain sub
--	probe3   => sub_b_12d(3) & sub_b_12d(2) & sub_b_12d(1) & sub_b_12d(0), --72
--	probe4(0)=> shsync_out, -- 1
--	probe5(0)=> svsync_out, -- 1
--	probe6   => shcnt_out , -- 12
--	probe7   => svcnt_out , -- 12
--	probe8   => sdata_out   -- 64 --16
--);

-- █▀▄ █▄▄ █▀▀
-- █▄▀ █▄█ █▄█ %dbg debug
-- ILA_DEBUG1 : if(GEN_ILA_tpc_proc = "ON") generate
--
-- begin

--u_ila_gain_para4 : ila_gain_para4
--PORT MAP (
--    clk                        => idata_clk,
--    probe0(0)                  => shsync_shft(1),
--    probe1(0)                  => svsync_shft(1),
--    probe2                     => shcnt_shft (1),
--    probe3                     => svcnt_shft (1),
--    probe4                     => sdata_shft (1)(64-1 downto 0),
--    probe5                     => live_data_1d  (64-1 downto 0),
--    probe6                     => dark_data_4d  (64-1 downto 0),
--    probe7(16*1-1 downto 16*0) => xray_offcut_4d(17*1-2 downto 17*0),
--    probe7(16*2-1 downto 16*1) => xray_offcut_4d(17*2-2 downto 17*1),
--    probe7(16*3-1 downto 16*2) => xray_offcut_4d(17*3-2 downto 17*2),
--    probe7(16*4-1 downto 16*3) => xray_offcut_4d(17*4-2 downto 17*3),
--    probe8                     => sXraySubRef_8d(64-1 downto 0)
--);

-- end generate ILA_DEBUG1;

end architecture behavioral;
