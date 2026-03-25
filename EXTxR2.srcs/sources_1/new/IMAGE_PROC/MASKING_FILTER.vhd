-- 220811mbh
-- divide 8 -> 9

library IEEE;
    use IEEE.STD_LOGIC_1164.ALL;
    use IEEE.STD_LOGIC_UNSIGNED.ALL;
    use IEEE.STD_LOGIC_ARITH.ALL;

    use WORK.TOP_HEADER.ALL;

entity MASKING_FILTER is
port(
    idata_clk  : in  std_logic;
    idata_rstn : in  std_logic;

    idata_arr  : in  std_logic_vector(143 downto 0);
    imask_arr  : in  std_logic_vector(36 downto 0);

    odata      : out std_logic_vector(15 downto 0)
);
end MASKING_FILTER;

architecture Behavioral of MASKING_FILTER is

    component MULTI_16x3
    port (
        clk : in  std_logic;
        ce  : in  std_logic;
        a   : in  std_logic_vector(15 downto 0);
        b   : in  std_logic_vector(2 downto 0);
        p   : out std_logic_vector(18 downto 0)
    );
    end component;

    type tmulti_out is array (0 to 8) of std_logic_vector(18 downto 0);
    signal smulti_out : tmulti_out := (others => (others => '0'));

    signal saddsub    : std_logic_vector(9 downto 0) := (others => '0');

    type tadd_arr is array (0 to 9) of std_logic_vector(22 downto 0);
    signal sadd_arr   : tadd_arr := (others => (others => '0'));
    signal ssub_arr   : tadd_arr := (others => (others => '0'));

    signal sadd       : std_logic_vector(26 downto 0) := (others => '0');
    signal ssub       : std_logic_vector(26 downto 0) := (others => '0');
    signal ssum       : std_logic_vector(26 downto 0) := (others => '0');

    signal saddsub_1d : std_logic_vector(9 downto 0) := (others => '0');
    signal saddsub_2d : std_logic_vector(9 downto 0) := (others => '0');
    signal saddsub_3d : std_logic_vector(9 downto 0) := (others => '0');
    signal saddsub_4d : std_logic_vector(9 downto 0) := (others => '0');
    signal saddsub_5d : std_logic_vector(9 downto 0) := (others => '0');
    signal saddsub_6d : std_logic_vector(9 downto 0) := (others => '0');

    signal sadd_sub   : std_logic_vector(26 downto 0) := (others => '0');
    signal sdivdata   : std_logic_vector(26 downto 0) := (others => '0');

