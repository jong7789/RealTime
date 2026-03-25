library IEEE;
    use IEEE.STD_LOGIC_1164.ALL;

ENTITY Rxaui_Wrapper IS
    PORT (
        reset                : IN  STD_LOGIC;
        dclk                 : IN  STD_LOGIC;
        clk156_out           : OUT STD_LOGIC;
        clk156_lock          : OUT STD_LOGIC;
        refclk_out           : OUT STD_LOGIC;
        refclk_p             : IN  STD_LOGIC;
        refclk_n             : IN  STD_LOGIC;
        qplloutclk_out       : OUT STD_LOGIC;
        qplllock_out         : OUT STD_LOGIC;
        qplloutrefclk_out    : OUT STD_LOGIC;
        xgmii_txd            : IN  STD_LOGIC_VECTOR(63 DOWNTO 0);
        xgmii_txc            : IN  STD_LOGIC_VECTOR(7 DOWNTO 0);
        xgmii_rxd            : OUT STD_LOGIC_VECTOR(63 DOWNTO 0);
        xgmii_rxc            : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
        rxaui_tx_l0_p        : OUT STD_LOGIC;
        rxaui_tx_l0_n        : OUT STD_LOGIC;
        rxaui_tx_l1_p        : OUT STD_LOGIC;
        rxaui_tx_l1_n        : OUT STD_LOGIC;
        rxaui_rx_l0_p        : IN  STD_LOGIC;
        rxaui_rx_l0_n        : IN  STD_LOGIC;
        rxaui_rx_l1_p        : IN  STD_LOGIC;
        rxaui_rx_l1_n        : IN  STD_LOGIC;
        signal_detect        : IN  STD_LOGIC_VECTOR(1 DOWNTO 0);
        debug                : OUT STD_LOGIC_VECTOR(5 DOWNTO 0);
        configuration_vector : IN  STD_LOGIC_VECTOR(6 DOWNTO 0);
        status_vector        : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
    );
END ENTITY Rxaui_Wrapper;

ARCHITECTURE Behavioral OF Rxaui_Wrapper IS

    -- Component instantiation for rxaui_0
    COMPONENT rxaui_0
        PORT (
            reset                : IN  STD_LOGIC;
            dclk                 : IN  STD_LOGIC;
            clk156_out           : OUT STD_LOGIC;
            clk156_lock          : OUT STD_LOGIC;
            refclk_out           : OUT STD_LOGIC;
            refclk_p             : IN  STD_LOGIC;
            refclk_n             : IN  STD_LOGIC;
            qplloutclk_out       : OUT STD_LOGIC;
            qplllock_out         : OUT STD_LOGIC;
            qplloutrefclk_out    : OUT STD_LOGIC;
            xgmii_txd            : IN  STD_LOGIC_VECTOR(63 DOWNTO 0);
            xgmii_txc            : IN  STD_LOGIC_VECTOR(7 DOWNTO 0);
            xgmii_rxd            : OUT STD_LOGIC_VECTOR(63 DOWNTO 0);
            xgmii_rxc            : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
            rxaui_tx_l0_p        : OUT STD_LOGIC;
            rxaui_tx_l0_n        : OUT STD_LOGIC;
            rxaui_tx_l1_p        : OUT STD_LOGIC;
            rxaui_tx_l1_n        : OUT STD_LOGIC;
            rxaui_rx_l0_p        : IN  STD_LOGIC;
            rxaui_rx_l0_n        : IN  STD_LOGIC;
            rxaui_rx_l1_p        : IN  STD_LOGIC;
            rxaui_rx_l1_n        : IN  STD_LOGIC;
            signal_detect        : IN  STD_LOGIC_VECTOR(1 DOWNTO 0);
            debug                : OUT STD_LOGIC_VECTOR(5 DOWNTO 0);
            configuration_vector : IN  STD_LOGIC_VECTOR(6 DOWNTO 0);
            status_vector        : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
        );
    END COMPONENT;

BEGIN

    -- Instantiate the rxaui_0 component
    U1: rxaui_0
        PORT MAP (
            reset                => reset,
            dclk                 => dclk,
            clk156_out           => clk156_out,
            clk156_lock          => clk156_lock,
            refclk_out           => refclk_out,
            refclk_p             => refclk_p,
            refclk_n             => refclk_n,
            qplloutclk_out       => qplloutclk_out,
            qplllock_out         => qplllock_out,
            qplloutrefclk_out    => qplloutrefclk_out,
            xgmii_txd            => xgmii_txd,
            xgmii_txc            => xgmii_txc,
            xgmii_rxd            => xgmii_rxd,
            xgmii_rxc            => xgmii_rxc,
            rxaui_tx_l0_p        => rxaui_tx_l0_p,
            rxaui_tx_l0_n        => rxaui_tx_l0_n,
            rxaui_tx_l1_p        => rxaui_tx_l1_p,
            rxaui_tx_l1_n        => rxaui_tx_l1_n,
            rxaui_rx_l0_p        => rxaui_rx_l0_p,
            rxaui_rx_l0_n        => rxaui_rx_l0_n,
            rxaui_rx_l1_p        => rxaui_rx_l1_p,
            rxaui_rx_l1_n        => rxaui_rx_l1_n,
            signal_detect        => signal_detect,
            debug                => debug,
            configuration_vector => configuration_vector,
            status_vector        => status_vector
        );

END ARCHITECTURE Behavioral;
