library ieee;
    use ieee.std_logic_1164.all;
    use ieee.std_logic_unsigned.all;
    use ieee.std_logic_arith.all;
    use work.top_header.all;

entity REG_TOP is
  generic (
              GNR_MODEL                : string  := "EXT1616R" 
          );
    port (
        isys_clk  : in    std_logic;
        isys_rstn : in    std_logic;

        iepc_addr  : in    std_logic_vector(15 downto 0);
        iepc_wdata : in    std_logic_vector(31 downto 0);
        oepc_rdata : out   std_logic_vector(31 downto 0);
        iepc_cs_n  : in    std_logic;
        iepc_we_n  : in    std_logic;
        oepc_rdy   : out   std_logic;

        axil_reg_awaddr  : in  STD_LOGIC_VECTOR ( 31 downto 0 );
        axil_reg_awprot  : in  STD_LOGIC_VECTOR ( 2 downto 0 );
        axil_reg_awvalid : in  STD_LOGIC_VECTOR ( 0 to 0 );
        axil_reg_awready : out STD_LOGIC_VECTOR ( 0 to 0 );
        axil_reg_wdata   : in  STD_LOGIC_VECTOR ( 31 downto 0 );
        axil_reg_wstrb   : in  STD_LOGIC_VECTOR ( 3 downto 0 );
        axil_reg_wvalid  : in  STD_LOGIC_VECTOR ( 0 to 0 );
        axil_reg_wready  : out STD_LOGIC_VECTOR ( 0 to 0 );
        axil_reg_bresp   : out STD_LOGIC_VECTOR ( 1 downto 0 );
        axil_reg_bvalid  : out STD_LOGIC_VECTOR ( 0 to 0 );
        axil_reg_bready  : in  STD_LOGIC_VECTOR ( 0 to 0 );
        axil_reg_araddr  : in  STD_LOGIC_VECTOR ( 31 downto 0 );
        axil_reg_arprot  : in  STD_LOGIC_VECTOR ( 2 downto 0 );
        axil_reg_arvalid : in  STD_LOGIC_VECTOR ( 0 to 0 );
        axil_reg_arready : out STD_LOGIC_VECTOR ( 0 to 0 );
        axil_reg_rdata   : out STD_LOGIC_VECTOR ( 31 downto 0 );
        axil_reg_rresp   : out STD_LOGIC_VECTOR ( 1 downto 0 );
        axil_reg_rvalid  : out STD_LOGIC_VECTOR ( 0 to 0 );
        axil_reg_rready  : in  STD_LOGIC_VECTOR ( 0 to 0 );

        oreg_out_en   : out   std_logic;
        oreg_width    : out   std_logic_vector(11 downto 0);
        oreg_height   : out   std_logic_vector(11 downto 0);
        oreg_offsetx  : out   std_logic_vector(11 downto 0);
        oreg_offsety  : out   std_logic_vector(11 downto 0);
        oreg_rev_x    : out   std_logic;
        oreg_rev_y    : out   std_logic;
        oreg_tp_sel   : out   std_logic_vector( 3 downto 0);
        oreg_tp_mode  : out   std_logic;
        oreg_tp_dtime : out   std_logic_vector(15 downto 0);
        oreg_tp_value : out   std_logic_vector(15 downto 0);

        oreg_pwr_mode       : out   std_logic;
        oreg_grab_en        : out   std_logic;
        oreg_gate_en        : out   std_logic_vector(7 downto 0);
        oreg_img_mode       : out   std_logic_vector(2 downto 0);
        oreg_timing_mode    : out   std_logic_vector(1 downto 0);
        oreg_rst_mode       : out   std_logic_vector(1 downto 0);
        oreg_rst_num        : out   std_logic_vector(3 downto 0);
        oreg_erase_en       : out   std_logic;
        oreg_erase_time     : out   std_logic_vector(31 downto 0);
        oreg_shutter        : out   std_logic;
        oreg_trig_mode      : out   std_logic_vector(1 downto 0);
        oreg_trig_delay     : out   std_logic_vector(15 downto 0);
        oreg_trig_filt      : out   std_logic_vector(7 downto 0);
        oreg_trig_valid     : out   std_logic;
        oreg_roic_shaazen   : out   std_logic;
        oreg_roic_tp_sel    : out   std_logic;
        oreg_roic_fa        : out   std_logic_vector(15 downto 0);
        oreg_roic_cds1      : out   std_logic_vector(15 downto 0);
        oreg_roic_cds2      : out   std_logic_vector(15 downto 0);
        oreg_roic_intrst    : out   std_logic_vector(15 downto 0);
        oreg_roic_sync_aclk : out   std_logic_vector(15 downto 0);
        oreg_roic_dead      : out   std_logic_vector(15 downto 0);
        oreg_roic_mute      : out   std_logic_vector(15 downto 0);
        oreg_roic_sync_dclk : out   std_logic_vector(15 downto 0);
        oreg_roic_afe_dclk  : out   std_logic_vector(15 downto 0);
        oreg_gate_oe        : out   std_logic_vector(15 downto 0);
        oreg_gate_xon       : out   std_logic_vector(31 downto 0);
        oreg_gate_xon_flk   : out   std_logic_vector(31 downto 0);
        oreg_gate_flk       : out   std_logic_vector(31 downto 0);
        oreg_gate_rst_cycle : out   std_logic_vector(31 downto 0);
        oreg_sexp_time      : out   std_logic_vector(31 downto 0);
        oreg_exp_time       : out   std_logic_vector(31 downto 0);
        oreg_frame_time     : out   std_logic_vector(31 downto 0);
        oreg_frame_num      : out   std_logic_vector(15 downto 0);
        oreg_frame_val      : out   std_logic_vector(15 downto 0);
        ireg_frame_cnt      : in    std_logic_vector(31 downto 0);
        ireg_ext_exp_time   : in    std_logic_vector(31 downto 0);
        ireg_ext_frame_time : in    std_logic_vector(31 downto 0);
        oreg_roic_en        : out   std_logic;
        oreg_roic_addr      : out   std_logic_vector(7 downto 0);
        oreg_roic_wdata     : out   std_logic_vector(15 downto 0);
        ireg_roic_rdata     : in    std_logic_vector(15 downto 0);
        oreg_req_align      : out   std_logic;
        oreg_out_mode       : out   std_logic_vector(3 downto 0);
        oreg_ddr_ch_en     : out   std_logic_vector(7 downto 0);
        oreg_ddr_base_addr : out   std_logic_vector(31 downto 0);
        oreg_ddr_ch0_waddr : out   std_logic_vector(29 downto 0);
        oreg_ddr_ch1_waddr : out   std_logic_vector(29 downto 0);
        oreg_ddr_ch2_waddr : out   std_logic_vector(29 downto 0);
        oreg_ddr_ch3_waddr : out   std_logic_vector(29 downto 0);
        oreg_ddr_ch4_waddr : out   std_logic_vector(29 downto 0);
        oreg_ddr_ch0_raddr : out   std_logic_vector(29 downto 0);
        oreg_ddr_ch1_raddr : out   std_logic_vector(29 downto 0);
        oreg_ddr_ch2_raddr : out   std_logic_vector(29 downto 0);
        oreg_ddr_ch3_raddr : out   std_logic_vector(29 downto 0);
        oreg_ddr_ch4_raddr : out   std_logic_vector(29 downto 0);
        oreg_ddr_out       : out   std_logic_vector(2 downto 0);
        oreg_line_time     : out   std_logic_vector(15 downto 0);
        oreg_debug_mode    : out   std_logic;
        oreg_gain_cal      : out   std_logic;
        oreg_offset_cal    : out   std_logic;
        oreg_mpc_ctrl      : out   std_logic_vector(3 downto 0);
        oreg_mpc_num       : out   std_logic_vector(3 downto 0);
        oreg_mpc_point0    : out   std_logic_vector(15 downto 0);
        oreg_mpc_point1    : out   std_logic_vector(15 downto 0);
        oreg_mpc_point2    : out   std_logic_vector(15 downto 0);
        oreg_mpc_point3    : out   std_logic_vector(15 downto 0);
        oreg_defect_mode   : out   std_logic;
        oreg_defect_wen    : out   std_logic;
        oreg_defect_addr   : out   std_logic_vector(15 downto 0);
        oreg_defect_wdata  : out   std_logic_vector(31 downto 0);
        ireg_defect_rdata  : in    std_logic_vector(31 downto 0);
        oreg_defect2_wen   : out   std_logic;
        oreg_defect2_addr  : out   std_logic_vector(15 downto 0);
        oreg_defect2_wdata : out   std_logic_vector(31 downto 0);
        ireg_defect2_rdata : in    std_logic_vector(31 downto 0);
        oreg_ldefect_mode  : out   std_logic;
        oreg_rdefect_wen   : out   std_logic;
        oreg_rdefect_addr  : out   std_logic_vector(3 downto 0);
        oreg_rdefect_wdata : out   std_logic_vector(15 downto 0); -- news en 210817mbh
        ireg_rdefect_rdata : in    std_logic_vector(15 downto 0);
        oreg_cdefect_wen   : out   std_logic;
        oreg_cdefect_addr  : out   std_logic_vector(3 downto 0);
        oreg_cdefect_wdata : out   std_logic_vector(15 downto 0); -- news en 210817mbh
        ireg_cdefect_rdata : in    std_logic_vector(15 downto 0);
        oreg_defect_map    : out   std_logic;
        oreg_dgain         : out   std_logic_vector(10 downto 0);
        oreg_avg_en        : out   std_logic;
        oreg_avg_level     : out   std_logic_vector(3 downto 0);
        ireg_avg_end       : in    std_logic_vector(15 downto 0);
        oreg_iproc_mode    : out   std_logic_vector(3 downto 0);
        oreg_bright        : out   std_logic_vector(16 downto 0);
        oreg_contrast      : out   std_logic_vector(15 downto 0);
        ireg_pwr_done      : in    std_logic;
        ireg_erase_done    : in    std_logic;
        ireg_align_done    : in    std_logic;
        ireg_roic_done     : in    std_logic;
        ireg_grab_done     : in    std_logic;
        ireg_calib_done    : in    std_logic;
        ireg_roic_temp     : in    std_logic_vector(ROIC_NUM(GNR_MODEL)*16-1 downto 0);
        oreg_i2c_mode   : out   std_logic;
        oreg_i2c_wen    : out   std_logic;
        oreg_i2c_wsize  : out   std_logic_vector(3 downto 0);
        oreg_i2c_wdata  : out   std_logic_vector(31 downto 0);
        oreg_i2c_ren    : out   std_logic;
        oreg_i2c_rsize  : out   std_logic_vector(3 downto 0);
        ireg_i2c_rdata0 : in    std_logic_vector(31 downto 0);
        ireg_i2c_rdata1 : in    std_logic_vector(31 downto 0);
        ireg_i2c_rdata2 : in    std_logic_vector(31 downto 0);
        ireg_i2c_rdata3 : in    std_logic_vector(31 downto 0);
        ireg_i2c_done   : in    std_logic;
        oreg_temp_en     : out   std_logic;
        ireg_device_temp : in    std_logic_vector(15 downto 0);
        oreg_sd_wen    : out   std_logic;
        oreg_sd_ren    : out   std_logic;
        oreg_sd_addr   : out   std_logic_vector(31 downto 0);
        ireg_sd_rw_end : in    std_logic;
        oreg_api_ext_trig    : out   std_logic_vector(3 downto 0);
        oreg_ext_trig_high   : out   std_logic_vector(31 downto 0);
        oreg_ext_trig_period : out   std_logic_vector(31 downto 0);
        oreg_ext_trig_active : out   std_logic_vector(1 downto 0);
        ireg_clk_mclk     : in    std_logic_vector(15 downto 0);
        ireg_clk_dclk     : in    std_logic_vector(15 downto 0);
        ireg_clk_roicdclk : in    std_logic_vector(15 downto 0);
        ireg_clk_uiclk    : in    std_logic_vector(15 downto 0);
        oreg_fla_ctrl : out   std_logic_vector(31 downto 0);
        oreg_fla_addr : out   std_logic_vector(31 downto 0);
        ireg_fla_data : in    std_logic_vector(31 downto 0);
        oreg_flaw_ctrl  : out   std_logic_vector(32 - 1 downto 0);
        oreg_flaw_cmd   : out   std_logic_vector(32 - 1 downto 0);
        oreg_flaw_addr  : out   std_logic_vector(32 - 1 downto 0);
        oreg_flaw_wdata : out   std_logic_vector(32 - 1 downto 0);
        ireg_flaw_rdata : in    std_logic_vector(32 - 1 downto 0);
        oreg_d2m_en         : out   std_logic;
        oreg_d2m_exp_in     : out   std_logic;
        oreg_d2m_sexp_time  : out   std_logic_vector(32 - 1 downto 0);
        oreg_d2m_frame_time : out   std_logic_vector(32 - 1 downto 0);
        oreg_d2m_xrst_num   : out   std_logic_vector(16 - 1 downto 0);
        oreg_d2m_drst_num   : out   std_logic_vector(16 - 1 downto 0);
        oreg_sync_ctrl        : out   std_logic_vector(31 downto 0);
        ireg_sync_rcnt0       : in    std_logic_vector(31 downto 0);
        ireg_sync_rcnt1       : in    std_logic_vector(31 downto 0);
        ireg_sync_rcnt2       : in    std_logic_vector(31 downto 0);
        ireg_sync_rcnt3       : in    std_logic_vector(31 downto 0);
        ireg_sync_rcnt4       : in    std_logic_vector(31 downto 0);
        ireg_sync_rcnt5       : in    std_logic_vector(31 downto 0);
        ireg_sync_rcnt6       : in    std_logic_vector(31 downto 0);
        ireg_sync_rcnt7       : in    std_logic_vector(31 downto 0);
        ireg_sync_rcnt8       : in    std_logic_vector(31 downto 0);
        ireg_sync_rcnt9       : in    std_logic_vector(31 downto 0);
        ireg_sync_rdata_avcn0 : in    std_logic_vector(31 downto 0);
        ireg_sync_rdata_avcn1 : in    std_logic_vector(31 downto 0);
        ireg_sync_rdata_avcn2 : in    std_logic_vector(31 downto 0);
        ireg_sync_rdata_avcn3 : in    std_logic_vector(31 downto 0);
        ireg_sync_rdata_avcn4 : in    std_logic_vector(31 downto 0);
        ireg_sync_rdata_avcn5 : in    std_logic_vector(31 downto 0);
        ireg_sync_rdata_avcn6 : in    std_logic_vector(31 downto 0);
        ireg_sync_rdata_avcn7 : in    std_logic_vector(31 downto 0);
        ireg_sync_rdata_avcn8 : in    std_logic_vector(31 downto 0);
        ireg_sync_rdata_avcn9 : in    std_logic_vector(31 downto 0);
        ireg_sync_rdata_bglw0 : in    std_logic_vector(31 downto 0);
        ireg_sync_rdata_bglw1 : in    std_logic_vector(31 downto 0);
        ireg_sync_rdata_bglw2 : in    std_logic_vector(31 downto 0);
        ireg_sync_rdata_bglw3 : in    std_logic_vector(31 downto 0);
        ireg_sync_rdata_bglw4 : in    std_logic_vector(31 downto 0);
        ireg_sync_rdata_bglw5 : in    std_logic_vector(31 downto 0);
        ireg_sync_rdata_bglw6 : in    std_logic_vector(31 downto 0);
        ireg_sync_rdata_bglw7 : in    std_logic_vector(31 downto 0);
        ireg_sync_rdata_bglw8 : in    std_logic_vector(31 downto 0);
        ireg_sync_rdata_bglw9 : in    std_logic_vector(31 downto 0);
        oreg_sm_ctrl  : out   std_logic_vector(31 downto 0);
        ireg_sm_data0 : in    std_logic_vector(31 downto 0);
        ireg_sm_data1 : in    std_logic_vector(31 downto 0);
        ireg_sm_data2 : in    std_logic_vector(31 downto 0);
        ireg_sm_data3 : in    std_logic_vector(31 downto 0);
        ireg_sm_data4 : in    std_logic_vector(31 downto 0);
        ireg_sm_data5 : in    std_logic_vector(31 downto 0);
        ireg_sm_data6 : in    std_logic_vector(31 downto 0);
        ireg_sm_data7 : in    std_logic_vector(31 downto 0);
        oreg_bcal_ctrl : out   std_logic_vector(31 downto 0);
        ireg_bcal_data : in    std_logic_vector(31 downto 0);
        oreg_mpc_posoffset : out   std_logic_vector(15 downto 0);
        oreg_d2m_ctrl      : out   std_logic_vector(3 downto 0);
        oreg_fw_busy     : out   std_logic;
        oreg_toprst_ctrl : out   std_logic_vector(15 downto 0);
        oreg_DnrCtrl     : out   std_logic_vector(15 downto 0);
        oreg_SobelCoeff0 : out   std_logic_vector(15 downto 0);
        oreg_SobelCoeff1 : out   std_logic_vector(15 downto 0);
        oreg_SobelCoeff2 : out   std_logic_vector(15 downto 0);
        oreg_BlurOffset  : out   std_logic_vector(15 downto 0);
        oreg_AccCtrl     : out   std_logic_vector(15 downto 0);
        iReg_AccStat     : in    std_logic_vector(15 downto 0);
        oreg_ExtTrigEn : out   std_logic;
        oreg_ExtRst_MODE    : out   std_logic_vector( 7 downto 0);
        oreg_ExtRst_DetTime : out   std_logic_vector(31 downto 0);
        oreg_led_ctrl       : out   std_logic_vector( 3 downto 0);
        ireg_trigcnt        : in    std_logic_vector(16 - 1 downto 0);
        oreg_osd_ctrl       : out   std_logic_vector(16 - 1 downto 0);
        oreg_pwdac_cmd       : out   std_logic_vector(16 - 1 downto 0);
        oreg_pwdac_ticktime  : out   std_logic_vector(32 - 1 downto 0);
        oreg_pwdac_tickinc   : out   std_logic_vector(12 - 1 downto 0);
        oreg_pwdac_trig      : out   std_logic;
        ireg_pwdac_currlevel : in    std_logic_vector(16 - 1 downto 0);
        oreg_testpoint1 : out   std_logic_vector(16 - 1 downto 0);
        oreg_testpoint2 : out   std_logic_vector(16 - 1 downto 0);
        oreg_testpoint3 : out   std_logic_vector(16 - 1 downto 0);
        oreg_testpoint4 : out   std_logic_vector(16 - 1 downto 0);
        oreg_roic_str : out   std_logic_vector( 7 downto 0);
        oreg_edge_ctrl   : out   std_logic_vector(16 - 1 downto 0);
        oreg_edge_value  : out   std_logic_vector(16 - 1 downto 0);
        oreg_edge_top    : out   std_logic_vector(16 - 1 downto 0);
        oreg_edge_left   : out   std_logic_vector(16 - 1 downto 0);
        oreg_edge_right  : out   std_logic_vector(16 - 1 downto 0);
        oreg_edge_bottom : out   std_logic_vector(16 - 1 downto 0);
        oreg_bnc_ctrl : out   std_logic_vector(16 - 1 downto 0);
        oreg_bnc_high : out   std_logic_vector(16 - 1 downto 0);
        oreg_ofga_lim : out std_logic_vector(16 - 1 downto 0); --# 230725
        oreg_EqCtrl   : out   std_logic_vector(16 - 1 downto 0);
        oreg_EqTopVal : out   std_logic_vector(16 - 1 downto 0);
        oreg_debug : out   std_logic_vector(15 downto 0)
    );
end entity reg_top;

architecture behavioral of reg_top is

