----------------------------------------------------------------------------------
-- Company: DRTECH
-- Engineer: BHMoon
--
-- Create Date: 2021/12/06 14:41:33
-- Design Name:
-- Module Name: probe_top - Behavioral
-- Project Name:
-- Target Devices:
-- Tool Versions:
-- Description:
--
-- Dependencies:
--
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
----------------------------------------------------------------------------------

library IEEE;
    use IEEE.STD_LOGIC_1164.ALL;
    use IEEE.STD_LOGIC_UNSIGNED.ALL;
    use IEEE.STD_LOGIC_ARITH.ALL;

library UNISIM;
    use UNISIM.VCOMPONENTS.ALL;
    use WORK.TOP_HEADER.ALL;

entity probe_top is
    port (
        sys_clk    : in    std_logic;
        sbd_mclk   : in    std_logic;
        sbd_dclk   : in    std_logic;
        sui_clk    : in    std_logic;
        sroic_dclk : in    std_logic;
    --####################
    --### CLK COUNTER ###
        sreg_clk_mclk     : out   std_logic_vector(15 downto 0);
        sreg_clk_dclk     : out   std_logic_vector(15 downto 0);
        sreg_clk_roicdclk : out   std_logic_vector(15 downto 0);
        sreg_clk_uiclk    : out   std_logic_vector(15 downto 0);

    --####################
    --### SYNC COUNTER ###
        svsync_tft : in    std_logic;
        shsync_tft : in    std_logic;
        sdata_tft  : in    std_logic_vector(63 downto 0);

        svsync_ddr3 : in    std_logic;
        shsync_ddr3 : in    std_logic;
        sdata_ddr3  : in    std_logic_vector(15 downto 0);

        shsync_calib : in    std_logic;
        svsync_calib : in    std_logic;
        sdata_calib  : in    std_logic_vector(15 downto 0);

        shsync_img_proc : in    std_logic;
        svsync_img_proc : in    std_logic;
        sdata_img_proc  : in    std_logic_vector(15 downto 0);

        sfb_frame : in    std_logic;
        sfb_dv    : in    std_logic;
        sfb_data  : in    std_logic_vector(63 downto 0);

        sreg_sync_ctrl : in    std_logic_vector(31 downto 0);

        sreg_sync_rcnt2 : out   std_logic_vector(31 downto 0);
        sreg_sync_rcnt3 : out   std_logic_vector(31 downto 0);
        sreg_sync_rcnt7 : out   std_logic_vector(31 downto 0);
        sreg_sync_rcnt8 : out   std_logic_vector(31 downto 0);
        sreg_sync_rcnt9 : out   std_logic_vector(31 downto 0);

        sreg_sync_rdata_avcn2 : out   std_logic_vector(31 downto 0);
        sreg_sync_rdata_avcn3 : out   std_logic_vector(31 downto 0);
        sreg_sync_rdata_avcn7 : out   std_logic_vector(31 downto 0);
        sreg_sync_rdata_avcn8 : out   std_logic_vector(31 downto 0);
        sreg_sync_rdata_avcn9 : out   std_logic_vector(31 downto 0);

        sreg_sync_rdata_bglw2 : out   std_logic_vector(31 downto 0);
        sreg_sync_rdata_bglw3 : out   std_logic_vector(31 downto 0);
        sreg_sync_rdata_bglw7 : out   std_logic_vector(31 downto 0);
        sreg_sync_rdata_bglw8 : out   std_logic_vector(31 downto 0);
        sreg_sync_rdata_bglw9 : out   std_logic_vector(31 downto 0);

    --################
    --### SM PROBE ###
        oostate_tft              : in    tstate_tft;
        oostate_roic             : in    tstate_roic;
        oostate_gate             : in    tstate_gate;
        oostate_roic_setting     : in    tstate_roic_setting;
        oostate_dpram_data_align : in    tstate_dpram_data_align;
        oostate_dpram_roi        : in    tstate_dpram_roi;
        oostate_avg              : in    tstate_avg;
        oostate_grab             : in    tstate_grab;

        sroic_mclk_div : in    std_logic;
        sreg_sm_ctrl   : in    std_logic_vector(31 downto 0);
        sreg_sm_data0  : out   std_logic_vector(31 downto 0);
        sreg_sm_data1  : out   std_logic_vector(31 downto 0);
        sreg_sm_data2  : out   std_logic_vector(31 downto 0);
        sreg_sm_data3  : out   std_logic_vector(31 downto 0);
        sreg_sm_data4  : out   std_logic_vector(31 downto 0);
        sreg_sm_data5  : out   std_logic_vector(31 downto 0);
        sreg_sm_data6  : out   std_logic_vector(31 downto 0);
        sreg_sm_data7  : out   std_logic_vector(31 downto 0)
    );
