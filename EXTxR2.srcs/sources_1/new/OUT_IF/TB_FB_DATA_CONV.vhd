library IEEE;
    use IEEE.STD_LOGIC_1164.ALL;
    use IEEE.STD_LOGIC_ARITH.ALL;
    use IEEE.STD_LOGIC_UNSIGNED.ALL;

--$ 2605211400 Standalone testbench for FB_DATA_CONV: 3072x3072, 128-cycle hblank, 16-bit 4-pixel incrementing input
entity TB_FB_DATA_CONV is
end TB_FB_DATA_CONV;

architecture Behavioral of TB_FB_DATA_CONV is

    component FB_DATA_CONV is
    port(
        iclk   : in  std_logic;
        irstn  : in  std_logic;
        ien    : in  std_logic;
        iframe : in  std_logic;
        ihcnt  : in  std_logic_vector( 9 downto 0);
        idata  : in  std_logic_vector(63 downto 0);
        oen    : out std_logic;
        oframe : out std_logic;
        odata  : out std_logic_vector(511 downto 0);
        owidth : out std_logic_vector(  5 downto 0)
    );
    end component;

    constant C_CLK_PERIOD : time    := 5.000 ns;   -- 200 MHz DDR3 ui_clk
    constant C_H_BEATS    : integer := 768;          -- 3072px / 4px per beat
    constant C_V_LINES    : integer := 3072;         -- full frame height (reference)
    constant C_H_BLANK    : integer := 128;          -- horizontal blank cycles
    constant C_SIM_LINES  : integer := 4;            -- lines to simulate (reduce for speed)

    signal tbclk   : std_logic := '0';
    signal tbrstn  : std_logic := '0';
    signal tben    : std_logic := '0';
    signal tbframe : std_logic := '0';
    signal tbhcnt  : std_logic_vector( 9 downto 0) := (others => '0');
    signal tbdata  : std_logic_vector(63 downto 0) := (others => '0');
    signal rbframe : std_logic := '0';                          --$ 2605211930 Frame-active gate (high during entire frame body)

    signal oen    : std_logic;
    signal oframe : std_logic;
    signal odata  : std_logic_vector(511 downto 0);
    signal owidth : std_logic_vector(  5 downto 0);

begin

    TB_CLK_GEN : process
    begin
        tbclk <= '0';   wait for C_CLK_PERIOD / 2;
        tbclk <= '1';   wait for C_CLK_PERIOD / 2;
    end process;

    TB_RSTN_GEN : process
    begin
        tbrstn <= '0';  wait for 1 us;
        tbrstn <= '1';  wait;
    end process;

    --$ 2605211400 Stimulus: vsync pulse -> C_SIM_LINES lines of 768 beats + 128 hblank
    TB_STIM : process
        variable vpix : std_logic_vector(15 downto 0) := (others => '0');
    begin
        tben    <= '0';
        tbframe <= '0';
        tbhcnt  <= (others => '0');
        tbdata  <= (others => '0');
        rbframe <= '0';                                                 --$ 2605211930 Initialize rbframe low

        wait until tbrstn = '1';
        wait until rising_edge(tbclk);

        -- vsync pulse (1 cycle)
        tbframe <= '1';
        wait until rising_edge(tbclk);
        tbframe <= '0';

        rbframe <= '1';                                                 --$ 2605211930 Raise frame-active gate before first line

        for line in 0 to C_SIM_LINES - 1 loop

            -- Active pixels: 768 beats x 4 pixels x 16-bit = 3072 pixels/line
            for beat in 0 to C_H_BEATS - 1 loop
                tben   <= '1';
                tbhcnt <= conv_std_logic_vector(beat, 10);
                -- 4 x 16-bit incrementing pixel values packed into 64-bit
                -- bits[63:48]=px3, [47:32]=px2, [31:16]=px1, [15:0]=px0
                tbdata <= (vpix + 3) & (vpix + 2) & (vpix + 1) & vpix;
                vpix   := vpix + 4;
                wait until rising_edge(tbclk);
            end loop;

            -- Horizontal blank (128 cycles)
            tben   <= '0';
            tbhcnt <= (others => '0');
            tbdata <= (others => '0');
            if line = C_SIM_LINES - 1 then                              --$ 2605211930 Drop rbframe at last line's tben falling
                rbframe <= '0';
            end if;
            for i in 0 to C_H_BLANK - 1 loop
                wait until rising_edge(tbclk);
            end loop;

        end loop;

        wait;
    end process;

    U_DUT : FB_DATA_CONV
    port map (
        iclk   => tbclk,
        irstn  => tbrstn,
        ien    => tben,
        iframe => rbframe,                                              --$ 2605211930 Route frame-active gate (was tbframe vsync pulse)
        ihcnt  => tbhcnt,
        idata  => tbdata,
        oen    => oen,
        oframe => oframe,
        odata  => odata,
        owidth => owidth
    );

end Behavioral;
