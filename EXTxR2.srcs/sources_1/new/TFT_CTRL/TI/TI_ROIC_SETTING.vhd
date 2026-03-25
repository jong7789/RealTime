library IEEE;
    use IEEE.STD_LOGIC_1164.ALL;
    use IEEE.STD_LOGIC_UNSIGNED.ALL;
    use IEEE.STD_LOGIC_ARITH.ALL;

    use WORK.TOP_HEADER.ALL;

entity TI_ROIC_SETTING is
    generic ( GNR_MODEL : string := "EXT1616R" );
    port (
        imain_clk           : in  std_logic;
        imain_rstn          : in  std_logic;

        itft_busy           : in  std_logic;

        ireg_roic_en        : in  std_logic;
        ireg_roic_addr      : in  std_logic_vector(7 downto 0);
        ireg_roic_wdata     : in  std_logic_vector(15 downto 0);
        oreg_roic_rdata     : out std_logic_vector(15 downto 0);

        oroic_spi_sck       : out std_logic;
        oroic_spi_cs        : out std_logic;
        oroic_spi_sdo       : out std_logic;
        iroic_spi_sdi       : in  std_logic_vector(ROIC_SDI_NUM(GNR_MODEL)-1 downto 0);
        ostate_roic_setting : out tstate_roic_setting;
        oroic_done          : out std_logic
    );
end TI_ROIC_SETTING;

architecture Behavioral of TI_ROIC_SETTING is

--  type tstate_roic_setting is (
--                                  s_IDLE,
--                                  s_READY,
--                                  s_CS,
--                                  s_DATA,
--                                  s_WAIT,
--                                  s_FINISH
--                              );

    signal state_roic        : tstate_roic_setting;

    signal sroic_spi_cs      : std_logic;
    signal sroic_spi_sck     : std_logic;
    signal sroic_spi_sdo     : std_logic;

    signal sroic_wdata       : std_logic_vector(23 downto 0);
    type troic_rdata         is array (0 to ROIC_NUM(GNR_MODEL)-1) of std_logic_vector(23 downto 0);
    signal sroic_rdata_arr   : troic_rdata;
    signal sbit_cnt          : std_logic_vector(4 downto 0);

    signal sroic_done        : std_logic;

    signal sreg_roic_en_1d    : std_logic;
    signal sreg_roic_en_2d    : std_logic;
    signal sreg_roic_en_3d    : std_logic;
    signal sreg_roic_addr_1d  : std_logic_vector(7 downto 0);
    signal sreg_roic_addr_2d  : std_logic_vector(7 downto 0);
    signal sreg_roic_addr_3d  : std_logic_vector(7 downto 0);
    signal sreg_roic_wdata_1d : std_logic_vector(15 downto 0);
    signal sreg_roic_wdata_2d : std_logic_vector(15 downto 0);
    signal sreg_roic_wdata_3d : std_logic_vector(15 downto 0);

    signal sroic_sck_div      : std_logic;

    component ILA_TI_ROIC_SETTING
    port (
        clk     : in std_logic;
        probe0  : in std_logic;
        probe1  : in std_logic;
        probe2  : in std_logic;
        probe3  : in std_logic_vector(23 downto 0);
        probe4  : in tstate_roic_setting;
        probe5  : in std_logic_vector(4 downto 0);
        probe6  : in std_logic;
        probe7  : in std_logic;
        probe8  : in std_logic_vector(7 downto 0);
        probe9  : in std_logic_vector(15 downto 0);
        probe10 : in std_logic_vector(23 downto 0);
        probe11 : in std_logic
    );
    end component;