end entity probe_top;

architecture behavioral of probe_top is

    component clk_counter
        generic (
            sysclkhz : integer := 100000000;
            vio      : std_logic  := '1'
        );
        port (
            ISYSCLK : in    std_logic; -- 100 Mhz
            ICLK    : in    std_logic;
            OCLKCNT : out   std_logic_vector(16 - 1 downto 0)
        );
    end component;

begin

    u_clk_counter0 : clk_counter
        generic map (
            sysclkhz => CSYSCLKHZ,
            vio      => GEN_VIO_CLK_COUNTER
        )
        port map (
            ISYSCLK => sys_clk, -- 100 Mhz
            ICLK    => sbd_mclk,
            OCLKCNT => sreg_clk_mclk
        );
    u_clk_counter1 : clk_counter
        generic map (
            sysclkhz => CSYSCLKHZ,
            vio      => GEN_VIO_CLK_COUNTER
        )
        port map (
            ISYSCLK => sys_clk, -- 100 Mhz
            ICLK    => sbd_dclk,
            OCLKCNT => sreg_clk_dclk
        );
    u_clk_counter2 : clk_counter
        generic map (
            sysclkhz => CSYSCLKHZ,
            vio      => GEN_VIO_CLK_COUNTER
        )
        port map (
            ISYSCLK => sys_clk, -- 100 Mhz
            ICLK    => sroic_dclk,
            OCLKCNT => sreg_clk_roicdclk
        );
    u_clk_counter3 : clk_counter
        generic map (
            sysclkhz => CSYSCLKHZ,
            vio      => GEN_VIO_CLK_COUNTER
        )
        port map (
            ISYSCLK => sys_clk, -- 100 Mhz
            ICLK    => sui_clk,
            OCLKCNT => sreg_clk_uiclk
        );

    ILA_DEBUG_SYNC_COUNTER : if(GEN_SYNC_COUNTER = "ON") generate

    component sync_counter
            generic (
                sysclkhz : integer   := 100_000_000;
                vio      : std_logic := '1';
                para     : integer   := 1
            );
        port (
            ISYSCLK : in    std_logic;

            ICLK           : in    std_logic;
            IVSYNC         : in    std_logic;
            IHSYNC         : in    std_logic;
            IDATA          : in    std_logic_vector(16 * para - 1 downto 0);
            IREG_CTRL      : in    std_logic_vector(32 - 1 downto 0);
            OREG_CNT       : out   std_logic_vector(32 - 1 downto 0);
            OREG_DATA_AvCn : out   std_logic_vector(32 - 1 downto 0);
            OREG_DATA_BgLw : out   std_logic_vector(32 - 1 downto 0)
        );
    end component sync_counter;

