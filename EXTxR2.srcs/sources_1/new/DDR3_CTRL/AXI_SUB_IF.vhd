
library IEEE;
    use IEEE.STD_LOGIC_1164.ALL;
    use IEEE.STD_LOGIC_ARITH.ALL;
    use IEEE.STD_LOGIC_UNSIGNED.ALL;
    use WORK.TOP_HEADER.ALL;

entity AXI_SUB_IF is
generic ( GNR_MODEL : string  := "EXT1616R" );
    port (
        iui_clk    : in    std_logic;
        iui_rstn   : in    std_logic;
        iaxi_clk   : in    std_logic;
        iaxi_rstn  : in    std_logic;
        idata_clk  : in    std_logic;
        idata_rstn : in    std_logic;

        ireg_ddr_acc_ch_en : in     std_logic;
        ireg_ddr_ch_en     : in    std_logic_vector(7 downto 0);
        ireg_ddr_base_addr : in    std_logic_vector(31 downto 0);

        --* jhkim 28 -> 29bit
        -- 29b-> 30b ddr8Gb
        ireg_ddr_ch0_waddr : in    std_logic_vector(29 downto 0);
        ireg_ddr_ch1_waddr : in    std_logic_vector(29 downto 0);
        ireg_ddr_ch2_waddr : in    std_logic_vector(29 downto 0);
        ireg_ddr_ch3_waddr : in    std_logic_vector(29 downto 0); -- acc
        ireg_ddr_ch4_waddr : in    std_logic_vector(29 downto 0); -- acc
        ireg_ddr_ch0_raddr : in    std_logic_vector(29 downto 0);
        ireg_ddr_ch1_raddr : in    std_logic_vector(29 downto 0);
        ireg_ddr_ch2_raddr : in    std_logic_vector(29 downto 0);
        ireg_ddr_ch3_raddr : in    std_logic_vector(29 downto 0);
        ireg_ddr_ch4_raddr : in    std_logic_vector(29 downto 0);

        ireg_width    : in    std_logic_vector(11 downto 0);
        ireg_height : in    std_logic_vector(11 downto 0);

        iaxi_wready : in    std_logic;
        iaxi_bready : in    std_logic;

        iconv_rlast : in    std_logic;
        iconv_hsync : in    std_logic;
        iconv_vcnt    : in    std_logic_vector(11 downto 0);

        ich0_wen   : in    std_logic;
        ich0_waddr : in    std_logic_vector(11 downto 0);
        ich0_wvcnt : in    std_logic_vector(11 downto 0);
        ich0_wdata : in    std_logic_vector(DDR_BIT_W0( (GNR_MODEL))-1 downto 0); 
        ich1_wen   : in    std_logic;
        ich1_waddr : in    std_logic_vector(11 downto 0);
        ich1_wvcnt : in    std_logic_vector(11 downto 0);
        ich1_wdata : in    std_logic_vector(DDR_BIT_W1( (GNR_MODEL))-1 downto 0); 
        ich2_wen   : in    std_logic;
        ich2_waddr : in    std_logic_vector(11 downto 0);
        ich2_wvcnt : in    std_logic_vector(11 downto 0);
        ich2_wdata : in    std_logic_vector(DDR_BIT_W2( (GNR_MODEL))-1 downto 0); 
        id2m_xray  : in       std_logic;
        ich3_wen   : in    std_logic;
        ich3_waddr : in    std_logic_vector(11 downto 0);
        ich3_wvcnt : in    std_logic_vector(11 downto 0);
        ich3_wdata : in    std_logic_vector(DDR_BIT_W3( (GNR_MODEL))-1 downto 0); 
        ich4_wen   : in    std_logic;
        ich4_waddr : in    std_logic_vector(11 downto 0);
        ich4_wvcnt : in    std_logic_vector(11 downto 0);
        ich4_wdata : in    std_logic_vector(DDR_BIT_W4( (GNR_MODEL))-1 downto 0); 

        och0_wtrig : out   std_logic;
        och0_waddr : out   std_logic_vector(31 downto 0);
        och0_wdata : out   std_logic_vector(511 downto 0);
        och1_wtrig : out   std_logic;
        och1_waddr : out   std_logic_vector(31 downto 0);
        och1_wdata : out   std_logic_vector(511 downto 0);
        och2_wtrig : out   std_logic;
        och2_waddr : out   std_logic_vector(31 downto 0);
        och2_wdata : out   std_logic_vector(511 downto 0);
        och3_wtrig : out   std_logic;
        och3_waddr : out   std_logic_vector(31 downto 0);
        och3_wdata : out   std_logic_vector(511 downto 0);
        och4_wtrig : out   std_logic;
        och4_waddr : out   std_logic_vector(31 downto 0);
        och4_wdata : out   std_logic_vector(511 downto 0);
        och0_rtrig : out   std_logic;
        och0_raddr : out   std_logic_vector(31 downto 0);
        och0_rvcnt : out   std_logic_vector(11 downto 0);
        och1_rtrig : out   std_logic;
        och1_raddr : out   std_logic_vector(31 downto 0);
        och1_rvcnt : out   std_logic_vector(11 downto 0);
        och2_rtrig : out   std_logic;
        och2_raddr : out   std_logic_vector(31 downto 0);
        och2_rvcnt : out   std_logic_vector(11 downto 0);
        och3_rtrig : out   std_logic;
        och3_raddr : out   std_logic_vector(31 downto 0);
        och3_rvcnt : out   std_logic_vector(11 downto 0);
        och4_rtrig : out   std_logic;
        och4_raddr : out   std_logic_vector(31 downto 0);
        och4_rvcnt : out   std_logic_vector(11 downto 0);
        ostate_ddr_sub : out tstate_ddr_sub
    );
end entity axi_sub_if;

architecture behavioral of axi_sub_if is

    component MULTI_13x12 -- 3 Delay
        port (
            clk : in    std_logic;
            ce    : in    std_logic;
            a    : in    std_logic_vector(12 downto 0);
            b    : in    std_logic_vector(11 downto 0);
            p    : out    std_logic_vector(24 downto 0)
        );
    end component;

    component AXI_WDATA_CONV
        generic (
            data_depth : integer
        );
        port (
            iwr_clk  : in     std_logic;
            iwr_rstn : in     std_logic;

            iwr_en     : in     std_logic;
            iwr_addr : in     std_logic_vector(11 downto 0);
            iwr_vcnt : in     std_logic_vector(11 downto 0);
            iwr_data : in     std_logic_vector(DATA_DEPTH - 1 downto 0);

            ird_clk  : in     std_logic;
            ird_rstn : in     std_logic;

            ird_en     : in     std_logic;
            ird_addr : in     std_logic_vector(11 downto 0);
            ird_vcnt : in     std_logic_vector(11 downto 0);
            ord_data : out     std_logic_vector(511 downto 0)
        );
    end component;