type tdata_par                  is array (0 to ROIC_NUM(GNR_MODEL)-1) of std_logic_vector(15 downto 0);

    component iprog_rst is -- # 221110
        port (
            RST : in    std_logic;
            CLK : in    std_logic;
            RIP : out   std_logic
        );
    end component;

    signal wr_rdy     : std_logic;
    signal wr_blk     : std_logic;
    signal rd_rdy     : std_logic;
    signal rd_blk     : std_logic;
    signal srst_rdata : std_logic;

    -- User Register
    signal sreg_out_en   : std_logic;
    signal sreg_width    : std_logic_vector(11 downto 0);
    signal sreg_height   : std_logic_vector(11 downto 0);
    signal sreg_offsetx  : std_logic_vector(11 downto 0);
    signal sreg_offsety  : std_logic_vector(11 downto 0);
    signal sreg_rev_x    : std_logic;
    signal sreg_rev_y    : std_logic;
    signal sreg_tp_sel   : std_logic_vector( 3 downto 0);
    signal sreg_tp_mode  : std_logic;
    signal sreg_tp_dtime : std_logic_vector(15 downto 0);
    signal sreg_tp_value : std_logic_vector(15 downto 0);

    signal sreg_pwr_mode       : std_logic;
    signal sreg_grab_en        : std_logic;
    signal sreg_grab_done      : std_logic;
    signal sreg_gate_en        : std_logic_vector(7 downto 0);
    signal sreg_img_mode       : std_logic_vector(2 downto 0);
    signal sreg_timing_mode    : std_logic_vector(1 downto 0);
    signal sreg_rst_mode       : std_logic_vector(1 downto 0);
    signal sreg_rst_num        : std_logic_vector(3 downto 0);
    signal sreg_shutter        : std_logic;
    signal sreg_erase_en       : std_logic;
    signal sreg_erase_time     : std_logic_vector(31 downto 0);
    signal sreg_trig_mode      : std_logic_vector(1 downto 0);
    signal sreg_trig_delay     : std_logic_vector(15 downto 0);
    signal sreg_trig_filt      : std_logic_vector(7 downto 0);
    signal sreg_trig_valid     : std_logic;
    signal sreg_roic_shaazen   : std_logic;
    signal sreg_roic_tp_sel    : std_logic;
    signal sreg_roic_fa        : std_logic_vector(15 downto 0);
    signal sreg_roic_cds1      : std_logic_vector(15 downto 0);
    signal sreg_roic_cds2      : std_logic_vector(15 downto 0);
    signal sreg_roic_intrst    : std_logic_vector(15 downto 0);
    signal sreg_roic_sync_aclk : std_logic_vector(15 downto 0);
    signal sreg_roic_dead      : std_logic_vector(15 downto 0);
    signal sreg_roic_mute      : std_logic_vector(15 downto 0);
    signal sreg_roic_sync_dclk : std_logic_vector(15 downto 0);
    signal sreg_roic_afe_dclk  : std_logic_vector(15 downto 0);
    signal sreg_gate_oe        : std_logic_vector(15 downto 0);
    signal sreg_gate_xon       : std_logic_vector(31 downto 0);
    signal sreg_gate_xon_flk   : std_logic_vector(31 downto 0);
    signal sreg_gate_flk       : std_logic_vector(31 downto 0);
    signal sreg_gate_rst_cycle : std_logic_vector(31 downto 0);
    signal sreg_sexp_time      : std_logic_vector(31 downto 0);
    signal sreg_exp_time       : std_logic_vector(31 downto 0);
    signal sreg_frame_time     : std_logic_vector(31 downto 0);
    signal sreg_frame_num      : std_logic_vector(15 downto 0);
    signal sreg_frame_val      : std_logic_vector(15 downto 0);
    signal sreg_ext_exp_time   : std_logic_vector(31 downto 0);
    signal sreg_ext_frame_time : std_logic_vector(31 downto 0);
    signal sreg_roic_en        : std_logic;
    signal sreg_roic_addr      : std_logic_vector(7 downto 0);
    signal sreg_roic_wdata     : std_logic_vector(15 downto 0);
    signal sreg_roic_rdata     : std_logic_vector(15 downto 0);
    signal sreg_req_align      : std_logic;
    signal sreg_out_mode       : std_logic_vector(3 downto 0);

    signal sreg_ddr_ch_en     : std_logic_vector(7 downto 0);
    signal sreg_ddr_base_addr : std_logic_vector(31 downto 0);
    -- * jhkim 28 -> 29bit
    -- 29-> 30b ddr8g -- mbh 210412
    signal sreg_ddr_ch0_waddr : std_logic_vector(29 downto 0);
    signal sreg_ddr_ch1_waddr : std_logic_vector(29 downto 0);
    signal sreg_ddr_ch2_waddr : std_logic_vector(29 downto 0);
    signal sreg_ddr_ch3_waddr : std_logic_vector(29 downto 0);
    signal sreg_ddr_ch4_waddr : std_logic_vector(29 downto 0);
    signal sreg_ddr_ch0_raddr : std_logic_vector(29 downto 0);
    signal sreg_ddr_ch1_raddr : std_logic_vector(29 downto 0);
    signal sreg_ddr_ch2_raddr : std_logic_vector(29 downto 0);
    signal sreg_ddr_ch3_raddr : std_logic_vector(29 downto 0);
    signal sreg_ddr_ch4_raddr : std_logic_vector(29 downto 0);
    signal sreg_ddr_out       : std_logic_vector(2 downto 0);
    signal sreg_line_time     : std_logic_vector(15 downto 0);
    signal sreg_debug_mode    : std_logic;
    signal sreg_gain_cal      : std_logic;
    signal sreg_offset_cal    : std_logic;
    signal sreg_mpc_ctrl      : std_logic_vector(3 downto 0);
    signal sreg_mpc_num       : std_logic_vector(3 downto 0);
    signal sreg_mpc_point0    : std_logic_vector(15 downto 0);
    signal sreg_mpc_point1    : std_logic_vector(15 downto 0);
    signal sreg_mpc_point2    : std_logic_vector(15 downto 0);
    signal sreg_mpc_point3    : std_logic_vector(15 downto 0);
    signal sreg_mpc_posoffset : std_logic_vector(15 downto 0);
    signal sreg_defect_mode   : std_logic;
    signal sreg_defect_wen    : std_logic;
    signal sreg_defect_addr   : std_logic_vector(15 downto 0);
    signal sreg_defect_wdata  : std_logic_vector(31 downto 0);
    signal sreg_defect_rdata  : std_logic_vector(31 downto 0);
    signal sreg_defect2_wen   : std_logic;
    signal sreg_defect2_addr  : std_logic_vector(15 downto 0);
    signal sreg_defect2_wdata : std_logic_vector(31 downto 0);
    signal sreg_defect2_rdata : std_logic_vector(31 downto 0);
    signal sreg_ldefect_mode  : std_logic;
    signal sreg_rdefect_wen   : std_logic;
    signal sreg_rdefect_addr  : std_logic_vector(3 downto 0);
    signal sreg_rdefect_wdata : std_logic_vector(15 downto 0);
    signal sreg_rdefect_rdata : std_logic_vector(15 downto 0);
    signal sreg_cdefect_wen   : std_logic;
    signal sreg_cdefect_addr  : std_logic_vector(3 downto 0);
    signal sreg_cdefect_wdata : std_logic_vector(15 downto 0);
    signal sreg_cdefect_rdata : std_logic_vector(15 downto 0);
    signal sreg_defect_map    : std_logic;
    signal sreg_dgain         : std_logic_vector(10 downto 0);
    signal sreg_avg_en        : std_logic;
    signal sreg_avg_level     : std_logic_vector(3 downto 0);
    signal sreg_avg_end       : std_logic_vector(15 downto 0);
    signal sreg_iproc_mode    : std_logic_vector(3 downto 0);
    signal sreg_bright        : std_logic_vector(16 downto 0);
    signal sreg_contrast      : std_logic_vector(15 downto 0);
    signal sreg_pwr_done      : std_logic;
    signal sreg_erase_done    : std_logic;
    signal sreg_align_done    : std_logic;
    signal sreg_roic_done     : std_logic;
    signal sreg_calib_done    : std_logic;

    type   treg_roic_temp is array (0 to 11) of std_logic_vector(15 downto 0);
    signal sreg_roic_temp :  treg_roic_temp;