signal portm_64b_0 : std_logic_vector(64-1 downto 0);
begin

      -- ########################
      -- ##### sync counter #####

     -- ### TFT OUT ###
    u_sync_counter2 : sync_counter
        generic map (
            sysclkhz => CSYSCLKHZ,
            vio      => GEN_VIO_SYNC_COUNTER0,
            para     => 4
        )
        port map (
            ISYSCLK        => sys_clk,   -- 100 Mhz
            ICLK           => sui_clk,
            IVSYNC         => svsync_tft,
            IHSYNC         => shsync_tft,
            IDATA          => sdata_tft, -- (16-1 downto 0),
            IREG_CTRL      => sreg_sync_ctrl,
            OREG_CNT       => sreg_sync_rcnt2,
            OREG_DATA_AvCn => sreg_sync_rdata_avcn2,
            OREG_DATA_BgLw => sreg_sync_rdata_bglw2
        );

    -- ### DDR OUT ###
    u_sync_counter3 : sync_counter
        generic map (
            sysclkhz => CSYSCLKHZ,
            vio      => GEN_VIO_SYNC_COUNTER0,
            para     => 1
        )
        port map (
            ISYSCLK        => sys_clk,
            ICLK           => sui_clk,
            IVSYNC         => svsync_ddr3,
            IHSYNC         => shsync_ddr3,
            IDATA          => sdata_ddr3,
            IREG_CTRL      => sreg_sync_ctrl,
            OREG_CNT       => sreg_sync_rcnt3,
            OREG_DATA_AvCn => sreg_sync_rdata_avcn3,
            OREG_DATA_BgLw => sreg_sync_rdata_bglw3
        );

    -- ### CALIB OUT ###
    u_sync_counter7 : sync_counter
        generic map (
            sysclkhz => CSYSCLKHZ,
            vio      => GEN_VIO_SYNC_COUNTER1,
            para     => 1
        )
        port map (
            ISYSCLK        => sys_clk,
            ICLK           => sui_clk,
            IVSYNC         => svsync_calib,
            IHSYNC         => shsync_calib,
            IDATA          => sdata_calib,
            IREG_CTRL      => sreg_sync_ctrl,
            OREG_CNT       => sreg_sync_rcnt7,
            OREG_DATA_AvCn => sreg_sync_rdata_avcn7,
            OREG_DATA_BgLw => sreg_sync_rdata_bglw7
        );

    -- ### IMG PROC OUT ###
    u_sync_counter8 : sync_counter
        generic map (
            sysclkhz => CSYSCLKHZ,
            vio      => GEN_VIO_SYNC_COUNTER1,
            para     => 1
        )
        port map (
            ISYSCLK        => sys_clk,
            ICLK           => sui_clk,
            IVSYNC         => svsync_img_proc,
            IHSYNC         => shsync_img_proc,
            IDATA          => sdata_img_proc,
            IREG_CTRL      => sreg_sync_ctrl,
            OREG_CNT       => sreg_sync_rcnt8,
            OREG_DATA_AvCn => sreg_sync_rdata_avcn8,
            OREG_DATA_BgLw => sreg_sync_rdata_bglw8
        );

    -- ### IMG OUT ###
    portm_64b_0 <= 
               sfb_data(8 * 7 - 1 downto 8 * 6) &
               sfb_data(8 * 8 - 1 downto 8 * 7) &
               sfb_data(8 * 5 - 1 downto 8 * 4) &
               sfb_data(8 * 6 - 1 downto 8 * 5) &
               sfb_data(8 * 3 - 1 downto 8 * 2) &
               sfb_data(8 * 4 - 1 downto 8 * 3) &
               sfb_data(8 * 1 - 1 downto 8 * 0) &
               sfb_data(8 * 2 - 1 downto 8 * 1);
    u_sync_counter9 : sync_counter
        generic map (
            sysclkhz => CSYSCLKHZ,
            vio      => GEN_VIO_SYNC_COUNTER1,
            para     => 4
        )
        port map (
            ISYSCLK        => sys_clk,
            ICLK           => sui_clk,
            IVSYNC         => sfb_frame,
            IHSYNC         => sfb_dv,
            IDATA          => portm_64b_0,
            IREG_CTRL      => sreg_sync_ctrl,
            OREG_CNT       => sreg_sync_rcnt9,
            OREG_DATA_AvCn => sreg_sync_rdata_avcn9,
            OREG_DATA_BgLw => sreg_sync_rdata_bglw9
        );
end generate ila_debug_sync_counter;

