library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;

use WORK.TOP_HEADER.ALL;

entity TB_TOP is
end TB_TOP;
    
architecture Behavioral of TB_TOP is

    component EXTREAM_R
    generic ( GNR_MODEL : string  := "EXT1616R" );
    port (
        SYSTEM_CLK_P        : in    std_logic;
        SYSTEM_CLK_N        : in    std_logic;

        ROIC_DCLK_P         : in    std_logic_vector(ROIC_DCLK_NUM(MODEL)-1 downto 0);
        ROIC_DCLK_N         : in    std_logic_vector(ROIC_DCLK_NUM(MODEL)-1 downto 0);
        ROIC_FCLK_P         : in    std_logic_vector(ROIC_FCLK_NUM(MODEL)-1 downto 0);
        ROIC_FCLK_N         : in    std_logic_vector(ROIC_FCLK_NUM(MODEL)-1 downto 0);
        ROIC_DOUT_P         : in    std_logic_vector(ROIC_NUM     (MODEL)-1 downto 0);
        ROIC_DOUT_N         : in    std_logic_vector(ROIC_NUM     (MODEL)-1 downto 0);
        

        TEMP_SCL            : out   std_logic;                        
        TEMP_SDA            : inout std_logic;                        
        EEPROM_SCL          : out   std_logic;
        EEPROM_SDA          : inout std_logic;


        GATE_SHIFT_CLK      : out std_logic;
        GATE_SHIFT_CLK1L    : out std_logic; -- 210127 added
        GATE_SHIFT_CLK2L    : out std_logic;
        GATE_SHIFT_CLK1R    : out std_logic;
        GATE_SHIFT_CLK2R    : out std_logic;
        GATE_START_PULSE1   : out std_logic_vector(GATE_NUM (GNR_MODEL)-1 downto 0);
        GATE_START_PULSE2   : out std_logic_vector(GATE_NUM2(GNR_MODEL)-1 downto 0);
        GATE_OUT_EN1        : out std_logic;
        GATE_OUT_EN2        : out std_logic;
        GATE_OUT_EN1L       : out std_logic; -- 210127 added
        GATE_OUT_EN2L       : out std_logic;
        GATE_OUT_EN1R       : out std_logic;
        GATE_OUT_EN2R       : out std_logic;
        GATE_ALL_OUT        : out std_logic;
        GATE_ALL_OUT_R      : out std_logic;
        GATE_CONFIG         : out std_logic_vector(GATE_CONFIG_NUM(GNR_MODEL)-1 downto 0);
        GATE_VGH_RST        : out std_logic;

        STATUS_LED          : out   std_logic_vector(1 downto 0);

    --# DAC_LDAC_N          : out   std_logic;
    --# DAC_CS_N            : out   std_logic;
    --# DAC_SCLK            : out   std_logic;
    --# DAC_SDI             : out   std_logic;
    --# DAC_SDO             : out   std_logic;
    
        PWR_EN              : out   std_logic_vector(PWR_NUM(MODEL)-1 downto 0);

        EXP_IN              : in    std_logic; -- mbh 210511 1616 v0.3
        EXT_IN              : in    std_logic;
        EXT_OUT             : out   std_logic;
        
        F_ROIC_MCLK         : out   std_logic_vector(ROIC_MCLK_NUM     (GNR_MODEL)-1 downto 0);
        F_ROIC_SYNC         : out   std_logic_vector(ROIC_DUAL_BY_MODEL(GNR_MODEL)-1 downto 0);
        F_ROIC_TP_SEL       : out   std_logic_vector(ROIC_DUAL_BY_MODEL(GNR_MODEL)-1 downto 0);
        F_ROIC_SCLK         : out   std_logic_vector(ROIC_SCLK_NUM     (GNR_MODEL)-1 downto 0);
        F_ROIC_CS           : out   std_logic_vector(ROIC_DUAL_BY_MODEL(GNR_MODEL)-1 downto 0);
        F_ROIC_SDI          : out   std_logic_vector(ROIC_DUAL_BY_MODEL(GNR_MODEL)-1 downto 0);
        F_ROIC_SDO          : in    std_logic_vector(ROIC_SDI_NUM      (GNR_MODEL)-1 downto 0);

        F_GPIO1             : inout std_logic;
        F_GPIO2             : inout std_logic;
        F_GPIO3             : inout std_logic;
        F_GPIO4             : inout std_logic;

        tb_alignreq         : in    std_logic;
        tb_aligndone        : out   std_logic;

        UART_RX             : in    std_logic;
        UART_TX             : out   std_logic;

        FLASH_FCS           : inout std_logic;
        FLASH_D             : inout std_logic_vector(3 downto 0);
        
        DDR3_RESET_N        : out   std_logic;
        DDR3_CK_P           : out   std_logic_vector( 0 downto 0);
        DDR3_CK_N           : out   std_logic_vector( 0 downto 0);
        DDR3_CKE            : out   std_logic_vector( 0 downto 0);
        DDR3_CS_N           : out   std_logic_vector( 0 downto 0);
        DDR3_ODT            : out   std_logic_vector( 0 downto 0);
        DDR3_RAS_N          : out   std_logic;
        DDR3_CAS_N          : out   std_logic;
        DDR3_WE_N           : out   std_logic;
        DDR3_BA             : out   std_logic_vector( 2 downto 0);
        DDR3_ADDR           : out   std_logic_vector(14 downto 0);
        DDR3_DM             : out   std_logic_vector( 3 downto 0);
        DDR3_DQS_P          : inout std_logic_vector( 3 downto 0);
        DDR3_DQS_N          : inout std_logic_vector( 3 downto 0);
        DDR3_DQ             : inout std_logic_vector(31 downto 0);
        
        PHY_SIP             : out   std_logic_vector(1 downto 0);
        PHY_SIN             : out   std_logic_vector(1 downto 0);
        PHY_SOP             : in    std_logic_vector(1 downto 0);
        PHY_SON             : in    std_logic_vector(1 downto 0);
        PHY_CLK_P           : in    std_logic;
        PHY_CLK_N           : in    std_logic;
        
        PHY_RESET_N         : out   std_logic;                        
        PHY_MDC             : out   std_logic;
        PHY_MDIO            : inout std_logic
    );
    end component;

    component SIM_AFE2256 is
    port (
        iroic_mclk          : in  std_logic;
    
        iroic_sync          : in  std_logic;
        iroic_tp_sel        : in  std_logic;
        ialign_done         : in  std_logic;
    
        oroic_data          : out std_logic_vector(ROIC_NUM(MODEL)-1 downto 0);
        oroic_dclk          : out std_logic_vector(ROIC_DCLK_NUM(MODEL)-1 downto 0);
        oroic_fclk          : out std_logic_vector(ROIC_FCLK_NUM(MODEL)-1 downto 0)
    );
    end component;

    signal tbclk_200m            : std_logic;
    constant period_200m        : time := 5.000 ns;