begin
    ostate_roic_setting <= state_roic;

    --$ 260226 SPI SCLK = imain_clk / 4
    --# SPI clock divider (sync reset)
    process(imain_clk)
    begin
        if (imain_clk'event and imain_clk = '1') then
            if (imain_rstn = '0') then
                sroic_sck_div <= '0';
            else
                sroic_sck_div <= not sroic_sck_div;
            end if;
        end if;
    end process;

    --# ROIC SPI state machine (sync reset)
    process(imain_clk)
    begin
        if (imain_clk'event and imain_clk = '1') then
            if (imain_rstn = '0') then
                state_roic      <= s_IDLE;
                sroic_spi_cs    <= '0';
                sroic_spi_sck   <= '0';
                sroic_spi_sdo   <= '0';
                sroic_wdata     <= (others => '0');
                sroic_rdata_arr <= (others => (others => '0'));
                sbit_cnt        <= (others => '0');
                sroic_done      <= '0';
            else
                case (state_roic) is
                    when s_IDLE =>
                        if (sreg_roic_en_3d = '1') then
                            state_roic  <= s_READY;
                            sroic_wdata <= sreg_roic_addr_3d & sreg_roic_wdata_3d;
                            sroic_done  <= '0';
                        end if;

                        sroic_spi_cs  <= '1';
                        sroic_spi_sck <= '1';
                        sroic_spi_sdo <= '0';
                        sbit_cnt      <= (others => '0');

                    when s_READY =>
--                      if(itft_busy = '0') then -- 210106 mbh
                            state_roic    <= s_CS;
                            sroic_spi_sck <= '0';
--                      end if;

                    when s_CS =>
                        state_roic    <= s_DATA;
                        sroic_spi_cs  <= '0';
                        sroic_spi_sdo <= sroic_wdata(23);
                        sroic_wdata   <= sroic_wdata(22 downto 0) & '1';

                    when s_DATA =>
                        sroic_spi_sck <= '1';

                        if (sroic_sck_div = '1') then
                            if (sbit_cnt >= 23) then
                                state_roic <= s_FINISH;
                                sbit_cnt   <= (others => '0');
                            else
                                state_roic <= s_WAIT;
                                sbit_cnt   <= sbit_cnt + '1';
                            end if;

                            for i in 0 to ROIC_SDI_NUM(GNR_MODEL)-1 loop
                                sroic_rdata_arr(i) <= sroic_rdata_arr(i)(22 downto 0) & iroic_spi_sdi(i);
                            end loop;
                        end if;

                    when s_WAIT =>
                        sroic_spi_sck <= '0';

                        if (sroic_sck_div = '1') then
                            state_roic    <= s_DATA;
                            sroic_spi_sdo <= sroic_wdata(23);
                            sroic_wdata   <= sroic_wdata(22 downto 0) & '1';
                        end if;

                    when s_FINISH =>
                        if (sreg_roic_en_3d = '0') then
                            state_roic <= s_IDLE;
                        end if;

                        sroic_spi_cs <= '1';
                        sroic_done   <= '1';

                end case;
            end if;
        end if;
    end process;

    --# ROIC register CDC pipeline (sync reset)
    process(imain_clk)
    begin
        if (imain_clk'event and imain_clk = '1') then
            if (imain_rstn = '0') then
                sreg_roic_en_1d    <= '0';
                sreg_roic_en_2d    <= '0';
                sreg_roic_en_3d    <= '0';
                sreg_roic_addr_1d  <= (others => '0');
                sreg_roic_addr_2d  <= (others => '0');
                sreg_roic_addr_3d  <= (others => '0');
                sreg_roic_wdata_1d <= (others => '0');
                sreg_roic_wdata_2d <= (others => '0');
                sreg_roic_wdata_3d <= (others => '0');
            else
                sreg_roic_en_1d    <= ireg_roic_en;
                sreg_roic_en_2d    <= sreg_roic_en_1d;
                sreg_roic_en_3d    <= sreg_roic_en_2d;
                sreg_roic_addr_1d  <= ireg_roic_addr;
                sreg_roic_addr_2d  <= sreg_roic_addr_1d;
                sreg_roic_addr_3d  <= sreg_roic_addr_2d;
                sreg_roic_wdata_1d <= ireg_roic_wdata;
                sreg_roic_wdata_2d <= sreg_roic_wdata_1d;
                sreg_roic_wdata_3d <= sreg_roic_wdata_2d;
            end if;
        end if;
    end process;
    oroic_spi_sck <= sroic_spi_sck;
    oroic_spi_cs  <= sroic_spi_cs;
    oroic_spi_sdo <= sroic_spi_sdo;

    oreg_roic_rdata <= sroic_rdata_arr(0)(15 downto 0);
    oroic_done      <= sroic_done;

    ILA_DEBUG : if(GEN_ILA_roic_setting = "ON") generate
    begin
        U_ILA_TI_ROIC_SETTING : ILA_TI_ROIC_SETTING
        port map (
            clk     => imain_clk,
            probe0  => sroic_spi_sck,
            probe1  => sroic_spi_cs,
            probe2  => sroic_spi_sdo,
            probe3  => sroic_rdata_arr(0),
            probe4  => state_roic,
            probe5  => sbit_cnt,
            probe6  => iroic_spi_sdi(0),
            probe7  => sreg_roic_en_3d,
            probe8  => sreg_roic_addr_3d,
            probe9  => sreg_roic_wdata_3d,
            probe10 => sroic_wdata,
            probe11 => sroic_sck_div
        );
    end generate;

end Behavioral;
