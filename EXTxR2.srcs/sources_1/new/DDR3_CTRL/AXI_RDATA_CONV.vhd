library IEEE;
    use IEEE.STD_LOGIC_1164.ALL;
    use IEEE.STD_LOGIC_ARITH.ALL;
    use IEEE.STD_LOGIC_UNSIGNED.ALL;

    use WORK.TOP_HEADER.ALL;

entity AXI_RDATA_CONV is
generic (
    DATA_DEPTH : integer
);
port(
    iwr_clk  : in  std_logic;
    iwr_rstn : in  std_logic;

    iwr_en   : in  std_logic;
    iwr_addr : in  std_logic_vector(11 downto 0);
    iwr_vcnt : in  std_logic_vector(11 downto 0);
    iwr_data : in  std_logic_vector(511 downto 0);

    ird_clk  : in  std_logic;
    ird_rstn : in  std_logic;

    ird_en   : in  std_logic;
    ird_addr : in  std_logic_vector(11 downto 0);
    ird_vcnt : in  std_logic_vector(11 downto 0);
    ord_data : out std_logic_vector(DATA_DEPTH - 1 downto 0)
);
end entity AXI_RDATA_CONV;

architecture behavioral of AXI_RDATA_CONV is

    component DPRAM_512x768_128x3072 is
    port(
        clka  : in  std_logic;
        ena   : in  std_logic;
        wea   : in  std_logic;
        addra : in  std_logic_vector(9 downto 0);
        dina  : in  std_logic_vector(511 downto 0);
        clkb  : in  std_logic;
        enb   : in  std_logic;
        addrb : in  std_logic_vector(11 downto 0);
        doutb : out std_logic_vector(127 downto 0)
    );
    end component;

    component DPRAM_512x960_128x3840 is
    port(
        clka  : in  std_logic;
        ena   : in  std_logic;
        wea   : in  std_logic;
        addra : in  std_logic_vector(9 downto 0);
        dina  : in  std_logic_vector(511 downto 0);
        clkb  : in  std_logic;
        enb   : in  std_logic;
        addrb : in  std_logic_vector(11 downto 0);
        doutb : out std_logic_vector(127 downto 0)
    );
    end component;

    component DPRAM_512x480_64x3840 is
    port(
        clka  : in  std_logic;
        ena   : in  std_logic;
        wea   : in  std_logic;
        addra : in  std_logic_vector(8 downto 0);
        dina  : in  std_logic_vector(511 downto 0);
        clkb  : in  std_logic;
        enb   : in  std_logic;
        addrb : in  std_logic_vector(11 downto 0);
        doutb : out std_logic_vector(63 downto 0)
    );
    end component;

    component DPRAM_512x192_32x3072 is
    port(
        clka  : in  std_logic;
        ena   : in  std_logic;
        wea   : in  std_logic;
        addra : in  std_logic_vector(7 downto 0);
        dina  : in  std_logic_vector(511 downto 0);
        clkb  : in  std_logic;
        enb   : in  std_logic;
        addrb : in  std_logic_vector(11 downto 0);
        doutb : out std_logic_vector(31 downto 0)
    );
    end component;

    component DPRAM_512x240_32x3840 is
    port(
        clka  : in  std_logic;
        ena   : in  std_logic;
        wea   : in  std_logic;
        addra : in  std_logic_vector(7 downto 0);
        dina  : in  std_logic_vector(511 downto 0);
        clkb  : in  std_logic;
        enb   : in  std_logic;
        addrb : in  std_logic_vector(11 downto 0);
        doutb : out std_logic_vector(31 downto 0)
    );
    end component;

    component DPRAM_512x96_16x3072 is
    port(
        clka  : in  std_logic;
        ena   : in  std_logic;
        wea   : in  std_logic;
        addra : in  std_logic_vector(6 downto 0);
        dina  : in  std_logic_vector(511 downto 0);
        clkb  : in  std_logic;
        enb   : in  std_logic;
        addrb : in  std_logic_vector(11 downto 0);
        doutb : out std_logic_vector(15 downto 0)
    );
    end component;

    component DPRAM_512x120_16x3840 is -- 2430 h size up
    port(
        clka  : in  std_logic;
        ena   : in  std_logic;
        wea   : in  std_logic;                       -- _VECTOR(0 DOWNTO 0);
        addra : in  std_logic_vector(6 downto 0);
        dina  : in  std_logic_vector(511 downto 0);
        clkb  : in  std_logic;
        enb   : in  std_logic;
        addrb : in  std_logic_vector(11 downto 0);
        doutb : out std_logic_vector(15 downto 0)
    );
    end component;

    signal swr_mem_sel    : std_logic;
    signal srd_mem_sel    : std_logic;

    signal swr_en_odd     : std_logic;
    signal swr_addr_odd   : std_logic_vector(11 downto 0);
    signal swr_data_odd   : std_logic_vector(511 downto 0);
    signal srd_en_odd     : std_logic;
    signal srd_addr_odd   : std_logic_vector(11 downto 0);
    signal srd_data_odd   : std_logic_vector(DATA_DEPTH - 1 downto 0);

    signal swr_en_even    : std_logic;
    signal swr_addr_even  : std_logic_vector(11 downto 0);
    signal swr_data_even  : std_logic_vector(511 downto 0);
    signal srd_en_even    : std_logic;
    signal srd_addr_even  : std_logic_vector(11 downto 0);
    signal srd_data_even  : std_logic_vector(DATA_DEPTH - 1 downto 0);

    signal swr_mem_sel_1d : std_logic;
    signal swr_mem_sel_2d : std_logic;
    signal swr_mem_sel_3d : std_logic;
    signal srd_mem_sel_1d : std_logic;
    signal srd_mem_sel_2d : std_logic;
    signal srd_mem_sel_3d : std_logic;