--    type tstate_ddr_sub is (
--        s_IDLE,
--        s_READY,
--        s_WRITE,
--        s_WRESP,
--        s_READ,
--        s_WCHECK,
--        s_RCHECK,
--        s_FINISH
--    );

    signal state_ddr : tstate_ddr_sub;

    signal swait_cnt : std_logic_vector(7 downto 0);

    signal sch0_base_waddr : std_logic_vector(31 downto 0);
    signal sch1_base_waddr : std_logic_vector(31 downto 0);
    signal sch2_base_waddr : std_logic_vector(31 downto 0);
    signal sch3_base_waddr : std_logic_vector(31 downto 0);
    signal sch4_base_waddr : std_logic_vector(31 downto 0);
    signal sch0_base_raddr : std_logic_vector(31 downto 0);
    signal sch1_base_raddr : std_logic_vector(31 downto 0);
    signal sch2_base_raddr : std_logic_vector(31 downto 0);
    signal sch3_base_raddr : std_logic_vector(31 downto 0);
    signal sch4_base_raddr : std_logic_vector(31 downto 0);

    signal sch0_waddr : std_logic_vector(31 downto 0);
    signal sch1_waddr : std_logic_vector(31 downto 0);
    signal sch2_waddr : std_logic_vector(31 downto 0);
    signal sch3_waddr : std_logic_vector(31 downto 0);
    signal sch4_waddr : std_logic_vector(31 downto 0);
    signal sch0_raddr : std_logic_vector(31 downto 0);
    signal sch1_raddr : std_logic_vector(31 downto 0);
    signal sch2_raddr : std_logic_vector(31 downto 0);
    signal sch3_raddr : std_logic_vector(31 downto 0);
    signal sch4_raddr : std_logic_vector(31 downto 0);

    signal sch0_waddr_top : std_logic_vector(31 downto 0);
    signal sch0_waddr_bot : std_logic_vector(31 downto 0);
    signal simg_size1      : std_logic_vector(24 downto 0);
    signal simg_size2      : std_logic_vector(24 downto 0);
    signal simg_size3      : std_logic_vector(25 downto 0);

    signal sch0_wlen : std_logic_vector(11 downto 0);
    signal sch1_wlen : std_logic_vector(11 downto 0);
    signal sch2_wlen : std_logic_vector(11 downto 0);
    signal sch3_wlen : std_logic_vector(11 downto 0);
    signal sch4_wlen : std_logic_vector(11 downto 0);

    signal sch0_wtrig : std_logic;
    signal sch1_wtrig : std_logic;
    signal sch2_wtrig : std_logic;
    signal sch3_wtrig : std_logic;
    signal sch4_wtrig : std_logic;
    signal sch0_rtrig : std_logic;
    signal sch1_rtrig : std_logic;
    signal sch2_rtrig : std_logic;
    signal sch3_rtrig : std_logic;
    signal sch4_rtrig : std_logic;

    signal sch0_warea : std_logic;
    signal sch0_rarea : std_logic;

    -- signal sddr_ch_en : std_logic_vector(7 downto 0);
    signal sddr_ch_en : std_logic_vector(9 downto 0);

    signal sddr_wen   : std_logic;
    signal sddr_wlen  : std_logic_vector(11 downto 0);
    signal sddr_waddr : std_logic_vector(11 downto 0);

    signal sddr_ch0_wen   : std_logic;
    signal sddr_ch0_waddr : std_logic_vector(11 downto 0);
    signal sddr_ch0_wvcnt : std_logic_vector(11 downto 0);
    signal sddr_ch0_wdata : std_logic_vector(511 downto 0);
    signal sddr_ch1_wen   : std_logic;
    signal sddr_ch1_waddr : std_logic_vector(11 downto 0);
    signal sddr_ch1_wvcnt : std_logic_vector(11 downto 0);
    signal sddr_ch1_wdata : std_logic_vector(511 downto 0);
    signal sddr_ch2_wen   : std_logic;
    signal sddr_ch2_waddr : std_logic_vector(11 downto 0);
    signal sddr_ch2_wvcnt : std_logic_vector(11 downto 0);
    signal sddr_ch2_wdata : std_logic_vector(511 downto 0);
    signal sddr_ch3_wen   : std_logic;
    signal sddr_ch3_waddr : std_logic_vector(11 downto 0);
    signal sddr_ch3_wvcnt : std_logic_vector(11 downto 0);
    signal sddr_ch3_wdata : std_logic_vector(511 downto 0);
    signal sddr_ch4_wen   : std_logic;
    signal sddr_ch4_waddr : std_logic_vector(11 downto 0);
    signal sddr_ch4_wvcnt : std_logic_vector(11 downto 0);
    signal sddr_ch4_wdata : std_logic_vector(511 downto 0);

    signal sddr_ch0_rvcnt : std_logic_vector(11 downto 0);
    signal sddr_ch1_rvcnt : std_logic_vector(11 downto 0);
    signal sddr_ch2_rvcnt : std_logic_vector(11 downto 0);
    signal sddr_ch3_rvcnt : std_logic_vector(11 downto 0);
    signal sddr_ch4_rvcnt : std_logic_vector(11 downto 0);

    signal sddr_ch          : integer range 0 to 4;
    signal sdual_roic_cnt : integer range 0 to ROIC_DUAL_BY_MODEL(GNR_MODEL) - 1;

    signal sreg_ddr_ch_en : std_logic_vector(9 downto 0);

    signal sch0_wen_1d     : std_logic;
    signal sch0_wen_2d     : std_logic;
    signal sch0_wen_3d     : std_logic;
    signal sch1_wen_1d     : std_logic;
    signal sch1_wen_2d     : std_logic;
    signal sch1_wen_3d     : std_logic;
    signal sch2_wen_1d     : std_logic;
    signal sch2_wen_2d     : std_logic;
    signal sch2_wen_3d     : std_logic;
    signal sch3_wen_1d     : std_logic;
    signal sch3_wen_2d     : std_logic;
    signal sch3_wen_3d     : std_logic;
    signal sch4_wen_1d     : std_logic;
    signal sch4_wen_2d     : std_logic;
    signal sch4_wen_3d     : std_logic;
    signal sch0_wvcnt_1d : std_logic_vector(11 downto 0);
    signal sch0_wvcnt_2d : std_logic_vector(11 downto 0);
    signal sch0_wvcnt_3d : std_logic_vector(11 downto 0);
    signal sch1_wvcnt_1d : std_logic_vector(11 downto 0);
    signal sch1_wvcnt_2d : std_logic_vector(11 downto 0);
    signal sch1_wvcnt_3d : std_logic_vector(11 downto 0);
    signal sch2_wvcnt_1d : std_logic_vector(11 downto 0);
    signal sch2_wvcnt_2d : std_logic_vector(11 downto 0);
    signal sch2_wvcnt_3d : std_logic_vector(11 downto 0);
    signal sch3_wvcnt_1d : std_logic_vector(11 downto 0);
    signal sch3_wvcnt_2d : std_logic_vector(11 downto 0);
    signal sch3_wvcnt_3d : std_logic_vector(11 downto 0);
    signal sch4_wvcnt_1d : std_logic_vector(11 downto 0);
    signal sch4_wvcnt_2d : std_logic_vector(11 downto 0);
    signal sch4_wvcnt_3d : std_logic_vector(11 downto 0);

    signal sconv_hsync_1d : std_logic;
    signal sconv_hsync_2d : std_logic;
    signal sconv_hsync_3d : std_logic;
    signal sconv_vcnt_1d  : std_logic_vector(11 downto 0);
    signal sconv_vcnt_2d  : std_logic_vector(11 downto 0);
    signal sconv_vcnt_3d  : std_logic_vector(11 downto 0);
    signal sconv_vcnt_4d  : std_logic_vector(11 downto 0);
    signal sconv_vcnt_sum : std_logic_vector(15 downto 0);
    signal sconv_vcnt_cut : std_logic_vector(15 downto 0);

    signal sconv_vcnt_sumw : std_logic_vector(15 downto 0);
    signal sconv_vcnt_cutw : std_logic_vector(15 downto 0);

    signal smulti_a : std_logic_vector(12 downto 0);
    signal smulti_b : std_logic_vector(11 downto 0);
    signal smulti_p : std_logic_vector(24 downto 0);

    -- signal ireg0_ddr_base_addr : std_logic_vector(31 downto 0);
    -- signal ireg0_ddr_ch0_waddr : std_logic_vector(27 downto 0);
    -- signal ireg0_ddr_ch1_waddr : std_logic_vector(27 downto 0);
    -- signal ireg0_ddr_ch2_waddr : std_logic_vector(27 downto 0);
    -- signal ireg0_ddr_ch3_waddr : std_logic_vector(27 downto 0);
    -- signal ireg0_ddr_ch0_raddr : std_logic_vector(27 downto 0);
    -- signal ireg0_ddr_ch1_raddr : std_logic_vector(27 downto 0);
    -- signal ireg0_ddr_ch2_raddr : std_logic_vector(27 downto 0);
    -- signal ireg0_width           : std_logic_vector(11 downto 0);
    -- signal ireg0_height           : std_logic_vector(11 downto 0);

    -- signal ireg1_ddr_base_addr : std_logic_vector(31 downto 0);
    -- signal ireg1_ddr_ch0_waddr : std_logic_vector(27 downto 0);
    -- signal ireg1_ddr_ch1_waddr : std_logic_vector(27 downto 0);
    -- signal ireg1_ddr_ch2_waddr : std_logic_vector(27 downto 0);
    -- signal ireg1_ddr_ch0_raddr : std_logic_vector(27 downto 0);
    -- signal ireg1_ddr_ch1_raddr : std_logic_vector(27 downto 0);
    -- signal ireg1_ddr_ch2_raddr : std_logic_vector(27 downto 0);
    -- signal ireg1_width           : std_logic_vector(11 downto 0);
    -- signal ireg1_height           : std_logic_vector(11 downto 0);

    signal reg_changed : std_logic;

    component ILA_AXI_SUB_IF
        port (
            clk    : in    std_logic;
            probe0 : in    std_logic;
            probe1 : in    std_logic_vector(31 downto 0);
            probe2 : in    std_logic;
            probe3 : in    std_logic_vector(31 downto 0);
            probe4 : in    std_logic_vector(11 downto 0);
            probe5 : in    std_logic;
            probe6 : in    std_logic
        );
    end component;

    signal debugnum   : std_logic_vector(4 - 1 downto 0);
    signal vsynctrig  : std_logic;
    signal sch0_wdata : std_logic_vector(512 - 1 downto 0);

    signal w0ireg_height : std_logic_vector(11 downto 0);
    signal w0ireg_width  : std_logic_vector(11 downto 0);
    signal w1ireg_height : std_logic_vector(11 downto 0);
    signal w1ireg_width  : std_logic_vector(11 downto 0);
    signal w2ireg_height : std_logic_vector(11 downto 0);
    signal w2ireg_width  : std_logic_vector(11 downto 0);
    signal w3ireg_height : std_logic_vector(11 downto 0);
    signal w3ireg_width  : std_logic_vector(11 downto 0);
    signal w4ireg_height : std_logic_vector(11 downto 0);
    signal w4ireg_width  : std_logic_vector(11 downto 0);
    signal r0ireg_height : std_logic_vector(11 downto 0);
    signal r0ireg_width  : std_logic_vector(11 downto 0);
    signal r1ireg_height : std_logic_vector(11 downto 0);
    signal r1ireg_width  : std_logic_vector(11 downto 0);
    signal r2ireg_height : std_logic_vector(11 downto 0);
    signal r2ireg_width  : std_logic_vector(11 downto 0);
    signal r3ireg_height : std_logic_vector(11 downto 0);
    signal r3ireg_width  : std_logic_vector(11 downto 0);
    signal r4ireg_height : std_logic_vector(11 downto 0);
    signal r4ireg_width  : std_logic_vector(11 downto 0);
    
    signal stimeoutcnt  : std_logic_vector(15 downto 0):=(others=>'0');
    signal stimeoutindi  : std_logic:='0';

    signal sd2m_xray_1d : std_logic:='0';
    signal sd2m_xray_2d : std_logic:='0';
    signal sd2m_xray    : std_logic:='0';

    signal sch0_warea_done : std_logic;