begin

    MULTI_PROC : for i in 0 to 8 generate
        U0_MULTI_16x3 : MULTI_16x3             -- 3 Delay
        port map (
            clk => idata_clk,
            ce  => idata_rstn,
            a   => idata_arr((((i + 1) * 16) - 1) downto (16 * i)),
            b   => imask_arr((((i + 1) * 4) - 2) downto (4 * i)),
            p   => smulti_out(i)
        );
    end generate;

    --# Latch add/sub control bits from mask array
    process(idata_clk)
    begin
        if(idata_clk'event and idata_clk = '1') then
            if(idata_rstn = '0') then
                saddsub <= (others => '0');
            else
                saddsub <= imask_arr(36) & imask_arr(35) & imask_arr(31) & imask_arr(27) & imask_arr(23)
                         & imask_arr(19) & imask_arr(15) & imask_arr(11) & imask_arr(7) & imask_arr(3);
            end if;
        end if;
    end process;

    --# Separate multiplier outputs into add/sub arrays based on control bits
    process(idata_clk)
    begin
        if(idata_clk'event and idata_clk = '1') then
            if(idata_rstn = '0') then
                sadd_arr <= (others => (others => '0'));
                ssub_arr <= (others => (others => '0'));
            else
                for i in 0 to 8 loop
                    if(saddsub_2d(i) = '0') then
                        sadd_arr(i) <= "0000" & smulti_out(i);
                        ssub_arr(i) <= (others => '0');
                    else
                        sadd_arr(i) <= (others => '0');
                        ssub_arr(i) <= "0000" & smulti_out(i);
                    end if;
                end loop;
            end if;
        end if;
    end process;

    --# Sum all add and sub arrays separately
    process(idata_clk)
    begin
        if(idata_clk'event and idata_clk = '1') then
            sadd <= (("0000" & sadd_arr(0))
                   + ("0000" & sadd_arr(1))
                   + ("0000" & sadd_arr(2))
                   + ("0000" & sadd_arr(3))
                   + ("0000" & sadd_arr(4))
                   + ("0000" & sadd_arr(5))
                   + ("0000" & sadd_arr(6))
                   + ("0000" & sadd_arr(7))
                   + ("0000" & sadd_arr(8)));

            ssub <= (("0000" & ssub_arr(0))
                   + ("0000" & ssub_arr(1))
                   + ("0000" & ssub_arr(2))
                   + ("0000" & ssub_arr(3))
                   + ("0000" & ssub_arr(4))
                   + ("0000" & ssub_arr(5))
                   + ("0000" & ssub_arr(6))
                   + ("0000" & ssub_arr(7))
                   + ("0000" & ssub_arr(8)));
        end if;
    end process;

    --# Compute add minus sub with saturation at zero
    process(idata_clk)
    begin
        if(idata_clk'event and idata_clk = '1') then
            if(idata_rstn = '0') then
                sadd_sub <= (others => '0');
            else
                if(ssub > sadd) then
                    sadd_sub <= (others => '0');
                else
                    sadd_sub <= sadd - ssub;
                end if;
            end if;
        end if;
    end process;

    --# Divide by 9 approximation or pass through
    process(idata_clk)
    begin
        if(idata_clk'event and idata_clk = '1') then
            if(idata_rstn = '0') then
                sdivdata <= (others => '0');
            else
                if saddsub_6d(9) = '0' then
                    sdivdata <= sadd_sub;
                else
                    -- 1/9                   = 0.1111..
                    -- 1/16+1/32+1/64+1/1048 = 0.10986328..
                    sdivdata <= "000" & x"00_0000" -- 27bit
                              + sadd_sub(sadd_sub'left downto 4)
                              + sadd_sub(sadd_sub'left downto 5)
                              + sadd_sub(sadd_sub'left downto 6)
                              + sadd_sub(sadd_sub'left downto 10)
                              + sadd_sub(sadd_sub'left downto 11)
                              + sadd_sub(sadd_sub'left downto 12)
                              + sadd_sub(sadd_sub'left downto 16)
                              + sadd_sub(sadd_sub'left downto 17);
                end if;
            end if;
        end if;
    end process;

    --# Saturate result to 16-bit max
    process(idata_clk)
    begin
        if(idata_clk'event and idata_clk = '1') then
            if(idata_rstn = '0') then
                ssum <= (others => '0');
            else
                if(sdivdata > x"FFFF") then
                    ssum(ssum'left downto 16) <= (others => '0');
                    ssum(15 downto 0)         <= x"FFFF";
                else
                    ssum <= sdivdata;
                end if;
            end if;
        end if;
    end process;

    odata <= ssum(16 - 1 downto 0);

    --# Delay chain for add/sub control bits
    process(idata_clk)
    begin
        if(idata_clk'event and idata_clk = '1') then
            if(idata_rstn = '0') then
                saddsub_1d <= (others => '0');
                saddsub_2d <= (others => '0');
                saddsub_3d <= (others => '0');
                saddsub_4d <= (others => '0');
                saddsub_5d <= (others => '0');
                saddsub_6d <= (others => '0');
            else
                saddsub_1d <= saddsub;
                saddsub_2d <= saddsub_1d;
                saddsub_3d <= saddsub_2d;
                saddsub_4d <= saddsub_3d;
                saddsub_5d <= saddsub_4d;
                saddsub_6d <= saddsub_5d;
            end if;
        end if;
    end process;

end Behavioral;