ILA_DEBUG_SM_PROBE0 : if(GEN_SM_PROBE = "ON") generate

    component sm_probe is
        generic (
            sysclkhz : integer := 100_000_000;
            sm_bit   : integer := 4;
            sm_num   : integer := 9
        );
        port (
            ISYSCLK      : in    std_logic;
            ireg_sm_ctrl : in    std_logic_vector(32 - 1 downto 0);
            ireg_sm_data : out   std_logic_vector(32 - 1 downto 0);

            iclk : in    std_logic;
--      sm   : in   tstate_roic
            sm : in    std_logic_vector(sm_bit - 1 downto 0)
        );
    end component sm_probe;

    constant sysclkhz : integer := 100_000_000;
    signal   sm_temp0 : std_logic_vector(4 - 1 downto 0);
    signal   sm_temp1 : std_logic_vector(4 - 1 downto 0);
    signal   sm_temp2 : std_logic_vector(4 - 1 downto 0);

    signal sm_temp3 : std_logic_vector(4 - 1 downto 0);
    signal sm_temp4 : std_logic_vector(4 - 1 downto 0);
    signal sm_temp5 : std_logic_vector(4 - 1 downto 0);
    signal sm_temp6 : std_logic_vector(4 - 1 downto 0);
    signal sm_temp7 : std_logic_vector(4 - 1 downto 0);