--COMPONENT vio_axi_sub_if
--  PORT (
--    clk : IN STD_LOGIC;
--    probe_out0 : OUT STD_LOGIC_VECTOR(11 DOWNTO 0)
--  );
--END COMPONENT;
--signal vio_probe_out0    : std_logic_vector(11 downto 0):=(others=>'0'); 
begin   
-- u_vio_axi_sub_if : vio_axi_sub_if
--  PORT MAP (
--    clk => iui_clk,
--    probe_out0 => vio_probe_out0
--  );
    ostate_ddr_sub <= state_ddr;

    sch0_base_waddr <= ireg_ddr_base_addr + ireg_ddr_ch0_waddr;
    sch1_base_waddr <= ireg_ddr_base_addr + ireg_ddr_ch1_waddr;
    --sch2_base_waddr <= ireg_ddr_base_addr + ireg_ddr_ch2_waddr;
    sch2_base_waddr <= ireg_ddr_base_addr + ireg_ddr_ch3_waddr when id2m_xray='1' else
                       ireg_ddr_base_addr + ireg_ddr_ch2_waddr;
    sch3_base_waddr <= ireg_ddr_base_addr + ireg_ddr_ch3_waddr;
    sch4_base_waddr <= ireg_ddr_base_addr + ireg_ddr_ch4_waddr;
    sch0_base_raddr <= ireg_ddr_base_addr + ireg_ddr_ch0_raddr;
    sch1_base_raddr <= ireg_ddr_base_addr + ireg_ddr_ch1_raddr;
    sch2_base_raddr <= ireg_ddr_base_addr + ireg_ddr_ch2_raddr;
    sch3_base_raddr <= ireg_ddr_base_addr + ireg_ddr_ch3_raddr;
    sch4_base_raddr <= ireg_ddr_base_addr + ireg_ddr_ch4_raddr;
GEN_10G_LEN : if (GEV_SPEED_BY_MODEL(GNR_MODEL) = "10G ") generate
begin 
    sch0_wlen <= "00000"  & ireg_width(11 downto 5); -- 512 / 16 bit = 2^5
--    sch1_wlen <= "00000"  & ireg_width(11 downto 5); -- 512 / 16 bit = 2^5
    sch1_wlen <=  "0000"  & ireg_width(11 downto 4); -- 512 / 32 bit = 2^4
    sch2_wlen <= "00000"  & ireg_width(11 downto 5); -- 512 / 16 bit = 2^5
    sch3_wlen <= "00000"  & ireg_width(11 downto 5); -- 512 / 16 bit = 2^5
    sch4_wlen <= "00000"  & ireg_width(11 downto 5); -- 512 / 16 bit = 2^5
end generate GEN_10G_LEN; 

GEN_2p5G_LEN : if (GEV_SPEED_BY_MODEL(GNR_MODEL) = "2p5G") generate
begin 
    sch0_wlen <= "00000"  & ireg_width(11 downto 5); -- 512 / 16 bit = 2^5
    sch1_wlen <=    "00"  & ireg_width(11 downto 2); -- 512 / 128 bit = 2^2
    sch2_wlen <=  "0000"  & ireg_width(11 downto 4); -- 512 / 32 bit = 2^4
    sch3_wlen <=  "0000"  & ireg_width(11 downto 4); -- 512 / 32 bit = 2^4
    sch4_wlen <= "00000"  & ireg_width(11 downto 5); -- 512 / 16 bit = 2^5
end generate GEN_2p5G_LEN; 

    U0_MULTI_13x12 : MULTI_13x12 -- 3 Delay
        port map (
            clk => iaxi_clk,
            ce    => iaxi_rstn,
            a    => smulti_a,
            b    => smulti_b,
            p    => smulti_p
        );