begin

    --# Write-side memory select delay pipeline
    process(iwr_clk)
    begin
        if (iwr_clk'event and iwr_clk = '1') then
            if (iwr_rstn = '0') then
                swr_mem_sel    <= '0';
                swr_mem_sel_1d <= '0';
                swr_mem_sel_2d <= '0';
                swr_mem_sel_3d <= '0';
            else
                swr_mem_sel    <= iwr_vcnt(0);
                swr_mem_sel_1d <= swr_mem_sel;
                swr_mem_sel_2d <= swr_mem_sel_1d;
                swr_mem_sel_3d <= swr_mem_sel_2d;
            end if;
        end if;
    end process;

    --# Read-side memory select delay pipeline
    process(ird_clk)
    begin
        if (ird_clk'event and ird_clk = '1') then
            if (ird_rstn = '0') then
                srd_mem_sel    <= '0';
                srd_mem_sel_1d <= '0';
                srd_mem_sel_2d <= '0';
                srd_mem_sel_3d <= '0';
            else
                srd_mem_sel    <= ird_vcnt(0);
                srd_mem_sel_1d <= srd_mem_sel;
                srd_mem_sel_2d <= srd_mem_sel_1d;
                srd_mem_sel_3d <= srd_mem_sel_2d;
            end if;
        end if;
    end process;

    swr_en_odd    <= iwr_en   when swr_mem_sel_3d = '0' else '0';
    swr_addr_odd  <= iwr_addr when swr_mem_sel_3d = '0' else (others => '0');
    swr_data_odd  <= iwr_data when swr_mem_sel_3d = '0' else (others => '0');

    swr_en_even   <= iwr_en   when swr_mem_sel_3d = '1' else '0';
    swr_addr_even <= iwr_addr when swr_mem_sel_3d = '1' else (others => '0');
    swr_data_even <= iwr_data when swr_mem_sel_3d = '1' else (others => '0');

    srd_en_odd    <= ird_en   when srd_mem_sel_3d = '0' else '0';
    srd_addr_odd  <= ird_addr when srd_mem_sel_3d = '0' else (others => '0');

    srd_en_even   <= ird_en   when srd_mem_sel_3d = '1' else '0';
    srd_addr_even <= ird_addr when srd_mem_sel_3d = '1' else (others => '0');

    WIDTH_128_GEN : if (DATA_DEPTH = 128) generate
    begin
        ODD_DPRAM_512x960_128x3840 : DPRAM_512x960_128x3840
        port map(
            clka  => iwr_clk,
            wea   => swr_en_odd,
            ena   => '1',
            addra => swr_addr_odd(9 downto 0),
            dina  => swr_data_odd,
            clkb  => ird_clk,
            enb   => '1', -- no need mbh 210315 -- srd_en_odd,
            addrb => srd_addr_odd,
            doutb => srd_data_odd
        );
        EVEN_DPRAM_512x960_128x3840 : DPRAM_512x960_128x3840
        port map(
            clka  => iwr_clk,
            wea   => swr_en_even,
            ena   => '1',
            addra => swr_addr_even(9 downto 0),
            dina  => swr_data_even,
            clkb  => ird_clk,
            enb   => '1', -- srd_en_even,
            addrb => srd_addr_even,
            doutb => srd_data_even
        );
    end generate;

    WIDTH_64_GEN : if (DATA_DEPTH = 64) generate
    begin
        ODD_DPRAM_512x480_64x3840 : DPRAM_512x480_64x3840
        port map(
            clka  => iwr_clk,
            wea   => '1',
            ena   => swr_en_odd,
            addra => swr_addr_odd(8 downto 0),
            dina  => swr_data_odd,
            clkb  => ird_clk,
            enb   => srd_en_odd,
            addrb => srd_addr_odd,
            doutb => srd_data_odd
        );
        EVEN_DPRAM_512x480_64x3840 : DPRAM_512x480_64x3840
        port map(
            clka  => iwr_clk,
            wea   => '1',
            ena   => swr_en_even,
            addra => swr_addr_even(8 downto 0),
            dina  => swr_data_even,
            clkb  => ird_clk,
            enb   => srd_en_even,
            addrb => srd_addr_even,
            doutb => srd_data_even
        );
    end generate;

    WIDTH_32_GEN : if (DATA_DEPTH = 32) generate
    begin
        ODD_DPRAM_512x240_32x3840 : DPRAM_512x240_32x3840
        port map(
            clka  => iwr_clk,
            wea   => '1',
            ena   => swr_en_odd,
            addra => swr_addr_odd(7 downto 0),
            dina  => swr_data_odd,
            clkb  => ird_clk,
            enb   => srd_en_odd,
            addrb => srd_addr_odd,
            doutb => srd_data_odd
        );
        EVEN_DPRAM_512x240_32x3840 : DPRAM_512x240_32x3840
        port map(
            clka  => iwr_clk,
            wea   => '1',
            ena   => swr_en_even,
            addra => swr_addr_even(7 downto 0),
            dina  => swr_data_even,
            clkb  => ird_clk,
            enb   => srd_en_even,
            addrb => srd_addr_even,
            doutb => srd_data_even
        );
    end generate;

    WIDTH_16_GEN : if (DATA_DEPTH = 16) generate
    begin
        ODD_DPRAM_512x120_16x3840 : DPRAM_512x120_16x3840
        port map(
            clka  => iwr_clk,
            wea   => '1',
            ena   => swr_en_odd,
            addra => swr_addr_odd(6 downto 0),
            dina  => swr_data_odd,
            clkb  => ird_clk,
            enb   => srd_en_odd,
            addrb => srd_addr_odd,
            doutb => srd_data_odd
        );
        EVEN_DPRAM_512x120_16x3840 : DPRAM_512x120_16x3840
        port map(
            clka  => iwr_clk,
            wea   => '1',
            ena   => swr_en_even,
            addra => swr_addr_even(6 downto 0),
            dina  => swr_data_even,
            clkb  => ird_clk,
            enb   => srd_en_even,
            addrb => srd_addr_even,
            doutb => srd_data_even
        );
    end generate;

    ord_data <= srd_data_odd when srd_mem_sel_3d = '0' else
                srd_data_even;

end architecture behavioral;
