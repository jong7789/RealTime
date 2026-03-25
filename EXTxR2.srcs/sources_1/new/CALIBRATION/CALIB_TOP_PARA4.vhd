library IEEE;
    use IEEE.STD_LOGIC_1164.all;
    use IEEE.STD_LOGIC_UNSIGNED.all;
    use IEEE.STD_LOGIC_ARITH.all;
    use WORK.TOP_HEADER.all;

entity CALIB_TOP_PARA4 is
    generic (
        GNR_MODEL : string := "EXT1616R"
    );
    port (
        isys_clk              : in std_logic;
        idata_clk             : in std_logic;
        idata_rstn            : in std_logic;

        ireg_debug_mode       : in std_logic;
        ireg_gain_cal         : in std_logic;
        ireg_offset_cal       : in std_logic;
        ireg_defect_mode      : in std_logic;
        ireg_ldefect_mode     : in std_logic;
        ireg_defect_map       : in std_logic;

        ireg_mpc_ctrl         : in std_logic_vector(3 downto 0);
        ireg_mpc_num          : in std_logic_vector(3 downto 0);
        ireg_mpc_point0       : in std_logic_vector(15 downto 0);
        ireg_mpc_point1       : in std_logic_vector(15 downto 0);
        ireg_mpc_point2       : in std_logic_vector(15 downto 0);
        ireg_mpc_point3       : in std_logic_vector(15 downto 0);
        ireg_mpc_posoffset    : in std_logic_vector(16 - 1 downto 0);

        ireg_rdefect_wen      : in std_logic;
        ireg_rdefect_addr     : in std_logic_vector(3 downto 0);
        ireg_rdefect_wdata    : in std_logic_vector(15 downto 0); -- news en 210817mbh
        oreg_rdefect_rdata    : out std_logic_vector(15 downto 0);
        ireg_cdefect_wen      : in std_logic;
        ireg_cdefect_addr     : in std_logic_vector(3 downto 0);
        ireg_cdefect_wdata    : in std_logic_vector(15 downto 0); -- news en 210817mbh
        oreg_cdefect_rdata    : out std_logic_vector(15 downto 0);
        ireg_defect_wen       : in std_logic;
        ireg_defect_addr      : in std_logic_vector(15 downto 0);
        ireg_defect_wdata     : in std_logic_vector(31 downto 0);
        oreg_defect_rdata     : out std_logic_vector(31 downto 0);
        ireg_defect2_wen      : in std_logic;
        ireg_defect2_addr     : in std_logic_vector(15 downto 0);
        ireg_defect2_wdata    : in std_logic_vector(31 downto 0);
        oreg_defect2_rdata    : out std_logic_vector(31 downto 0);

        ireg_dgain            : in std_logic_vector(10 downto 0);
        ireg_avg_en           : in std_logic;
        ireg_avg_level        : in std_logic_vector(3 downto 0);
        oreg_avg_end          : out std_logic_vector(15 downto 0);

        ireg_width            : in std_logic_vector(11 downto 0);
        ireg_height           : in std_logic_vector(11 downto 0);

        ireg_AccCtrl          : in std_logic_vector(15 downto 0);
        oreg_AccStat          : out std_logic_vector(16 - 1 downto 0);

--        itpc_rdata             : in std_logic_vector(64-1 downto 0);
        itpc_rdata            : in std_logic_vector(128 - 1 downto 0);
        iavg_rinfo            : in std_logic_vector(64 - 1 downto 0);
        iofs_rinfo            : in std_logic_vector(64 - 1 downto 0);
        iacc_rdata            : in std_logic_vector(64 - 1 downto 0);

        id2m_xray             : in std_logic;
        id2m_dark             : in std_logic;
        iExtTrig_Srst         : in std_logic;
        ireg_shutter          : in std_logic;

        oavg_wen              : out std_logic;
        oavg_waddr            : out std_logic_vector(11 downto 0);
        oavg_winfo            : out std_logic_vector(64 - 1 downto 0);
        oavg_wvcnt            : out std_logic_vector(11 downto 0);

        oacc_wen              : out std_logic;
        oacc_waddr            : out std_logic_vector(11 downto 0);
        oacc_wdata            : out std_logic_vector(64 - 1 downto 0);
        oacc_wvcnt            : out std_logic_vector(11 downto 0);

        o_chgdet_osd_en       : out std_logic;
        o_chgdet_osd_da       : out std_logic_vector(16 - 1 downto 0);

        ireg_sync_ctrl        : in  std_logic_vector(31 downto 0);
        oreg_sync_rcnt4       : out std_logic_vector(31 downto 0);
        oreg_sync_rcnt5       : out std_logic_vector(31 downto 0);
        oreg_sync_rcnt6       : out std_logic_vector(31 downto 0);
        oreg_sync_rdata_AVCN4 : out std_logic_vector(31 downto 0);
        oreg_sync_rdata_AVCN5 : out std_logic_vector(31 downto 0);
        oreg_sync_rdata_AVCN6 : out std_logic_vector(31 downto 0);
        oreg_sync_rdata_BGLW4 : out std_logic_vector(31 downto 0);
        oreg_sync_rdata_BGLW5 : out std_logic_vector(31 downto 0);
        oreg_sync_rdata_BGLW6 : out std_logic_vector(31 downto 0);

        istate_tftd           : in tstate_tft;
        ostate_avg            : out tstate_avg;

        ihsync                : in std_logic;
        ivsync                : in std_logic;
        ihcnt                 : in std_logic_vector(11 downto 0);
        ivcnt                 : in std_logic_vector(11 downto 0);
        idata                 : in std_logic_vector(64 - 1 downto 0);

        ohsync                : out std_logic;
        ovsync                : out std_logic;
        ohcnt                 : out std_logic_vector(11 downto 0);
        ovcnt                 : out std_logic_vector(11 downto 0);
        odata                 : out std_logic_vector(64 - 1 downto 0)
    );
end entity CALIB_TOP_PARA4;

