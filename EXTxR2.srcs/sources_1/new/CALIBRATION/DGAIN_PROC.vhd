library IEEE;
    use IEEE.STD_LOGIC_1164.ALL;
    use IEEE.STD_LOGIC_UNSIGNED.ALL;
    use IEEE.STD_LOGIC_ARITH.ALL;

    use WORK.TOP_HEADER.ALL;

entity DGAIN_PROC is
port (
    idata_clk  : in  std_logic;
    idata_rstn : in  std_logic;

    ireg_dgain : in  std_logic_vector(10 downto 0);

    ihsync     : in  std_logic;
    ivsync     : in  std_logic;
    ihcnt      : in  std_logic_vector(11 downto 0);
    ivcnt      : in  std_logic_vector(11 downto 0);
    idata      : in  std_logic_vector(23 downto 0);

    ohsync     : out std_logic;
    ovsync     : out std_logic;
    ohcnt      : out std_logic_vector(11 downto 0);
    ovcnt      : out std_logic_vector(11 downto 0);
    odata      : out std_logic_vector(15 downto 0)
);
end DGAIN_PROC;

architecture Behavioral of DGAIN_PROC is

    component ROM_20x1600
    port (
        clka  : in  std_logic;
        ena   : in  std_logic;
        addra : in  std_logic_vector(10 downto 0);
        douta : out std_logic_vector(19 downto 0)
    );
    end component;

    component MULTI_24x20
    port (
        clk : in  std_logic;
        ce  : in  std_logic;
        a   : in  std_logic_vector(23 downto 0);
        b   : in  std_logic_vector(19 downto 0);
        p   : out std_logic_vector(43 downto 0)
    );
    end component;

    signal sreg_dgain    : std_logic_vector(10 downto 0);
    signal sreg_dgain_1d : std_logic_vector(10 downto 0);
    signal sreg_dgain_2d : std_logic_vector(10 downto 0);
    signal sreg_dgain_3d : std_logic_vector(10 downto 0);

    signal sdgain_conv   : std_logic_vector(19 downto 0);
    signal smulti_data   : std_logic_vector(43 downto 0);

    signal shsync_out    : std_logic;
    signal svsync_out    : std_logic;
    signal shcnt_out     : std_logic_vector(11 downto 0);
    signal svcnt_out     : std_logic_vector(11 downto 0);
    signal sdata_out     : std_logic_vector(15 downto 0);

    signal shsync_1d     : std_logic;
    signal shsync_2d     : std_logic;
    signal shsync_3d     : std_logic;
    signal shsync_4d     : std_logic;
    signal shsync_5d     : std_logic;
    signal svsync_1d     : std_logic;
    signal svsync_2d     : std_logic;
    signal svsync_3d     : std_logic;
    signal svsync_4d     : std_logic;
    signal svsync_5d     : std_logic;
    signal shcnt_1d      : std_logic_vector(11 downto 0);
    signal shcnt_2d      : std_logic_vector(11 downto 0);
    signal shcnt_3d      : std_logic_vector(11 downto 0);
    signal shcnt_4d      : std_logic_vector(11 downto 0);
    signal shcnt_5d      : std_logic_vector(11 downto 0);
    signal svcnt_1d      : std_logic_vector(11 downto 0);
    signal svcnt_2d      : std_logic_vector(11 downto 0);
    signal svcnt_3d      : std_logic_vector(11 downto 0);
    signal svcnt_4d      : std_logic_vector(11 downto 0);
    signal svcnt_5d      : std_logic_vector(11 downto 0);

begin

    U0_ROM_20x1600 : ROM_20x1600
    port map (
        clka  => idata_clk,
        ena   => idata_rstn,
        addra => sreg_dgain_3d,
        douta => sdgain_conv
    );

    U0_MULTI_24x20 : MULTI_24x20 -- 5 Delay
    port map (
        clk => idata_clk,
        ce  => idata_rstn,
        a   => idata,
        b   => sdgain_conv,
        p   => smulti_data
    );

    --# Output register: latch multiplied data with saturation clamp
    process(idata_clk)
    begin
        if (idata_clk'event and idata_clk = '1') then
            if (idata_rstn = '0') then
                shsync_out <= '0';
                svsync_out <= '0';
                shcnt_out  <= (others => '0');
                svcnt_out  <= (others => '0');
                sdata_out  <= (others => '0');
            else
                shsync_out <= shsync_5d;
                svsync_out <= svsync_5d;
                shcnt_out  <= shcnt_5d;
                svcnt_out  <= svcnt_5d;

                if (smulti_data(43 downto 32) > 0) then
                    sdata_out <= x"FFFF";
                else
                    sdata_out <= smulti_data(31 downto 16);
                end if;
            end if;
        end if;
    end process;

    ohsync <= shsync_out;
    ovsync <= svsync_out;
    ohcnt  <= shcnt_out;
    ovcnt  <= svcnt_out;
    odata  <= sdata_out;

    --# Delay pipeline: register dgain and sync/count signals through 5-stage delay
    process(idata_clk)
    begin
        if (idata_clk'event and idata_clk = '1') then
            if (idata_rstn = '0') then
                sreg_dgain    <= (others => '0');
                sreg_dgain_1d <= (others => '0');
                sreg_dgain_2d <= (others => '0');
                sreg_dgain_3d <= (others => '0');
                shsync_1d     <= '0';
                shsync_2d     <= '0';
                shsync_3d     <= '0';
                shsync_4d     <= '0';
                shsync_5d     <= '0';
                svsync_1d     <= '0';
                svsync_2d     <= '0';
                svsync_3d     <= '0';
                svsync_4d     <= '0';
                svsync_5d     <= '0';
                shcnt_1d      <= (others => '0');
                shcnt_2d      <= (others => '0');
                shcnt_3d      <= (others => '0');
                shcnt_4d      <= (others => '0');
                shcnt_5d      <= (others => '0');
                svcnt_1d      <= (others => '0');
                svcnt_2d      <= (others => '0');
                svcnt_3d      <= (others => '0');
                svcnt_4d      <= (others => '0');
                svcnt_5d      <= (others => '0');
            else
                sreg_dgain    <= ireg_dgain;
                sreg_dgain_1d <= sreg_dgain;
                sreg_dgain_2d <= sreg_dgain_1d;
                sreg_dgain_3d <= sreg_dgain_2d;
                shsync_1d     <= ihsync;
                shsync_2d     <= shsync_1d;
                shsync_3d     <= shsync_2d;
                shsync_4d     <= shsync_3d;
                shsync_5d     <= shsync_4d;
                svsync_1d     <= ivsync;
                svsync_2d     <= svsync_1d;
                svsync_3d     <= svsync_2d;
                svsync_4d     <= svsync_3d;
                svsync_5d     <= svsync_4d;
                shcnt_1d      <= ihcnt;
                shcnt_2d      <= shcnt_1d;
                shcnt_3d      <= shcnt_2d;
                shcnt_4d      <= shcnt_3d;
                shcnt_5d      <= shcnt_4d;
                svcnt_1d      <= ivcnt;
                svcnt_2d      <= svcnt_1d;
                svcnt_3d      <= svcnt_2d;
                svcnt_4d      <= svcnt_3d;
                svcnt_5d      <= svcnt_4d;
            end if;
        end if;
    end process;

end Behavioral;