--    signal sreg_roic_temp :  std_logic_vector(ROIC_NUM2_REG(GNR_MODEL)*16-1 downto 0);

    signal sreg_i2c_mode   : std_logic;
    signal sreg_i2c_wen    : std_logic;
    signal sreg_i2c_wsize  : std_logic_vector(3 downto 0);
    signal sreg_i2c_wdata  : std_logic_vector(31 downto 0);
    signal sreg_i2c_ren    : std_logic;
    signal sreg_i2c_rsize  : std_logic_vector(3 downto 0);
    signal sreg_i2c_rdata0 : std_logic_vector(31 downto 0);
    signal sreg_i2c_rdata1 : std_logic_vector(31 downto 0);
    signal sreg_i2c_rdata2 : std_logic_vector(31 downto 0);
    signal sreg_i2c_rdata3 : std_logic_vector(31 downto 0);
    signal sreg_i2c_done   : std_logic;

    signal sreg_temp_en     : std_logic;
    signal sreg_device_temp : std_logic_vector(15 downto 0);

    signal sreg_sd_wen    : std_logic;
    signal sreg_sd_ren    : std_logic;
    signal sreg_sd_addr   : std_logic_vector(31 downto 0);
    signal sreg_sd_rw_end : std_logic;

    signal sreg_api_ext_trig    : std_logic_vector(3 downto 0);
    signal sreg_ext_trig_high   : std_logic_vector(31 downto 0);
    signal sreg_ext_trig_period : std_logic_vector(31 downto 0);
    signal sreg_ext_trig_active : std_logic_vector(1 downto 0);

    signal sreg_clk_mclk     : std_logic_vector(15 downto 0);
    signal sreg_clk_dclk     : std_logic_vector(15 downto 0);
    signal sreg_clk_roicdclk : std_logic_vector(15 downto 0);
    signal sreg_clk_uiclk    : std_logic_vector(15 downto 0);

    signal sreg_fla_ctrl : std_logic_vector(31 downto 0);
    signal sreg_fla_addr : std_logic_vector(31 downto 0);
    signal sreg_fla_data : std_logic_vector(31 downto 0);

    signal sreg_flaw_ctrl  : std_logic_vector(31 downto 0);
    signal sreg_flaw_cmd   : std_logic_vector(31 downto 0);
    signal sreg_flaw_addr  : std_logic_vector(31 downto 0);
    signal sreg_flaw_wdata : std_logic_vector(31 downto 0);
    signal sreg_flaw_rdata : std_logic_vector(31 downto 0);

    signal sreg_d2m_en         : std_logic;
    signal sreg_d2m_exp_in     : std_logic;
    signal sreg_d2m_sexp_time  : std_logic_vector(31 downto 0);
    signal sreg_d2m_frame_time : std_logic_vector(31 downto 0);
    signal sreg_d2m_xrst_num   : std_logic_vector(15 downto 0);
    signal sreg_d2m_drst_num   : std_logic_vector(15 downto 0);

    signal sreg_sync_ctrl        : std_logic_vector(31 downto 0);
    signal sreg_sync_rcnt0       : std_logic_vector(31 downto 0);
    signal sreg_sync_rcnt1       : std_logic_vector(31 downto 0);
    signal sreg_sync_rcnt2       : std_logic_vector(31 downto 0);
    signal sreg_sync_rcnt3       : std_logic_vector(31 downto 0);
    signal sreg_sync_rcnt4       : std_logic_vector(31 downto 0);
    signal sreg_sync_rcnt5       : std_logic_vector(31 downto 0);
    signal sreg_sync_rcnt6       : std_logic_vector(31 downto 0);
    signal sreg_sync_rcnt7       : std_logic_vector(31 downto 0);
    signal sreg_sync_rcnt8       : std_logic_vector(31 downto 0);
    signal sreg_sync_rcnt9       : std_logic_vector(31 downto 0);
    signal sreg_sync_rdata_avcn0 : std_logic_vector(31 downto 0);
    signal sreg_sync_rdata_avcn1 : std_logic_vector(31 downto 0);
    signal sreg_sync_rdata_avcn2 : std_logic_vector(31 downto 0);
    signal sreg_sync_rdata_avcn3 : std_logic_vector(31 downto 0);
    signal sreg_sync_rdata_avcn4 : std_logic_vector(31 downto 0);
    signal sreg_sync_rdata_avcn5 : std_logic_vector(31 downto 0);
    signal sreg_sync_rdata_avcn6 : std_logic_vector(31 downto 0);
    signal sreg_sync_rdata_avcn7 : std_logic_vector(31 downto 0);
    signal sreg_sync_rdata_avcn8 : std_logic_vector(31 downto 0);
    signal sreg_sync_rdata_avcn9 : std_logic_vector(31 downto 0);
    signal sreg_sync_rdata_bglw0 : std_logic_vector(31 downto 0);
    signal sreg_sync_rdata_bglw1 : std_logic_vector(31 downto 0);
    signal sreg_sync_rdata_bglw2 : std_logic_vector(31 downto 0);
    signal sreg_sync_rdata_bglw3 : std_logic_vector(31 downto 0);
    signal sreg_sync_rdata_bglw4 : std_logic_vector(31 downto 0);
    signal sreg_sync_rdata_bglw5 : std_logic_vector(31 downto 0);
    signal sreg_sync_rdata_bglw6 : std_logic_vector(31 downto 0);
    signal sreg_sync_rdata_bglw7 : std_logic_vector(31 downto 0);
    signal sreg_sync_rdata_bglw8 : std_logic_vector(31 downto 0);
    signal sreg_sync_rdata_bglw9 : std_logic_vector(31 downto 0);

    signal sreg_sm_ctrl  : std_logic_vector(31 downto 0);
    signal sreg_sm_data0 : std_logic_vector(31 downto 0);
    signal sreg_sm_data1 : std_logic_vector(31 downto 0);
    signal sreg_sm_data2 : std_logic_vector(31 downto 0);
    signal sreg_sm_data3 : std_logic_vector(31 downto 0);
    signal sreg_sm_data4 : std_logic_vector(31 downto 0);
    signal sreg_sm_data5 : std_logic_vector(31 downto 0);
    signal sreg_sm_data6 : std_logic_vector(31 downto 0);
    signal sreg_sm_data7 : std_logic_vector(31 downto 0);

    signal sreg_bcal_ctrl : std_logic_vector(31 downto 0);
    signal sreg_bcal_data : std_logic_vector(31 downto 0);

    signal sreg_fw_busy     : std_logic;
    signal sreg_toprst_ctrl : std_logic_vector(15 downto 0);

    signal sReg_DnrCtrl     : std_logic_vector(15 downto 0);
    signal sreg_SobelCoeff0 : std_logic_vector(15 downto 0);
    signal sreg_SobelCoeff1 : std_logic_vector(15 downto 0);
    signal sreg_SobelCoeff2 : std_logic_vector(15 downto 0);
    signal sreg_BlurOffset  : std_logic_vector(15 downto 0);
    signal sReg_AccCtrl     : std_logic_vector(15 downto 0);
    signal sReg_AccStat     : std_logic_vector(15 downto 0);

    signal sreg_ExtTrigEn : std_logic;

    signal sreg_ExtRst_MODE    : std_logic_vector( 7 downto 0);
    signal sreg_ExtRst_DetTime : std_logic_vector(31 downto 0);
    signal sreg_trigcnt        : std_logic_vector(15 downto 0);

    signal sreg_led_ctrl : std_logic_vector( 3 downto 0);
    signal sreg_debug    : std_logic_vector(15 downto 0);
    signal sreg_osd_ctrl : std_logic_vector(15 downto 0);

    signal sreg_pwdac_cmd       : std_logic_vector(16 - 1 downto 0);
    signal sreg_pwdac_ticktime  : std_logic_vector(32 - 1 downto 0);
    signal sreg_pwdac_tickinc   : std_logic_vector(12 - 1 downto 0);
    signal sreg_pwdac_trig      : std_logic;
    signal sreg_pwdac_currlevel : std_logic_vector(16 - 1 downto 0);

    signal sreg_testpoint1 : std_logic_vector(16 - 1 downto 0);
    signal sreg_testpoint2 : std_logic_vector(16 - 1 downto 0);
    signal sreg_testpoint3 : std_logic_vector(16 - 1 downto 0);
    signal sreg_testpoint4 : std_logic_vector(16 - 1 downto 0);

    signal sreg_roic_str : std_logic_vector(8 - 1 downto 0);

    signal sreg_edge_ctrl   : std_logic_vector(16-1 downto 0);
    signal sreg_edge_value  : std_logic_vector(16-1 downto 0);
    signal sreg_edge_top    : std_logic_vector(16-1 downto 0);
    signal sreg_edge_left   : std_logic_vector(16-1 downto 0);
    signal sreg_edge_right  : std_logic_vector(16-1 downto 0);
    signal sreg_edge_bottom : std_logic_vector(16-1 downto 0);

    signal sreg_bnc_ctrl : std_logic_vector(16-1 downto 0);
    signal sreg_bnc_high : std_logic_vector(16-1 downto 0);
    signal sreg_ofga_lim : std_logic_vector(16-1 downto 0);

    signal sreg_EqCtrl   : std_logic_vector(16-1 downto 0);
    signal sreg_EqTopVal : std_logic_vector(16-1 downto 0);
 
    signal sreg_grab_done_1d      : std_logic;
    signal sreg_grab_done_2d      : std_logic;
    signal sreg_grab_done_3d      : std_logic;
    signal sreg_ext_exp_time_1d   : std_logic_vector(31 downto 0);
    signal sreg_ext_exp_time_2d   : std_logic_vector(31 downto 0);
    signal sreg_ext_exp_time_3d   : std_logic_vector(31 downto 0);
    signal sreg_ext_frame_time_1d : std_logic_vector(31 downto 0);
    signal sreg_ext_frame_time_2d : std_logic_vector(31 downto 0);
    signal sreg_ext_frame_time_3d : std_logic_vector(31 downto 0);
    signal sreg_defect_rdata_1d   : std_logic_vector(31 downto 0);
    signal sreg_defect_rdata_2d   : std_logic_vector(31 downto 0);
    signal sreg_defect_rdata_3d   : std_logic_vector(31 downto 0);
    signal sreg_defect2_rdata_1d  : std_logic_vector(31 downto 0);
    signal sreg_defect2_rdata_2d  : std_logic_vector(31 downto 0);
    signal sreg_defect2_rdata_3d  : std_logic_vector(31 downto 0);
    signal sreg_rdefect_rdata_1d  : std_logic_vector(15 downto 0);
    signal sreg_rdefect_rdata_2d  : std_logic_vector(15 downto 0);
    signal sreg_rdefect_rdata_3d  : std_logic_vector(15 downto 0);
    signal sreg_cdefect_rdata_1d  : std_logic_vector(15 downto 0);
    signal sreg_cdefect_rdata_2d  : std_logic_vector(15 downto 0);
    signal sreg_cdefect_rdata_3d  : std_logic_vector(15 downto 0);
    signal sreg_avg_end_1d        : std_logic_vector(15 downto 0);
    signal sreg_avg_end_2d        : std_logic_vector(15 downto 0);
    signal sreg_avg_end_3d        : std_logic_vector(15 downto 0);
    signal sreg_pwr_done_1d       : std_logic;
    signal sreg_pwr_done_2d       : std_logic;
    signal sreg_pwr_done_3d       : std_logic;
    signal sreg_erase_done_1d     : std_logic;
    signal sreg_erase_done_2d     : std_logic;
    signal sreg_erase_done_3d     : std_logic;
    signal sreg_align_done_1d     : std_logic;
    signal sreg_align_done_2d     : std_logic;
    signal sreg_align_done_3d     : std_logic;
    signal sreg_roic_done_1d      : std_logic;
    signal sreg_roic_done_2d      : std_logic;
    signal sreg_roic_done_3d      : std_logic;
    signal sreg_calib_done_1d     : std_logic;
    signal sreg_calib_done_2d     : std_logic;
    signal sreg_calib_done_3d     : std_logic;
    signal sreg_i2c_rdata0_1d     : std_logic_vector(31 downto 0);
    signal sreg_i2c_rdata0_2d     : std_logic_vector(31 downto 0);
    signal sreg_i2c_rdata0_3d     : std_logic_vector(31 downto 0);
    signal sreg_i2c_rdata1_1d     : std_logic_vector(31 downto 0);
    signal sreg_i2c_rdata1_2d     : std_logic_vector(31 downto 0);
    signal sreg_i2c_rdata1_3d     : std_logic_vector(31 downto 0);
    signal sreg_i2c_rdata2_1d     : std_logic_vector(31 downto 0);
    signal sreg_i2c_rdata2_2d     : std_logic_vector(31 downto 0);
    signal sreg_i2c_rdata2_3d     : std_logic_vector(31 downto 0);
    signal sreg_i2c_rdata3_1d     : std_logic_vector(31 downto 0);
    signal sreg_i2c_rdata3_2d     : std_logic_vector(31 downto 0);
    signal sreg_i2c_rdata3_3d     : std_logic_vector(31 downto 0);
    signal sreg_i2c_done_1d       : std_logic;
    signal sreg_i2c_done_2d       : std_logic;
    signal sreg_i2c_done_3d       : std_logic;
    signal sreg_device_temp_1d    : std_logic_vector(15 downto 0);
    signal sreg_device_temp_2d    : std_logic_vector(15 downto 0);
    signal sreg_device_temp_3d    : std_logic_vector(15 downto 0);
    signal sreg_sd_rw_end_1d      : std_logic;
    signal sreg_sd_rw_end_2d      : std_logic;
    signal sreg_sd_rw_end_3d      : std_logic;
    signal sreg_clk_mclk_1d       : std_logic_vector(15 downto 0);
    signal sreg_clk_mclk_2d       : std_logic_vector(15 downto 0);
    signal sreg_clk_mclk_3d       : std_logic_vector(15 downto 0);
    signal sreg_clk_dclk_1d       : std_logic_vector(15 downto 0);
    signal sreg_clk_dclk_2d       : std_logic_vector(15 downto 0);
    signal sreg_clk_dclk_3d       : std_logic_vector(15 downto 0);
    signal sreg_clk_roicdclk_1d   : std_logic_vector(15 downto 0);
    signal sreg_clk_roicdclk_2d   : std_logic_vector(15 downto 0);
    signal sreg_clk_roicdclk_3d   : std_logic_vector(15 downto 0);
    signal sreg_clk_uiclk_1d      : std_logic_vector(15 downto 0);
    signal sreg_clk_uiclk_2d      : std_logic_vector(15 downto 0);
    signal sreg_clk_uiclk_3d      : std_logic_vector(15 downto 0);
    signal sreg_fla_data_1d       : std_logic_vector(31 downto 0);
    signal sreg_fla_data_2d       : std_logic_vector(31 downto 0);
    signal sreg_fla_data_3d       : std_logic_vector(31 downto 0);
    signal sreg_flaw_rdata_1d     : std_logic_vector(31 downto 0);
    signal sreg_flaw_rdata_2d     : std_logic_vector(31 downto 0);
    signal sreg_flaw_rdata_3d     : std_logic_vector(31 downto 0);

    signal sreg_roic_temp_1d  : std_logic_vector(ROIC_NUM(GNR_MODEL)*16-1 downto 0);
    signal sreg_roic_temp_2d  : std_logic_vector(ROIC_NUM(GNR_MODEL)*16-1 downto 0);
    signal sreg_roic_temp_3d  : std_logic_vector(ROIC_NUM(GNR_MODEL)*16-1 downto 0);
    signal sreg_roic_rdata_1d : std_logic_vector(15 downto 0);
    signal sreg_roic_rdata_2d : std_logic_vector(15 downto 0);
    signal sreg_roic_rdata_3d : std_logic_vector(15 downto 0);

    signal sreg_sync_rcnt0_1d : std_logic_vector(31 downto 0);
    signal sreg_sync_rcnt0_2d : std_logic_vector(31 downto 0);
    signal sreg_sync_rcnt0_3d : std_logic_vector(31 downto 0);
    signal sreg_sync_rcnt1_1d : std_logic_vector(31 downto 0);
    signal sreg_sync_rcnt1_2d : std_logic_vector(31 downto 0);
    signal sreg_sync_rcnt1_3d : std_logic_vector(31 downto 0);
    signal sreg_sync_rcnt2_1d : std_logic_vector(31 downto 0);
    signal sreg_sync_rcnt2_2d : std_logic_vector(31 downto 0);
    signal sreg_sync_rcnt2_3d : std_logic_vector(31 downto 0);
    signal sreg_sync_rcnt3_1d : std_logic_vector(31 downto 0);
    signal sreg_sync_rcnt3_2d : std_logic_vector(31 downto 0);
    signal sreg_sync_rcnt3_3d : std_logic_vector(31 downto 0);
    signal sreg_sync_rcnt4_1d : std_logic_vector(31 downto 0);
    signal sreg_sync_rcnt4_2d : std_logic_vector(31 downto 0);
    signal sreg_sync_rcnt4_3d : std_logic_vector(31 downto 0);
    signal sreg_sync_rcnt5_1d : std_logic_vector(31 downto 0);
    signal sreg_sync_rcnt5_2d : std_logic_vector(31 downto 0);
    signal sreg_sync_rcnt5_3d : std_logic_vector(31 downto 0);
    signal sreg_sync_rcnt6_1d : std_logic_vector(31 downto 0);
    signal sreg_sync_rcnt6_2d : std_logic_vector(31 downto 0);
    signal sreg_sync_rcnt6_3d : std_logic_vector(31 downto 0);
    signal sreg_sync_rcnt7_1d : std_logic_vector(31 downto 0);
    signal sreg_sync_rcnt7_2d : std_logic_vector(31 downto 0);
    signal sreg_sync_rcnt7_3d : std_logic_vector(31 downto 0);
    signal sreg_sync_rcnt8_1d : std_logic_vector(31 downto 0);
    signal sreg_sync_rcnt8_2d : std_logic_vector(31 downto 0);
    signal sreg_sync_rcnt8_3d : std_logic_vector(31 downto 0);
    signal sreg_sync_rcnt9_1d : std_logic_vector(31 downto 0);
    signal sreg_sync_rcnt9_2d : std_logic_vector(31 downto 0);
    signal sreg_sync_rcnt9_3d : std_logic_vector(31 downto 0);

    signal sreg_sync_rdata_avcn0_1d : std_logic_vector(31 downto 0);
    signal sreg_sync_rdata_avcn0_2d : std_logic_vector(31 downto 0);
    signal sreg_sync_rdata_avcn0_3d : std_logic_vector(31 downto 0);
    signal sreg_sync_rdata_avcn1_1d : std_logic_vector(31 downto 0);
    signal sreg_sync_rdata_avcn1_2d : std_logic_vector(31 downto 0);
    signal sreg_sync_rdata_avcn1_3d : std_logic_vector(31 downto 0);
    signal sreg_sync_rdata_avcn2_1d : std_logic_vector(31 downto 0);
    signal sreg_sync_rdata_avcn2_2d : std_logic_vector(31 downto 0);
    signal sreg_sync_rdata_avcn2_3d : std_logic_vector(31 downto 0);
    signal sreg_sync_rdata_avcn3_1d : std_logic_vector(31 downto 0);
    signal sreg_sync_rdata_avcn3_2d : std_logic_vector(31 downto 0);
    signal sreg_sync_rdata_avcn3_3d : std_logic_vector(31 downto 0);
    signal sreg_sync_rdata_avcn4_1d : std_logic_vector(31 downto 0);
    signal sreg_sync_rdata_avcn4_2d : std_logic_vector(31 downto 0);
    signal sreg_sync_rdata_avcn4_3d : std_logic_vector(31 downto 0);
    signal sreg_sync_rdata_avcn5_1d : std_logic_vector(31 downto 0);
    signal sreg_sync_rdata_avcn5_2d : std_logic_vector(31 downto 0);
    signal sreg_sync_rdata_avcn5_3d : std_logic_vector(31 downto 0);
    signal sreg_sync_rdata_avcn6_1d : std_logic_vector(31 downto 0);
    signal sreg_sync_rdata_avcn6_2d : std_logic_vector(31 downto 0);
    signal sreg_sync_rdata_avcn6_3d : std_logic_vector(31 downto 0);
    signal sreg_sync_rdata_avcn7_1d : std_logic_vector(31 downto 0);
    signal sreg_sync_rdata_avcn7_2d : std_logic_vector(31 downto 0);
    signal sreg_sync_rdata_avcn7_3d : std_logic_vector(31 downto 0);
    signal sreg_sync_rdata_avcn8_1d : std_logic_vector(31 downto 0);
    signal sreg_sync_rdata_avcn8_2d : std_logic_vector(31 downto 0);
    signal sreg_sync_rdata_avcn8_3d : std_logic_vector(31 downto 0);
    signal sreg_sync_rdata_avcn9_1d : std_logic_vector(31 downto 0);
    signal sreg_sync_rdata_avcn9_2d : std_logic_vector(31 downto 0);
    signal sreg_sync_rdata_avcn9_3d : std_logic_vector(31 downto 0);
    signal sreg_sync_rdata_bglw0_1d : std_logic_vector(31 downto 0);
    signal sreg_sync_rdata_bglw0_2d : std_logic_vector(31 downto 0);
    signal sreg_sync_rdata_bglw0_3d : std_logic_vector(31 downto 0);
    signal sreg_sync_rdata_bglw1_1d : std_logic_vector(31 downto 0);
    signal sreg_sync_rdata_bglw1_2d : std_logic_vector(31 downto 0);
    signal sreg_sync_rdata_bglw1_3d : std_logic_vector(31 downto 0);
    signal sreg_sync_rdata_bglw2_1d : std_logic_vector(31 downto 0);
    signal sreg_sync_rdata_bglw2_2d : std_logic_vector(31 downto 0);
    signal sreg_sync_rdata_bglw2_3d : std_logic_vector(31 downto 0);
    signal sreg_sync_rdata_bglw3_1d : std_logic_vector(31 downto 0);
    signal sreg_sync_rdata_bglw3_2d : std_logic_vector(31 downto 0);
    signal sreg_sync_rdata_bglw3_3d : std_logic_vector(31 downto 0);
    signal sreg_sync_rdata_bglw4_1d : std_logic_vector(31 downto 0);
    signal sreg_sync_rdata_bglw4_2d : std_logic_vector(31 downto 0);
    signal sreg_sync_rdata_bglw4_3d : std_logic_vector(31 downto 0);
    signal sreg_sync_rdata_bglw5_1d : std_logic_vector(31 downto 0);
    signal sreg_sync_rdata_bglw5_2d : std_logic_vector(31 downto 0);
    signal sreg_sync_rdata_bglw5_3d : std_logic_vector(31 downto 0);
    signal sreg_sync_rdata_bglw6_1d : std_logic_vector(31 downto 0);
    signal sreg_sync_rdata_bglw6_2d : std_logic_vector(31 downto 0);
    signal sreg_sync_rdata_bglw6_3d : std_logic_vector(31 downto 0);
    signal sreg_sync_rdata_bglw7_1d : std_logic_vector(31 downto 0);
    signal sreg_sync_rdata_bglw7_2d : std_logic_vector(31 downto 0);
    signal sreg_sync_rdata_bglw7_3d : std_logic_vector(31 downto 0);
    signal sreg_sync_rdata_bglw8_1d : std_logic_vector(31 downto 0);
    signal sreg_sync_rdata_bglw8_2d : std_logic_vector(31 downto 0);
    signal sreg_sync_rdata_bglw8_3d : std_logic_vector(31 downto 0);
    signal sreg_sync_rdata_bglw9_1d : std_logic_vector(31 downto 0);
    signal sreg_sync_rdata_bglw9_2d : std_logic_vector(31 downto 0);
    signal sreg_sync_rdata_bglw9_3d : std_logic_vector(31 downto 0);

    signal sreg_sm_data0_1d : std_logic_vector(31 downto 0);
    signal sreg_sm_data0_2d : std_logic_vector(31 downto 0);
    signal sreg_sm_data0_3d : std_logic_vector(31 downto 0);
    signal sreg_sm_data1_1d : std_logic_vector(31 downto 0);
    signal sreg_sm_data1_2d : std_logic_vector(31 downto 0);
    signal sreg_sm_data1_3d : std_logic_vector(31 downto 0);
    signal sreg_sm_data2_1d : std_logic_vector(31 downto 0);
    signal sreg_sm_data2_2d : std_logic_vector(31 downto 0);
    signal sreg_sm_data2_3d : std_logic_vector(31 downto 0);
    signal sreg_sm_data3_1d : std_logic_vector(31 downto 0);
    signal sreg_sm_data3_2d : std_logic_vector(31 downto 0);
    signal sreg_sm_data3_3d : std_logic_vector(31 downto 0);
    signal sreg_sm_data4_1d : std_logic_vector(31 downto 0);
    signal sreg_sm_data4_2d : std_logic_vector(31 downto 0);
    signal sreg_sm_data4_3d : std_logic_vector(31 downto 0);
    signal sreg_sm_data5_1d : std_logic_vector(31 downto 0);
    signal sreg_sm_data5_2d : std_logic_vector(31 downto 0);
    signal sreg_sm_data5_3d : std_logic_vector(31 downto 0);
    signal sreg_sm_data6_1d : std_logic_vector(31 downto 0);
    signal sreg_sm_data6_2d : std_logic_vector(31 downto 0);
    signal sreg_sm_data6_3d : std_logic_vector(31 downto 0);
    signal sreg_sm_data7_1d : std_logic_vector(31 downto 0);
    signal sreg_sm_data7_2d : std_logic_vector(31 downto 0);
    signal sreg_sm_data7_3d : std_logic_vector(31 downto 0);
    signal sreg_sm_data8_1d : std_logic_vector(31 downto 0);
    signal sreg_sm_data8_2d : std_logic_vector(31 downto 0);
    signal sreg_sm_data8_3d : std_logic_vector(31 downto 0);

    signal sreg_bcal_data_1d : std_logic_vector(31 downto 0);
    signal sreg_bcal_data_2d : std_logic_vector(31 downto 0);
    signal sreg_bcal_data_3d : std_logic_vector(31 downto 0);

    signal sreg_frame_cnt_1d : std_logic_vector(31 downto 0);
    signal sreg_frame_cnt_2d : std_logic_vector(31 downto 0);
    signal sreg_frame_cnt_3d : std_logic_vector(31 downto 0);
    signal sreg_frame_cnt    : std_logic_vector(31 downto 0);

    signal sreg_trigcnt_1d : std_logic_vector(16 - 1 downto 0);
    signal sreg_trigcnt_2d : std_logic_vector(16 - 1 downto 0);
    signal sreg_trigcnt_3d : std_logic_vector(16 - 1 downto 0);

    signal sreg_AccStat_1d : std_logic_vector(16 - 1 downto 0);
    signal sreg_AccStat_2d : std_logic_vector(16 - 1 downto 0);
    signal sreg_AccStat_3d : std_logic_vector(16 - 1 downto 0);

    signal sreg_pwdac_currlevel_1d : std_logic_vector(16 - 1 downto 0);
    signal sreg_pwdac_currlevel_2d : std_logic_vector(16 - 1 downto 0);
    signal sreg_pwdac_currlevel_3d : std_logic_vector(16 - 1 downto 0);

    signal sreg_fpga_reboot : std_logic := '0';
    signal fpga_reboot      : std_logic := '0';
    signal vo_reboot        : std_logic := '0';

    signal sreg_freeruncnt : std_logic_vector(32 - 1 downto 0);

--%begin
begin

    oepc_rdy <= wr_rdy or rd_rdy;

    process (isys_clk, isys_rstn)
    begin
        if (isys_rstn = '0') then
            sreg_grab_done      <= '0';
            sreg_ext_exp_time   <= (others => '0');
            sreg_ext_frame_time <= (others => '0');
            sreg_defect_rdata   <= (others => '0');
            sreg_defect2_rdata  <= (others => '0');
            sreg_rdefect_rdata  <= (others => '0');
            sreg_cdefect_rdata  <= (others => '0');
            sreg_avg_end        <= (others => '0');
            sreg_pwr_done       <= '0';
            sreg_erase_done     <= '0';
            sreg_align_done     <= '0';
            sreg_roic_done      <= '0';
            sreg_calib_done     <= '0';
            sreg_i2c_rdata0     <= (others => '0');
            sreg_i2c_rdata1     <= (others => '0');
            sreg_i2c_rdata2     <= (others => '0');
            sreg_i2c_rdata3     <= (others => '0');
            sreg_i2c_done       <= '0';
            sreg_device_temp    <= (others => '0');
            sreg_sd_rw_end      <= '0';
            sreg_roic_temp      <= (others => (others => '0'));