--    signal tbclk_240m            : std_logic;
--    constant period_240m        : time := 4.166 ns;

    signal tbext_in                : std_logic;

    signal sroic_data            : std_logic_vector(ROIC_NUM(MODEL)-1 downto 0);        
    signal sroic_dclk            : std_logic_vector(ROIC_DCLK_NUM(MODEL)-1 downto 0);
    signal sroic_fclk            : std_logic_vector(ROIC_FCLK_NUM(MODEL)-1 downto 0);
    signal sroic_sync            : std_logic_vector(ROIC_DUAL-1 downto 0);
    signal sroic_tp_sel            : std_logic_vector(ROIC_DUAL-1 downto 0);
    signal F_ROIC_MCLK          : std_logic_vector(ROIC_MCLK_NUM(MODEL)-1 downto 0);
    
    signal tb_alignreq           : std_logic;
    signal tb_aligndone         : std_logic;

begin

    TB_CLK_200M_GEN : process
    begin
        tbclk_200m    <= '0';        wait for period_200m / 2;
        tbclk_200m    <= '1';        wait for period_200m / 2;
    end process;

--    TB_CLK_240M_GEN : process
--    begin
--        tbclk_240m    <= '0';        wait for period_240m / 2;
--        tbclk_240m    <= '1';        wait for period_240m / 2;
--    end process;

    TB_EXT_IN_GEN : process
    begin
        tbext_in    <= '0';        wait for 20us;

        -- Normal 
        tbext_in    <= '1';        wait for 20us;        -- EWT
        tbext_in    <= '0';        wait for 250us;        -- SCAN
        tbext_in    <= '1';        wait for 20us;        -- EWT
        tbext_in    <= '0';        wait for 250us;        -- SCAN

        -- Over Trigger
        tbext_in    <= '1';        wait for 20us;        -- EWT
        tbext_in    <= '0';        wait for 150us;        -- SCAN
        tbext_in    <= '1';        wait for 20us;        -- EWT
        tbext_in    <= '0';        wait for 150us;        -- SCAN
        tbext_in    <= '1';        wait for 20us;        -- EWT
        tbext_in    <= '0';        wait for 150us;        -- SCAN

        -- Normal 
        tbext_in    <= '1';        wait for 20us;        -- EWT
        tbext_in    <= '0';        wait for 250us;        -- SCAN
        tbext_in    <= '1';        wait for 20us;        -- EWT
        tbext_in    <= '0';        wait for 250us;        -- SCAN
    end process;

    U0_EXTREAM_R: EXTREAM_R
    port map (
        ROIC_DCLK_P            => sroic_dclk,
        ROIC_DCLK_N            => not sroic_dclk,
        ROIC_FCLK_P            => sroic_fclk,
        ROIC_FCLK_N            => not sroic_fclk,
        ROIC_DOUT_P            => sroic_data,
        ROIC_DOUT_N            => not sroic_data,
        
        FLASH_FCS           => open,
        FLASH_D                => open,

        TEMP_SCL            => open,
        TEMP_SDA            => open,
        EEPROM_SCL             => open,
        EEPROM_SDA             => open,

        UART_RX                => '0',
        UART_TX                => open,

        GATE_SHIFT_CLK        => open,
        GATE_START_PULSE1    => open,
        GATE_START_PULSE2    => open,
        GATE_OUT_EN1        => open,
        GATE_OUT_EN2        => open,
        GATE_ALL_OUT        => open,
        GATE_CONFIG            => open,
        GATE_VGH_RST        => open,

        STATUS_LED            => open,

        --# DAC_LDAC_N            => open,
        --# DAC_CS_N            => open,
        --# DAC_SCLK            => open,
        --# DAC_SDI                => open,
        --# DAC_SDO                => open,
        
        PWR_EN                => open,

        EXP_IN                => '0',
        EXT_IN                => tbext_in,
        EXT_OUT                => open,
        
        PHY_RESET_N            => open,
        PHY_MDC                => open,
        PHY_MDIO            => open,
        
        DDR3_RESET_N        => open,
        DDR3_CK_P           => open,
        DDR3_CK_N           => open,
        DDR3_CKE            => open,
        DDR3_CS_N           => open,
        DDR3_ODT            => open,
        DDR3_RAS_N          => open,
        DDR3_CAS_N          => open,
        DDR3_WE_N           => open,
        DDR3_BA             => open,
        DDR3_ADDR           => open,
        DDR3_DM             => open,
        DDR3_DQS_P          => open,
        DDR3_DQS_N          => open,
        DDR3_DQ             => open,
        SYSTEM_CLK_P        => tbclk_200m,
        SYSTEM_CLK_N        => not tbclk_200m,
        
        F_ROIC_MCLK            => F_ROIC_MCLK,
        F_ROIC_SYNC            => sroic_sync,
        F_ROIC_TP_SEL        => sroic_tp_sel,
        F_ROIC_SCLK            => open,
        F_ROIC_CS            => open,
        F_ROIC_SDI            => open,
        F_ROIC_SDO            => (others => '1'),
        
        PHY_SIP                => open,
        PHY_SIN                => open,
        PHY_SOP                => (others => '1'),
        PHY_SON                => (others => '0'),
        PHY_CLK_P            => '1',
        PHY_CLK_N            => '0',
        
        F_GPIO1 => open, 
        F_GPIO2 => open, 
        F_GPIO3 => open,
        F_GPIO4 => open,
        
        tb_alignreq         => tb_alignreq,
        tb_aligndone        => tb_aligndone
    );

tb_alignreq <= not tb_aligndone;

    U0_SIM_AFE2256 : SIM_AFE2256 
    port map (
        iroic_mclk            => F_ROIC_MCLK(0),        -- 20M Input -> 240M Output (= 240M)
    
        iroic_sync            => sroic_sync(0),
        iroic_tp_sel        => sroic_tp_sel(0),
        ialign_done            => tb_aligndone,

        oroic_data            => sroic_data,
        oroic_dclk            => sroic_dclk,
        oroic_fclk            => sroic_fclk
    );

end Behavioral;