--    smulti_a   <= (ireg_width & '0');
--    smulti_b   <= ireg_height;
--    simg_size1 <= smulti_p;
--    simg_size2 <= smulti_p - (ireg_width & '0');
--    simg_size3 <= (smulti_p & '0') - (ireg_width & '0');
    smulti_a   <= (w0ireg_width & '0');
    smulti_b   <= w0ireg_height;
    simg_size1 <= smulti_p;
    simg_size2 <= smulti_p - (w0ireg_width & '0');
    simg_size3 <= (smulti_p & '0') - (w0ireg_width & '0');

    U0_AXI_WDATA_CONV : AXI_WDATA_CONV
        generic map (
            data_depth => DDR_BIT_W0( (GNR_MODEL))
        )
        port map (
            iwr_clk  => iui_clk,
            iwr_rstn => iui_rstn,

            iwr_en   => ich0_wen,
            iwr_addr => ich0_waddr,
            iwr_vcnt => ich0_wvcnt,
            iwr_data => ich0_wdata,

            ird_clk  => iaxi_clk,
            ird_rstn => iaxi_rstn,

            ird_en   => sddr_ch0_wen,
            ird_addr => sddr_ch0_waddr,
            ird_vcnt => sddr_ch0_wvcnt,
            ord_data => sch0_wdata
        );
    och0_wdata <= sch0_wdata; -- for debug

    U2_AXI_WDATA_CONV : AXI_WDATA_CONV
        generic map (
            data_depth => DDR_BIT_W2( (GNR_MODEL))
        )
        port map (
            iwr_clk  => idata_clk,
            iwr_rstn => idata_rstn,

            iwr_en   => ich2_wen,
            iwr_addr => ich2_waddr,
            iwr_vcnt => ich2_wvcnt,
            iwr_data => ich2_wdata,

            ird_clk  => iaxi_clk,
            ird_rstn => iaxi_rstn,

            ird_en   => sddr_ch2_wen,
            ird_addr => sddr_ch2_waddr,
            ird_vcnt => sddr_ch2_wvcnt,
            ord_data => och2_wdata
        );

    U4_AXI_WDATA_CONV : AXI_WDATA_CONV
        generic map (
            data_depth => DDR_BIT_W4( (GNR_MODEL))
        )
        port map (
            iwr_clk  => idata_clk,
            iwr_rstn => idata_rstn,

            iwr_en   => ich4_wen,
            iwr_addr => ich4_waddr,
            iwr_vcnt => ich4_wvcnt,
            iwr_data => ich4_wdata,

            ird_clk  => iaxi_clk,
            ird_rstn => iaxi_rstn,

            ird_en   => sddr_ch4_wen,
            ird_addr => sddr_ch4_waddr,
            ird_vcnt => sddr_ch4_wvcnt,
            ord_data => och4_wdata
        );
    sddr_ch0_wen   <= sddr_wen      when sddr_ch = 0 else
                      '0';
    sddr_ch1_wen   <= sddr_wen      when sddr_ch = 1 else
                      '0';
    sddr_ch2_wen   <= sddr_wen      when sddr_ch = 2 else
                      '0';
    sddr_ch3_wen   <= sddr_wen      when sddr_ch = 3 else
                      '0';
    sddr_ch4_wen   <= sddr_wen      when sddr_ch = 4 else
                      '0';
    sddr_ch0_waddr <= sddr_waddr  when sddr_ch = 0 else (others => '0');
    sddr_ch1_waddr <= sddr_waddr  when sddr_ch = 1 else (others => '0');
    sddr_ch2_waddr <= sddr_waddr  when sddr_ch = 2 else (others => '0');
    sddr_ch3_waddr <= sddr_waddr  when sddr_ch = 3 else (others => '0');
    sddr_ch4_waddr <= sddr_waddr  when sddr_ch = 4 else (others => '0');

    process (iaxi_clk, iaxi_rstn)
    begin
        if(iaxi_rstn = '0') then
            sreg_ddr_ch_en <= (others => '0');
        elsif (iaxi_clk'event and iaxi_clk = '1') then
            if(state_ddr = s_READY or state_ddr = s_IDLE) then
                if(sddr_ch0_wvcnt = 0 and sch0_wvcnt_3d = 0) then
                    sreg_ddr_ch_en(0) <= ireg_ddr_ch_en(0);
                end if;
                if(sddr_ch1_wvcnt = 0 and sch1_wvcnt_3d = 0) then
                    sreg_ddr_ch_en(1) <= ireg_ddr_ch_en(1);
                end if;
                if(sddr_ch2_wvcnt = 0 and sch2_wvcnt_3d = 0) then
                    sreg_ddr_ch_en(2) <= ireg_ddr_ch_en(2);
                end if;
                if(sddr_ch3_wvcnt = 0 and sch3_wvcnt_3d = 0) then
                    sreg_ddr_ch_en(3) <= ireg_ddr_ch_en(3);
                end if;
                if(sddr_ch4_wvcnt = 0 and sch4_wvcnt_3d = 0) then
                    sreg_ddr_ch_en(8) <= ireg_ddr_acc_ch_en and ireg_ddr_ch_en(0); -- prevent roi addr bug 220120mbh
                end if;

                if(sddr_ch0_rvcnt = 0 and sconv_vcnt_3d = ireg_height - 1) then
                    sreg_ddr_ch_en(4) <= ireg_ddr_ch_en(4);
                end if;
                if(sddr_ch1_rvcnt = 0 and sconv_vcnt_3d = ireg_height - 1) then
                    sreg_ddr_ch_en(5) <= ireg_ddr_ch_en(5);
                end if;
                if(sddr_ch2_rvcnt = 0 and sconv_vcnt_3d = ireg_height - 1) then
                    sreg_ddr_ch_en(6) <= ireg_ddr_ch_en(6);
                end if;
                if(sddr_ch3_rvcnt = 0 and sconv_vcnt_3d = ireg_height - 1) then
                    sreg_ddr_ch_en(7) <= ireg_ddr_ch_en(7);
                end if;
                if(sddr_ch4_rvcnt = 0 and sconv_vcnt_3d = ireg_height - 1) then
                    sreg_ddr_ch_en(9) <= ireg_ddr_acc_ch_en and ireg_ddr_ch_en(4); -- prevent roi addr bug 220120mbh
                end if;
            end if;
        end if;
    end process;

    process (iaxi_clk, iaxi_rstn)
    begin
        if(iaxi_rstn = '0') then
            sddr_ch_en <= (others => '0');
        elsif (iaxi_clk'event and iaxi_clk = '1') then
            if(sreg_ddr_ch_en(0) = '1') then
                if(sch0_wen_2d = '0' and sch0_wen_3d = '1') then -- Falling Edge
                    sddr_ch_en(0) <= '1';
                elsif (sch0_wtrig = '1') then
                    sddr_ch_en(0) <= '0';
                end if;
            else
                if(sddr_ch0_wvcnt = 0) then
                    sddr_ch_en(0) <= '0';
                end if;
            end if;

            if(sreg_ddr_ch_en(1) = '1') then
                if(sch1_wen_2d = '0' and sch1_wen_3d = '1') then -- Falling Edge
                    sddr_ch_en(1) <= '1';
                elsif (sch1_wtrig = '1') then
                    sddr_ch_en(1) <= '0';
                end if;
            else
                if(sddr_ch1_wvcnt = 0) then
                    sddr_ch_en(1) <= '0';
                end if;
            end if;

            if(sreg_ddr_ch_en(2) = '1') then
                if(sch2_wen_2d = '0' and sch2_wen_3d = '1') then -- Falling Edge
                    sddr_ch_en(2) <= '1';
                elsif (sch2_wtrig = '1') then
                    sddr_ch_en(2) <= '0';
                end if;
            else
                if(sddr_ch2_wvcnt = 0) then
                    sddr_ch_en(2) <= '0';
                end if;
            end if;

            if(sreg_ddr_ch_en(3) = '1') then
                if(sch3_wen_2d = '0' and sch3_wen_3d = '1') then -- Falling Edge
                    sddr_ch_en(3) <= '1';
                elsif (sch3_wtrig = '1') then
                    sddr_ch_en(3) <= '0';
                end if;
            else
                if(sddr_ch3_wvcnt = 0) then
                    sddr_ch_en(3) <= '0';
                end if;
            end if;

            -- write ch 4 for acc
            if(sreg_ddr_ch_en(8) = '1') then
                if(sch4_wen_2d = '0' and sch4_wen_3d = '1') then -- Falling Edge
                    sddr_ch_en(8) <= '1';
                elsif (sch4_wtrig = '1') then
                    sddr_ch_en(8) <= '0';
                end if;
            else
                if(sddr_ch4_wvcnt = 0) then
                    sddr_ch_en(8) <= '0';
                end if;
            end if;

            if(sreg_ddr_ch_en(4) = '1') then
                if(sconv_hsync_2d = '1' and sconv_hsync_3d = '0') then -- Rising Edge
                    sddr_ch_en(4) <= '1';
                elsif (sch0_rtrig = '1') then
                    sddr_ch_en(4) <= '0';
                end if;
            else
                if(sddr_ch0_rvcnt = 0) then
                    sddr_ch_en(4) <= '0';
                end if;
            end if;

            if(sreg_ddr_ch_en(5) = '1') then
                if(sconv_hsync_2d = '1' and sconv_hsync_3d = '0') then -- Rising Edge
                    sddr_ch_en(5) <= '1';
                elsif (sch1_rtrig = '1') then
                    sddr_ch_en(5) <= '0';
                end if;
            else
                if(sddr_ch1_rvcnt = 0) then
                    sddr_ch_en(5) <= '0';
                end if;
            end if;

            if(sreg_ddr_ch_en(6) = '1') then
                if(sconv_hsync_2d = '1' and sconv_hsync_3d = '0') then -- Rising Edge
                    sddr_ch_en(6) <= '1';
                elsif (sch2_rtrig = '1') then
                    sddr_ch_en(6) <= '0';
                end if;
            else
                if(sddr_ch2_rvcnt = 0) then
                    sddr_ch_en(6) <= '0';
                end if;
            end if;

            if(sreg_ddr_ch_en(7) = '1') then
                if(sconv_hsync_2d = '1' and sconv_hsync_3d = '0') then -- Rising Edge
                    sddr_ch_en(7) <= '1';
                elsif (sch3_rtrig = '1') then
                    sddr_ch_en(7) <= '0';
                end if;
            else
                if(sddr_ch3_rvcnt = 0) then
                    sddr_ch_en(7) <= '0';
                end if;
            end if;

            -- read ch 4
            if(sreg_ddr_ch_en(9) = '1') then
                if(sconv_hsync_2d = '1' and sconv_hsync_3d = '0') then -- Rising Edge
                    sddr_ch_en(9) <= '1';
                elsif (sch4_rtrig = '1') then
                    sddr_ch_en(9) <= '0';
                end if;
            else
                if(sddr_ch4_rvcnt = 0) then
                    sddr_ch_en(9) <= '0';
                end if;
            end if;

        end if;
    end process;

    process (iaxi_clk, iaxi_rstn)
    begin
        if(iaxi_rstn = '0') then
            state_ddr <= s_IDLE;

            swait_cnt <= (others => '0');

            sch0_waddr <= (others => '0');
            sch1_waddr <= (others => '0');
            sch2_waddr <= (others => '0');
            sch3_waddr <= (others => '0');
            sch4_waddr <= (others => '0');
            sch0_raddr <= (others => '0');
            sch1_raddr <= (others => '0');
            sch2_raddr <= (others => '0');
            sch3_raddr <= (others => '0');
            sch4_raddr <= (others => '0');

--            sch0_warea <= '0';  -- when changing to d2m, first img got a abnormal. 
--            sch0_rarea <= '1';
            sch0_warea <= '1'; -- mbh210723
            sch0_rarea <= '0';

            sddr_ch0_wvcnt <= (others => '0');
            sddr_ch1_wvcnt <= (others => '0');
            sddr_ch2_wvcnt <= (others => '0');
            sddr_ch3_wvcnt <= (others => '0');
            sddr_ch4_wvcnt <= (others => '0');
            sddr_ch0_rvcnt <= (others => '0');
            sddr_ch1_rvcnt <= (others => '0');
            sddr_ch2_rvcnt <= (others => '0');
            sddr_ch3_rvcnt <= (others => '0');
            sddr_ch4_rvcnt <= (others => '0');

            sch0_waddr_top <= (others => '0');
            sch0_waddr_bot <= (others => '0');

            sch0_wtrig <= '0';
            sch1_wtrig <= '0';
            sch2_wtrig <= '0';
            sch3_wtrig <= '0';
            sch4_wtrig <= '0';
            sch0_rtrig <= '0';
            sch1_rtrig <= '0';
            sch2_rtrig <= '0';
            sch3_rtrig <= '0';
            sch4_rtrig <= '0';

            sddr_wen   <= '0';
            sddr_wlen  <= (others => '0');
            sddr_waddr <= (others => '0');

            sddr_ch           <= 0;
            sdual_roic_cnt <= 0;
        elsif (iaxi_clk'event and iaxi_clk = '1') then
    -- ### latch registers
--        if    sddr_ch0_wvcnt = 0 then
--            w0ireg_height <= ireg_height;
--            w0ireg_width  <= ireg_width;
--        end if;
--        if    sddr_ch1_wvcnt = 0 then
--            w1ireg_height <= ireg_height;
--            w1ireg_width  <= ireg_width;
--        end if;
--        if    sddr_ch2_wvcnt = 0 then
--            w2ireg_height <= ireg_height;
--            w2ireg_width  <= ireg_width;
--        end if;
--      if    sddr_ch0_rvcnt = r0ireg_height - 1 then -- for latch mbh 210105
--            r0ireg_height <= ireg_height;
--            r0ireg_width  <= ireg_width;
--        end if;
--        if    sddr_ch1_rvcnt = r1ireg_height - 1 then -- for latch mbh 210105
--            r1ireg_height <= ireg_height;
--            r1ireg_width  <= ireg_width;
--        end if;
--        if    sddr_ch2_rvcnt = r2ireg_height - 1 then -- for latch mbh 210105
--            r2ireg_height <= ireg_height;
--            r2ireg_width  <= ireg_width;
--        end if;
    -- ### not latch registers
              w0ireg_height <= ireg_height;
              w0ireg_width  <= ireg_width;
              w1ireg_height <= ireg_height;
              w1ireg_width  <= ireg_width;
              w2ireg_height <= ireg_height;
              w2ireg_width  <= ireg_width;
              w3ireg_height <= ireg_height;
              w3ireg_width  <= ireg_width;
              w4ireg_height <= ireg_height;
              w4ireg_width  <= ireg_width;
              r0ireg_height <= ireg_height;
              r0ireg_width  <= ireg_width;
              r1ireg_height <= ireg_height;
              r1ireg_width  <= ireg_width;
              r2ireg_height <= ireg_height;
              r2ireg_width  <= ireg_width;
              r3ireg_height <= ireg_height;
              r3ireg_width  <= ireg_width;
              r4ireg_height <= ireg_height;
              r4ireg_width  <= ireg_width;

            case (state_ddr) is
                when s_IDLE =>
                    if(swait_cnt = x"FF") then
                        if(ireg_ddr_ch_en /= 0) then
                            state_ddr <= s_READY;
                            swait_cnt <= (others => '0');
                        end if;
                    else
                        swait_cnt <= swait_cnt + '1';
                    end if;

                    sch0_waddr <= sch0_base_waddr;
                    sch1_waddr <= sch1_base_waddr;
                    sch2_waddr <= sch2_base_waddr;
                    sch3_waddr <= sch3_base_waddr;
                    sch4_waddr <= sch4_base_waddr;
                    sch0_raddr <= sch0_base_raddr;
                    sch1_raddr <= sch1_base_raddr;
                    sch2_raddr <= sch2_base_raddr;
                    sch3_raddr <= sch3_base_raddr;
                    sch4_raddr <= sch4_base_raddr;

                    sch0_waddr_bot <= sch0_base_waddr;
                    sch0_waddr_top <= sch0_base_waddr + simg_size2;
                    debugnum       <= x"1"; -- debug

                when s_READY =>
                    if(sddr_ch_en(0) = '1') then -- # roic write
                        state_ddr  <= s_WRITE;
                        sddr_ch    <= 0;
                        sch0_wtrig <= '1';

                        sddr_wen   <= '1';
                        sddr_wlen  <= sch0_wlen;
                        sddr_waddr <= (others => '0');
                        debugnum   <= x"2"; -- debug

                    elsif (sddr_ch_en(2) = '1') then  -- # write offset / some time
                        state_ddr  <= s_WRITE;
                        sddr_ch    <= 2;
                        sch2_wtrig <= '1';

                        sddr_wen   <= '1';
                        sddr_wlen  <= sch2_wlen;
                        sddr_waddr <= (others => '0');

                    elsif (sddr_ch_en(8) = '1') then -- # write acc //# 221207 ######################
                        state_ddr  <= s_WRITE;
                        sddr_ch    <= 4;
                        sch4_wtrig <= '1';

                        sddr_wen   <= '1';
                        sddr_wlen  <= sch4_wlen;
                        sddr_waddr <= (others => '0');
                        
                    elsif (sddr_ch_en(1) = '1') then -- # NUC write not using
                        state_ddr  <= s_WRITE;
                        sddr_ch    <= 1;
                        sch1_wtrig <= '1';

                        sddr_wen   <= '1';
                        sddr_wlen  <= sch1_wlen;
                        sddr_waddr <= (others => '0');
--                    elsif (sddr_ch_en(2) = '1') then  -- # write offset / some time
--                        state_ddr  <= s_WRITE;
--                        sddr_ch    <= 2;
--                        sch2_wtrig <= '1';

--                        sddr_wen   <= '1';
--                        sddr_wlen  <= sch2_wlen;
--                        sddr_waddr <= (others => '0');
                    elsif (sddr_ch_en(3) = '1') then -- # not using
                        state_ddr  <= s_WRITE;
                        sddr_ch    <= 3;
                        sch3_wtrig <= '1';

                        sddr_wen   <= '1';
                        sddr_wlen  <= sch3_wlen;
                        sddr_waddr <= (others => '0');


                    elsif (sddr_ch_en(4) = '1') then -- # read roic
                        state_ddr <= s_READ;
                        sddr_ch   <= 0;
                        sch0_rtrig <= '1';
                        
                    elsif (sddr_ch_en(9) = '1') then -- # read acc 
                        state_ddr <= s_READ;
                        sddr_ch   <= 4;
                        sch4_rtrig <= '1';
                        
                    elsif (sddr_ch_en(6) = '1') then -- # read offset
                        state_ddr <= s_READ;
                        sddr_ch   <= 2;
                        sch2_rtrig <= '1';

                    elsif (sddr_ch_en(5) = '1') then -- # read nuc : low priority cause long command
                        state_ddr <= s_READ;
                        sddr_ch   <= 1;
                        sch1_rtrig <= '1';
                        
                    elsif (sddr_ch_en(7) = '1') then  -- # d2m xray
                        state_ddr <= s_READ;
                        sddr_ch   <= 3;
                        sch3_rtrig <= '1';

--                    elsif (sddr_ch_en(9) = '1') then -- # read acc 
--                        state_ddr <= s_READ;
--                        sddr_ch   <= 4;
--                        sch4_rtrig <= '1';

--                    elsif (sddr_ch_en(8) = '1') then -- # write acc //221207
--                        state_ddr  <= s_WRITE;
--                        sddr_ch    <= 4;
--                        sch4_wtrig <= '1';

--                        sddr_wen   <= '1';
--                        sddr_wlen  <= sch4_wlen;
--                        sddr_waddr <= (others => '0');

                    else
                        -- if(sreg_ddr_ch_en(0) = '0' and sddr_ch0_wvcnt = 0 and sch0_warea = '0') then
                        if(sreg_ddr_ch_en(0) = '0' and sddr_ch0_wvcnt = 0) then -- checked mbh 210203 
                            sch0_waddr       <= sch0_base_waddr;
                            sch0_waddr_bot <= sch0_base_waddr;
                            sch0_waddr_top <= sch0_base_waddr + simg_size2;
                        end if;

                        if(sreg_ddr_ch_en(1) = '0' and sddr_ch1_wvcnt = 0) then
                            sch1_waddr <= sch1_base_waddr;
                        end if;

                        if sd2m_xray /= sd2m_xray_2d then -- 210729mbh
                            sch2_waddr <= sch2_base_waddr;
                        elsif(sreg_ddr_ch_en(2) = '0' and sddr_ch2_wvcnt = 0) then
                            sch2_waddr <= sch2_base_waddr;
                        end if;

                        if(sreg_ddr_ch_en(3) = '0' and sddr_ch3_wvcnt = 0) then
                            sch3_waddr <= sch3_base_waddr;
                        end if;

                        if(sreg_ddr_ch_en(8) = '0' and sddr_ch4_wvcnt = 0) then
                            sch4_waddr <= sch4_base_waddr;
                        end if;

                        -- if(sreg_ddr_ch_en(4) = '0' and sddr_ch0_rvcnt = 0 and sch0_rarea = '0') then
                        if(sreg_ddr_ch_en(4) = '0' and sddr_ch0_rvcnt = 0) then -- checked mbh 210203
                            sch0_raddr <= sch0_base_raddr;
                        end if;

                        if(sreg_ddr_ch_en(5) = '0' and sddr_ch1_rvcnt = 0) then
                            sch1_raddr <= sch1_base_raddr;
                        end if;

                        if(sreg_ddr_ch_en(6) = '0' and sddr_ch2_rvcnt = 0) then
                            sch2_raddr <= sch2_base_raddr;
                        end if;

                        if(sreg_ddr_ch_en(7) = '0' and sddr_ch3_rvcnt = 0) then
                            sch3_raddr <= sch3_base_raddr;
                        end if;

                        if(sreg_ddr_ch_en(9) = '0' and sddr_ch4_rvcnt = 0) then
                            sch4_raddr <= sch4_base_raddr;
                        end if;

                    end if;

                when s_READ =>
                    if(iconv_rlast = '1') then
                        state_ddr <= s_RCHECK;
                    end if;

                    sch0_rtrig <= '0';
                    sch1_rtrig <= '0';
                    sch2_rtrig <= '0';
                    sch3_rtrig <= '0';
                    sch4_rtrig <= '0';

                when s_WRITE =>
                    if(iaxi_wready = '1') then
                        if(sddr_waddr = sddr_wlen - 1) then
                            state_ddr <= s_WRESP;

                            sddr_wen   <= '0';
                            sddr_waddr <= (others => '0');

                            if(sddr_ch = 0) then
                                if(sdual_roic_cnt = 0) then
                                    sdual_roic_cnt <= ROIC_DUAL_BY_MODEL(GNR_MODEL) - 1;
                                    sch0_waddr_bot <= sch0_waddr_bot + (ireg_width(11 downto 0) & '0'); -- 16 / 8
                                else
                                    sdual_roic_cnt <= sdual_roic_cnt - 1;
                                    sch0_waddr_top <= sch0_waddr_top - (ireg_width(11 downto 0) & '0');
                                end if;
                            end if;
                        else
                            sddr_waddr <= sddr_waddr + '1';
                        end if;
                        stimeoutcnt <= (others=>'0');
                    else 
                       -- #### state machine time out 210406 mbh
                       if stimeoutcnt < 2**16-1 then
                           stimeoutcnt <= stimeoutcnt + '1';
                           stimeoutindi <= '0';
                       else
                           state_ddr <= s_READY;
                           sddr_wen   <= '0';
                           sddr_waddr <= (others => '0');
                            
                           stimeoutcnt <= (others=>'0');
                           stimeoutindi <= '1';
                       end if;
                    end if;

                    sch0_wtrig <= '0';
                    sch1_wtrig <= '0';
                    sch2_wtrig <= '0';
                    sch3_wtrig <= '0';
                    sch4_wtrig <= '0';

                when s_WRESP =>
                    if(iaxi_bready = '1') then
                        state_ddr <= s_WCHECK;
                    end if;

                when s_WCHECK =>
                    state_ddr <= s_FINISH;
                    if(GEV_SPEED_BY_MODEL(GNR_MODEL) = "10G ") then 
                        if(sddr_ch = 0) then
    --                        if(sddr_ch0_wvcnt = w0ireg_height - 1) then
                            if(sddr_ch0_wvcnt >= w0ireg_height - 1) then -- preventing ddr pointer overflow :mbh211213
                                sddr_ch0_wvcnt <= sconv_vcnt_cutw(12-1 downto 0); -- ivcnt synchronize (others => '0');
                                
                                sdual_roic_cnt <= 0;
    
                                if(sch0_warea = '0') then
                                    sch0_warea       <= '1';
                                    sch0_waddr       <= sch0_base_waddr + simg_size1;
                                    sch0_waddr_bot <= sch0_base_waddr + simg_size1;
                                    sch0_waddr_top <= sch0_base_waddr + simg_size3;
                                else
                                    sch0_warea       <= '0';
                                    sch0_waddr       <= sch0_base_waddr;
                                    sch0_waddr_bot <= sch0_base_waddr;
                                    sch0_waddr_top <= sch0_base_waddr + simg_size2;
                                end if;
                            else
                                sddr_ch0_wvcnt <= sddr_ch0_wvcnt + '1';
    
                                if(sdual_roic_cnt = 0) then
                                    sch0_waddr <= sch0_waddr_bot;
                                else
                                    sch0_waddr <= sch0_waddr_top;
                                end if;
                            end if;
                        elsif (sddr_ch = 1) then
    --                        if(sddr_ch1_wvcnt = w1ireg_height - 1) then  -- preventing ddr pointer overflow :mbh211213
                            if(sddr_ch1_wvcnt >= w1ireg_height - 1) then
--                             sddr_ch1_wvcnt <= (others => '0');
                                sddr_ch1_wvcnt <= sch1_wvcnt_3d;   --# v position 230717  
                                sch1_waddr       <= sch1_base_waddr;
                            else
                                sddr_ch1_wvcnt <= sddr_ch1_wvcnt + '1';
--                                sch1_waddr       <= sch1_waddr + (w1ireg_width(11 downto 0) & '0'); -- 16 / 8
                                sch1_waddr       <= sch1_waddr + (w1ireg_width(11 downto 0) & "00"); -- 32 / 8
                            end if;
                        elsif (sddr_ch = 2) then
    --                        if(sddr_ch2_wvcnt = w2ireg_height - 1) then
                            if(sddr_ch2_wvcnt >= w2ireg_height - 1) then  -- preventing ddr pointer overflow :mbh211213
--                             sddr_ch2_wvcnt <= (others => '0');
                                sddr_ch2_wvcnt <= sch2_wvcnt_3d;   --# v position 230717 
                                sch2_waddr       <= sch2_base_waddr;
                            else
                                sddr_ch2_wvcnt <= sddr_ch2_wvcnt + '1';
                                sch2_waddr       <= sch2_waddr + (w2ireg_width(11 downto 0) & '0');     -- 16 / 8
                            end if;
                        elsif (sddr_ch = 3) then
    --                        if(sddr_ch3_wvcnt = w3ireg_height - 1) then
                            if(sddr_ch3_wvcnt >= w3ireg_height - 1) then  -- preventing ddr pointer overflow :mbh211213
--                             sddr_ch3_wvcnt <= (others => '0');
                                sddr_ch3_wvcnt <= sch3_wvcnt_3d;   --# v position 230717 
                                sch3_waddr       <= sch3_base_waddr;
                            else
                                sddr_ch3_wvcnt <= sddr_ch3_wvcnt + '1';
                                sch3_waddr       <= sch3_waddr + (w3ireg_width(11 downto 0) & '0');     -- 16 / 8
                            end if;
                        elsif (sddr_ch = 4) then
                            if(sddr_ch4_wvcnt = w4ireg_height - 1) then
--                             sddr_ch4_wvcnt <= (others => '0');
                                sddr_ch4_wvcnt <= sch4_wvcnt_3d; --# v position 230717
                                sch4_waddr       <= sch4_base_waddr;
                            else
                                sddr_ch4_wvcnt <= sddr_ch4_wvcnt + '1';
                                sch4_waddr       <= sch4_waddr + (w4ireg_width(11 downto 0) & '0');     -- 16 / 8
                            end if;
                        end if;
                    else --##### 2.5G #####
                        if(sddr_ch = 0) then
    --                        if(sddr_ch0_wvcnt = w0ireg_height - 1) then
                            if(sddr_ch0_wvcnt >= w0ireg_height - 1) then -- preventing ddr pointer overflow :mbh211213
                                sddr_ch0_wvcnt <= sconv_vcnt_cutw(12-1 downto 0); -- ivcnt synchronize (others => '0');
    
                                sdual_roic_cnt <= 0;
    
                                if(sch0_warea = '0') then
                                    sch0_warea       <= '1';
                                    sch0_waddr       <= sch0_base_waddr + simg_size1;
                                    sch0_waddr_bot <= sch0_base_waddr + simg_size1;
                                    sch0_waddr_top <= sch0_base_waddr + simg_size3;
                                else
                                    sch0_warea       <= '0';
                                    sch0_waddr       <= sch0_base_waddr;
                                    sch0_waddr_bot <= sch0_base_waddr;
                                    sch0_waddr_top <= sch0_base_waddr + simg_size2;
                                end if;
                            else
                                sddr_ch0_wvcnt <= sddr_ch0_wvcnt + '1';
    
                                if(sdual_roic_cnt = 0) then
                                    sch0_waddr <= sch0_waddr_bot;
                                else
                                    sch0_waddr <= sch0_waddr_top;
                                end if;
                            end if;
                        elsif (sddr_ch = 1) then
    --                        if(sddr_ch1_wvcnt = w1ireg_height - 1) then  -- preventing ddr pointer overflow :mbh211213
                            if(sddr_ch1_wvcnt >= w1ireg_height - 1) then
--                              sddr_ch1_wvcnt <= (others => '0');
                                sddr_ch1_wvcnt <= sch1_wvcnt_3d;   --# v position 230717  
                                sch1_waddr     <= sch1_base_waddr;
                            else
                                sddr_ch1_wvcnt <= sddr_ch1_wvcnt + '1';
                                sch1_waddr     <= sch1_waddr + (w1ireg_width(11 downto 0) & "0000"); -- 128 / 8
                            end if;
                        elsif (sddr_ch = 2) then
    --                        if(sddr_ch2_wvcnt = w2ireg_height - 1) then
                            if(sddr_ch2_wvcnt >= w2ireg_height - 1) then  -- preventing ddr pointer overflow :mbh211213
--                             sddr_ch2_wvcnt <= (others => '0');
                                sddr_ch2_wvcnt <= sch2_wvcnt_3d;   --# v position 230717 
                                sch2_waddr     <= sch2_base_waddr;
                            else
                                sddr_ch2_wvcnt <= sddr_ch2_wvcnt + '1';
                                sch2_waddr     <= sch2_waddr + (w2ireg_width(11 downto 0) & "00");     -- 32 / 8
                            end if;
                        elsif (sddr_ch = 3) then
    --                        if(sddr_ch3_wvcnt = w3ireg_height - 1) then
                            if(sddr_ch3_wvcnt >= w3ireg_height - 1) then  -- preventing ddr pointer overflow :mbh211213
--                             sddr_ch3_wvcnt <= (others => '0'); 
                                sddr_ch3_wvcnt <= sch3_wvcnt_3d;   --# v position 230717 
                                sch3_waddr     <= sch3_base_waddr;
                            else
                                sddr_ch3_wvcnt <= sddr_ch3_wvcnt + '1';
                                sch3_waddr     <= sch3_waddr + (w3ireg_width(11 downto 0) & "00");     -- 32 / 8
                            end if;
                        elsif (sddr_ch = 4) then
                            if(sddr_ch4_wvcnt = w4ireg_height - 1) then
--                                 sddr_ch4_wvcnt <= (others => '0');
                                sddr_ch4_wvcnt <= sch4_wvcnt_3d; --# v position 230717
                                sch4_waddr     <= sch4_base_waddr;
                            else
                                sddr_ch4_wvcnt <= sddr_ch4_wvcnt + '1';
                                sch4_waddr     <= sch4_waddr + (w4ireg_width(11 downto 0) & '0');     -- 16 / 8
                            end if;
                        end if;
                    end if;

                when s_RCHECK =>
                    state_ddr <= s_FINISH;
                    if(GEV_SPEED_BY_MODEL(GNR_MODEL) = "10G ") then 
                        if(sddr_ch = 0) then
                            if(sddr_ch0_rvcnt >= r0ireg_height - 1) then
                                sddr_ch0_rvcnt <= sconv_vcnt_cut(12-1 downto 0); -- vcnt synchronize (others => '0');
    
    --                            if(sch0_rarea = '0') then
--                                if(sch0_warea = '1') then -- rarea sync with warea , 210713 mbh
                                if(sch0_warea = '0') then
                                    sch0_rarea <= '1';
                                    sch0_raddr <= sch0_base_raddr + simg_size1;
                                else
                                    sch0_rarea <= '0';
                                    sch0_raddr <= sch0_base_raddr;
                                end if;
                            else
                                sddr_ch0_rvcnt <= sddr_ch0_rvcnt + '1';
                                sch0_raddr       <= sch0_raddr + (r0ireg_width(11 downto 0) & '0');
                            end if;
                        elsif (sddr_ch = 1) then
                            if(sddr_ch1_rvcnt >= r1ireg_height - 1) then
                                 sddr_ch1_rvcnt <= sconv_vcnt_cut(12-1 downto 0); -- (others => '0');
                                sch1_raddr       <= sch1_base_raddr;
                            else
                                sddr_ch1_rvcnt <= sddr_ch1_rvcnt + '1';
--                                sch1_raddr       <= sch1_raddr + (r1ireg_width(11 downto 0) & '0');
                                sch1_raddr       <= sch1_raddr + (r1ireg_width(11 downto 0) & "00"); --# 32b
                            end if;
                        elsif (sddr_ch = 2) then
                            if(sddr_ch2_rvcnt >= r2ireg_height - 1) then
                                sddr_ch2_rvcnt <= sconv_vcnt_cut(12-1 downto 0); -- (others => '0');
                                sch2_raddr       <= sch2_base_raddr;
                            else
                                sddr_ch2_rvcnt <= sddr_ch2_rvcnt + '1';
                                sch2_raddr       <= sch2_raddr + (r2ireg_width(11 downto 0) & '0');
                            end if;
    
                        elsif (sddr_ch = 3) then --# read ch3
                            if(sddr_ch3_rvcnt >= r3ireg_height - 1) then
                                sddr_ch3_rvcnt <= sconv_vcnt_cut(12-1 downto 0); -- (others => '0');
                                sch3_raddr       <= sch3_base_raddr;
                            else
                                sddr_ch3_rvcnt <= sddr_ch3_rvcnt + '1';
                                sch3_raddr       <= sch3_raddr + (r3ireg_width(11 downto 0) & '0');
                            end if;
                        elsif (sddr_ch = 4) then --# read ch4
                            if(sddr_ch4_rvcnt >= r4ireg_height - 1) then
                                sddr_ch4_rvcnt <= sconv_vcnt_cut(12-1 downto 0); -- (others => '0');
                                sch4_raddr       <= sch4_base_raddr;
                            else
                                sddr_ch4_rvcnt <= sddr_ch4_rvcnt + '1';
                                sch4_raddr       <= sch4_raddr + (r4ireg_width(11 downto 0) & '0');
--                                  sch4_raddr       <= sch4_raddr + (r4ireg_width(11 downto 0) & '0');
    --                            sch4_raddr       <= sch4_raddr + (r4ireg_width(11 downto 0) & "0000");
                            end if;
                        end if;
                     else --##### 2.5G #####             
                        if(sddr_ch = 0) then
                            if(sddr_ch0_rvcnt >= r0ireg_height - 1) then
                                sddr_ch0_rvcnt <= sconv_vcnt_cut(12-1 downto 0); -- vcnt synchronize (others => '0');
    
    --                            if(sch0_rarea = '0') then
                                if(sch0_warea = '1') then -- rarea sync with warea , 210713 mbh
                                    sch0_rarea <= '1';
                                    sch0_raddr <= sch0_base_raddr + simg_size1;
                                else
                                    sch0_rarea <= '0';
                                    sch0_raddr <= sch0_base_raddr;
                                end if;
                            else
                                sddr_ch0_rvcnt <= sddr_ch0_rvcnt + '1';
                                sch0_raddr       <= sch0_raddr + (r0ireg_width(11 downto 0) & '0');
                            end if;
                        elsif (sddr_ch = 1) then
                            if(sddr_ch1_rvcnt >= r1ireg_height - 1) then
                                 sddr_ch1_rvcnt <= sconv_vcnt_cut(12-1 downto 0); -- (others => '0');
                                sch1_raddr       <= sch1_base_raddr;
                            else
                                sddr_ch1_rvcnt <= sddr_ch1_rvcnt + '1';
                                sch1_raddr       <= sch1_raddr + (r1ireg_width(11 downto 0) & "0000");
                            end if;
                        elsif (sddr_ch = 2) then
                            if(sddr_ch2_rvcnt >= r2ireg_height - 1) then
                                sddr_ch2_rvcnt <= sconv_vcnt_cut(12-1 downto 0); -- (others => '0');
                                sch2_raddr       <= sch2_base_raddr;
                            else
                                sddr_ch2_rvcnt <= sddr_ch2_rvcnt + '1';
                                sch2_raddr       <= sch2_raddr + (r2ireg_width(11 downto 0) & "00");
                            end if;
    
                        elsif (sddr_ch = 3) then --# read ch3
                            if(sddr_ch3_rvcnt >= r3ireg_height - 1) then
                                sddr_ch3_rvcnt <= sconv_vcnt_cut(12-1 downto 0); -- (others => '0');
                                sch3_raddr       <= sch3_base_raddr;
                            else
                                sddr_ch3_rvcnt <= sddr_ch3_rvcnt + '1';
                                sch3_raddr       <= sch3_raddr + (r3ireg_width(11 downto 0) & "00");
                            end if;
                        elsif (sddr_ch = 4) then --# read ch4
                            if(sddr_ch4_rvcnt >= r4ireg_height - 1) then
                                sddr_ch4_rvcnt <= sconv_vcnt_cut(12-1 downto 0); -- (others => '0');
                                sch4_raddr       <= sch4_base_raddr;
                            else
                                sddr_ch4_rvcnt <= sddr_ch4_rvcnt + '1';
    --                            sch4_raddr       <= sch4_raddr + (r4ireg_width(11 downto 0) & "00");
                                  sch4_raddr       <= sch4_raddr + (r4ireg_width(11 downto 0) & '0');
    --                            sch4_raddr       <= sch4_raddr + (r4ireg_width(11 downto 0) & "0000");
                            end if;
                        end if;
                    end if;

                when s_FINISH =>
                    if(swait_cnt = 3) then
                        state_ddr <= s_READY;
                        swait_cnt <= (others => '0');
                    else
                        swait_cnt <= swait_cnt + '1';
                    end if;

                when others =>
                    NULL;
            end case;

        end if;
    end process;

    process (iaxi_clk, iaxi_rstn)
    begin
        if(iaxi_rstn = '0') then
            sch0_wen_1d   <= '0';
            sch0_wen_2d   <= '0';
            sch0_wen_3d   <= '0';
            sch1_wen_1d   <= '0';
            sch1_wen_2d   <= '0';
            sch1_wen_3d   <= '0';
            sch2_wen_1d   <= '0';
            sch2_wen_2d   <= '0';
            sch2_wen_3d   <= '0';
            sch3_wen_1d   <= '0';
            sch3_wen_2d   <= '0';
            sch3_wen_3d   <= '0';
            sch4_wen_1d   <= '0';
            sch4_wen_2d   <= '0';
            sch4_wen_3d   <= '0';
            sch0_wvcnt_1d <= (others => '0');
            sch0_wvcnt_2d <= (others => '0');
            sch0_wvcnt_3d <= (others => '0');
            sch1_wvcnt_1d <= (others => '0');
            sch1_wvcnt_2d <= (others => '0');
            sch1_wvcnt_3d <= (others => '0');
            sch2_wvcnt_1d <= (others => '0');
            sch2_wvcnt_2d <= (others => '0');
            sch2_wvcnt_3d <= (others => '0');
            sch3_wvcnt_1d <= (others => '0');
            sch3_wvcnt_2d <= (others => '0');
            sch3_wvcnt_3d <= (others => '0');
            sch4_wvcnt_1d <= (others => '0');
            sch4_wvcnt_2d <= (others => '0');
            sch4_wvcnt_3d <= (others => '0');

            sconv_hsync_1d <= '0';
            sconv_hsync_2d <= '0';
            sconv_hsync_3d <= '0';
            sconv_vcnt_1d  <= (others => '0');
            sconv_vcnt_2d  <= (others => '0');
            sconv_vcnt_3d  <= (others => '0');
            sconv_vcnt_4d  <= (others => '0');
            sd2m_xray_1d <= '0';
            sd2m_xray_2d <= '0';
            sd2m_xray    <= '0';
        elsif (iaxi_clk'event and iaxi_clk = '1') then
            sch0_wen_1d   <= ich0_wen;
            sch0_wen_2d   <= sch0_wen_1d;
            sch0_wen_3d   <= sch0_wen_2d;
            sch1_wen_1d   <= ich1_wen;
            sch1_wen_2d   <= sch1_wen_1d;
            sch1_wen_3d   <= sch1_wen_2d;
            sch2_wen_1d   <= ich2_wen;
            sch2_wen_2d   <= sch2_wen_1d;
            sch2_wen_3d   <= sch2_wen_2d;
            sch3_wen_1d   <= ich3_wen;
            sch3_wen_2d   <= sch3_wen_1d;
            sch3_wen_3d   <= sch3_wen_2d;
            sch4_wen_1d   <= ich4_wen;
            sch4_wen_2d   <= sch4_wen_1d;
            sch4_wen_3d   <= sch4_wen_2d;
            sch0_wvcnt_1d <= ich0_wvcnt;
            sch0_wvcnt_2d <= sch0_wvcnt_1d;
            sch0_wvcnt_3d <= sch0_wvcnt_2d;
            sch1_wvcnt_1d <= ich1_wvcnt;
            sch1_wvcnt_2d <= sch1_wvcnt_1d;
            sch1_wvcnt_3d <= sch1_wvcnt_2d;
            sch2_wvcnt_1d <= ich2_wvcnt;
            sch2_wvcnt_2d <= sch2_wvcnt_1d;
            sch2_wvcnt_3d <= sch2_wvcnt_2d;
            sch3_wvcnt_1d <= ich3_wvcnt;
            sch3_wvcnt_2d <= sch3_wvcnt_1d;
            sch3_wvcnt_3d <= sch3_wvcnt_2d;
            sch4_wvcnt_1d <= ich4_wvcnt;
            sch4_wvcnt_2d <= sch4_wvcnt_1d;
            sch4_wvcnt_3d <= sch4_wvcnt_2d;

            sconv_hsync_1d <= iconv_hsync;
            sconv_hsync_2d <= sconv_hsync_1d;
            sconv_hsync_3d <= sconv_hsync_2d;
            sconv_vcnt_1d  <= iconv_vcnt;
            sconv_vcnt_2d  <= sconv_vcnt_1d;
            sconv_vcnt_3d  <= sconv_vcnt_2d;
            if sconv_hsync_3d='0' and sconv_hsync_2d='1' then -- rising h edge latch -- mbh 210316
                 sconv_vcnt_4d  <= sconv_vcnt_3d;
            end if;
            
             sd2m_xray_1d <= id2m_xray;
             sd2m_xray_2d <= sd2m_xray_1d;
             sd2m_xray    <= sd2m_xray_2d;
        end if;
    end process;

    -- ###########################
    -- ### write counter fixed ###
   sconv_vcnt_sumw <= x"0" & sch0_wvcnt_3d;
   sconv_vcnt_cutw <=
                      sconv_vcnt_sumw - ireg_height when ireg_height <= sconv_vcnt_sumw else
                         sconv_vcnt_sumw;

    -- ##########################
    -- ### read counter fixed ###
    -- ### for sync with  sconv_vcnt_3d & sddr_ch2_rvcnt. input conv_sync & made ddr_sync.
    -- ### conv_sync faster 2vcnt then ddr_sync
    -- ### cut cnt at height     
    sconv_vcnt_sum <= x"0" & sconv_vcnt_4d + 2;
   sconv_vcnt_cut <= 
                     sconv_vcnt_sum - ireg_height when ireg_height <= sconv_vcnt_sum else
                        sconv_vcnt_sum;

    och0_wtrig <= sch0_wtrig;
    och0_waddr <= sch0_waddr;
    och1_wtrig <= sch1_wtrig;
    och1_waddr <= sch1_waddr;
    och2_wtrig <= sch2_wtrig;
    och2_waddr <= sch2_waddr;
    och3_wtrig <= sch3_wtrig;
    och3_waddr <= sch3_waddr;
    och4_wtrig <= sch4_wtrig;
    och4_waddr <= sch4_waddr;

    och0_rtrig <= sch0_rtrig;
    och0_raddr <= sch0_raddr;
    och0_rvcnt <= sddr_ch0_rvcnt;
    och1_rtrig <= sch1_rtrig;
    och1_raddr <= sch1_raddr;
    och1_rvcnt <= sddr_ch1_rvcnt;
    och2_rtrig <= sch2_rtrig;
    och2_raddr <= sch2_raddr;
    och2_rvcnt <= sddr_ch2_rvcnt;
    och3_rtrig <= sch3_rtrig;
    och3_raddr <= sch3_raddr;
    och3_rvcnt <= sddr_ch3_rvcnt;
    och4_rtrig <= sch4_rtrig;
    och4_raddr <= sch4_raddr;
    och4_rvcnt <= sddr_ch4_rvcnt;

--    ILA_DEBUG : if(SIMULATION = "OFF") generate
--    begin
--      U0_ILA_AXI_SUB_IF : ILA_AXI_SUB_IF
--      port map (
--      clk    => iui_clk,
--      probe0  => sch0_wtrig,
--      probe1  => sch0_waddr,
--      probe2  => sch0_rtrig,
--      probe3  => sch0_raddr,
--      probe4  => sddr_ch0_rvcnt,
--      probe5  => sch0_warea,
--      probe6  => sch0_rarea
--      );
--    end generate;

    ila_debug0 : if(GEN_ILA_axi_sub_if = "ON") generate

    component ila_axi_sub_if_vaddr
        port (
            clk        : in    std_logic;
            probe0    : in    std_logic_vector(1 downto 0);
            probe1    : in    std_logic_vector(7 downto 0);
            probe2    : in    std_logic_vector(11 downto 0);
            probe3    : in    std_logic_vector(0 downto 0);
            probe4    : in    tstate_ddr_sub; -- STD_LOGIC_VECTOR(2 DOWNTO 0);
            probe5    : in    std_logic_vector(7 downto 0);
            probe6    : in    std_logic_vector(0 downto 0);
            probe7    : in    std_logic_vector(0 downto 0);
            probe8    : in    std_logic_vector(11 downto 0);
            probe9    : in    std_logic_vector(11 downto 0);
            probe10 : in    std_logic_vector(11 downto 0);
            probe11 : in    std_logic_vector(31 downto 0);
            probe12 : in    std_logic_vector(31 downto 0);
            probe13 : in    std_logic_vector(31 downto 0);
            probe14 : in    std_logic_vector(1 downto 0);
            probe15 : in    std_logic_vector(3 downto 0);
            probe16 : in    std_logic_vector(11 downto 0);
            probe17 : in    std_logic_vector(15 downto 0);
            probe18 : in    std_logic_vector(0 downto 0);
            probe19 : in    std_logic_vector(0 downto 0);
            probe20 : in    std_logic_vector(11 downto 0);
            probe21 : in    std_logic_vector(0 downto 0);
            probe22 : in    std_logic_vector(31 downto 0);
            probe23 : in    std_logic_vector(11 downto 0);
            probe24 : in    std_logic_vector(0 downto 0);
            probe25 : in    std_logic_vector(0 downto 0);
            probe26 : in    std_logic_vector(0 downto 0)
            
        );
    end component;
   
    COMPONENT ila_axi_sub_if_d2mavg
    PORT (
        clk : IN STD_LOGIC;
        probe0 : IN STD_LOGIC_VECTOR(0 DOWNTO 0); 
        probe1 : IN STD_LOGIC_VECTOR(31 DOWNTO 0); 
        probe2 : IN STD_LOGIC_VECTOR(31 DOWNTO 0); 
        probe3 : IN tstate_ddr_sub;
        probe4 : IN STD_LOGIC_VECTOR(11 DOWNTO 0); 
        probe5 : IN STD_LOGIC_VECTOR(11 DOWNTO 0);
        probe6 : IN STD_LOGIC_VECTOR(7 DOWNTO 0)
    );
    END COMPONENT  ;

begin
--    u_ila_axi_sub_if_vaddr : ila_axi_sub_if_vaddr
--        port map (
--            clk           => iaxi_clk,
--            probe0       => conv_std_logic_vector(sddr_ch, 2),        --2
--            probe1       => sreg_ddr_ch_en,                            -- 8
--            probe2       => sddr_ch0_wvcnt,                            -- 12 nowhere to vsync rst
--            probe3(0)  => sch0_warea,                                -- 1 top/btm
--            probe4       => state_ddr,                                -- 3
--            probe5       => sddr_ch_en,                                -- 8 hand up
--            probe6(0)  => sch0_wen_3d,                                -- 1 indata fall edge
--            probe7(0)  => sch0_wtrig,                                -- 1 write clear signal
--            probe8       => sddr_wlen,                                -- 12 h length
--            probe9       => sddr_waddr,                                -- 12 count to sddr_wlen
--            probe10    => sddr_ch0_waddr,                            -- 12 conv address from sddr_waddr
--            probe11    => sch0_waddr_top,                            -- 32
--            probe12    => sch0_waddr_bot,                            -- 32
--            probe13    => sch0_waddr,                                -- 32 -- same with waddr_bot
--            probe14    => conv_std_logic_vector(sdual_roic_cnt, 2), -- 2?
--            probe15    => debugnum,                                    -- 4
--            probe16    => sch0_wvcnt_3d,                            -- 12
--            probe17    => sch0_wdata(15 downto 0),                    -- 12
--            probe18(0) => iconv_rlast,                                -- 1
--            probe19(0) => iconv_hsync,                                -- 1
--            probe20    => iconv_vcnt,                                -- 12
--            probe21(0) => sch0_rtrig,                                -- 1
--            probe22    => sch0_raddr,                                -- 32
--            probe23    => sddr_ch0_rvcnt,                            -- 12
--            probe24(0) => iaxi_wready,                                -- 1
--            probe25(0) => sch1_wtrig,                               -- 1
--            probe26(0) => stimeoutindi -- sch2_wtrig                                -- 1    
--        );

        u_ila_axi_sub_if_d2mavg : ila_axi_sub_if_d2mavg
        PORT MAP (
            clk       => iaxi_clk,
            probe0(0) => id2m_xray,       -- 1
            probe1    => sch3_base_waddr, -- 32
            probe2    => sch3_waddr,      -- 32
            probe3    => state_ddr,          -- 3 
            probe4    => sddr_ch3_wvcnt,  -- 12
            probe5    => ich3_wvcnt,   -- 12
            probe6    => sddr_ch_en(8-1 downto 0) -- 8 
        );

end generate ila_debug0;

end architecture behavioral;