--            sreg_roic_temp      <= (others => '0');
            sreg_roic_rdata     <= (others => '0');
        elsif (isys_clk'event and isys_clk = '1') then
            sreg_grab_done        <= sreg_grab_done_3d;
            sreg_ext_exp_time     <= sreg_ext_exp_time_3d;
            sreg_ext_frame_time   <= sreg_ext_frame_time_3d;
            sreg_defect_rdata     <= sreg_defect_rdata_3d;
            sreg_defect2_rdata    <= sreg_defect2_rdata_3d;
            sreg_rdefect_rdata    <= sreg_rdefect_rdata_3d;
            sreg_cdefect_rdata    <= sreg_cdefect_rdata_3d;
            sreg_avg_end          <= sreg_avg_end_3d;
            sreg_pwr_done         <= sreg_pwr_done_3d;
            sreg_erase_done       <= sreg_erase_done_3d;
            sreg_align_done       <= sreg_align_done_3d;
            sreg_roic_done        <= sreg_roic_done_3d;
            sreg_calib_done       <= sreg_calib_done_3d;
            sreg_i2c_rdata0       <= sreg_i2c_rdata0_3d;
            sreg_i2c_rdata1       <= sreg_i2c_rdata1_3d;
            sreg_i2c_rdata2       <= sreg_i2c_rdata2_3d;
            sreg_i2c_rdata3       <= sreg_i2c_rdata3_3d;
            sreg_i2c_done         <= sreg_i2c_done_3d;
            sreg_device_temp      <= sreg_device_temp_3d;
            sreg_sd_rw_end        <= sreg_sd_rw_end_3d;
            sreg_roic_rdata       <= sreg_roic_rdata_3d;
            sreg_clk_mclk         <= sreg_clk_mclk_3d;
            sreg_clk_dclk         <= sreg_clk_dclk_3d;
            sreg_clk_roicdclk     <= sreg_clk_roicdclk_3d;
            sreg_clk_uiclk        <= sreg_clk_uiclk_3d;
            sreg_fla_data         <= sreg_fla_data_3d;
            sreg_flaw_rdata       <= sreg_flaw_rdata_3d;
            sreg_sync_rcnt0       <= sreg_sync_rcnt0_3d;
            sreg_sync_rcnt1       <= sreg_sync_rcnt1_3d;
            sreg_sync_rcnt2       <= sreg_sync_rcnt2_3d;
            sreg_sync_rcnt3       <= sreg_sync_rcnt3_3d;
            sreg_sync_rcnt4       <= sreg_sync_rcnt4_3d;
            sreg_sync_rcnt5       <= sreg_sync_rcnt5_3d;
            sreg_sync_rcnt6       <= sreg_sync_rcnt6_3d;
            sreg_sync_rcnt7       <= sreg_sync_rcnt7_3d;
            sreg_sync_rcnt8       <= sreg_sync_rcnt8_3d;
            sreg_sync_rcnt9       <= sreg_sync_rcnt9_3d;
            sreg_sync_rdata_avcn0 <= sreg_sync_rdata_avcn0_3d;
            sreg_sync_rdata_avcn1 <= sreg_sync_rdata_avcn1_3d;
            sreg_sync_rdata_avcn2 <= sreg_sync_rdata_avcn2_3d;
            sreg_sync_rdata_avcn3 <= sreg_sync_rdata_avcn3_3d;
            sreg_sync_rdata_avcn4 <= sreg_sync_rdata_avcn4_3d;
            sreg_sync_rdata_avcn5 <= sreg_sync_rdata_avcn5_3d;
            sreg_sync_rdata_avcn6 <= sreg_sync_rdata_avcn6_3d;
            sreg_sync_rdata_avcn7 <= sreg_sync_rdata_avcn7_3d;
            sreg_sync_rdata_avcn8 <= sreg_sync_rdata_avcn8_3d;
            sreg_sync_rdata_avcn9 <= sreg_sync_rdata_avcn9_3d;
            sreg_sync_rdata_bglw0 <= sreg_sync_rdata_bglw0_3d;
            sreg_sync_rdata_bglw1 <= sreg_sync_rdata_bglw1_3d;
            sreg_sync_rdata_bglw2 <= sreg_sync_rdata_bglw2_3d;
            sreg_sync_rdata_bglw3 <= sreg_sync_rdata_bglw3_3d;
            sreg_sync_rdata_bglw4 <= sreg_sync_rdata_bglw4_3d;
            sreg_sync_rdata_bglw5 <= sreg_sync_rdata_bglw5_3d;
            sreg_sync_rdata_bglw6 <= sreg_sync_rdata_bglw6_3d;
            sreg_sync_rdata_bglw7 <= sreg_sync_rdata_bglw7_3d;
            sreg_sync_rdata_bglw8 <= sreg_sync_rdata_bglw8_3d;
            sreg_sync_rdata_bglw9 <= sreg_sync_rdata_bglw9_3d;

            sreg_sm_data0 <= sreg_sm_data0_3d;
            sreg_sm_data1 <= sreg_sm_data1_3d;
            sreg_sm_data2 <= sreg_sm_data2_3d;
            sreg_sm_data3 <= sreg_sm_data3_3d;
            sreg_sm_data4 <= sreg_sm_data4_3d;
            sreg_sm_data5 <= sreg_sm_data5_3d;
            sreg_sm_data6 <= sreg_sm_data6_3d;
            sreg_sm_data7 <= sreg_sm_data7_3d;

            sreg_bcal_data       <= sreg_bcal_data_3d;
            sreg_frame_cnt       <= sreg_frame_cnt_3d;
            sreg_trigcnt         <= sreg_trigcnt_3d;
            sReg_AccStat         <= sreg_AccStat_3d;
            sreg_pwdac_currlevel <= sreg_pwdac_currlevel_3d;

            sreg_freeruncnt <= sreg_freeruncnt + '1';

            for i in 0 to ROIC_NUM2_REG(GNR_MODEL) - 1 loop
                sreg_roic_temp(i) <= sreg_roic_temp_3d((i+1)*16-1 downto 16*i);
            end loop;
--                sreg_roic_temp <= sreg_roic_temp_3d;

        end if;
    end process;

    -- Write access
    process (isys_clk, isys_rstn)
    begin
        if (isys_rstn = '0') then
            sreg_out_en      <= '0';
            sreg_width       <= conv_std_logic_vector(MAX_WIDTH(GNR_MODEL), 12);
            sreg_height      <= conv_std_logic_vector(MAX_HEIGHT(GNR_MODEL), 12);
            sreg_offsetx     <= (others => '0');
            sreg_offsety     <= (others => '0');
            sreg_rev_x       <= '0';
            sreg_rev_y       <= '0';
            sreg_tp_sel      <= "0001";
            sreg_tp_mode     <= '1';
            sreg_tp_dtime    <= x"015E";
            sreg_tp_value    <= x"0000";
            sreg_pwr_mode    <= '0';
            sreg_grab_en     <= '0';
            sreg_gate_en     <= x"01";
            sreg_img_mode    <= (others => '0');
            sreg_timing_mode <= (others => '0');
            sreg_rst_mode    <= (others => '0');
            sreg_rst_num     <= x"1";
            sreg_shutter     <= '0';
            sreg_erase_en    <= '0';
            sreg_erase_time  <= (others => '0');
            sreg_trig_mode   <= "00";
            sreg_trig_delay  <= conv_std_logic_vector(0, 16);
            sreg_trig_filt   <= conv_std_logic_vector(0, 8);
            sreg_trig_valid  <= '0';

            sreg_roic_shaazen   <= '0';
            sreg_roic_tp_sel    <= '0';
--            sreg_roic_mute      <= conv_std_logic_vector(ROIC_MUTE(GNR_MODEL), 16); --# ADI option 231117
--            sreg_roic_afe_dclk  <= conv_std_logic_vector(ROIC_AFE_DCLK(GNR_MODEL), 16); --# ADI option 231117
            sreg_roic_sync_dclk <= conv_std_logic_vector(ROIC_SYNC_DCLK(GNR_MODEL), 16);
            sreg_roic_sync_aclk <= conv_std_logic_vector(ROIC_SYNC_ACLK(GNR_MODEL), 16);
            sreg_roic_dead      <= conv_std_logic_vector(ROIC_DEAD(GNR_MODEL), 16);
            sreg_roic_fa        <= conv_std_logic_vector(ROIC_FA(GNR_MODEL), 16);
            sreg_roic_cds1      <= conv_std_logic_vector(ROIC_CDS1(GNR_MODEL), 16);
            sreg_roic_cds2      <= conv_std_logic_vector(ROIC_CDS2(GNR_MODEL), 16);
            sreg_roic_intrst    <= conv_std_logic_vector(ROIC_INTRST(GNR_MODEL), 16);

            sreg_gate_oe        <= conv_std_logic_vector(GATE_OE(GNR_MODEL), 16);
            sreg_gate_xon       <= conv_std_logic_vector(GATE_XON(GNR_MODEL), 32);
            sreg_gate_xon_flk   <= conv_std_logic_vector(GATE_XON_FLK(GNR_MODEL), 32);
            sreg_gate_flk       <= conv_std_logic_vector(GATE_FLK(GNR_MODEL), 32);
            sreg_gate_rst_cycle <= conv_std_logic_vector(GATE_TRST_PERIOD(GNR_MODEL), 32);

            sreg_sexp_time     <= conv_std_logic_vector(10000000, 32); -- 200ms
            sreg_exp_time      <= conv_std_logic_vector(10000000, 32); -- 200ms
            sreg_frame_time    <= conv_std_logic_vector(50000000, 32); -- 1s
            sreg_frame_num     <= conv_std_logic_vector(0, 16);
            sreg_frame_val     <= conv_std_logic_vector(0, 16);
            sreg_roic_en       <= '0';
            sreg_roic_addr     <= (others => '0');
            sreg_roic_wdata    <= x"82CF";
            sreg_req_align     <= '0';
            sreg_out_mode      <= (others => '0');
            sreg_ddr_ch_en     <= (others => '0');
            sreg_ddr_base_addr <= x"90000000";

            -- * org
            -- * sreg_ddr_ch0_waddr    <= (others => '0');
            -- * sreg_ddr_ch1_waddr    <= x"1000000";
            -- * sreg_ddr_ch2_waddr    <= x"2000000";
            -- * sreg_ddr_ch0_raddr    <= (others => '0');
            -- * sreg_ddr_ch1_raddr    <= x"1000000";
            -- * sreg_ddr_ch2_raddr    <= x"2000000";

            -- * jhkim 28 -> 29bit
            -- 28b->29
            sreg_ddr_ch0_waddr <= (others => '0');
            sreg_ddr_ch1_waddr <= "00" & x"1000000";
            sreg_ddr_ch2_waddr <= "00" & x"2000000";
            sreg_ddr_ch3_waddr <= "00" & x"2000000";
            sreg_ddr_ch4_waddr <= "00" & x"2000000";
            sreg_ddr_ch0_raddr <= (others => '0');
            sreg_ddr_ch1_raddr <= "00" & x"1000000";
            sreg_ddr_ch2_raddr <= "00" & x"2000000";
            sreg_ddr_ch3_raddr <= "00" & x"2000000";
            sreg_ddr_ch4_raddr <= "00" & x"2000000";

            sreg_ddr_out       <= (others => '0');
            sreg_line_time     <= conv_std_logic_vector(MAX_WIDTH(GNR_MODEL) + 100, 16);
            sreg_debug_mode    <= '0';
            sreg_gain_cal      <= '0';
            sreg_offset_cal    <= '0';
            sreg_mpc_ctrl      <= (others => '0');
            sreg_mpc_num       <= (others => '0');
            sreg_mpc_point0    <= conv_std_logic_vector(8000, 16);
            sreg_mpc_point1    <= conv_std_logic_vector(20000, 16);
            sreg_mpc_point2    <= conv_std_logic_vector(30000, 16);
            sreg_mpc_point3    <= conv_std_logic_vector(45000, 16);
            sreg_defect_mode   <= '0';
            sreg_defect_wen    <= '0';
            sreg_defect_addr   <= (others => '0');
            sreg_defect_wdata  <= (others => '1');
            sreg_defect2_wen   <= '0';
            sreg_defect2_addr  <= (others => '0');
            sreg_defect2_wdata <= (others => '1');
            sreg_ldefect_mode  <= '0';
            sreg_rdefect_wen   <= '0';
            sreg_rdefect_addr  <= (others => '0');
            sreg_rdefect_wdata <= (others => '1');
            sreg_cdefect_wen   <= '0';
            sreg_cdefect_addr  <= (others => '0');
            sreg_cdefect_wdata <= (others => '1');
            sreg_defect_map    <= '0';
            sreg_dgain         <= conv_std_logic_vector(99, 11);
            sreg_avg_en        <= '0';
            sreg_avg_level     <= conv_std_logic_vector(15, 4);
            sreg_iproc_mode    <= (others => '0');
            sreg_bright        <= (others => '0');
--            sreg_contrast      <= x"0100";
            sreg_contrast      <= x"0100"; --# 230724 noting changed

            sreg_i2c_mode  <= '0';
            sreg_i2c_wen   <= '0';
            sreg_i2c_wsize <= (others => '0');
            sreg_i2c_wdata <= (others => '0');
            sreg_i2c_ren   <= '0';
            sreg_i2c_rsize <= (others => '0');

            sreg_temp_en <= '0';

            sreg_sd_wen  <= '0';
            sreg_sd_ren  <= '0';
            sreg_sd_addr <= (others => '0');

            sreg_api_ext_trig    <= (others => '0');
            sreg_ext_trig_high   <= (others => '0');
            sreg_ext_trig_period <= (others => '0');
            sreg_ext_trig_active <= (others => '0');

            sreg_fla_ctrl <= (others => '0');
            sreg_fla_addr <= (others => '0');

            sreg_flaw_ctrl  <= (others => '0');
            sreg_flaw_cmd   <= (others => '0');
            sreg_flaw_addr  <= (others => '0');
            sreg_flaw_wdata <= (others => '0');

            sreg_d2m_en         <= '0';
            sreg_d2m_exp_in     <= '0';
            sreg_d2m_sexp_time  <= (others => '0');
            sreg_d2m_frame_time <= (others => '0');
            sreg_d2m_xrst_num   <= (others => '0');
            sreg_d2m_drst_num   <= (others => '0');

            sreg_sm_ctrl   <= (others => '0');
            sreg_bcal_ctrl <= (others => '0');
            sreg_sync_ctrl <= (others => '0');

            sreg_mpc_posoffset <= conv_std_logic_vector(400, 16);

            sreg_fw_busy     <= '0';
            sreg_toprst_ctrl <= (others => '0');

            sReg_DnrCtrl     <= (others => '0');
            sreg_SobelCoeff0 <= (others => '0');
            sreg_SobelCoeff1 <= (others => '0');
            sreg_SobelCoeff2 <= (others => '0');
            sreg_BlurOffset  <= (others => '0');
            sReg_AccCtrl     <= (others => '0');

            sreg_ExtTrigEn <= '0';

            sreg_ExtRst_MODE    <= conv_std_logic_vector(2, 8);
            sreg_ExtRst_DetTime <= conv_std_logic_vector(40000000, 32); -- 2sec at 20MHz

            sreg_led_ctrl <= conv_std_logic_vector(0, 4);
            sreg_osd_ctrl <= conv_std_logic_vector(0, 16);

            sreg_pwdac_cmd      <= (others => '0');
            sreg_pwdac_ticktime <= (others => '0');
            sreg_pwdac_tickinc  <= (others => '0');
            sreg_pwdac_trig     <= '0';

            sreg_testpoint1 <= (others => '0'); -- x"1001";
            sreg_testpoint2 <= (others => '0'); -- x"1002";
            sreg_testpoint3 <= (others => '0'); -- x"1003";
            sreg_testpoint4 <= (others => '0'); -- x"1004";

            sreg_roic_str    <= (others => '0');
            sreg_edge_value  <= conv_std_logic_vector(50000, 16);   
            sreg_debug       <= (others => '0');
            
            sreg_bnc_high    <= conv_std_logic_vector(55000, 16);
            sreg_ofga_lim    <= conv_std_logic_vector(65000, 16);

            sreg_EqCtrl      <= (others => '0');
            sreg_EqTopVal    <= (others => '0');
        elsif (isys_clk'event and isys_clk = '1') then
            if (iepc_cs_n = '0' and iepc_we_n = '0' and wr_blk = '0') then
-- █░█░█ █▀█ █ ▀█▀ █▀▀
-- ▀▄▀▄▀ █▀▄ █ ░█░ ██▄
                case iepc_addr is
                    when ADDR_OUT_EN           => sreg_out_en          <= iepc_wdata(0);
                    when ADDR_WIDTH            => sreg_width           <= iepc_wdata(11 downto 0);
                    when ADDR_HEIGHT           => sreg_height          <= iepc_wdata(11 downto 0);
                    when ADDR_OFFSETX          => sreg_offsetx         <= iepc_wdata(11 downto 0);
                    when ADDR_OFFSETY          => sreg_offsety         <= iepc_wdata(11 downto 0);
                    when ADDR_REV_X            => sreg_rev_x           <= iepc_wdata(0);
                    when ADDR_REV_Y            => sreg_rev_y           <= iepc_wdata(0);
                    when ADDR_TP_SEL           => sreg_tp_sel          <= iepc_wdata(3 downto 0);
                    when ADDR_TP_MODE          => sreg_tp_mode         <= iepc_wdata(0);
                    when ADDR_TP_DTIME         => sreg_tp_dtime        <= iepc_wdata(15 downto 0);
                    when ADDR_TP_VALUE         => sreg_tp_value        <= iepc_wdata(15 downto 0);
                    when ADDR_PWR_MODE         => sreg_pwr_mode        <= iepc_wdata(0);
                    when ADDR_GRAB_EN          => sreg_grab_en         <= iepc_wdata(0);
                    when ADDR_GATE_EN          => sreg_gate_en         <= iepc_wdata(7 downto 0); --# 1->8bit 240122
                    when ADDR_IMG_MODE         => sreg_img_mode        <= iepc_wdata(2 downto 0);
                    when ADDR_RST_MODE         => sreg_rst_mode        <= iepc_wdata(1 downto 0);
                    when ADDR_RST_NUM          => sreg_rst_num         <= iepc_wdata(3 downto 0);
                    when ADDR_TRIG_MODE        => sreg_trig_mode       <= iepc_wdata(1 downto 0);
                    when ADDR_TRIG_DELAY       => sreg_trig_delay      <= iepc_wdata(15 downto 0);
                    when ADDR_TRIG_VALID       => sreg_trig_valid      <= iepc_wdata(0);
                    when ADDR_TRIG_FILT        => sreg_trig_filt       <= iepc_wdata(7 downto 0);
                    when ADDR_ROIC_CDS1        => sreg_roic_cds1       <= iepc_wdata(15 downto 0);
                    when ADDR_ROIC_CDS2        => sreg_roic_cds2       <= iepc_wdata(15 downto 0);
                    when ADDR_ROIC_INTRST      => sreg_roic_intrst     <= iepc_wdata(15 downto 0);
                    when ADDR_GATE_OE          => sreg_gate_oe         <= iepc_wdata(15 downto 0);
                    when ADDR_GATE_XON         => sreg_gate_xon        <= iepc_wdata(31 downto 0);
                    when ADDR_GATE_XON_FLK     => sreg_gate_xon_flk    <= iepc_wdata(31 downto 0);
                    when ADDR_GATE_FLK         => sreg_gate_flk        <= iepc_wdata(31 downto 0);
                    when ADDR_ROIC_DEAD        => sreg_roic_dead       <= iepc_wdata(15 downto 0);
                    when ADDR_ROIC_MUTE        => sreg_roic_mute       <= iepc_wdata(15 downto 0);
                    when ADDR_SEXP_TIME        => sreg_sexp_time       <= iepc_wdata;
                    when ADDR_EXP_TIME         => sreg_exp_time        <= iepc_wdata;
                    when ADDR_FRAME_TIME       => sreg_frame_time      <= iepc_wdata;
                    when ADDR_FRAME_NUM        => sreg_frame_num       <= iepc_wdata(15 downto 0);
                    when ADDR_FRAME_VAL        => sreg_frame_val       <= iepc_wdata(15 downto 0);
--                  when ADDR_EXT_EXP_TIME     => sreg_ext_exp_time    <= Read Only
--                  when ADDR_EXT_FRAME_TIME   => sreg_ext_frame_time  <= Read Only
                    when ADDR_ROIC_EN          => sreg_roic_en         <= iepc_wdata(0);
                    when ADDR_ROIC_ADDR        => sreg_roic_addr       <= iepc_wdata(7 downto 0);
                    when ADDR_ROIC_WDATA       => sreg_roic_wdata      <= iepc_wdata(15 downto 0);
--                  when ADDR_ROIC_RDATA       => sreg_roic_rdata      <= Read Only
                    when ADDR_REQ_ALIGN        => sreg_req_align       <= iepc_wdata(0);
                    when ADDR_OUT_MODE         => sreg_out_mode        <= iepc_wdata(3 downto 0);
                    when ADDR_DEBUG            => sreg_debug           <= iepc_wdata(15 downto 0);
                    when ADDR_DDR_CH_EN        => sreg_ddr_ch_en       <= iepc_wdata(7 downto 0);
                    when ADDR_DDR_BASE_ADDR    => sreg_ddr_base_addr   <= iepc_wdata;
                    when ADDR_DDR_CH0_WADDR    => sreg_ddr_ch0_waddr   <= iepc_wdata(29 downto 0);
                    when ADDR_DDR_CH1_WADDR    => sreg_ddr_ch1_waddr   <= iepc_wdata(29 downto 0);
                    when ADDR_DDR_CH2_WADDR    => sreg_ddr_ch2_waddr   <= iepc_wdata(29 downto 0);
                    when ADDR_DDR_CH3_WADDR    => sreg_ddr_ch3_waddr   <= iepc_wdata(29 downto 0);
                    when ADDR_DDR_CH4_WADDR    => sreg_ddr_ch4_waddr   <= iepc_wdata(29 downto 0);
                    when ADDR_DDR_CH0_RADDR    => sreg_ddr_ch0_raddr   <= iepc_wdata(29 downto 0);
                    when ADDR_DDR_CH1_RADDR    => sreg_ddr_ch1_raddr   <= iepc_wdata(29 downto 0);
                    when ADDR_DDR_CH2_RADDR    => sreg_ddr_ch2_raddr   <= iepc_wdata(29 downto 0);
                    when ADDR_DDR_CH3_RADDR    => sreg_ddr_ch3_raddr   <= iepc_wdata(29 downto 0);
                    when ADDR_DDR_CH4_RADDR    => sreg_ddr_ch4_raddr   <= iepc_wdata(29 downto 0);
                    when ADDR_DDR_OUT          => sreg_ddr_out         <= iepc_wdata(2 downto 0);
                    when ADDR_DEBUG_MODE       => sreg_debug_mode      <= iepc_wdata(0);
                    when ADDR_GAIN_CAL         => sreg_gain_cal        <= iepc_wdata(0);
                    when ADDR_OFFSET_CAL       => sreg_offset_cal      <= iepc_wdata(0);
                    when ADDR_MPC_CTRL         => sreg_mpc_ctrl        <= iepc_wdata(3 downto 0);
                    when ADDR_MPC_NUM          => sreg_mpc_num         <= iepc_wdata(3 downto 0);
                    when ADDR_MPC_POINT0       => sreg_mpc_point0      <= iepc_wdata(15 downto 0);
                    when ADDR_MPC_POINT1       => sreg_mpc_point1      <= iepc_wdata(15 downto 0);
                    when ADDR_MPC_POINT2       => sreg_mpc_point2      <= iepc_wdata(15 downto 0);
                    when ADDR_MPC_POINT3       => sreg_mpc_point3      <= iepc_wdata(15 downto 0);
                    when ADDR_DEFECT_CAL       => sreg_defect_mode     <= iepc_wdata(0);
                    when ADDR_DEFECT_WEN       => sreg_defect_wen      <= iepc_wdata(0);
                    when ADDR_DEFECT_ADDR      => sreg_defect_addr     <= iepc_wdata(15 downto 0);
                    when ADDR_DEFECT_WDATA     => sreg_defect_wdata    <= iepc_wdata;
--                  when ADDR_DEFECT_RDATA     => sreg_defect_rdata    <= Read Only
                    when ADDR_DEFECT2_WEN      => sreg_defect2_wen     <= iepc_wdata(0);
                    when ADDR_DEFECT2_ADDR     => sreg_defect2_addr    <= iepc_wdata(15 downto 0);
                    when ADDR_DEFECT2_WDATA    => sreg_defect2_wdata   <= iepc_wdata;
--                  when ADDR_DEFECT2_RDATA    => sreg_defect2_rdata   <= Read Only
                    when ADDR_DGAIN            => sreg_dgain           <= iepc_wdata(10 downto 0);
                    when ADDR_AVG_EN           => sreg_avg_en          <= iepc_wdata(0);
                    when ADDR_AVG_LEVEL        => sreg_avg_level       <= iepc_wdata(3 downto 0);
--                  when ADDR_AVG_END          => sreg_avg_end         <= Read Only
                    when ADDR_IPROC_MODE       => sreg_iproc_mode      <= iepc_wdata(3 downto 0);
                    when ADDR_BRIGHT           => sreg_bright          <= iepc_wdata(16 downto 0);
                    when ADDR_CONTRAST         => sreg_contrast        <= iepc_wdata(15 downto 0);
--                  when ADDR_ROIC_DONE        => sreg_roic_done       <= Read Only
--                  when ADDR_ALIGN_DONE       => sreg_align_done      <= Read Only
--                  when ADDR_CALIB_DONE       => sreg_calib_done      <= Read Only
--                  when ADDR_PWR_DONE         => sreg_pwr_done        <= Read Only
--                  when ADDR_ERASE_DONE       => sreg_erase_done      <= Read Only
                    when ADDR_SHUTTER_MODE     => sreg_shutter         <= iepc_wdata(0);
                    when ADDR_I2C_WEN          => sreg_i2c_wen         <= iepc_wdata(0);
                    when ADDR_I2C_WSIZE        => sreg_i2c_wsize       <= iepc_wdata(3 downto 0);
                    when ADDR_I2C_WDATA        => sreg_i2c_wdata       <= iepc_wdata(31 downto 0);
                    when ADDR_I2C_REN          => sreg_i2c_ren         <= iepc_wdata(0);
                    when ADDR_I2C_RSIZE        => sreg_i2c_rsize       <= iepc_wdata(3 downto 0);
--                  when ADDR_I2C_RDATA0       => sreg_i2c_rdata0      <= Read Only
--                  when ADDR_I2C_RDATA1       => sreg_i2c_rdata1      <= Read Only
--                  when ADDR_I2C_RDATA2       => sreg_i2c_rdata2      <= Read Only
--                  when ADDR_I2C_RDATA3       => sreg_i2c_rdata3      <= Read Only
                    when ADDR_I2C_MODE         => sreg_i2c_mode        <= iepc_wdata(0);
--                  when ADDR_I2C_DONE         => sreg_i2c_done        <= Read Only
                    when ADDR_ROIC_SYNC_ACLK   => sreg_roic_sync_aclk  <= iepc_wdata(15 downto 0);
--                  when ADDR_ROIC_A0_A1       => sreg_roic_a0_a1      <= iepc_wdata(15 downto 0);
                    when ADDR_ROIC_FA          => sreg_roic_fa         <= iepc_wdata(15 downto 0);
                    when ADDR_ROIC_SYNC_DCLK   => sreg_roic_sync_dclk  <= iepc_wdata(15 downto 0);
                    when ADDR_ROIC_AFE_DCLK    => sreg_roic_afe_dclk   <= iepc_wdata(15 downto 0);
                    when ADDR_GATE_RST_CYCLE   => sreg_gate_rst_cycle  <= iepc_wdata(31 downto 0);
                    when ADDR_TEMP_EN          => sreg_temp_en         <= iepc_wdata(0);
--                  when ADDR_DEVICE_TEMP      => sreg_device_temp     <= Read Only
                    when ADDR_ROIC_SHAAZEN     => sreg_roic_shaazen    <= iepc_wdata(0);
                    when ADDR_TIMING_MODE      => sreg_timing_mode     <= iepc_wdata(1 downto 0);
--                  when ADDR_GRAB_DONE        => sreg_grab_done       <= Read Only
                    when ADDR_LDEFECT_CAL      => sreg_ldefect_mode    <= iepc_wdata(0);
                    when ADDR_RDEFECT_WEN      => sreg_rdefect_wen     <= iepc_wdata(0);
                    when ADDR_RDEFECT_ADDR     => sreg_rdefect_addr    <= iepc_wdata(3 downto 0);
                    when ADDR_RDEFECT_WDATA    => sreg_rdefect_wdata   <= iepc_wdata(15 downto 0);
--                  when ADDR_RDEFECT_RDATA    => sreg_rdefect_rdata   <= Read Only
                    when ADDR_CDEFECT_WEN      => sreg_cdefect_wen     <= iepc_wdata(0);
                    when ADDR_CDEFECT_ADDR     => sreg_cdefect_addr    <= iepc_wdata(3 downto 0);
                    when ADDR_CDEFECT_WDATA    => sreg_cdefect_wdata   <= iepc_wdata(15 downto 0);
--                  when ADDR_CDEFECT_RDATA    => sreg_cdefect_rdata   <= Read Only
                    when ADDR_LINE_TIME        => sreg_line_time       <= iepc_wdata(15 downto 0);
                    when ADDR_SD_WEN           => sreg_sd_wen          <= iepc_wdata(0);
                    when ADDR_SD_REN           => sreg_sd_ren          <= iepc_wdata(0);
                    when ADDR_SD_ADDR          => sreg_sd_addr         <= iepc_wdata(31 downto 0);
--                   when ADDR_SD_RW_END       => sreg_sd_rw_end       <= Read Only
                    when ADDR_DEFECT_MAP       => sreg_defect_map      <= iepc_wdata(0);
--                  when ADDR_ROIC_TEMP0       => sreg_roic_temp(0)    <= Read Only
--                  when ADDR_ROIC_TEMP1       => sreg_roic_temp(1)    <= Read Only
--                  when ADDR_ROIC_TEMP2       => sreg_roic_temp(2)    <= Read Only
--                  when ADDR_ROIC_TEMP3       => sreg_roic_temp(3)    <= Read Only
--                  when ADDR_ROIC_TEMP4       => sreg_roic_temp(4)    <= Read Only
--                  when ADDR_ROIC_TEMP5       => sreg_roic_temp(5)    <= Read Only
--                  when ADDR_ROIC_TEMP6       => sreg_roic_temp(6)    <= Read Only
--                  when ADDR_ROIC_TEMP7       => sreg_roic_temp(7)    <= Read Only
--                  when ADDR_ROIC_TEMP8       => sreg_roic_temp(8)    <= Read Only
--                  when ADDR_ROIC_TEMP9       => sreg_roic_temp(9)    <= Read Only
--                  when ADDR_ROIC_TEMP10      => sreg_roic_temp(10)   <= Read Only
--                  when ADDR_ROIC_TEMP11      => sreg_roic_temp(11)   <= Read Only
                    when ADDR_API_EXT_TRIG     => sreg_api_ext_trig    <= iepc_wdata(3 downto 0);
                    when ADDR_EXT_TRIG_HIGH    => sreg_ext_trig_high   <= iepc_wdata(31 downto 0);
                    when ADDR_EXT_TRIG_PERIOD  => sreg_ext_trig_period <= iepc_wdata(31 downto 0);
                    when ADDR_EXT_TRIG_ACTIVE  => sreg_ext_trig_active <= iepc_wdata(1 downto 0);
--                  when ADDR_CLK_MCLK         => sreg_clk_mclk        <= Read Only
--                  when ADDR_CLK_DCLK         => sreg_clk_dclk        <= Read Only
--                  when ADDR_CLK_ROICDCLK     => sreg_clk_roicdclk    <= Read Only
                    when ADDR_FLA_CTRL         => sreg_fla_ctrl        <= iepc_wdata(31 downto 0);
                    when ADDR_FLA_ADDR         => sreg_fla_addr        <= iepc_wdata(31 downto 0);
--                  when ADDR_FLA_DATA         => sreg_fla_data        <= iepc_wdata(31 downto 0);
                    when ADDR_FLAW_CTRL        => sreg_flaw_ctrl       <= iepc_wdata(31 downto 0);
                    when ADDR_FLAW_CMD         => sreg_flaw_cmd        <= iepc_wdata(31 downto 0);
                    when ADDR_FLAW_ADDR        => sreg_flaw_addr       <= iepc_wdata(31 downto 0);
                    when ADDR_FLAW_WDATA       => sreg_flaw_wdata      <= iepc_wdata(31 downto 0);
--                  when ADDR_FLAW_RDATA       => sreg_flaw_rdata      <= iepc_wdata(31 downto 0);
                    when ADDR_FW_BUSY          => sreg_fw_busy         <= iepc_wdata(0);
                    when ADDR_SYNC_CTRL        => sreg_sync_ctrl       <= iepc_wdata(31 downto 0);
                    when ADDR_ERASE_EN         => sreg_erase_en        <= iepc_wdata(0);
                    when ADDR_ERASE_TIME       => sreg_erase_time      <= iepc_wdata(31 downto 0);
                    when ADDR_ROIC_TP_SEL      => sreg_roic_tp_sel     <= iepc_wdata(0);
--                  when ADDR_I2C_RDATA0       => sreg_roic_tp_sel     <= Read Only;
--                  when ADDR_I2C_RDATA1       => sreg_roic_tp_sel     <= Read Only;
--                  when ADDR_I2C_RDATA2       => sreg_roic_tp_sel     <= Read Only;
--                  when ADDR_I2C_RDATA3       => sreg_roic_tp_sel     <= Read Only;
--                  when ADDR_I2C_RDATA4       => sreg_roic_tp_sel     <= Read Only;
--                  when ADDR_I2C_RDATA5       => sreg_roic_tp_sel     <= Read Only;
--                  when ADDR_I2C_RDATA6       => sreg_roic_tp_sel     <= Read Only;
--                  when ADDR_I2C_RDATA7       => sreg_roic_tp_sel     <= Read Only;
                    when ADDR_SM_CTRL          => sreg_sm_ctrl         <= iepc_wdata(31 downto 0);
                    when ADDR_BCAL_CTRL        => sreg_bcal_ctrl       <= iepc_wdata(31 downto 0);
                    when ADDR_MPC_POSOFFSET    => sreg_mpc_posoffset   <= iepc_wdata(15 downto 0);
                    when ADDR_D2M_EN           => sreg_d2m_en          <= iepc_wdata(0);
                    when ADDR_D2M_EXP_IN       => sreg_d2m_exp_in      <= iepc_wdata(0);
                    when ADDR_D2M_SEXP_TIME    => sreg_d2m_sexp_time   <= iepc_wdata(31 downto 0);
                    when ADDR_D2M_FRAME_TIME   => sreg_d2m_frame_time  <= iepc_wdata(31 downto 0);
                    when ADDR_D2M_XRST_NUM     => sreg_d2m_xrst_num    <= iepc_wdata(15 downto 0);
                    when ADDR_D2M_DRST_NUM     => sreg_d2m_drst_num    <= iepc_wdata(15 downto 0);
                    when ADDR_TOPRST_CTRL      => sreg_toprst_ctrl     <= iepc_wdata(15 downto 0);
                    when ADDR_DNR_CTRL         => sReg_DnrCtrl         <= iepc_wdata(15 downto 0);
                    when ADDR_DNR_SOBELCOEFF0  => sreg_SobelCoeff0     <= iepc_wdata(15 downto 0);
                    when ADDR_DNR_SOBELCOEFF1  => sreg_SobelCoeff1     <= iepc_wdata(15 downto 0);
                    when ADDR_DNR_SOBELCOEFF2  => sreg_SobelCoeff2     <= iepc_wdata(15 downto 0);
                    when ADDR_DNR_BLUROFFSET   => sreg_BlurOffset      <= iepc_wdata(15 downto 0);
                    when ADDR_ACC_CTRL         => sReg_AccCtrl         <= iepc_wdata(15 downto 0);
                    when ADDR_EXT_TRIG_EN      => sreg_ExtTrigEn       <= iepc_wdata(0);
                    when ADDR_EXT_RST_MODE     => sreg_ExtRst_MODE     <= iepc_wdata( 7 downto 0);
                    when ADDR_EXT_RST_DetTime  => sreg_ExtRst_DetTime  <= iepc_wdata(31 downto 0);
                    when ADDR_LED_CTRL         => sreg_led_ctrl        <= iepc_wdata( 3 downto 0);
                    when ADDR_OSD_CTRL         => sreg_osd_ctrl        <= iepc_wdata(15 downto 0);
                    when ADDR_PWDAC_CMD        => sreg_pwdac_cmd       <= iepc_wdata(15 downto 0);
                    when ADDR_PWDAC_TICKTIME   => sreg_pwdac_ticktime  <= iepc_wdata(31 downto 0);
                    when ADDR_PWDAC_TICKINC    => sreg_pwdac_tickinc   <= iepc_wdata(11 downto 0);
                    when ADDR_PWDAC_TRIG       => sreg_pwdac_trig      <= iepc_wdata(0);
                    when ADDR_TESTPOINT1       => sreg_testpoint1      <= iepc_wdata(15 downto 0);
                    when ADDR_TESTPOINT2       => sreg_testpoint2      <= iepc_wdata(15 downto 0);
                    when ADDR_TESTPOINT3       => sreg_testpoint3      <= iepc_wdata(15 downto 0);
                    when ADDR_TESTPOINT4       => sreg_testpoint4      <= iepc_wdata(15 downto 0);
                    when ADDR_ROIC_STR         => sreg_roic_str        <= iepc_wdata( 7 downto 0);
                    when ADDR_EDGE_CTRL        => sreg_edge_ctrl       <= iepc_wdata(15 downto 0);
                    when ADDR_EDGE_VALUE       => sreg_edge_value      <= iepc_wdata(15 downto 0);
                    when ADDR_EDGE_TOP         => sreg_edge_top        <= iepc_wdata(15 downto 0);
                    when ADDR_EDGE_LEFT        => sreg_edge_left       <= iepc_wdata(15 downto 0);
                    when ADDR_EDGE_RIGHT       => sreg_edge_right      <= iepc_wdata(15 downto 0);
                    when ADDR_EDGE_BOTTOM      => sreg_edge_bottom     <= iepc_wdata(15 downto 0);
                    when ADDR_BNC_CTRL         => sreg_bnc_ctrl        <= iepc_wdata(15 downto 0);
                    when ADDR_BNC_HIGH         => sreg_bnc_high        <= iepc_wdata(15 downto 0);
                    when ADDR_OFGA_LIM         => sreg_ofga_lim        <= iepc_wdata(15 downto 0);
                    when ADDR_EQ_CTRL          => sreg_EqCtrl          <= iepc_wdata(15 downto 0);
                    when ADDR_EQ_TOPVAL        => sreg_EqTopVal        <= iepc_wdata(15 downto 0);
                    when ADDR_FPGA_REBOOT      => sreg_fpga_reboot     <= iepc_wdata(0);
                    when others => NULL;
                end case;

                wr_rdy <= '1';
                wr_blk <= '1';
            else
                wr_rdy <= '0';
                if (iepc_cs_n = '1') then
                    wr_blk <= '0';
                end if;
            end if;
        end if;
    end process;

    process (isys_clk, isys_rstn)
    begin
        if (isys_rstn = '0') then
            rd_rdy     <= '0';
            rd_blk     <= '0';
            oepc_rdata <= (others => '0');
        elsif (isys_clk'event and isys_clk = '1') then
-- █▀█ █▀▀ ▄▀█ █▀▄
-- █▀▄ ██▄ █▀█ █▄▀
            if (iepc_cs_n = '0' and iepc_we_n = '1' and rd_blk = '0') then
                if (srst_rdata = '1') then
                    oepc_rdata <= (others => '0');
                    srst_rdata <= '0';
                else
                    case iepc_addr is
                        when ADDR_OUT_EN           => oepc_rdata(0)           <= sreg_out_en;
                        when ADDR_WIDTH            => oepc_rdata(11 downto 0) <= sreg_width;
                        when ADDR_HEIGHT           => oepc_rdata(11 downto 0) <= sreg_height;
                        when ADDR_OFFSETX          => oepc_rdata(11 downto 0) <= sreg_offsetx;
                        when ADDR_OFFSETY          => oepc_rdata(11 downto 0) <= sreg_offsety;
                        when ADDR_REV_X            => oepc_rdata(0)           <= sreg_rev_x;
                        when ADDR_REV_Y            => oepc_rdata(0)           <= sreg_rev_y;
                        when ADDR_TP_SEL           => oepc_rdata(3 downto 0)  <= sreg_tp_sel;
                        when ADDR_TP_MODE          => oepc_rdata(0)           <= sreg_tp_mode;
                        when ADDR_TP_DTIME         => oepc_rdata(15 downto 0) <= sreg_tp_dtime;
                        when ADDR_TP_VALUE         => oepc_rdata(15 downto 0) <= sreg_tp_value;
                        when ADDR_PWR_MODE         => oepc_rdata(0)           <= sreg_pwr_mode;
                        when ADDR_GRAB_EN          => oepc_rdata(0)           <= sreg_grab_en;
                        when ADDR_GATE_EN          => oepc_rdata(7 downto 0)  <= sreg_gate_en;
                        when ADDR_IMG_MODE         => oepc_rdata(2 downto 0)  <= sreg_img_mode;
                        when ADDR_RST_MODE         => oepc_rdata(1 downto 0)  <= sreg_rst_mode;
                        when ADDR_RST_NUM          => oepc_rdata(3 downto 0)  <= sreg_rst_num;
                        when ADDR_TRIG_MODE        => oepc_rdata(1 downto 0)  <= sreg_trig_mode;
                        when ADDR_TRIG_DELAY       => oepc_rdata(15 downto 0) <= sreg_trig_delay;
                        when ADDR_TRIG_VALID       => oepc_rdata(0)           <= sreg_trig_valid;
                        when ADDR_TRIG_FILT        => oepc_rdata(7 downto 0)  <= sreg_trig_filt;
                        when ADDR_ROIC_CDS1        => oepc_rdata(15 downto 0) <= sreg_roic_cds1;
                        when ADDR_ROIC_CDS2        => oepc_rdata(15 downto 0) <= sreg_roic_cds2;
                        when ADDR_ROIC_INTRST      => oepc_rdata(15 downto 0) <= sreg_roic_intrst;
                        when ADDR_GATE_OE          => oepc_rdata(15 downto 0) <= sreg_gate_oe;
                        when ADDR_GATE_XON         => oepc_rdata(31 downto 0) <= sreg_gate_xon;
                        when ADDR_GATE_XON_FLK     => oepc_rdata(31 downto 0) <= sreg_gate_xon_flk;
                        when ADDR_GATE_FLK         => oepc_rdata(31 downto 0) <= sreg_gate_flk;
                        when ADDR_ROIC_DEAD        => oepc_rdata(15 downto 0) <= sreg_roic_dead;
                        when ADDR_ROIC_MUTE        => oepc_rdata(15 downto 0) <= sreg_roic_mute;
                        when ADDR_SEXP_TIME        => oepc_rdata              <= sreg_sexp_time;
                        when ADDR_EXP_TIME         => oepc_rdata              <= sreg_exp_time;
                        when ADDR_FRAME_TIME       => oepc_rdata              <= sreg_frame_time;
                        when ADDR_FRAME_NUM        => oepc_rdata(15 downto 0) <= sreg_frame_num;
                        when ADDR_FRAME_VAL        => oepc_rdata(15 downto 0) <= sreg_frame_val;
                        when ADDR_FRAME_CNT        => oepc_rdata(31 downto 0) <= sreg_frame_cnt;
                        when ADDR_EXT_EXP_TIME     => oepc_rdata              <= sreg_ext_exp_time;
                        when ADDR_EXT_FRAME_TIME   => oepc_rdata              <= sreg_ext_frame_time;
                        when ADDR_ROIC_EN          => oepc_rdata(0)           <= sreg_roic_en;
                        when ADDR_ROIC_ADDR        => oepc_rdata(7 downto 0)  <= sreg_roic_addr;
                        when ADDR_ROIC_WDATA       => oepc_rdata(15 downto 0) <= sreg_roic_wdata;
                        when ADDR_ROIC_RDATA       => oepc_rdata(15 downto 0) <= sreg_roic_rdata;
                        when ADDR_REQ_ALIGN        => oepc_rdata(0)           <= sreg_req_align;
                        when ADDR_OUT_MODE         => oepc_rdata(3 downto 0)  <= sreg_out_mode;
                        when ADDR_DEBUG            => oepc_rdata(15 downto 0) <= sreg_debug;
                        when ADDR_DDR_CH_EN        => oepc_rdata(7 downto 0)  <= sreg_ddr_ch_en;
                        when ADDR_DDR_BASE_ADDR    => oepc_rdata              <= sreg_ddr_base_addr;
                        when ADDR_DDR_CH0_WADDR    => oepc_rdata(29 downto 0) <= sreg_ddr_ch0_waddr;
                        when ADDR_DDR_CH1_WADDR    => oepc_rdata(29 downto 0) <= sreg_ddr_ch1_waddr;
                        when ADDR_DDR_CH2_WADDR    => oepc_rdata(29 downto 0) <= sreg_ddr_ch2_waddr;
                        when ADDR_DDR_CH3_WADDR    => oepc_rdata(29 downto 0) <= sreg_ddr_ch3_waddr;
                        when ADDR_DDR_CH4_WADDR    => oepc_rdata(29 downto 0) <= sreg_ddr_ch4_waddr;
                        when ADDR_DDR_CH0_RADDR    => oepc_rdata(29 downto 0) <= sreg_ddr_ch0_raddr;
                        when ADDR_DDR_CH1_RADDR    => oepc_rdata(29 downto 0) <= sreg_ddr_ch1_raddr;
                        when ADDR_DDR_CH2_RADDR    => oepc_rdata(29 downto 0) <= sreg_ddr_ch2_raddr;
                        when ADDR_DDR_CH3_RADDR    => oepc_rdata(29 downto 0) <= sreg_ddr_ch3_raddr;
                        when ADDR_DDR_CH4_RADDR    => oepc_rdata(29 downto 0) <= sreg_ddr_ch4_raddr;
                        when ADDR_DDR_OUT          => oepc_rdata(2 downto 0)  <= sreg_ddr_out;
                        when ADDR_DEBUG_MODE       => oepc_rdata(0)           <= sreg_debug_mode;
                        when ADDR_GAIN_CAL         => oepc_rdata(0)           <= sreg_gain_cal;
                        when ADDR_OFFSET_CAL       => oepc_rdata(0)           <= sreg_offset_cal;
                        when ADDR_MPC_CTRL         => oepc_rdata(3 downto 0)  <= sreg_mpc_ctrl;
                        when ADDR_MPC_NUM          => oepc_rdata(3 downto 0)  <= sreg_mpc_num;
                        when ADDR_MPC_POINT0       => oepc_rdata(15 downto 0) <= sreg_mpc_point0;
                        when ADDR_MPC_POINT1       => oepc_rdata(15 downto 0) <= sreg_mpc_point1;
                        when ADDR_MPC_POINT2       => oepc_rdata(15 downto 0) <= sreg_mpc_point2;
                        when ADDR_MPC_POINT3       => oepc_rdata(15 downto 0) <= sreg_mpc_point3;
                        when ADDR_DEFECT_CAL       => oepc_rdata(0)           <= sreg_defect_mode;
                        when ADDR_DEFECT_WEN       => oepc_rdata(0)           <= sreg_defect_wen;
                        when ADDR_DEFECT_ADDR      => oepc_rdata(15 downto 0) <= sreg_defect_addr;
                        when ADDR_DEFECT_WDATA     => oepc_rdata              <= sreg_defect_wdata;
                        when ADDR_DEFECT_RDATA     => oepc_rdata              <= sreg_defect_rdata;
                        when ADDR_DEFECT2_WEN      => oepc_rdata(0)           <= sreg_defect2_wen;
                        when ADDR_DEFECT2_ADDR     => oepc_rdata(15 downto 0) <= sreg_defect2_addr;
                        when ADDR_DEFECT2_WDATA    => oepc_rdata              <= sreg_defect2_wdata;
                        when ADDR_DEFECT2_RDATA    => oepc_rdata              <= sreg_defect2_rdata;
                        when ADDR_DGAIN            => oepc_rdata(10 downto 0) <= sreg_dgain;
                        when ADDR_AVG_EN           => oepc_rdata(0)           <= sreg_avg_en;
                        when ADDR_AVG_LEVEL        => oepc_rdata(3 downto 0)  <= sreg_avg_level;
                        when ADDR_AVG_END          => oepc_rdata(15 downto 0) <= sreg_avg_end;
                        when ADDR_IPROC_MODE       => oepc_rdata(3 downto 0)  <= sreg_iproc_mode;
                        when ADDR_BRIGHT           => oepc_rdata(16 downto 0) <= sreg_bright;
                        when ADDR_CONTRAST         => oepc_rdata(15 downto 0) <= sreg_contrast;
                        when ADDR_FPGA_VER         => oepc_rdata(31 downto 0) <= conv_std_logic_vector(FUNC_MODEL_NAME(GNR_MODEL), 12) & FPGA_VER;
                        when ADDR_ROIC_DONE        => oepc_rdata(0)           <= sreg_roic_done;
                        when ADDR_ALIGN_DONE       => oepc_rdata(0)           <= sreg_align_done;
                        when ADDR_CALIB_DONE       => oepc_rdata(0)           <= sreg_calib_done;
                        when ADDR_PWR_DONE         => oepc_rdata(0)           <= sreg_pwr_done;
                        when ADDR_ERASE_DONE       => oepc_rdata(0)           <= sreg_erase_done;
                        when ADDR_SHUTTER_MODE     => oepc_rdata(0)           <= sreg_shutter;
                        when ADDR_I2C_WEN          => oepc_rdata(0)           <= sreg_i2c_wen;
                        when ADDR_I2C_WSIZE        => oepc_rdata(3 downto 0)  <= sreg_i2c_wsize;
                        when ADDR_I2C_WDATA        => oepc_rdata(31 downto 0) <= sreg_i2c_wdata;
                        when ADDR_I2C_REN          => oepc_rdata(0)           <= sreg_i2c_ren;
                        when ADDR_I2C_RSIZE        => oepc_rdata(3 downto 0)  <= sreg_i2c_rsize;
                        when ADDR_I2C_RDATA0       => oepc_rdata(31 downto 0) <= sreg_i2c_rdata0;
                        when ADDR_I2C_RDATA1       => oepc_rdata(31 downto 0) <= sreg_i2c_rdata1;
                        when ADDR_I2C_RDATA2       => oepc_rdata(31 downto 0) <= sreg_i2c_rdata2;
                        when ADDR_I2C_RDATA3       => oepc_rdata(31 downto 0) <= sreg_i2c_rdata3;
                        when ADDR_I2C_MODE         => oepc_rdata(0)           <= sreg_i2c_mode;
                        when ADDR_I2C_DONE         => oepc_rdata(0)           <= sreg_i2c_done;
                        when ADDR_ROIC_SYNC_ACLK   => oepc_rdata(15 downto 0) <= sreg_roic_sync_aclk;
                        when ADDR_ROIC_FA          => oepc_rdata(15 downto 0) <= sreg_roic_fa;
                        when ADDR_ROIC_SYNC_DCLK   => oepc_rdata(15 downto 0) <= sreg_roic_sync_dclk;
                        when ADDR_ROIC_AFE_DCLK    => oepc_rdata(15 downto 0) <= sreg_roic_afe_dclk;
                        when ADDR_GATE_RST_CYCLE   => oepc_rdata(31 downto 0) <= sreg_gate_rst_cycle;
                        when ADDR_TEMP_EN          => oepc_rdata(0)           <= sreg_temp_en;
                        when ADDR_DEVICE_TEMP      => oepc_rdata(15 downto 0) <= sreg_device_temp;
                        when ADDR_ROIC_SHAAZEN     => oepc_rdata(0)           <= sreg_roic_shaazen;
                        when ADDR_TIMING_MODE      => oepc_rdata(1 downto 0)  <= sreg_timing_mode;
                        when ADDR_GRAB_DONE        => oepc_rdata(0)           <= sreg_grab_done;
                        when ADDR_LDEFECT_CAL      => oepc_rdata(0)           <= sreg_ldefect_mode;
                        when ADDR_RDEFECT_WEN      => oepc_rdata(0)           <= sreg_rdefect_wen;
                        when ADDR_RDEFECT_ADDR     => oepc_rdata(3 downto 0)  <= sreg_rdefect_addr;
                        when ADDR_RDEFECT_WDATA    => oepc_rdata(15 downto 0) <= sreg_rdefect_wdata;
                        when ADDR_RDEFECT_RDATA    => oepc_rdata(15 downto 0) <= sreg_rdefect_rdata;
                        when ADDR_CDEFECT_WEN      => oepc_rdata(0)           <= sreg_cdefect_wen;
                        when ADDR_CDEFECT_ADDR     => oepc_rdata(3 downto 0)  <= sreg_cdefect_addr;
                        when ADDR_CDEFECT_WDATA    => oepc_rdata(15 downto 0) <= sreg_cdefect_wdata;
                        when ADDR_CDEFECT_RDATA    => oepc_rdata(15 downto 0) <= sreg_cdefect_rdata;
                        when ADDR_LINE_TIME        => oepc_rdata(15 downto 0) <= sreg_line_time;
                        when ADDR_SD_WEN           => oepc_rdata(0)           <= sreg_sd_wen;
                        when ADDR_SD_REN           => oepc_rdata(0)           <= sreg_sd_ren;
                        when ADDR_SD_ADDR          => oepc_rdata(31 downto 0) <= sreg_sd_addr;
                        when ADDR_SD_RW_END        => oepc_rdata(0)           <= sreg_sd_rw_end;
                        when ADDR_DEFECT_MAP       => oepc_rdata(0)           <= sreg_defect_map;
                        when ADDR_ROIC_TEMP0       => oepc_rdata(15 downto 0) <= sreg_roic_temp(0 );
                        when ADDR_ROIC_TEMP1       => oepc_rdata(15 downto 0) <= sreg_roic_temp(1 );
                        when ADDR_ROIC_TEMP2       => oepc_rdata(15 downto 0) <= sreg_roic_temp(2 );
                        when ADDR_ROIC_TEMP3       => oepc_rdata(15 downto 0) <= sreg_roic_temp(3 );
                        when ADDR_ROIC_TEMP4       => oepc_rdata(15 downto 0) <= sreg_roic_temp(4 );
                        when ADDR_ROIC_TEMP5       => oepc_rdata(15 downto 0) <= sreg_roic_temp(5 );
                        when ADDR_ROIC_TEMP6       => oepc_rdata(15 downto 0) <= sreg_roic_temp(6 );
                        when ADDR_ROIC_TEMP7       => oepc_rdata(15 downto 0) <= sreg_roic_temp(7 );
                        when ADDR_ROIC_TEMP8       => oepc_rdata(15 downto 0) <= sreg_roic_temp(8 );
                        when ADDR_ROIC_TEMP9       => oepc_rdata(15 downto 0) <= sreg_roic_temp(9 );
                        when ADDR_ROIC_TEMP10      => oepc_rdata(15 downto 0) <= sreg_roic_temp(10);
                        when ADDR_ROIC_TEMP11      => oepc_rdata(15 downto 0) <= sreg_roic_temp(11);
                        when ADDR_API_EXT_TRIG     => oepc_rdata(3 downto 0)  <= sreg_api_ext_trig;
                        when ADDR_EXT_TRIG_HIGH    => oepc_rdata(31 downto 0) <= sreg_ext_trig_high;
                        when ADDR_EXT_TRIG_PERIOD  => oepc_rdata(31 downto 0) <= sreg_ext_trig_period;
                        when ADDR_EXT_TRIG_ACTIVE  => oepc_rdata(1 downto 0)  <= sreg_ext_trig_active;
                        when ADDR_CLK_MCLK         => oepc_rdata(15 downto 0) <= sreg_clk_mclk;
                        when ADDR_CLK_DCLK         => oepc_rdata(15 downto 0) <= sreg_clk_dclk;
                        when ADDR_CLK_ROICDCLK     => oepc_rdata(15 downto 0) <= sreg_clk_roicdclk;
                        when ADDR_FLA_CTRL         => oepc_rdata(31 downto 0) <= sreg_fla_ctrl;
                        when ADDR_FLA_ADDR         => oepc_rdata(31 downto 0) <= sreg_fla_addr;
                        when ADDR_FLA_DATA         => oepc_rdata(31 downto 0) <= sreg_fla_data;
                        when ADDR_FLAW_CTRL        => oepc_rdata(31 downto 0) <= sreg_flaw_ctrl;
                        when ADDR_FLAW_CMD         => oepc_rdata(31 downto 0) <= sreg_flaw_cmd;
                        when ADDR_FLAW_ADDR        => oepc_rdata(31 downto 0) <= sreg_flaw_addr;
                        when ADDR_FLAW_WDATA       => oepc_rdata(31 downto 0) <= sreg_flaw_wdata;
                        when ADDR_FLAW_RDATA       => oepc_rdata(31 downto 0) <= sreg_flaw_rdata;
                        when ADDR_SYNC_CTRL        => oepc_rdata(31 downto 0) <= sreg_sync_ctrl;
                        when ADDR_FW_BUSY          => oepc_rdata(0)           <= sreg_fw_busy;
                        when ADDR_ERASE_EN         => oepc_rdata(0)           <= sreg_erase_en;
                        when ADDR_ERASE_TIME       => oepc_rdata(31 downto 0) <= sreg_erase_time;
                        when ADDR_ROIC_TP_SEL      => oepc_rdata(0)           <= sreg_roic_tp_sel;
                        when ADDR_SYNC_RCNT0       => oepc_rdata(31 downto 0) <= sreg_sync_rcnt0;
                        when ADDR_SYNC_RCNT1       => oepc_rdata(31 downto 0) <= sreg_sync_rcnt1;
                        when ADDR_SYNC_RCNT2       => oepc_rdata(31 downto 0) <= sreg_sync_rcnt2;
                        when ADDR_SYNC_RCNT3       => oepc_rdata(31 downto 0) <= sreg_sync_rcnt3;
                        when ADDR_SYNC_RCNT4       => oepc_rdata(31 downto 0) <= sreg_sync_rcnt4;
                        when ADDR_SYNC_RCNT5       => oepc_rdata(31 downto 0) <= sreg_sync_rcnt5;
                        when ADDR_SYNC_RCNT6       => oepc_rdata(31 downto 0) <= sreg_sync_rcnt6;
                        when ADDR_SYNC_RCNT7       => oepc_rdata(31 downto 0) <= sreg_sync_rcnt7;
                        when ADDR_SYNC_RCNT8       => oepc_rdata(31 downto 0) <= sreg_sync_rcnt8;
                        when ADDR_SYNC_RCNT9       => oepc_rdata(31 downto 0) <= sreg_sync_rcnt9;
                        when ADDR_SYNC_RDATA_AVCN0 => oepc_rdata(31 downto 0) <= sreg_sync_rdata_avcn0;
                        when ADDR_SYNC_RDATA_AVCN1 => oepc_rdata(31 downto 0) <= sreg_sync_rdata_avcn1;
                        when ADDR_SYNC_RDATA_AVCN2 => oepc_rdata(31 downto 0) <= sreg_sync_rdata_avcn2;
                        when ADDR_SYNC_RDATA_AVCN3 => oepc_rdata(31 downto 0) <= sreg_sync_rdata_avcn3;
                        when ADDR_SYNC_RDATA_AVCN4 => oepc_rdata(31 downto 0) <= sreg_sync_rdata_avcn4;
                        when ADDR_SYNC_RDATA_AVCN5 => oepc_rdata(31 downto 0) <= sreg_sync_rdata_avcn5;
                        when ADDR_SYNC_RDATA_AVCN6 => oepc_rdata(31 downto 0) <= sreg_sync_rdata_avcn6;
                        when ADDR_SYNC_RDATA_AVCN7 => oepc_rdata(31 downto 0) <= sreg_sync_rdata_avcn7;
                        when ADDR_SYNC_RDATA_AVCN8 => oepc_rdata(31 downto 0) <= sreg_sync_rdata_avcn8;
                        when ADDR_SYNC_RDATA_AVCN9 => oepc_rdata(31 downto 0) <= sreg_sync_rdata_avcn9;
                        when ADDR_SYNC_RDATA_BGLW0 => oepc_rdata(31 downto 0) <= sreg_sync_rdata_bglw0;
                        when ADDR_SYNC_RDATA_BGLW1 => oepc_rdata(31 downto 0) <= sreg_sync_rdata_bglw1;
                        when ADDR_SYNC_RDATA_BGLW2 => oepc_rdata(31 downto 0) <= sreg_sync_rdata_bglw2;
                        when ADDR_SYNC_RDATA_BGLW3 => oepc_rdata(31 downto 0) <= sreg_sync_rdata_bglw3;
                        when ADDR_SYNC_RDATA_BGLW4 => oepc_rdata(31 downto 0) <= sreg_sync_rdata_bglw4;
                        when ADDR_SYNC_RDATA_BGLW5 => oepc_rdata(31 downto 0) <= sreg_sync_rdata_bglw5;
                        when ADDR_SYNC_RDATA_BGLW6 => oepc_rdata(31 downto 0) <= sreg_sync_rdata_bglw6;
                        when ADDR_SYNC_RDATA_BGLW7 => oepc_rdata(31 downto 0) <= sreg_sync_rdata_bglw7;
                        when ADDR_SYNC_RDATA_BGLW8 => oepc_rdata(31 downto 0) <= sreg_sync_rdata_bglw8;
                        when ADDR_SYNC_RDATA_BGLW9 => oepc_rdata(31 downto 0) <= sreg_sync_rdata_bglw9;
                        when ADDR_SM_CTRL          => oepc_rdata(31 downto 0) <= sreg_sm_ctrl;
                        when ADDR_SM_DATA0         => oepc_rdata(31 downto 0) <= sreg_sm_data0;
                        when ADDR_SM_DATA1         => oepc_rdata(31 downto 0) <= sreg_sm_data1;
                        when ADDR_SM_DATA2         => oepc_rdata(31 downto 0) <= sreg_sm_data2;
                        when ADDR_SM_DATA3         => oepc_rdata(31 downto 0) <= sreg_sm_data3;
                        when ADDR_SM_DATA4         => oepc_rdata(31 downto 0) <= sreg_sm_data4;
                        when ADDR_SM_DATA5         => oepc_rdata(31 downto 0) <= sreg_sm_data5;
                        when ADDR_SM_DATA6         => oepc_rdata(31 downto 0) <= sreg_sm_data6;
                        when ADDR_SM_DATA7         => oepc_rdata(31 downto 0) <= sreg_sm_data7;
                        when ADDR_CLK_UICLK        => oepc_rdata(15 downto 0) <= sreg_clk_uiclk; --# 260123
                        when ADDR_BCAL_CTRL        => oepc_rdata(31 downto 0) <= sreg_bcal_ctrl;
                        when ADDR_BCAL_DATA        => oepc_rdata(31 downto 0) <= sreg_bcal_data;
                        when ADDR_MPC_POSOFFSET    => oepc_rdata(15 downto 0) <= sreg_mpc_posoffset;
                        when ADDR_D2M_EN           => oepc_rdata(0)           <= sreg_d2m_en;
                        when ADDR_D2M_EXP_IN       => oepc_rdata(0)           <= sreg_d2m_exp_in;
                        when ADDR_D2M_SEXP_TIME    => oepc_rdata(31 downto 0) <= sreg_d2m_sexp_time;
                        when ADDR_D2M_FRAME_TIME   => oepc_rdata(31 downto 0) <= sreg_d2m_frame_time;
                        when ADDR_D2M_XRST_NUM     => oepc_rdata(15 downto 0) <= sreg_d2m_xrst_num;
                        when ADDR_D2M_DRST_NUM     => oepc_rdata(15 downto 0) <= sreg_d2m_drst_num;
                        when ADDR_TOPRST_CTRL      => oepc_rdata(15 downto 0) <= sreg_toprst_ctrl;
                        when ADDR_DNR_CTRL         => oepc_rdata(15 downto 0) <= sReg_DnrCtrl;
                        when ADDR_DNR_SOBELCOEFF0  => oepc_rdata(15 downto 0) <= sreg_SobelCoeff0;
                        when ADDR_DNR_SOBELCOEFF1  => oepc_rdata(15 downto 0) <= sreg_SobelCoeff1;
                        when ADDR_DNR_SOBELCOEFF2  => oepc_rdata(15 downto 0) <= sreg_SobelCoeff2;
                        when ADDR_DNR_BLUROFFSET   => oepc_rdata(15 downto 0) <= sreg_BlurOffset;
                        when ADDR_ACC_CTRL         => oepc_rdata(15 downto 0) <= sReg_AccCtrl;
                        when ADDR_ACC_STAT         => oepc_rdata(15 downto 0) <= sReg_AccStat;
                        when ADDR_EXT_TRIG_EN      => oepc_rdata(0)           <= sreg_ExtTrigEn;
                        when ADDR_EXT_RST_MODE     => oepc_rdata( 7 downto 0) <= sreg_ExtRst_MODE;
                        when ADDR_EXT_RST_DetTime  => oepc_rdata(31 downto 0) <= sreg_ExtRst_DetTime;
                        when ADDR_LED_CTRL         => oepc_rdata( 3 downto 0) <= sreg_led_ctrl;
                        when ADDR_TRIGCNT          => oepc_rdata(15 downto 0) <= sreg_trigcnt;
                        when ADDR_OSD_CTRL         => oepc_rdata(15 downto 0) <= sreg_osd_ctrl;
                        when ADDR_PWDAC_CMD        => oepc_rdata(15 downto 0) <= sreg_pwdac_cmd;
                        when ADDR_PWDAC_TICKTIME   => oepc_rdata(31 downto 0) <= sreg_pwdac_ticktime;
                        when ADDR_PWDAC_TICKINC    => oepc_rdata(11 downto 0) <= sreg_pwdac_tickinc;
                        when ADDR_PWDAC_TRIG       => oepc_rdata(0)           <= sreg_pwdac_trig;
                        when ADDR_PWDAC_CURRLEVEL  => oepc_rdata(15 downto 0) <= sreg_pwdac_currlevel;
                        when ADDR_TESTPOINT1       => oepc_rdata(15 downto 0) <= sreg_testpoint1;
                        when ADDR_TESTPOINT2       => oepc_rdata(15 downto 0) <= sreg_testpoint2;
                        when ADDR_TESTPOINT3       => oepc_rdata(15 downto 0) <= sreg_testpoint3;
                        when ADDR_TESTPOINT4       => oepc_rdata(15 downto 0) <= sreg_testpoint4;
                        when ADDR_ROIC_STR         => oepc_rdata( 7 downto 0) <= sreg_roic_str;
                        when ADDR_EDGE_CTRL        => oepc_rdata(15 downto 0) <= sreg_edge_ctrl;
                        when ADDR_EDGE_VALUE       => oepc_rdata(15 downto 0) <= sreg_edge_value;
                        when ADDR_EDGE_TOP         => oepc_rdata(15 downto 0) <= sreg_edge_top;
                        when ADDR_EDGE_LEFT        => oepc_rdata(15 downto 0) <= sreg_edge_left;
                        when ADDR_EDGE_RIGHT       => oepc_rdata(15 downto 0) <= sreg_edge_right;
                        when ADDR_EDGE_BOTTOM      => oepc_rdata(15 downto 0) <= sreg_edge_bottom;
                        when ADDR_FREERUN_CNT      => oepc_rdata(31 downto 0) <= sreg_freeruncnt;
                        when ADDR_FPGA_DATE        => oepc_rdata(31 downto 0) <= FPGA_DATE;
                        when ADDR_BNC_CTRL         => oepc_rdata(15 downto 0) <= sreg_bnc_ctrl;
                        when ADDR_BNC_HIGH         => oepc_rdata(15 downto 0) <= sreg_bnc_high;
                        when ADDR_EQ_CTRL          => oepc_rdata(15 downto 0) <= sreg_EqCtrl  ;
                        when ADDR_EQ_TOPVAL        => oepc_rdata(15 downto 0) <= sreg_EqTopVal;
                        when ADDR_OFGA_LIM         => oepc_rdata(15 downto 0) <= sreg_ofga_lim;
                        when others => NULL;
                    end case;

                    rd_rdy <= '1';
                    rd_blk <= '1';
                end if;
            else
                srst_rdata <= '1';
                rd_rdy     <= '0';
                if (iepc_cs_n = '1') then
                    rd_blk <= '0';
                end if;
            end if;
        end if;
    end process;

    oreg_out_en   <= sreg_out_en;
    oreg_width    <= sreg_width;
    oreg_height   <= sreg_height;
    oreg_offsetx  <= sreg_offsetx;
    oreg_offsety  <= sreg_offsety;
    oreg_rev_x    <= sreg_rev_x;
    oreg_rev_y    <= sreg_rev_y;
    oreg_tp_sel   <= sreg_tp_sel;
    oreg_tp_mode  <= sreg_tp_mode;
    oreg_tp_dtime <= sreg_tp_dtime;
    oreg_tp_value <= sreg_tp_value;

    oreg_pwr_mode       <= sreg_pwr_mode;
    oreg_grab_en        <= sreg_grab_en;
    oreg_gate_en        <= sreg_gate_en;
    oreg_img_mode       <= sreg_img_mode;
    oreg_timing_mode    <= sreg_timing_mode;
    oreg_rst_mode       <= sreg_rst_mode;
    oreg_rst_num        <= sreg_rst_num;
    oreg_erase_en       <= sreg_erase_en;
    oreg_erase_time     <= sreg_erase_time;
    oreg_shutter        <= sreg_shutter;
    oreg_trig_mode      <= sreg_trig_mode;
    oreg_trig_delay     <= sreg_trig_delay;
    oreg_trig_filt      <= sreg_trig_filt;
    oreg_trig_valid     <= sreg_trig_valid;
    oreg_roic_shaazen   <= sreg_roic_shaazen;
    oreg_roic_tp_sel    <= sreg_roic_tp_sel;
    oreg_roic_fa        <= sreg_roic_fa;
    oreg_roic_cds1      <= sreg_roic_cds1;
    oreg_roic_cds2      <= sreg_roic_cds2;
    oreg_roic_intrst    <= sreg_roic_intrst;
    oreg_roic_sync_aclk <= sreg_roic_sync_aclk;
    oreg_roic_dead      <= sreg_roic_dead;
    oreg_roic_mute      <= sreg_roic_mute;
    oreg_roic_sync_dclk <= sreg_roic_sync_dclk;
    oreg_roic_afe_dclk  <= sreg_roic_afe_dclk;
    oreg_gate_oe        <= sreg_gate_oe;
    oreg_gate_xon       <= sreg_gate_xon;
    oreg_gate_xon_flk   <= sreg_gate_xon_flk;
    oreg_gate_flk       <= sreg_gate_flk;
    oreg_gate_rst_cycle <= sreg_gate_rst_cycle;
    oreg_sexp_time      <= sreg_sexp_time;
    oreg_exp_time       <= sreg_exp_time;
    oreg_frame_time     <= sreg_frame_time;
    oreg_frame_num      <= sreg_frame_num;
    oreg_frame_val      <= sreg_frame_val;
    oreg_roic_en        <= sreg_roic_en;
    oreg_roic_addr      <= sreg_roic_addr;
    oreg_roic_wdata     <= sreg_roic_wdata;
    oreg_req_align      <= sreg_req_align;
    oreg_out_mode       <= sreg_out_mode;

    oreg_ddr_ch_en     <= sreg_ddr_ch_en;
    oreg_ddr_base_addr <= sreg_ddr_base_addr;
    oreg_ddr_ch0_waddr <= sreg_ddr_ch0_waddr;
    oreg_ddr_ch1_waddr <= sreg_ddr_ch1_waddr;
    oreg_ddr_ch2_waddr <= sreg_ddr_ch2_waddr;
    oreg_ddr_ch3_waddr <= sreg_ddr_ch3_waddr;
    oreg_ddr_ch4_waddr <= sreg_ddr_ch4_waddr;
    oreg_ddr_ch0_raddr <= sreg_ddr_ch0_raddr;
    oreg_ddr_ch1_raddr <= sreg_ddr_ch1_raddr;
    oreg_ddr_ch2_raddr <= sreg_ddr_ch2_raddr;
    oreg_ddr_ch3_raddr <= sreg_ddr_ch3_raddr;
    oreg_ddr_ch4_raddr <= sreg_ddr_ch4_raddr;
    oreg_ddr_out       <= sreg_ddr_out;
    oreg_line_time     <= sreg_line_time;
    oreg_debug_mode    <= sreg_debug_mode;
    oreg_gain_cal      <= sreg_gain_cal;
    oreg_offset_cal    <= sreg_offset_cal;
    oreg_mpc_ctrl      <= sreg_mpc_ctrl;
    oreg_mpc_num       <= sreg_mpc_num;
    oreg_mpc_point0    <= sreg_mpc_point0;
    oreg_mpc_point1    <= sreg_mpc_point1;
    oreg_mpc_point2    <= sreg_mpc_point2;
    oreg_mpc_point3    <= sreg_mpc_point3;
    oreg_defect_mode   <= sreg_defect_mode;
    oreg_defect_wen    <= sreg_defect_wen;
    oreg_defect_addr   <= sreg_defect_addr;
    oreg_defect_wdata  <= sreg_defect_wdata;
    oreg_defect2_wen   <= sreg_defect2_wen;
    oreg_defect2_addr  <= sreg_defect2_addr;
    oreg_defect2_wdata <= sreg_defect2_wdata;
    oreg_ldefect_mode  <= sreg_ldefect_mode;
    oreg_rdefect_wen   <= sreg_rdefect_wen;
    oreg_rdefect_addr  <= sreg_rdefect_addr;
    oreg_rdefect_wdata <= sreg_rdefect_wdata;
    oreg_cdefect_wen   <= sreg_cdefect_wen;
    oreg_cdefect_addr  <= sreg_cdefect_addr;
    oreg_cdefect_wdata <= sreg_cdefect_wdata;
    oreg_defect_map    <= sreg_defect_map;
    oreg_dgain         <= sreg_dgain;
    oreg_avg_en        <= sreg_avg_en;
    oreg_avg_level     <= sreg_avg_level;
    oreg_iproc_mode    <= sreg_iproc_mode;
    oreg_bright        <= sreg_bright;
    oreg_contrast      <= sreg_contrast;

    oreg_i2c_mode  <= sreg_i2c_mode;
    oreg_i2c_wen   <= sreg_i2c_wen;
    oreg_i2c_wsize <= sreg_i2c_wsize;
    oreg_i2c_wdata <= sreg_i2c_wdata;
    oreg_i2c_ren   <= sreg_i2c_ren;
    oreg_i2c_rsize <= sreg_i2c_rsize;

    oreg_temp_en <= sreg_temp_en;

    oreg_sd_wen  <= sreg_sd_wen;
    oreg_sd_ren  <= sreg_sd_ren;
    oreg_sd_addr <= sreg_sd_addr;

    oreg_api_ext_trig    <= sreg_api_ext_trig;
    oreg_ext_trig_high   <= sreg_ext_trig_high;
    oreg_ext_trig_period <= sreg_ext_trig_period;
    oreg_ext_trig_active <= sreg_ext_trig_active;

    oreg_fla_ctrl <= sreg_fla_ctrl;
    oreg_fla_addr <= sreg_fla_addr;

    oreg_flaw_ctrl  <= sreg_flaw_ctrl;
    oreg_flaw_cmd   <= sreg_flaw_cmd;
    oreg_flaw_addr  <= sreg_flaw_addr;
    oreg_flaw_wdata <= sreg_flaw_wdata;

    oreg_d2m_en         <= sreg_d2m_en;
    oreg_d2m_exp_in     <= sreg_d2m_exp_in;
    oreg_d2m_sexp_time  <= sreg_d2m_sexp_time;
    oreg_d2m_frame_time <= sreg_d2m_frame_time;
    oreg_d2m_xrst_num   <= sreg_d2m_xrst_num;
    oreg_d2m_drst_num   <= sreg_d2m_drst_num;

    oreg_sync_ctrl <= sreg_sync_ctrl;

    oreg_sm_ctrl   <= sreg_sm_ctrl;
    oreg_bcal_ctrl <= sreg_bcal_ctrl;

    oreg_mpc_posoffset <= sreg_mpc_posoffset;

    oreg_fw_busy     <= sreg_fw_busy;
    oreg_toprst_ctrl <= sreg_toprst_ctrl;

    oreg_DnrCtrl     <= sReg_DnrCtrl;
    oreg_SobelCoeff0 <= sreg_SobelCoeff0;
    oreg_SobelCoeff1 <= sreg_SobelCoeff1;
    oreg_SobelCoeff2 <= sreg_SobelCoeff2;
    oreg_BlurOffset  <= sreg_BlurOffset;
    oreg_AccCtrl     <= sReg_AccCtrl;

    oreg_ExtTrigEn      <= sreg_ExtTrigEn;
    oreg_ExtRst_MODE    <= sreg_ExtRst_MODE;
    oreg_ExtRst_DetTime <= sreg_ExtRst_DetTime;

    oreg_led_ctrl <= sreg_led_ctrl;
    oreg_osd_ctrl <= sreg_osd_ctrl;

    oreg_pwdac_cmd      <= sreg_pwdac_cmd;
    oreg_pwdac_ticktime <= sreg_pwdac_ticktime;
    oreg_pwdac_tickinc  <= sreg_pwdac_tickinc;
    oreg_pwdac_trig     <= sreg_pwdac_trig;

    oreg_testpoint1 <= sreg_testpoint1;
    oreg_testpoint2 <= sreg_testpoint2;
    oreg_testpoint3 <= sreg_testpoint3;
    oreg_testpoint4 <= sreg_testpoint4;

    oreg_roic_str <= sreg_roic_str;

    oreg_edge_ctrl   <= sreg_edge_ctrl;
    oreg_edge_value  <= sreg_edge_value;
    oreg_edge_top    <= sreg_edge_top;
    oreg_edge_left   <= sreg_edge_left;
    oreg_edge_right  <= sreg_edge_right;
    oreg_edge_bottom <= sreg_edge_bottom;

    oreg_bnc_ctrl    <= sreg_bnc_ctrl;
    oreg_bnc_high    <= sreg_bnc_high;
    oreg_ofga_lim    <= sreg_ofga_lim; 
    oreg_EqCtrl      <= sreg_EqCtrl  ;
    oreg_EqTopVal    <= sreg_EqTopVal;
    oreg_debug <= sreg_debug;

    process (isys_clk, isys_rstn)
    begin
        if (isys_rstn = '0') then
            sreg_grab_done_1d      <= '0';
            sreg_grab_done_2d      <= '0';
            sreg_grab_done_3d      <= '0';
            sreg_ext_exp_time_1d   <= (others => '0');
            sreg_ext_exp_time_2d   <= (others => '0');
            sreg_ext_exp_time_3d   <= (others => '0');
            sreg_ext_frame_time_1d <= (others => '0');
            sreg_ext_frame_time_2d <= (others => '0');
            sreg_ext_frame_time_3d <= (others => '0');
            sreg_defect_rdata_1d   <= (others => '0');
            sreg_defect_rdata_2d   <= (others => '0');
            sreg_defect_rdata_3d   <= (others => '0');
            sreg_defect2_rdata_1d  <= (others => '0');
            sreg_defect2_rdata_2d  <= (others => '0');
            sreg_defect2_rdata_3d  <= (others => '0');
            sreg_rdefect_rdata_1d  <= (others => '0');
            sreg_rdefect_rdata_2d  <= (others => '0');
            sreg_rdefect_rdata_3d  <= (others => '0');
            sreg_cdefect_rdata_1d  <= (others => '0');
            sreg_cdefect_rdata_2d  <= (others => '0');
            sreg_cdefect_rdata_3d  <= (others => '0');
            sreg_avg_end_1d        <= (others => '0');
            sreg_avg_end_2d        <= (others => '0');
            sreg_avg_end_3d        <= (others => '0');
            sreg_pwr_done_1d       <= '0';
            sreg_pwr_done_2d       <= '0';
            sreg_pwr_done_3d       <= '0';
            sreg_erase_done_1d     <= '0';
            sreg_erase_done_2d     <= '0';
            sreg_erase_done_3d     <= '0';
            sreg_align_done_1d     <= '0';
            sreg_align_done_2d     <= '0';
            sreg_align_done_3d     <= '0';
            sreg_roic_done_1d      <= '0';
            sreg_roic_done_2d      <= '0';
            sreg_roic_done_3d      <= '0';
            sreg_calib_done_1d     <= '0';
            sreg_calib_done_2d     <= '0';
            sreg_calib_done_3d     <= '0';
            sreg_i2c_rdata0_1d     <= (others => '0');
            sreg_i2c_rdata0_2d     <= (others => '0');
            sreg_i2c_rdata0_3d     <= (others => '0');
            sreg_i2c_rdata1_1d     <= (others => '0');
            sreg_i2c_rdata1_2d     <= (others => '0');
            sreg_i2c_rdata1_3d     <= (others => '0');
            sreg_i2c_done_1d       <= '0';
            sreg_i2c_done_2d       <= '0';
            sreg_i2c_done_3d       <= '0';
            sreg_device_temp_1d    <= (others => '0');
            sreg_device_temp_2d    <= (others => '0');
            sreg_device_temp_3d    <= (others => '0');
            sreg_sd_rw_end_1d      <= '0';
            sreg_sd_rw_end_2d      <= '0';
            sreg_sd_rw_end_3d      <= '0';
--            sreg_roic_temp_1d      <= (others => (others => '0'));
--            sreg_roic_temp_2d      <= (others => (others => '0'));
--            sreg_roic_temp_3d      <= (others => (others => '0'));
            sreg_roic_temp_1d      <= ((others => '0'));
            sreg_roic_temp_2d      <= ((others => '0'));
            sreg_roic_temp_3d      <= ((others => '0'));
            sreg_roic_rdata_1d     <= (others => '0');
            sreg_roic_rdata_2d     <= (others => '0');
            sreg_roic_rdata_3d     <= (others => '0');
            sreg_clk_mclk_1d       <= (others => '0');
            sreg_clk_mclk_2d       <= (others => '0');
            sreg_clk_mclk_3d       <= (others => '0');
            sreg_clk_dclk_1d       <= (others => '0');
            sreg_clk_dclk_2d       <= (others => '0');
            sreg_clk_dclk_3d       <= (others => '0');
            sreg_clk_roicdclk_1d   <= (others => '0');
            sreg_clk_roicdclk_2d   <= (others => '0');
            sreg_clk_roicdclk_3d   <= (others => '0');
            sreg_clk_uiclk_1d      <= (others => '0');
            sreg_clk_uiclk_2d      <= (others => '0');
            sreg_clk_uiclk_3d      <= (others => '0');
            sreg_fla_data_1d       <= (others => '0');
            sreg_fla_data_2d       <= (others => '0');
            sreg_fla_data_3d       <= (others => '0');
            sreg_flaw_rdata_1d     <= (others => '0');
            sreg_flaw_rdata_2d     <= (others => '0');
            sreg_flaw_rdata_3d     <= (others => '0');
        elsif (isys_clk'event and isys_clk = '1') then
            sreg_grab_done_1d        <= ireg_grab_done;
            sreg_grab_done_2d        <= sreg_grab_done_1d;
            sreg_grab_done_3d        <= sreg_grab_done_2d;
            sreg_ext_exp_time_1d     <= ireg_ext_exp_time;
            sreg_ext_exp_time_2d     <= sreg_ext_exp_time_1d;
            sreg_ext_exp_time_3d     <= sreg_ext_exp_time_2d;
            sreg_ext_frame_time_1d   <= ireg_ext_frame_time;
            sreg_ext_frame_time_2d   <= sreg_ext_frame_time_1d;
            sreg_ext_frame_time_3d   <= sreg_ext_frame_time_2d;
            sreg_defect_rdata_1d     <= ireg_defect_rdata;
            sreg_defect_rdata_2d     <= sreg_defect_rdata_1d;
            sreg_defect_rdata_3d     <= sreg_defect_rdata_2d;
            sreg_defect2_rdata_1d    <= ireg_defect2_rdata;
            sreg_defect2_rdata_2d    <= sreg_defect2_rdata_1d;
            sreg_defect2_rdata_3d    <= sreg_defect2_rdata_2d;
            sreg_rdefect_rdata_1d    <= ireg_rdefect_rdata;
            sreg_rdefect_rdata_2d    <= sreg_rdefect_rdata_1d;
            sreg_rdefect_rdata_3d    <= sreg_rdefect_rdata_2d;
            sreg_cdefect_rdata_1d    <= ireg_cdefect_rdata;
            sreg_cdefect_rdata_2d    <= sreg_cdefect_rdata_1d;
            sreg_cdefect_rdata_3d    <= sreg_cdefect_rdata_2d;
            sreg_avg_end_1d          <= ireg_avg_end;
            sreg_avg_end_2d          <= sreg_avg_end_1d;
            sreg_avg_end_3d          <= sreg_avg_end_2d;
            sreg_pwr_done_1d         <= ireg_pwr_done;
            sreg_pwr_done_2d         <= sreg_pwr_done_1d;
            sreg_pwr_done_3d         <= sreg_pwr_done_2d;
            sreg_erase_done_1d       <= ireg_erase_done;
            sreg_erase_done_2d       <= sreg_erase_done_1d;
            sreg_erase_done_3d       <= sreg_erase_done_2d;
            sreg_align_done_1d       <= ireg_align_done;
            sreg_align_done_2d       <= sreg_align_done_1d;
            sreg_align_done_3d       <= sreg_align_done_2d;
            sreg_roic_done_1d        <= ireg_roic_done;
            sreg_roic_done_2d        <= sreg_roic_done_1d;
            sreg_roic_done_3d        <= sreg_roic_done_2d;
            sreg_calib_done_1d       <= ireg_calib_done;
            sreg_calib_done_2d       <= sreg_calib_done_1d;
            sreg_calib_done_3d       <= sreg_calib_done_2d;
            sreg_i2c_rdata0_1d       <= ireg_i2c_rdata0;
            sreg_i2c_rdata0_2d       <= sreg_i2c_rdata0_1d;
            sreg_i2c_rdata0_3d       <= sreg_i2c_rdata0_2d;
            sreg_i2c_rdata1_1d       <= ireg_i2c_rdata1;
            sreg_i2c_rdata1_2d       <= sreg_i2c_rdata1_1d;
            sreg_i2c_rdata1_3d       <= sreg_i2c_rdata1_2d;
            sreg_i2c_rdata2_1d       <= ireg_i2c_rdata2;
            sreg_i2c_rdata2_2d       <= sreg_i2c_rdata2_1d;
            sreg_i2c_rdata2_3d       <= sreg_i2c_rdata2_2d;
            sreg_i2c_rdata3_1d       <= ireg_i2c_rdata3;
            sreg_i2c_rdata3_2d       <= sreg_i2c_rdata3_1d;
            sreg_i2c_rdata3_3d       <= sreg_i2c_rdata3_2d;
            sreg_i2c_done_1d         <= ireg_i2c_done;
            sreg_i2c_done_2d         <= sreg_i2c_done_1d;
            sreg_i2c_done_3d         <= sreg_i2c_done_2d;
            sreg_device_temp_1d      <= ireg_device_temp;
            sreg_device_temp_2d      <= sreg_device_temp_1d;
            sreg_device_temp_3d      <= sreg_device_temp_2d;
            sreg_sd_rw_end_1d        <= ireg_sd_rw_end;
            sreg_sd_rw_end_2d        <= sreg_sd_rw_end_1d;
            sreg_sd_rw_end_3d        <= sreg_sd_rw_end_2d;
            sreg_clk_mclk_1d         <= ireg_clk_mclk;
            sreg_clk_mclk_2d         <= sreg_clk_mclk_1d;
            sreg_clk_mclk_3d         <= sreg_clk_mclk_2d;
            sreg_clk_dclk_1d         <= ireg_clk_dclk;
            sreg_clk_dclk_2d         <= sreg_clk_dclk_1d;
            sreg_clk_dclk_3d         <= sreg_clk_dclk_2d;
            sreg_clk_roicdclk_1d     <= ireg_clk_roicdclk;
            sreg_clk_roicdclk_2d     <= sreg_clk_roicdclk_1d;
            sreg_clk_roicdclk_3d     <= sreg_clk_roicdclk_2d;
            sreg_clk_uiclk_1d        <= ireg_clk_uiclk;
            sreg_clk_uiclk_2d        <= sreg_clk_uiclk_1d;
            sreg_clk_uiclk_3d        <= sreg_clk_uiclk_2d;
            sreg_fla_data_1d         <= ireg_fla_data;
            sreg_fla_data_2d         <= sreg_fla_data_1d;
            sreg_fla_data_3d         <= sreg_fla_data_2d;
            sreg_flaw_rdata_1d       <= ireg_flaw_rdata;
            sreg_flaw_rdata_2d       <= sreg_flaw_rdata_1d;
            sreg_flaw_rdata_3d       <= sreg_flaw_rdata_2d;
            sreg_sync_rcnt0_1d       <= ireg_sync_rcnt0;
            sreg_sync_rcnt0_2d       <= sreg_sync_rcnt0_1d;
            sreg_sync_rcnt0_3d       <= sreg_sync_rcnt0_2d;
            sreg_sync_rcnt1_1d       <= ireg_sync_rcnt1;
            sreg_sync_rcnt1_2d       <= sreg_sync_rcnt1_1d;
            sreg_sync_rcnt1_3d       <= sreg_sync_rcnt1_2d;
            sreg_sync_rcnt2_1d       <= ireg_sync_rcnt2;
            sreg_sync_rcnt2_2d       <= sreg_sync_rcnt2_1d;
            sreg_sync_rcnt2_3d       <= sreg_sync_rcnt2_2d;
            sreg_sync_rcnt3_1d       <= ireg_sync_rcnt3;
            sreg_sync_rcnt3_2d       <= sreg_sync_rcnt3_1d;
            sreg_sync_rcnt3_3d       <= sreg_sync_rcnt3_2d;
            sreg_sync_rcnt4_1d       <= ireg_sync_rcnt4;
            sreg_sync_rcnt4_2d       <= sreg_sync_rcnt4_1d;
            sreg_sync_rcnt4_3d       <= sreg_sync_rcnt4_2d;
            sreg_sync_rcnt5_1d       <= ireg_sync_rcnt5;
            sreg_sync_rcnt5_2d       <= sreg_sync_rcnt5_1d;
            sreg_sync_rcnt5_3d       <= sreg_sync_rcnt5_2d;
            sreg_sync_rcnt6_1d       <= ireg_sync_rcnt6;
            sreg_sync_rcnt6_2d       <= sreg_sync_rcnt6_1d;
            sreg_sync_rcnt6_3d       <= sreg_sync_rcnt6_2d;
            sreg_sync_rcnt7_1d       <= ireg_sync_rcnt7;
            sreg_sync_rcnt7_2d       <= sreg_sync_rcnt7_1d;
            sreg_sync_rcnt7_3d       <= sreg_sync_rcnt7_2d;
            sreg_sync_rcnt8_1d       <= ireg_sync_rcnt8;
            sreg_sync_rcnt8_2d       <= sreg_sync_rcnt8_1d;
            sreg_sync_rcnt8_3d       <= sreg_sync_rcnt8_2d;
            sreg_sync_rcnt9_1d       <= ireg_sync_rcnt9;
            sreg_sync_rcnt9_2d       <= sreg_sync_rcnt9_1d;
            sreg_sync_rcnt9_3d       <= sreg_sync_rcnt9_2d;
            sreg_sync_rdata_avcn0_1d <= ireg_sync_rdata_avcn0;
            sreg_sync_rdata_avcn0_2d <= sreg_sync_rdata_avcn0_1d;
            sreg_sync_rdata_avcn0_3d <= sreg_sync_rdata_avcn0_2d;
            sreg_sync_rdata_avcn1_1d <= ireg_sync_rdata_avcn1;
            sreg_sync_rdata_avcn1_2d <= sreg_sync_rdata_avcn1_1d;
            sreg_sync_rdata_avcn1_3d <= sreg_sync_rdata_avcn1_2d;
            sreg_sync_rdata_avcn2_1d <= ireg_sync_rdata_avcn2;
            sreg_sync_rdata_avcn2_2d <= sreg_sync_rdata_avcn2_1d;
            sreg_sync_rdata_avcn2_3d <= sreg_sync_rdata_avcn2_2d;
            sreg_sync_rdata_avcn3_1d <= ireg_sync_rdata_avcn3;
            sreg_sync_rdata_avcn3_2d <= sreg_sync_rdata_avcn3_1d;
            sreg_sync_rdata_avcn3_3d <= sreg_sync_rdata_avcn3_2d;
            sreg_sync_rdata_avcn4_1d <= ireg_sync_rdata_avcn4;
            sreg_sync_rdata_avcn4_2d <= sreg_sync_rdata_avcn4_1d;
            sreg_sync_rdata_avcn4_3d <= sreg_sync_rdata_avcn4_2d;
            sreg_sync_rdata_avcn5_1d <= ireg_sync_rdata_avcn5;
            sreg_sync_rdata_avcn5_2d <= sreg_sync_rdata_avcn5_1d;
            sreg_sync_rdata_avcn5_3d <= sreg_sync_rdata_avcn5_2d;
            sreg_sync_rdata_avcn6_1d <= ireg_sync_rdata_avcn6;
            sreg_sync_rdata_avcn6_2d <= sreg_sync_rdata_avcn6_1d;
            sreg_sync_rdata_avcn6_3d <= sreg_sync_rdata_avcn6_2d;
            sreg_sync_rdata_avcn7_1d <= ireg_sync_rdata_avcn7;
            sreg_sync_rdata_avcn7_2d <= sreg_sync_rdata_avcn7_1d;
            sreg_sync_rdata_avcn7_3d <= sreg_sync_rdata_avcn7_2d;
            sreg_sync_rdata_avcn8_1d <= ireg_sync_rdata_avcn8;
            sreg_sync_rdata_avcn8_2d <= sreg_sync_rdata_avcn8_1d;
            sreg_sync_rdata_avcn8_3d <= sreg_sync_rdata_avcn8_2d;
            sreg_sync_rdata_avcn9_1d <= ireg_sync_rdata_avcn9;
            sreg_sync_rdata_avcn9_2d <= sreg_sync_rdata_avcn9_1d;
            sreg_sync_rdata_avcn9_3d <= sreg_sync_rdata_avcn9_2d;
            sreg_sync_rdata_bglw0_1d <= ireg_sync_rdata_bglw0;
            sreg_sync_rdata_bglw0_2d <= sreg_sync_rdata_bglw0_1d;
            sreg_sync_rdata_bglw0_3d <= sreg_sync_rdata_bglw0_2d;
            sreg_sync_rdata_bglw1_1d <= ireg_sync_rdata_bglw1;
            sreg_sync_rdata_bglw1_2d <= sreg_sync_rdata_bglw1_1d;
            sreg_sync_rdata_bglw1_3d <= sreg_sync_rdata_bglw1_2d;
            sreg_sync_rdata_bglw2_1d <= ireg_sync_rdata_bglw2;
            sreg_sync_rdata_bglw2_2d <= sreg_sync_rdata_bglw2_1d;
            sreg_sync_rdata_bglw2_3d <= sreg_sync_rdata_bglw2_2d;
            sreg_sync_rdata_bglw3_1d <= ireg_sync_rdata_bglw3;
            sreg_sync_rdata_bglw3_2d <= sreg_sync_rdata_bglw3_1d;
            sreg_sync_rdata_bglw3_3d <= sreg_sync_rdata_bglw3_2d;
            sreg_sync_rdata_bglw4_1d <= ireg_sync_rdata_bglw4;
            sreg_sync_rdata_bglw4_2d <= sreg_sync_rdata_bglw4_1d;
            sreg_sync_rdata_bglw4_3d <= sreg_sync_rdata_bglw4_2d;
            sreg_sync_rdata_bglw5_1d <= ireg_sync_rdata_bglw5;
            sreg_sync_rdata_bglw5_2d <= sreg_sync_rdata_bglw5_1d;
            sreg_sync_rdata_bglw5_3d <= sreg_sync_rdata_bglw5_2d;
            sreg_sync_rdata_bglw6_1d <= ireg_sync_rdata_bglw6;
            sreg_sync_rdata_bglw6_2d <= sreg_sync_rdata_bglw6_1d;
            sreg_sync_rdata_bglw6_3d <= sreg_sync_rdata_bglw6_2d;
            sreg_sync_rdata_bglw7_1d <= ireg_sync_rdata_bglw7;
            sreg_sync_rdata_bglw7_2d <= sreg_sync_rdata_bglw7_1d;
            sreg_sync_rdata_bglw7_3d <= sreg_sync_rdata_bglw7_2d;
            sreg_sync_rdata_bglw8_1d <= ireg_sync_rdata_bglw8;
            sreg_sync_rdata_bglw8_2d <= sreg_sync_rdata_bglw8_1d;
            sreg_sync_rdata_bglw8_3d <= sreg_sync_rdata_bglw8_2d;
            sreg_sync_rdata_bglw9_1d <= ireg_sync_rdata_bglw9;
            sreg_sync_rdata_bglw9_2d <= sreg_sync_rdata_bglw9_1d;
            sreg_sync_rdata_bglw9_3d <= sreg_sync_rdata_bglw9_2d;
            sreg_sm_data0_1d <= ireg_sm_data0;
            sreg_sm_data0_2d <= sreg_sm_data0_1d;
            sreg_sm_data0_3d <= sreg_sm_data0_2d;
            sreg_sm_data1_1d <= ireg_sm_data1;
            sreg_sm_data1_2d <= sreg_sm_data1_1d;
            sreg_sm_data1_3d <= sreg_sm_data1_2d;
            sreg_sm_data2_1d <= ireg_sm_data2;
            sreg_sm_data2_2d <= sreg_sm_data2_1d;
            sreg_sm_data2_3d <= sreg_sm_data2_2d;
            sreg_sm_data3_1d <= ireg_sm_data3;
            sreg_sm_data3_2d <= sreg_sm_data3_1d;
            sreg_sm_data3_3d <= sreg_sm_data3_2d;
            sreg_sm_data4_1d <= ireg_sm_data4;
            sreg_sm_data4_2d <= sreg_sm_data4_1d;
            sreg_sm_data4_3d <= sreg_sm_data4_2d;
            sreg_sm_data5_1d <= ireg_sm_data5;
            sreg_sm_data5_2d <= sreg_sm_data5_1d;
            sreg_sm_data5_3d <= sreg_sm_data5_2d;
            sreg_sm_data6_1d <= ireg_sm_data6;
            sreg_sm_data6_2d <= sreg_sm_data6_1d;
            sreg_sm_data6_3d <= sreg_sm_data6_2d;
            sreg_sm_data7_1d <= ireg_sm_data7;
            sreg_sm_data7_2d <= sreg_sm_data7_1d;
            sreg_sm_data7_3d <= sreg_sm_data7_2d;
            sreg_bcal_data_1d <= ireg_bcal_data;
            sreg_bcal_data_2d <= sreg_bcal_data_1d;
            sreg_bcal_data_3d <= sreg_bcal_data_2d;
            sreg_frame_cnt_1d <= ireg_frame_cnt;
            sreg_frame_cnt_2d <= sreg_frame_cnt_1d;
            sreg_frame_cnt_3d <= sreg_frame_cnt_2d;

--            for i in 0 to ROIC_NUM2_REG(GNR_MODEL) - 1 loop
--                sreg_roic_temp_1d(i) <= ireg_roic_temp(i);
--                sreg_roic_temp_2d(i) <= sreg_roic_temp_1d(i);
--                sreg_roic_temp_3d(i) <= sreg_roic_temp_2d(i);
--            end loop;
                sreg_roic_temp_1d <= ireg_roic_temp;
                sreg_roic_temp_2d <= sreg_roic_temp_1d;
                sreg_roic_temp_3d <= sreg_roic_temp_2d;


            sreg_roic_rdata_1d <= ireg_roic_rdata;
            sreg_roic_rdata_2d <= sreg_roic_rdata_1d;
            sreg_roic_rdata_3d <= sreg_roic_rdata_2d;
            sreg_trigcnt_1d <= ireg_trigcnt;
            sreg_trigcnt_2d <= sreg_trigcnt_1d;
            sreg_trigcnt_3d <= sreg_trigcnt_2d;
            sreg_AccStat_1d <= iReg_AccStat;
            sreg_AccStat_2d <= sreg_AccStat_1d;
            sreg_AccStat_3d <= sreg_AccStat_2d;
            sreg_pwdac_currlevel_1d <= ireg_pwdac_currlevel;
            sreg_pwdac_currlevel_2d <= sreg_pwdac_currlevel_1d;
            sreg_pwdac_currlevel_3d <= sreg_pwdac_currlevel_2d;
        end if;
    end process;

    fpga_reboot <= sreg_fpga_reboot;

    u_iprog_rst : component iprog_rst port map (
            rst => fpga_reboot,
            clk => isys_clk,
            rip => OPEN
        );

end architecture behavioral;