begin

    sm_temp0 <= -- tstate_tft
                x"0" when oostate_tft = s_IDLE   else
                x"1" when oostate_tft = s_TRST   else
                x"2" when oostate_tft = s_SRST   else
                x"3" when oostate_tft = s_EWT   else
                x"4" when oostate_tft = s_SCAN   else
                x"5" when oostate_tft = s_FINISH else
                x"6" when oostate_tft = s_GRST   else
                x"7" when oostate_tft = s_RstFINISH  else
                x"8" when oostate_tft = s_ScanFrWait else
                x"9" when oostate_tft = s_RstFrWait  else
                x"A" when oostate_tft = s_SRST_EWT  else
                x"B" when oostate_tft = s_B   else
                x"C" when oostate_tft = s_C   else
                x"D" when oostate_tft = s_D   else
                x"E" when oostate_tft = s_Trig   else
                x"F" when oostate_tft = s_F   else
                (others=>'1');
    sm_temp1 <= -- tstate_roic
                x"0" when oostate_roic = s_IDLE    else
                x"1" when oostate_roic = s_OFFSET    else
                x"2" when oostate_roic = s_DUMMY    else
                x"3" when oostate_roic = s_INTRST    else
                x"4" when oostate_roic = s_CDS1    else
                x"5" when oostate_roic = s_GATE_OPEN else
                x"6" when oostate_roic = s_CDS2     else
                x"7" when oostate_roic = s_LDEAD     else
                x"8" when oostate_roic = s_FWAIT   else
                (others=>'1');
    sm_temp2 <= -- tstate_gate
                x"0" when oostate_gate = s_IDLE   else
                x"1" when oostate_gate = s_DUMMY    else
                x"2" when oostate_gate = s_READY    else
                x"3" when oostate_gate = s_DIO_CPV  else
                x"4" when oostate_gate = s_CPV       else
                x"5" when oostate_gate = s_XON       else
                x"6" when oostate_gate = s_OE       else
                x"7" when oostate_gate = s_XON_FLK  else
                x"8" when oostate_gate = s_FLK       else
                x"9" when oostate_gate = s_CHECK    else
                x"A" when oostate_gate = s_OE_READY else
                x"B" when oostate_gate = s_LWAIT    else
                x"C" when oostate_gate = s_FWAIT  else
                (others=>'1');
    sm_temp3 <= -- tstate_roic_setting
                x"0" when oostate_roic_setting = s_IDLE    else
                x"1" when oostate_roic_setting = s_READY   else
                x"2" when oostate_roic_setting = s_CS      else
                x"3" when oostate_roic_setting = s_DATA    else
                x"4" when oostate_roic_setting = s_WAIT    else
                x"5" when oostate_roic_setting = s_FINISH  else
                (others=>'1');
    sm_temp4 <= -- tstate_dpram_data_align
                x"0" when oostate_dpram_data_align = s_IDLE       else
                x"1" when oostate_dpram_data_align = s_READY      else
                x"2" when oostate_dpram_data_align = s_WAIT_ODD   else
                x"3" when oostate_dpram_data_align = s_DATA_ODD   else
                x"4" when oostate_dpram_data_align = s_WAIT_EVEN  else
                x"5" when oostate_dpram_data_align = s_DATA_EVEN  else
                (others=>'1');
    sm_temp5 <= -- tstate_dpram_roi
                x"0" when oostate_dpram_roi = s_IDLE  else
                x"1" when oostate_dpram_roi = s_WAIT  else
                x"2" when oostate_dpram_roi = s_DATA  else
                (others=>'1');
    sm_temp6 <= -- tstate_avg
                x"0" when oostate_avg = s_IDLE  else
                x"1" when oostate_avg = s_FWAIT else
                x"2" when oostate_avg = s_LWAIT else
                x"3" when oostate_avg = s_WAIT  else
                x"4" when oostate_avg = s_READY else
                x"5" when oostate_avg = s_AVG   else
                x"6" when oostate_avg = s_CHECK else
                (others=>'1');
    sm_temp7 <= -- tstate_grab
                x"0" when oostate_grab = s_IDLE else
                x"1" when oostate_grab = s_DATA else
                x"2" when oostate_grab = s_WAIT else
                (others=>'1');

    c_sm_probe0 : sm_probe
        generic map (
            sysclkhz => sysclkhz,
            sm_bit   => 4,
            sm_num   => 0
        )
        port map (
            ISYSCLK      => sys_clk,
            ireg_sm_ctrl => sreg_sm_ctrl,
            ireg_sm_data => sreg_sm_data0,
            iclk         => sroic_mclk_div,
            sm           => sm_temp0
        );
    c_sm_probe1 : sm_probe
        generic map (
            sysclkhz => sysclkhz,
            sm_bit   => 4,
            sm_num   => 1
        )
        port map (
            ISYSCLK      => sys_clk,
            ireg_sm_ctrl => sreg_sm_ctrl,
            ireg_sm_data => sreg_sm_data1,
            iclk         => sroic_mclk_div,
            sm           => sm_temp1
        );
    c_sm_probe2 : sm_probe
        generic map (
            sysclkhz => sysclkhz,
            sm_bit   => 4,
            sm_num   => 2
        )
        port map (
            ISYSCLK      => sys_clk,
            ireg_sm_ctrl => sreg_sm_ctrl,
            ireg_sm_data => sreg_sm_data2,
            iclk         => sroic_mclk_div,
            sm           => sm_temp2
        );
    c_sm_probe3 : sm_probe
        generic map (
            sysclkhz => sysclkhz,
            sm_bit   => 4,
            sm_num   => 3
        )
        port map (
            ISYSCLK      => sys_clk,
            ireg_sm_ctrl => sreg_sm_ctrl,
            ireg_sm_data => sreg_sm_data3,
            iclk         => sroic_mclk_div,
            sm           => sm_temp3
        );
    c_sm_probe4 : sm_probe
        generic map (
            sysclkhz => sysclkhz,
            sm_bit   => 4,
            sm_num   => 4
        )
        port map (
            ISYSCLK      => sys_clk,
            ireg_sm_ctrl => sreg_sm_ctrl,
            ireg_sm_data => sreg_sm_data4,
            iclk         => sroic_mclk_div,
            sm           => sm_temp4
        );
    c_sm_probe5 : sm_probe
        generic map (
            sysclkhz => sysclkhz,
            sm_bit   => 4,
            sm_num   => 5
        )
        port map (
            ISYSCLK      => sys_clk,
            ireg_sm_ctrl => sreg_sm_ctrl,
            ireg_sm_data => sreg_sm_data5,
            iclk         => sroic_mclk_div,
            sm           => sm_temp5
        );
    c_sm_probe6 : sm_probe
        generic map (
            sysclkhz => sysclkhz,
            sm_bit   => 4,
            sm_num   => 6
        )
        port map (
            ISYSCLK      => sys_clk,
            ireg_sm_ctrl => sreg_sm_ctrl,
            ireg_sm_data => sreg_sm_data6,
            iclk         => sroic_mclk_div,
            sm           => sm_temp6
        );
    c_sm_probe7 : sm_probe
        generic map (
            sysclkhz => sysclkhz,
            sm_bit   => 4,
            sm_num   => 7
        )
        port map (
            ISYSCLK      => sys_clk,
            ireg_sm_ctrl => sreg_sm_ctrl,
            ireg_sm_data => sreg_sm_data7,
            iclk         => sroic_mclk_div,
            sm           => sm_temp7
        );
end generate ila_debug_sm_probe0;

end architecture behavioral;