architecture behavioral of CALIB_TOP_PARA4 is

    component AVG_PROC_PARA4
        port (
            clk           : in  std_logic;
            rstn          : in  std_logic;

            i_reg_avg_en  : in  std_logic;
            i_reg_avg_lv  : in  std_logic_vector(4 - 1 downto 0);
            o_reg_avg_end : out std_logic_vector(16 - 1 downto 0);

            i_hsyn        : in  std_logic;
            i_vsyn        : in  std_logic;
            i_hcnt        : in  std_logic_vector(12 - 1 downto 0);
            i_vcnt        : in  std_logic_vector(12 - 1 downto 0);
            i_data        : in  std_logic_vector(64 - 1 downto 0);
            i_mdata       : in  std_logic_vector(64 - 1 downto 0);

            o_avg_wen     : out std_logic;
            o_avg_waddr   : out std_logic_vector(12 - 1 downto 0); --# hcnt
            o_avg_wvcnt   : out std_logic_vector(12 - 1 downto 0); --# vcnt
            o_avg_winfo   : out std_logic_vector(64 - 1 downto 0)
        );
    end component;

    component TPC_PROC
        port (
            idata_clk       : in std_logic;
            idata_rstn      : in std_logic;

            ireg_gain_cal   : in std_logic;
            ireg_offset_cal : in std_logic;

            ireg_mpc_ctrl   : in std_logic_vector(3 downto 0);
            ireg_mpc_num    : in std_logic_vector(3 downto 0);
            ireg_mpc_point0 : in std_logic_vector(15 downto 0);
            ireg_mpc_point1 : in std_logic_vector(15 downto 0);
            ireg_mpc_point2 : in std_logic_vector(15 downto 0);
            ireg_mpc_point3 : in std_logic_vector(15 downto 0);

            itpc_rdata      : in std_logic_vector(127 downto 0);
            iavg_rinfo      : in std_logic_vector(31 downto 0);

            ihsync          : in std_logic;
            ivsync          : in std_logic;
            ihcnt           : in std_logic_vector(11 downto 0);
            ivcnt           : in std_logic_vector(11 downto 0);
            idata           : in std_logic_vector(15 downto 0);

            ohsync          : out std_logic;
            ovsync          : out std_logic;
            ohcnt           : out std_logic_vector(11 downto 0);
            ovcnt           : out std_logic_vector(11 downto 0);
            odata           : out std_logic_vector(23 downto 0)
        );
    end component;

    component TPC_PROC_1418
        port (
            idata_clk          : in std_logic;
            idata_rstn         : in std_logic;

            ireg_gain_cal      : in std_logic;
            ireg_offset_cal    : in std_logic;

            ireg_mpc_ctrl      : in std_logic_vector(3 downto 0);
            ireg_mpc_num       : in std_logic_vector(3 downto 0);
            ireg_mpc_point0    : in std_logic_vector(15 downto 0);
            ireg_mpc_point1    : in std_logic_vector(15 downto 0);
            ireg_mpc_point2    : in std_logic_vector(15 downto 0);
            ireg_mpc_point3    : in std_logic_vector(15 downto 0);
            ireg_mpc_posoffset : in std_logic_vector(16 - 1 downto 0);
            id2m_xray          : in std_logic;
            id2m_dark          : in std_logic;

            itpc_rdata         : in std_logic_vector(127 downto 0);
            iavg_rinfo         : in std_logic_vector(31 downto 0);
            iofs_rinfo         : in std_logic_vector(31 downto 0);

            ihsync             : in std_logic;
            ivsync             : in std_logic;
            ihcnt              : in std_logic_vector(11 downto 0);
            ivcnt              : in std_logic_vector(11 downto 0);
            idata              : in std_logic_vector(15 downto 0);

            ohsync             : out std_logic;
            ovsync             : out std_logic;
            ohcnt              : out std_logic_vector(11 downto 0);
            ovcnt              : out std_logic_vector(11 downto 0);
            odata              : out std_logic_vector(23 downto 0)
        );
    end component;

    component TPC_PROC_PARA4
        port (
            idata_clk       : in std_logic;
            idata_rstn      : in std_logic;

            ireg_gain_cal   : in std_logic;
            ireg_offset_cal : in std_logic;

            --* GCAL POINT AREA
            ireg_mpc_ctrl      : in std_logic_vector(3 downto 0);
            ireg_mpc_num       : in std_logic_vector(3 downto 0);
            ireg_mpc_point0    : in std_logic_vector(15 downto 0);
    --      ireg_mpc_point1    : in std_logic_vector(15 downto 0);
    --      ireg_mpc_point2    : in std_logic_vector(15 downto 0);
    --      ireg_mpc_point3    : in std_logic_vector(15 downto 0);
            ireg_mpc_posoffset : in std_logic_vector(16 - 1 downto 0);
    --      id2m_xray          : in std_logic;
    --      id2m_dark          : in std_logic;

            --* FROM. DDR3_TOP
--            itpc_rdata : in  std_logic_vector(64-1 downto 0);
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
    end component;

    component ACC_PROC is
        port (
            i_clk            : in std_logic;

            i_reg_width      : in std_logic_vector(11 downto 0);
            i_reg_height     : in std_logic_vector(11 downto 0);
            i_regAccCtrl     : in std_logic_vector(16 - 1 downto 0);
            o_regAccStat     : out std_logic_vector(16 - 1 downto 0);

            i_MmrHsyn        : in std_logic;
            i_MmrVsyn        : in std_logic;
            i_MmrVcnt        : in std_logic_vector(12 - 1 downto 0);
            i_MmrHcnt        : in std_logic_vector(12 - 1 downto 0);
            i_MmrData        : in std_logic_vector(16 - 1 downto 0);

            i_LivHsyn        : in std_logic;
            i_LivVsyn        : in std_logic;
            i_LivVcnt        : in std_logic_vector(12 - 1 downto 0);
            i_LivHcnt        : in std_logic_vector(12 - 1 downto 0);
            i_LivData        : in std_logic_vector(16 - 1 downto 0);

            oacc_wen         : out std_logic;
            oacc_waddr       : out std_logic_vector(11 downto 0);
            oacc_wdata       : out std_logic_vector(15 downto 0);
            oacc_wvcnt       : out std_logic_vector(11 downto 0);

            o_chgdet_osd_en  : out std_logic;
            o_chgdet_osd_da  : out std_logic_vector(16 - 1 downto 0);

            o_hsyn           : out std_logic;
            o_vsyn           : out std_logic;
            o_vcnt           : out std_logic_vector(12 - 1 downto 0);
            o_hcnt           : out std_logic_vector(12 - 1 downto 0);
            o_data           : out std_logic_vector(16 - 1 downto 0)
        );
    end component acc_proc;

    component DGAIN_PROC
        port (
            idata_clk  : in std_logic;
            idata_rstn : in std_logic;

            ireg_dgain : in std_logic_vector(10 downto 0);

            ihsync     : in std_logic;
            ivsync     : in std_logic;
            ihcnt      : in std_logic_vector(11 downto 0);
            ivcnt      : in std_logic_vector(11 downto 0);
            idata      : in std_logic_vector(23 downto 0);

            ohsync     : out std_logic;
            ovsync     : out std_logic;
            ohcnt      : out std_logic_vector(11 downto 0);
            ovcnt      : out std_logic_vector(11 downto 0);
            odata      : out std_logic_vector(15 downto 0)
        );
    end component;

    component DEFECT_PROC
        port (
            idata_clk         : in std_logic;
            idata_rstn        : in std_logic;

            ireg_debug_mode   : in std_logic;
            ireg_defect_map   : in std_logic;

            ireg_defect_mode  : in std_logic;
            ireg_defect_wen   : in std_logic;
            ireg_defect_addr  : in std_logic_vector(15 downto 0);
            ireg_defect_wdata : in std_logic_vector(31 downto 0);
            oreg_defect_rdata : out std_logic_vector(31 downto 0);

            ireg_width        : in std_logic_vector(11 downto 0);
            ireg_height       : in std_logic_vector(11 downto 0);

            ihsync            : in std_logic;
            ivsync            : in std_logic;
            ihcnt             : in std_logic_vector(11 downto 0);
            ivcnt             : in std_logic_vector(11 downto 0);
            idata             : in std_logic_vector(15 downto 0);

            ohsync            : out std_logic;
            ovsync            : out std_logic;
            ohcnt             : out std_logic_vector(11 downto 0);
            ovcnt             : out std_logic_vector(11 downto 0);
            odata             : out std_logic_vector(15 downto 0)
        );
    end component;

    component DEFECT_PROC_PARA4
        port (
            clk                : in  std_logic;
            rstn               : in  std_logic;

            i_reg_debug_mode   : in  std_logic;
            i_reg_defect_map   : in  std_logic;

            i_reg_defect_mode  : in  std_logic;
            i_reg_defect_wen   : in  std_logic;
            i_reg_defect_addr  : in  std_logic_vector(16 - 1 downto 0);
            i_reg_defect_wdata : in  std_logic_vector(32 - 1 downto 0);
            o_reg_defect_rdata : out std_logic_vector(32 - 1 downto 0);

            i_reg_linedefect_mode  : in  std_logic;
            i_reg_row_defect_wen   : in  std_logic;
            i_reg_row_defect_addr  : in  std_logic_vector(3 downto 0);
            i_reg_row_defect_wdata : in  std_logic_vector(15 downto 0);
            o_reg_row_defect_rdata : out std_logic_vector(15 downto 0);
            i_reg_col_defect_wen   : in  std_logic;
            i_reg_col_defect_addr  : in  std_logic_vector(3 downto 0);
            i_reg_col_defect_wdata : in  std_logic_vector(15 downto 0);
            o_reg_col_defect_rdata : out std_logic_vector(15 downto 0);

            i_reg_width  : in  std_logic_vector(12 - 1 downto 0);
            i_reg_height : in  std_logic_vector(12 - 1 downto 0);

            i_hsyn       : in  std_logic;
            i_vsyn       : in  std_logic;
            i_hcnt       : in  std_logic_vector(12 - 1 downto 0);
            i_vcnt       : in  std_logic_vector(12 - 1 downto 0);
            i_data       : in  std_logic_vector(64 - 1 downto 0);

            o_hsyn       : out std_logic;
            o_vsyn       : out std_logic;
            o_hcnt       : out std_logic_vector(12 - 1 downto 0);
            o_vcnt       : out std_logic_vector(12 - 1 downto 0);
            o_data       : out std_logic_vector(64 - 1 downto 0)
        );
    end component;

    component LINE_DEFECT_PROC
        generic (
            mode : string
        );
        port (
            idata_clk          : in std_logic;
            idata_rstn         : in std_logic;

            ireg_debug_mode    : in std_logic;
            ireg_defect_map    : in std_logic;

            ireg_ldefect_mode  : in std_logic;
            ireg_ldefect_wen   : in std_logic;
            ireg_ldefect_addr  : in std_logic_vector(3 downto 0);
            ireg_ldefect_wdata : in std_logic_vector(15 downto 0);
            oreg_ldefect_rdata : out std_logic_vector(15 downto 0);

            ireg_width         : in std_logic_vector(11 downto 0);
            ireg_height        : in std_logic_vector(11 downto 0);

            ihsync             : in std_logic;
            ivsync             : in std_logic;
            ihcnt              : in std_logic_vector(11 downto 0);
            ivcnt              : in std_logic_vector(11 downto 0);
            idata              : in std_logic_vector(15 downto 0);

            ohsync             : out std_logic;
            ovsync             : out std_logic;
            ohcnt              : out std_logic_vector(11 downto 0);
            ovcnt              : out std_logic_vector(11 downto 0);
            odata              : out std_logic_vector(15 downto 0)
        );
    end component;

    constant PARA : integer := 4;
    type ty_para_12b is array (PARA - 1 downto 0) of std_logic_vector(12 - 1 downto 0);
    type ty_para_16b is array (PARA - 1 downto 0) of std_logic_vector(16 - 1 downto 0);
    type ty_para_24b is array (PARA - 1 downto 0) of std_logic_vector(24 - 1 downto 0);

    signal shsync_tpc : std_logic;
    signal svsync_tpc : std_logic;
    signal shcnt_tpc  : std_logic_vector(11 downto 0);
    signal svcnt_tpc  : std_logic_vector(11 downto 0);
    signal sdata_tpc  : std_logic_vector(64 - 1 downto 0);

    signal shsync_dgain_tmp : std_logic;
    signal svsync_dgain_tmp : std_logic;
    signal shcnt_dgain_tmp  : std_logic_vector(11 downto 0);
    signal svcnt_dgain_tmp  : std_logic_vector(11 downto 0);
    signal sdata_dgain_tmp  : std_logic_vector(64 - 1 downto 0);

    signal shsync_dgain : std_logic;
    signal svsync_dgain : std_logic;
    signal shcnt_dgain  : std_logic_vector(11 downto 0);
    signal svcnt_dgain  : std_logic_vector(11 downto 0);
    signal sdata_dgain  : std_logic_vector(64 - 1 downto 0);

    signal shsyn_defect : std_logic;
    signal svsyn_defect : std_logic;
    signal shcnt_defect : std_logic_vector(11 downto 0);
    signal svcnt_defect : std_logic_vector(11 downto 0);
    signal sdata_defect : std_logic_vector(64 - 1 downto 0);

    signal shsync_cdefect : std_logic;
    signal svsync_cdefect : std_logic;
    signal shcnt_cdefect  : std_logic_vector(11 downto 0);
    signal svcnt_cdefect  : std_logic_vector(11 downto 0);
    signal sdata_cdefect  : std_logic_vector(64 - 1 downto 0);

    signal sdefect_map        : std_logic;
    signal sreg_defect_map_1d : std_logic;
    signal sreg_defect_map_2d : std_logic;
    signal sreg_defect_map_3d : std_logic;

    signal itpc_hsync : std_logic;
    signal itpc_vsync : std_logic;
    signal itpc_hcnt  : std_logic_vector(11 downto 0);
    signal itpc_vcnt  : std_logic_vector(11 downto 0);
    signal itpc_data  : std_logic_vector(64 - 1 downto 0);

    signal iavg_hsync : std_logic;
    signal iavg_vsync : std_logic;
    signal iavg_hcnt  : std_logic_vector(11 downto 0);
    signal iavg_vcnt  : std_logic_vector(11 downto 0);
    signal iavg_data  : std_logic_vector(64 - 1 downto 0);

    signal ihsync_d1 : std_logic;
    signal ivsync_d1 : std_logic;
    signal ihcnt_d1  : std_logic_vector(11 downto 0);
    signal ivcnt_d1  : std_logic_vector(11 downto 0);
    signal idata_d1  : std_logic_vector(64 - 1 downto 0);

--    signal itpc_rdata_d1 : std_logic_vector(64-1 downto 0);
    signal itpc_rdata_d1 : std_logic_vector(128 - 1 downto 0);
    signal iavg_rinfo_d1 : std_logic_vector(64 - 1 downto 0);
    signal iofs_rinfo_d1 : std_logic_vector(64 - 1 downto 0);

    signal sstate_tftd,
           sstate_tftd_d1,
           sstate_tftd_d2,
           sstate_tftd_d3 : tstate_tft;

    signal stream_tpc_en : std_logic;
    signal stream_avg_en : std_logic;
    signal ivsync0       : std_logic;

    signal sExtTrig_Srst,
           sExtTrig_Srst_d1,
           sExtTrig_Srst_d2,
           sExtTrig_Srst_d3 : std_logic;

    signal sreg_avg_end : std_logic_vector(15 downto 0);

    signal sreg_shutter_d1,
           sreg_shutter_d2,
           sreg_shutter_d3,
           sreg_shutter : std_logic;

    signal oreg_AccStat_p4    : ty_para_16b;
    signal oacc_wen_p4        : std_logic_vector(PARA - 1 downto 0);
    signal oacc_waddr_p4      : ty_para_12b;
    signal oacc_wdata_p4      : ty_para_16b;
    signal oacc_wvcnt_p4      : ty_para_12b;

    signal o_chgdet_osd_en_p4 : std_logic_vector(PARA - 1 downto 0);
    signal o_chgdet_osd_da_p4 : ty_para_16b;

    signal sAcc_hsyn_p4 : std_logic_vector(PARA - 1 downto 0);
    signal sAcc_vsyn_p4 : std_logic_vector(PARA - 1 downto 0);
    signal sAcc_vcnt_p4 : ty_para_12b;
    signal sAcc_hcnt_p4 : ty_para_12b;
    signal sAcc_data_p4 : ty_para_16b;

    signal sAcc_data_p4_24 : ty_para_24b;

    signal shsync_dgain_tmp_p4 : std_logic_vector(4 - 1 downto 0);
    signal svsync_dgain_tmp_p4 : std_logic_vector(4 - 1 downto 0);
    signal shcnt_dgain_tmp_p4  : ty_para_12b;
    signal svcnt_dgain_tmp_p4  : ty_para_12b;
    signal sdata_dgain_tmp_p4  : ty_para_16b;

-- █▄▄ █▀▀ █▀▀ █ █▄░█
-- █▄█ ██▄ █▄█ █ █░▀█
-- %begin
begin

    --# Stream control: shutter sync, input pipeline, trigger reset sync
    process (idata_clk) -- stream disable when serial reset 211020 mbh
    begin
        if (idata_clk'event and idata_clk = '1') then
            --
            sreg_shutter_d1 <= ireg_shutter;
            sreg_shutter_d2 <= sreg_shutter_d1;
            sreg_shutter_d3 <= sreg_shutter_d2;
            sreg_shutter    <= sreg_shutter_d3;

            ihsync_d1     <= ihsync;
            ivsync_d1     <= ivsync;
            ihcnt_d1      <= ihcnt;
            ivcnt_d1      <= ivcnt;
            idata_d1      <= idata;
            itpc_rdata_d1 <= itpc_rdata;
            iavg_rinfo_d1 <= iavg_rinfo;
            iofs_rinfo_d1 <= iofs_rinfo;

            ivsync0 <= ivsync;

            sExtTrig_Srst_d1 <= iExtTrig_Srst;
            sExtTrig_Srst_d2 <= sExtTrig_Srst_d1;
            sExtTrig_Srst_d3 <= sExtTrig_Srst_d2;
            sExtTrig_Srst    <= sExtTrig_Srst_d3;

            if sreg_shutter = '0' then -- rolling
                stream_avg_en <= '1';
            elsif ivsync0 = '0' and ivsync = '1' then -- its used global
                if sstate_tftd = s_SCAN then
                    stream_avg_en <= '1';
                elsif sstate_tftd = s_SRST and sExtTrig_Srst = '1' then
                    stream_avg_en <= '1';
                else
                    stream_avg_en <= '0';
                end if;
            end if;
            --
        end if;
    end process;

    iavg_hsync <= ihsync_d1 when stream_avg_en = '1' else '0';
    iavg_vsync <= ivsync_d1 when stream_avg_en = '1' else '0';
    iavg_hcnt  <= ihcnt_d1  when stream_avg_en = '1' else (others => '0');
    iavg_vcnt  <= ivcnt_d1  when stream_avg_en = '1' else (others => '0');
    iavg_data  <= idata_d1  when stream_avg_en = '1' else (others => '0');

-- ▄▀█ █░█ █▀▀
-- █▀█ ▀▄▀ █▄█
-- %avg
    U0_AVG_PROC : AVG_PROC_PARA4
    port map (
        clk           => idata_clk,
        rstn          => idata_rstn,

        i_reg_avg_en  => ireg_avg_en,
        i_reg_avg_lv  => ireg_avg_level,
        o_reg_avg_end => sreg_avg_end,

        i_hsyn        => iavg_hsync,
        i_vsyn        => iavg_vsync,
        i_hcnt        => iavg_hcnt,
        i_vcnt        => iavg_vcnt,
        i_data        => iavg_data,
        i_mdata       => iavg_rinfo_d1,

        o_avg_wen     => oavg_wen,
        o_avg_waddr   => oavg_waddr,
        o_avg_winfo   => oavg_winfo,
        o_avg_wvcnt   => oavg_wvcnt
    );
    oreg_avg_end <= sreg_avg_end;

    --# TPC stream enable control based on shutter mode and TFT state
    process (idata_clk) -- stream disable when serial reset 211020 mbh
    begin
        if (idata_clk'event and idata_clk = '1') then
            --
            sstate_tftd_d1 <= istate_tftd;
            sstate_tftd_d2 <= sstate_tftd_d1;
            sstate_tftd_d3 <= sstate_tftd_d2;
            sstate_tftd    <= sstate_tftd_d3;

            if sreg_shutter = '0' then -- rolling
                stream_tpc_en <= '1';
            elsif ivsync0 = '0' and ivsync = '1' then -- global
                if sstate_tftd = s_SCAN then
                    stream_tpc_en <= '1';
                else
                    stream_tpc_en <= '0';
                end if;
            end if;
            --
        end if;
    end process;
    -- probe_in0 <= stream_tpc_en;

    itpc_hsync <= ihsync_d1 when stream_tpc_en = '1' else '0';
    itpc_vsync <= ivsync_d1 when stream_tpc_en = '1' else '0';
    itpc_hcnt  <= ihcnt_d1  when stream_tpc_en = '1' else (others => '0');
    itpc_vcnt  <= ivcnt_d1  when stream_tpc_en = '1' else (others => '0');
    itpc_data  <= idata_d1  when stream_tpc_en = '1' else (others => '0');

-- █▀▀ ▄▀█ █ █▄░█
-- █▄█ █▀█ █ █░▀█
-- %gain
    U1_TPC_PROC : TPC_PROC_PARA4
    port map (
        idata_clk          => idata_clk,
        idata_rstn         => idata_rstn,

        ireg_gain_cal      => ireg_gain_cal,
        ireg_offset_cal    => ireg_offset_cal,

        ireg_mpc_ctrl      => ireg_mpc_ctrl,
        ireg_mpc_num       => ireg_mpc_num,
        ireg_mpc_point0    => ireg_mpc_point0,
--      ireg_mpc_point1    => ireg_mpc_point1,
--      ireg_mpc_point2    => ireg_mpc_point2,
--      ireg_mpc_point3    => ireg_mpc_point3,
        ireg_mpc_posoffset => ireg_mpc_posoffset,
--      id2m_dark          => id2m_dark,

        itpc_rdata         => itpc_rdata_d1,
        iavg_rinfo         => iavg_rinfo_d1,
--      iofs_rinfo         => iofs_rinfo_d1,

        ihsync             => itpc_hsync,
        ivsync             => itpc_vsync,
        ihcnt              => itpc_hcnt,
        ivcnt              => itpc_vcnt,
        idata              => itpc_data,

        ohsync             => shsync_tpc,
        ovsync             => svsync_tpc,
        ohcnt              => shcnt_tpc,
        ovcnt              => svcnt_tpc,
        odata              => sdata_tpc
    );

-- ▄▀█ █▀▀ █▀▀
-- █▀█ █▄▄ █▄▄
-- %acc
    GEN_ACC1 : if (GEN_ACC = '1') generate
        gen_acc4 : for i in 0 to 4 - 1 generate
            u_ACC_PROC : ACC_PROC
            port map (
                i_clk        => idata_clk,
                i_reg_width  => ireg_width,
                i_reg_height => ireg_height,
                i_regAccCtrl => ireg_AccCtrl,
                o_regAccStat => oreg_AccStat_p4(i),

                i_MmrHsyn    => ihsync,
                i_MmrVsyn    => ivsync,
                i_MmrHcnt    => ihcnt,
                i_MmrVcnt    => ivcnt,
                i_MmrData    => iacc_rdata(16 * (i + 1) - 1 downto 16 * i),

                i_LivHsyn    => shsync_tpc,
                i_LivVsyn    => svsync_tpc,
                i_LivHcnt    => shcnt_tpc,
                i_LivVcnt    => svcnt_tpc,
                i_LivData    => sdata_tpc(16 * (i + 1) - 1 downto 16 * i),

                oacc_wen        => oacc_wen_p4(i),
                oacc_waddr      => oacc_waddr_p4(i),
                oacc_wdata      => oacc_wdata_p4(i),
                oacc_wvcnt      => oacc_wvcnt_p4(i),

                o_chgdet_osd_en => o_chgdet_osd_en_p4(i),
                o_chgdet_osd_da => o_chgdet_osd_da_p4(i),

                o_hsyn          => sAcc_hsyn_p4(i),
                o_vsyn          => sAcc_vsyn_p4(i),
                o_hcnt          => sAcc_hcnt_p4(i),
                o_vcnt          => sAcc_vcnt_p4(i),
                o_data          => sAcc_data_p4(i)
            );

            sACC_data_p4_24(i) <= x"00" & sACC_data_p4(i);
        end generate gen_acc4;

        oreg_AccStat    <= oreg_AccStat_p4(0);
        oacc_wen        <= oacc_wen_p4(0);
        oacc_waddr      <= oacc_waddr_p4(0);
        oacc_wdata      <= oacc_wdata_p4(3) &
                           oacc_wdata_p4(2) &
                           oacc_wdata_p4(1) &
                           oacc_wdata_p4(0);
        oacc_wvcnt      <= oacc_wvcnt_p4(0);
        o_chgdet_osd_en <= o_chgdet_osd_en_p4(0);
        o_chgdet_osd_da <= o_chgdet_osd_da_p4(0);
--      sAcc_hsyn       <= sAcc_hsyn_p4(0);
--      sAcc_vsyn       <= sAcc_vsyn_p4(0);
--      sAcc_hcnt       <= sAcc_hcnt_p4(0);
--      sAcc_vcnt       <= sAcc_vcnt_p4(0);
--      sAcc_data       <= sAcc_data_p4(3) &
--                         sAcc_data_p4(2) &
--                         sAcc_data_p4(1) &
--                         sAcc_data_p4(0);

    end generate GEN_ACC1;

    --$ 251021 modify 2.5G -> 10G
    GEN_ACC0 : if (GEN_ACC = '0') generate
        gen_acc0_para4 : for i in 0 to 4 - 1 generate
            sAcc_hsyn_p4(i)    <= shsync_tpc;
            sAcc_vsyn_p4(i)    <= svsync_tpc;
            sAcc_hcnt_p4(i)    <= shcnt_tpc;
            sAcc_vcnt_p4(i)    <= svcnt_tpc;
            sAcc_data_p4(i)    <= sdata_tpc(16 * (i + 1) - 1 downto 16 * i);

            sACC_data_p4_24(i) <= x"00" & sACC_data_p4(i);
        end generate gen_acc0_para4;
    end generate GEN_ACC0;

-- █▀▄ █▀▀ ▄▀█ █ █▄░█
-- █▄▀ █▄█ █▀█ █ █░▀█
-- %dgain
    GEN_DGAIN1 : if (GEN_DGAIN = '1') generate
        gen_dgain4 : for i in 0 to 4 - 1 generate
            u_DGAIN_PROC : DGAIN_PROC
            port map (
                idata_clk  => idata_clk,
                idata_rstn => idata_rstn,

                ireg_dgain => ireg_dgain,

                ihsync     => sACC_hsyn_p4(i),
                ivsync     => sACC_vsyn_p4(i),
                ihcnt      => sACC_hcnt_p4(i),
                ivcnt      => sACC_vcnt_p4(i),
                idata      => sACC_data_p4_24(i),

                ohsync     => shsync_dgain_tmp_p4(i),
                ovsync     => svsync_dgain_tmp_p4(i),
                ohcnt      => shcnt_dgain_tmp_p4(i),
                ovcnt      => svcnt_dgain_tmp_p4(i),
                odata      => sdata_dgain_tmp_p4(i)
            );
        end generate gen_dgain4;

        shsync_dgain_tmp <= shsync_dgain_tmp_p4(0);
        svsync_dgain_tmp <= svsync_dgain_tmp_p4(0);
        shcnt_dgain_tmp  <= shcnt_dgain_tmp_p4(0);
        svcnt_dgain_tmp  <= svcnt_dgain_tmp_p4(0);
        sdata_dgain_tmp  <= sdata_dgain_tmp_p4(3) &
                            sdata_dgain_tmp_p4(2) &
                            sdata_dgain_tmp_p4(1) &
                            sdata_dgain_tmp_p4(0);
    end generate GEN_DGAIN1;

    --$ 251111 modify 2.5G -> 10G
    GEN_DGAIN0 : if (GEN_DGAIN = '0') generate
        shsync_dgain_tmp <= sACC_hsyn_p4(0);
        svsync_dgain_tmp <= sAcc_vsyn_p4(0);
        shcnt_dgain_tmp  <= sAcc_hcnt_p4(0);
        svcnt_dgain_tmp  <= sAcc_vcnt_p4(0);
        sdata_dgain_tmp  <= sAcc_data_p4(3) &
                            sAcc_data_p4(2) &
                            sAcc_data_p4(1) &
                            sAcc_data_p4(0);
    end generate GEN_DGAIN0;

-- U0_DGAIN_PROC : DGAIN_PROC
-- port map
-- (
--     idata_clk   => idata_clk,
--     idata_rstn  => idata_rstn,
--
--     ireg_dgain  => ireg_dgain,
--
--     ihsync      => sAcc_hsyn,
--     ivsync      => sAcc_vsyn,
--     ihcnt       => sAcc_hcnt,
--     ivcnt       => sAcc_vcnt,
--     idata       => sAcc_data,
--
--     ohsync      => shsync_dgain_tmp,
--     ovsync      => svsync_dgain_tmp,
--     ohcnt       => shcnt_dgain_tmp,
--     ovcnt       => svcnt_dgain_tmp,
--     odata       => sdata_dgain_tmp
-- );

-- shsync_dgain_tmp <= sAcc_hsyn;
-- svsync_dgain_tmp <= sAcc_vsyn;
-- shcnt_dgain_tmp  <= sAcc_hcnt;
-- svcnt_dgain_tmp  <= sAcc_vcnt;
-- sdata_dgain_tmp  <= sAcc_data;

    --# Sync defect_map register to vsync domain (async->sync reset converted)
    process (idata_clk)
    begin
        if (idata_clk'event and idata_clk = '1') then
            if (idata_rstn = '0') then
                sreg_defect_map_1d <= '0';
                sreg_defect_map_2d <= '0';
                sreg_defect_map_3d <= '0';
                sdefect_map        <= '0';
            else
                sreg_defect_map_1d <= ireg_defect_map;
                sreg_defect_map_2d <= sreg_defect_map_1d;
                sreg_defect_map_3d <= sreg_defect_map_2d;

                if (svsync_dgain_tmp = '0') then
                    sdefect_map <= sreg_defect_map_3d;
                end if;
            end if;
        end if;
    end process;

    --# Pipeline dgain output with defect_map blanking (async->sync reset converted)
    process (idata_clk)
    begin
        if (idata_clk'event and idata_clk = '1') then
            if (idata_rstn = '0') then
                shsync_dgain <= '0';
                svsync_dgain <= '0';
                shcnt_dgain  <= (others => '0');
                svcnt_dgain  <= (others => '0');
                sdata_dgain  <= (others => '0');
            else
                shsync_dgain <= shsync_dgain_tmp;
                svsync_dgain <= svsync_dgain_tmp;
                shcnt_dgain  <= shcnt_dgain_tmp;
                svcnt_dgain  <= svcnt_dgain_tmp;
                if (sdefect_map = '1') then
                    sdata_dgain <= (others => '0');
                else
                    sdata_dgain <= sdata_dgain_tmp;
                end if;
            end if;
        end if;
    end process;

-- █▀▄ █▀▀ █▀▀ █▀▀ █▀▀ ▀█▀
-- █▄▀ ██▄ █▀░ ██▄ █▄▄ ░█░
-- %defect
--U0_DEFECT_PROC : DEFECT_PROC
--    port map
--    (
--        idata_clk          => idata_clk,
--        idata_rstn         => idata_rstn,
--
--        ireg_debug_mode    => ireg_debug_mode,
--        ireg_defect_map    => ireg_defect_map,
--
--        ireg_defect_mode   => ireg_defect_mode,
--        ireg_defect_wen    => ireg_defect_wen,
--        ireg_defect_addr   => ireg_defect_addr,
--        ireg_defect_wdata  => ireg_defect_wdata,
--        oreg_defect_rdata  => oreg_defect_rdata,
--
--        ireg_width         => ireg_width,
--        ireg_height        => ireg_height,
--
--        ihsync             => shsync_dgain,
--        ivsync             => svsync_dgain,
--        ihcnt              => shcnt_dgain,
--        ivcnt              => svcnt_dgain,
--        idata              => sdata_dgain,
--
--        ohsync             => shsync_defect,
--        ovsync             => svsync_defect,
--        ohcnt              => shcnt_defect,
--        ovcnt              => svcnt_defect,
--        odata              => sdata_defect
--    );
--
--U1_DEFECT_PROC : DEFECT_PROC
--    port map
--    (
--        idata_clk          => idata_clk,
--        idata_rstn         => idata_rstn,
--
--        ireg_debug_mode    => ireg_debug_mode,
--        ireg_defect_map    => ireg_defect_map,
--
--        ireg_defect_mode   => ireg_defect_mode,
--        ireg_defect_wen    => ireg_defect2_wen,
--        ireg_defect_addr   => ireg_defect2_addr,
--        ireg_defect_wdata  => ireg_defect2_wdata,
--        oreg_defect_rdata  => oreg_defect2_rdata,
--
--        ireg_width         => ireg_width,
--        ireg_height        => ireg_height,
--
--        ihsync             => shsync_defect,
--        ivsync             => svsync_defect,
--        ihcnt              => shcnt_defect,
--        ivcnt              => svcnt_defect,
--        idata              => sdata_defect,
--
--        ohsync             => shsync_defect2,
--        ovsync             => svsync_defect2,
--        ohcnt              => shcnt_defect2,
--        ovcnt              => svcnt_defect2,
--        odata              => sdata_defect2
--    );
--
    GEN_DEFECT1 : if (GEN_DEFECT = '1') generate
        U1_DFCT_PARA4 : DEFECT_PROC_PARA4
        port map (
            clk                => idata_clk,
            rstn               => idata_rstn,

            i_reg_debug_mode   => ireg_debug_mode,
            i_reg_defect_map   => ireg_defect_map,

            i_reg_defect_mode  => ireg_defect_mode,
            i_reg_defect_wen   => ireg_defect2_wen,
            i_reg_defect_addr  => ireg_defect2_addr,
            i_reg_defect_wdata => ireg_defect2_wdata,
            o_reg_defect_rdata => oreg_defect2_rdata,

            i_reg_linedefect_mode  => ireg_ldefect_mode,
            i_reg_row_defect_wen   => ireg_rdefect_wen,
            i_reg_row_defect_addr  => ireg_rdefect_addr,
            i_reg_row_defect_wdata => ireg_rdefect_wdata,
            o_reg_row_defect_rdata => oreg_rdefect_rdata,
            i_reg_col_defect_wen   => ireg_cdefect_wen,
            i_reg_col_defect_addr  => ireg_cdefect_addr,
            i_reg_col_defect_wdata => ireg_cdefect_wdata,
            o_reg_col_defect_rdata => oreg_cdefect_rdata,

            i_reg_width  => ireg_width,
            i_reg_height => ireg_height,

            i_hsyn       => shsync_dgain,
            i_vsyn       => svsync_dgain,
            i_hcnt       => shcnt_dgain,
            i_vcnt       => svcnt_dgain,
            i_data       => sdata_dgain,

            o_hsyn       => shsyn_defect,
            o_vsyn       => svsyn_defect,
            o_hcnt       => shcnt_defect,
            o_vcnt       => svcnt_defect,
            o_data       => sdata_defect
        );
    end generate GEN_DEFECT1;

    GEN_DEFECT0 : if (GEN_DEFECT = '0') generate --$ 260122 GEN_DEFECT
        shsyn_defect <= shsync_dgain;
        svsyn_defect <= svsync_dgain;
        shcnt_defect <= shcnt_dgain;
        svcnt_defect <= svcnt_dgain;
        sdata_defect <= sdata_dgain;
    end generate GEN_DEFECT0;

--U0_ROW_DEFECT_PROC : LINE_DEFECT_PROC
--    generic map
--    (
--        mode => "ROW"
--    )
--    port map
--    (
--        idata_clk           => idata_clk,
--        idata_rstn          => idata_rstn,
--
--        ireg_debug_mode     => ireg_debug_mode,
--        ireg_defect_map     => ireg_defect_map,
--
--        ireg_ldefect_mode   => ireg_ldefect_mode,
--        ireg_ldefect_wen    => ireg_rdefect_wen,
--        ireg_ldefect_addr   => ireg_rdefect_addr,
--        ireg_ldefect_wdata  => ireg_rdefect_wdata,
--        oreg_ldefect_rdata  => oreg_rdefect_rdata,
--
--        ireg_width          => ireg_width,
--        ireg_height         => ireg_height,
--
--        ihsync              => shsync_defect2,
--        ivsync              => svsync_defect2,
--        ihcnt               => shcnt_defect2,
--        ivcnt               => svcnt_defect2,
--        idata               => sdata_defect2,
--
--        ohsync              => shsync_rdefect,
--        ovsync              => svsync_rdefect,
--        ohcnt               => shcnt_rdefect,
--        ovcnt               => svcnt_rdefect,
--        odata               => sdata_rdefect
--    );
--
--U1_COL_DEFECT_PROC : LINE_DEFECT_PROC
--    generic map
--    (
--        mode => "COL"
--    )
--    port map
--    (
--        idata_clk           => idata_clk,
--        idata_rstn          => idata_rstn,
--
--        ireg_debug_mode     => ireg_debug_mode,
--        ireg_defect_map     => ireg_defect_map,
--
--        ireg_ldefect_mode   => ireg_ldefect_mode,
--        ireg_ldefect_wen    => ireg_cdefect_wen,
--        ireg_ldefect_addr   => ireg_cdefect_addr,
--        ireg_ldefect_wdata  => ireg_cdefect_wdata,
--        oreg_ldefect_rdata  => oreg_cdefect_rdata,
--
--        ireg_width          => ireg_width,
--        ireg_height         => ireg_height,
--
--        ihsync              => shsync_rdefect,
--        ivsync              => svsync_rdefect,
--        ihcnt               => shcnt_rdefect,
--        ivcnt               => svcnt_rdefect,
--        idata               => sdata_rdefect,
--
--        ohsync              => shsync_cdefect,
--        ovsync              => svsync_cdefect,
--        ohcnt               => shcnt_cdefect,
--        ovcnt               => svcnt_cdefect,
--        odata               => sdata_cdefect
--    );

    shsync_cdefect <= shsyn_defect;
    svsync_cdefect <= svsyn_defect;
    shcnt_cdefect  <= shcnt_defect;
    svcnt_cdefect  <= svcnt_defect;
    sdata_cdefect  <= sdata_defect;

    ohsync <= shsync_cdefect;
    ovsync <= svsync_cdefect;
    ohcnt  <= shcnt_cdefect;
    ovcnt  <= svcnt_cdefect;
    odata  <= sdata_cdefect;

-- █▀▄ █▄▄ █▀▀
-- █▄▀ █▄█ █▄█
-- %dbg
    ILA_DEBUG_SYNC_COUNTER : if (GEN_SYNC_COUNTER = "ON") generate

        component sync_counter
            generic (
                sysclkhz : integer := 100_000_000;
                vio      : std_logic := '1';
                para     : integer -- := 4 -- 4 or 1
            );
            port (
                ISYSCLK        : in std_logic;

                ICLK           : in std_logic;
                IVSYNC         : in std_logic;
                IHSYNC         : in std_logic;
                IDATA          : in std_logic_vector(16 * para - 1 downto 0);
                IREG_CTRL      : in std_logic_vector(32 - 1 downto 0);
                OREG_CNT       : out std_logic_vector(32 - 1 downto 0);
                OREG_DATA_AvCn : out std_logic_vector(32 - 1 downto 0);
                OREG_DATA_BgLw : out std_logic_vector(32 - 1 downto 0)
            );
        end component sync_counter;

    begin
        -- ###############
        -- ### TPC OUT ###
        u_roic_sync_counter4 : sync_counter
        generic map (
            sysclkhz => CSYSCLKHZ,
            vio      => GEN_VIO_SYNC_COUNTER0,
            para     => 4
        )
        port map (
            ISYSCLK        => isys_clk,
            ICLK           => idata_clk,
            IVSYNC         => svsync_tpc,
            IHSYNC         => shsync_tpc,
            IDATA          => sdata_tpc,
            IREG_CTRL      => ireg_sync_ctrl,
            OREG_CNT       => oreg_sync_rcnt4,
            OREG_DATA_AvCn => oreg_sync_rdata_AVCN4,
            OREG_DATA_BgLw => oreg_sync_rdata_BGLW4
        );

        -- #################
        -- ### DGAIN OUT ###
        u_roic_sync_counter5 : sync_counter
        generic map (
            sysclkhz => CSYSCLKHZ,
            vio      => GEN_VIO_SYNC_COUNTER0,
            para     => 4
        )
        port map (
            ISYSCLK        => isys_clk,
            ICLK           => idata_clk,
            IVSYNC         => svsync_dgain,
            IHSYNC         => shsync_dgain,
            IDATA          => sdata_dgain,
            IREG_CTRL      => ireg_sync_ctrl,
            OREG_CNT       => oreg_sync_rcnt5,
            OREG_DATA_AvCn => oreg_sync_rdata_AVCN5,
            OREG_DATA_BgLw => oreg_sync_rdata_BGLW5
        );

        -- ######################
        -- ### Defect dot OUT ###
        u_roic_sync_counter6 : sync_counter
        generic map (
            sysclkhz => CSYSCLKHZ,
            vio      => GEN_VIO_SYNC_COUNTER1,
            para     => 4
        )
        port map (
            ISYSCLK        => isys_clk,
            ICLK           => idata_clk,
            IVSYNC         => svsyn_defect,
            IHSYNC         => shsyn_defect,
            IDATA          => sdata_defect,
            IREG_CTRL      => ireg_sync_ctrl,
            OREG_CNT       => oreg_sync_rcnt6,
            OREG_DATA_AvCn => oreg_sync_rdata_AVCN6,
            OREG_DATA_BgLw => oreg_sync_rdata_BGLW6
        );

    end generate ILA_DEBUG_SYNC_COUNTER;

    ila_debug : if (GEN_ILA_claib_top = "ON") generate

        component ila_calib_top0
            port (
                clk    : in std_logic;
                probe0 : in std_logic; -- _vector(0 downto 0);
                probe1 : in std_logic; -- _vector(0 downto 0);
                probe2 : in std_logic_vector(11 downto 0);
                probe3 : in std_logic_vector(11 downto 0);
                probe4 : in std_logic_vector(15 downto 0);
                probe5 : in std_logic; -- _vector(0 downto 0);
                probe6 : in std_logic; -- _vector(0 downto 0);
                probe7 : in std_logic_vector(11 downto 0);
                probe8 : in std_logic_vector(11 downto 0);
                probe9 : in std_logic_vector(15 downto 0)
            );
        end component;

    begin

        u_ila_calib_top0 : ila_calib_top0
        port map (
            clk    => idata_clk,
            probe0 => ihsync,         -- 1
            probe1 => ivsync,         -- 1
            probe2 => ihcnt,          -- 12
            probe3 => ivcnt,          -- 12
            probe4 => idata,          -- 16
            probe5 => shsync_cdefect, -- 1
            probe6 => svsync_cdefect, -- 1
            probe7 => shcnt_cdefect,  -- 12
            probe8 => svcnt_cdefect,  -- 12
            probe9 => sdata_cdefect   -- 16
        );

    end generate ila_debug;

end architecture behavioral;

--# Unused signals (removed from architecture declarations)
--# signal sAcc_hsyn       : std_logic;
--# signal sAcc_vsyn       : std_logic;
--# signal sAcc_hcnt       : std_logic_vector(11 downto 0);
--# signal sAcc_vcnt       : std_logic_vector(11 downto 0);
--# signal sAcc_data       : std_logic_vector(64-1 downto 0);
--# signal shsync_defect2  : std_logic;
--# signal svsync_defect2  : std_logic;
--# signal shcnt_defect2   : std_logic_vector(11 downto 0);
--# signal svcnt_defect2   : std_logic_vector(11 downto 0);
--# signal sdata_defect2   : std_logic_vector(64-1 downto 0);
--# signal shsync_rdefect  : std_logic;
--# signal svsync_rdefect  : std_logic;
--# signal shcnt_rdefect   : std_logic_vector(11 downto 0);
--# signal svcnt_rdefect   : std_logic_vector(11 downto 0);
--# signal sdata_rdefect   : std_logic_vector(64-1 downto 0);
--# signal sframe_cnt      : std_logic_vector(8-1 downto 0);
