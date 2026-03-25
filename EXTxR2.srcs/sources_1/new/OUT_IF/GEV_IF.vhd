library IEEE;
    use IEEE.STD_LOGIC_1164.ALL;
    use IEEE.STD_LOGIC_ARITH.ALL;
    use IEEE.STD_LOGIC_UNSIGNED.ALL;

    use WORK.TOP_HEADER.ALL;

entity GEV_IF is
    port (
        idata_clk  : in  std_logic;
        idata_rstn : in  std_logic;
        igev_clk   : in  std_logic;
        igev_rstn  : in  std_logic;

        ireg_out_en : in  std_logic;
        ireg_width  : in  std_logic_vector(11 downto 0);
        ireg_height : in  std_logic_vector(11 downto 0);

        ihsync : in  std_logic;
        ivsync : in  std_logic;
        ihcnt  : in  std_logic_vector(11 downto 0);
        ivcnt  : in  std_logic_vector(11 downto 0);
        idata  : in  std_logic_vector(15 downto 0);

        ofb_frame : out std_logic;
        ofb_dv    : out std_logic;
        ofb_data  : out std_logic_vector(63 downto 0);
        ofb_width : out std_logic_vector( 2 downto 0)
    );
end GEV_IF;

architecture Behavioral of GEV_IF is

    component GEV_DATA_CONV is
        port (
            idata_clk  : in  std_logic;
            idata_rstn : in  std_logic;
            igev_clk   : in  std_logic;
            igev_rstn  : in  std_logic;

            ireg_width  : in  std_logic_vector(11 downto 0);
            ireg_height : in  std_logic_vector(11 downto 0);

            ihsync : in  std_logic;
            ivsync : in  std_logic;
            ihcnt  : in  std_logic_vector(11 downto 0);
            ivcnt  : in  std_logic_vector(11 downto 0);
            idata  : in  std_logic_vector(15 downto 0);

            ohsync : out std_logic;
            ovsync : out std_logic;
            ohcnt  : out std_logic_vector(9 downto 0);
            ovcnt  : out std_logic_vector(11 downto 0);
            odata  : out std_logic_vector(63 downto 0)
        );
    end component;

    component GEV_DATA_MAPPING is
        port (
            igev_clk  : in  std_logic;
            igev_rstn : in  std_logic;

            ireg_out_en : in  std_logic;

            ihsync : in  std_logic;
            ivsync : in  std_logic;
            ihcnt  : in  std_logic_vector(9 downto 0);
            ivcnt  : in  std_logic_vector(11 downto 0);
            idata  : in  std_logic_vector(63 downto 0);

            ofb_frame : out std_logic;
            ofb_dv    : out std_logic;
            ofb_data  : out std_logic_vector(63 downto 0);
            ofb_width : out std_logic_vector( 2 downto 0)
        );
    end component;

    signal shsync_gev_dconv : std_logic;
    signal svsync_gev_dconv : std_logic;
    signal shcnt_gev_dconv  : std_logic_vector(9 downto 0);
    signal svcnt_gev_dconv  : std_logic_vector(11 downto 0);
    signal sdata_gev_dconv  : std_logic_vector(63 downto 0);

    component ILA_GEV_IF
        port (
            clk    : in  std_logic;

            probe0 : in  std_logic;
            probe1 : in  std_logic;
            probe2 : in  std_logic_vector(11 downto 0);
            probe3 : in  std_logic_vector(11 downto 0);
            probe4 : in  std_logic_vector(15 downto 0);
            probe5 : in  std_logic;
            probe6 : in  std_logic;
            probe7 : in  std_logic_vector(9 downto 0);
            probe8 : in  std_logic_vector(11 downto 0);
            probe9 : in  std_logic_vector(63 downto 0)
        );
    end component;

begin

    U0_GEV_DATA_CONV : GEV_DATA_CONV
    port map (
        idata_clk  => idata_clk,
        idata_rstn => idata_rstn,
        igev_clk   => igev_clk,
        igev_rstn  => igev_rstn,

        ireg_width  => ireg_width,
        ireg_height => ireg_height,

        ihsync => ihsync,
        ivsync => ivsync,
        ivcnt  => ivcnt,
        ihcnt  => ihcnt,
        idata  => idata,

        ohsync => shsync_gev_dconv,
        ovsync => svsync_gev_dconv,
        ohcnt  => shcnt_gev_dconv,
        ovcnt  => svcnt_gev_dconv,
        odata  => sdata_gev_dconv
    );

    U0_GEV_DATA_MAPPING : GEV_DATA_MAPPING
    port map (
        igev_clk  => igev_clk,
        igev_rstn => igev_rstn,

        ireg_out_en => ireg_out_en,

        ihsync => shsync_gev_dconv,
        ivsync => svsync_gev_dconv,
        ihcnt  => shcnt_gev_dconv,
        ivcnt  => svcnt_gev_dconv,
        idata  => sdata_gev_dconv,

        ofb_frame => ofb_frame,
        ofb_dv    => ofb_dv,
        ofb_data  => ofb_data,
        ofb_width => ofb_width
    );

--  ILA_DEBUG : if(SIMULATION = "OFF") generate
--  begin
--      U0_ILA_GEV_IF : ILA_GEV_IF
--      port map (
--          clk    => idata_clk,
--
--          probe0 => ihsync,
--          probe1 => ivsync,
--          probe2 => ivcnt,
--          probe3 => ihcnt,
--          probe4 => idata,
--          probe5 => shsync_gev_dconv,
--          probe6 => svsync_gev_dconv,
--          probe7 => shcnt_gev_dconv,
--          probe8 => svcnt_gev_dconv,
--          probe9 => sdata_gev_dconv
--      );
--  end generate;

end Behavioral;
