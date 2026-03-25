
library IEEE;
    use IEEE.STD_LOGIC_1164.ALL;
    use IEEE.STD_LOGIC_UNSIGNED.ALL;
    use IEEE.STD_LOGIC_ARITH.ALL;
    use WORK.TOP_HEADER.ALL;

entity TI_DATA_ALIGN is
    generic (GNR_MODEL : string := "EXT1616R");
    port (
        iroic_clk     : in std_logic;
        iroic_rstn    : in std_logic;
        iui_clk       : in std_logic;
        iui_rstn      : in std_logic;

        ialign_done   : in std_logic;
        ien_array     : in std_logic_vector(ROIC_NUM(GNR_MODEL) - 1 downto 0);
--        idata_array : in tdata_par;
        idata_array   : in std_logic_vector(ROIC_NUM(GNR_MODEL) * 16 - 1 downto 0);
        iroic_clk_sel : in std_logic_vector(ROIC_NUM(GNR_MODEL) - 1 downto 0); --# 241202

        ireg_width    : in std_logic_vector(11 downto 0);
        ireg_height   : in std_logic_vector(11 downto 0);

        ohsync        : out std_logic;
        ovsync        : out std_logic;
        ohcnt         : out std_logic_vector(9 downto 0);
        ovcnt         : out std_logic_vector(11 downto 0);
        odata         : out std_logic_vector(63 downto 0);

        orefvcnt                : out std_logic_vector(12 - 1 downto 0);
        ivcnt                   : in  std_logic_vector(12 - 1 downto 0); -- for ila debug
        ostate_dpram_data_align : out tstate_dpram_data_align
    );
end entity ti_data_align;

architecture behavioral of ti_data_align is

    type tdata_par is array (0 to ROIC_NUM(GNR_MODEL) - 1) of std_logic_vector(15 downto 0);

    constant ROIC_CH_START : integer := ROIC_DUMMY_CH(GNR_MODEL);
    constant ROIC_CH_END   : integer := (ROIC_MAX_CH(GNR_MODEL) - ROIC_DUMMY_CH(GNR_MODEL)) - 1;
    constant ALL_HIGH      : std_logic_vector(ROIC_NUM(GNR_MODEL) - 1 downto 0) := (others => '1');
    constant ALL_LOW       : std_logic_vector(ROIC_NUM(GNR_MODEL) - 1 downto 0) := (others => '0');

    constant ADDRA_MAX : integer := ROIC_MAX_CH(GNR_MODEL);
    constant ADDRB_MAX : integer := (ROIC_MAX_CH(GNR_MODEL) / 4);

    constant GLB_H_FLIP : std_logic := FUNC_H_FLIP(GNR_MODEL);
    --* ADC CHANGE
    --* 1 : reverse ADC data
    --* 0 : ADC DATA
--    constant ADC_REV    : std_logic := '1';
    constant ADC_REV : std_logic := FUNC_ADC_REV(GNR_MODEL);

    component DPRAM_16x64_64x16 is
        port (
            clka   : in  std_logic;
            wea    : in  std_logic;
            ena    : in  std_logic;
            addra  : in  std_logic_vector(5 downto 0);
            dina   : in  std_logic_vector(15 downto 0);
            toggle : in  std_logic;
            clkb   : in  std_logic;
            enb    : in  std_logic;
            addrb  : in  std_logic_vector(3 downto 0);
            doutb  : out std_logic_vector(63 downto 0)
        );
    end component;
    component DPRAM_16x128_64x32 is
        port (
            clka   : in  std_logic;
            wea    : in  std_logic;
            ena    : in  std_logic;
            addra  : in  std_logic_vector(6 downto 0);
            dina   : in  std_logic_vector(15 downto 0);
            toggle : in  std_logic;
            clkb   : in  std_logic;
            enb    : in  std_logic;
            addrb  : in  std_logic_vector(4 downto 0);
            doutb  : out std_logic_vector(63 downto 0)
        );
    end component;

    type taddra_tmp is array (0 to ROIC_NUM(GNR_MODEL) - 1) of std_logic_vector(7 downto 0);
    type taddra     is array (0 to ROIC_NUM(GNR_MODEL) - 1) of std_logic_vector(5 downto 0);
    type taddra7    is array (0 to ROIC_NUM(GNR_MODEL) - 1) of std_logic_vector(6 downto 0);
    type tdoutb     is array (0 to ROIC_NUM(GNR_MODEL) - 1) of std_logic_vector(63 downto 0);

--    type tstate_dpram_data_align is (
--        s_IDLE,
--        s_READY,
--        s_WAIT_ODD,
--        s_DATA_ODD,
--        s_WAIT_EVEN,
--        s_DATA_EVEN
--    );

    signal state_dpram   : tstate_dpram_data_align;
    signal stoggle_porta : std_logic_vector(ROIC_NUM(GNR_MODEL) - 1 downto 0);
    signal stoggle_portb : std_logic;

    signal sena_tmp   : std_logic_vector(ROIC_NUM(GNR_MODEL) - 1 downto 0);
    signal saddra_tmp : taddra_tmp;
    signal sdina_tmp  : tdata_par;

    signal sena0      : std_logic_vector(ROIC_NUM(GNR_MODEL) - 1 downto 0);
    signal sena0_odd  : std_logic_vector(ROIC_NUM(GNR_MODEL) - 1 downto 0);
    signal sena0_even : std_logic_vector(ROIC_NUM(GNR_MODEL) - 1 downto 0);
    signal sena1      : std_logic_vector(ROIC_NUM(GNR_MODEL) - 1 downto 0);
    signal sena1_odd  : std_logic_vector(ROIC_NUM(GNR_MODEL) - 1 downto 0);
    signal sena1_even : std_logic_vector(ROIC_NUM(GNR_MODEL) - 1 downto 0);
    signal sena2      : std_logic_vector(ROIC_NUM(GNR_MODEL) - 1 downto 0);
    signal sena2_odd  : std_logic_vector(ROIC_NUM(GNR_MODEL) - 1 downto 0);
    signal sena2_even : std_logic_vector(ROIC_NUM(GNR_MODEL) - 1 downto 0);
    signal sena3      : std_logic_vector(ROIC_NUM(GNR_MODEL) - 1 downto 0);
    signal sena3_odd  : std_logic_vector(ROIC_NUM(GNR_MODEL) - 1 downto 0);
    signal sena3_even : std_logic_vector(ROIC_NUM(GNR_MODEL) - 1 downto 0);
    signal saddra0     : taddra;
    signal saddra1     : taddra;
    signal saddra2     : taddra;
    signal saddra3     : taddra;
    signal sdina0      : tdata_par;
    signal sdina1      : tdata_par;
    signal sdina2      : tdata_par;
    signal sdina3      : tdata_par;
    signal sena_a      : std_logic_vector(ROIC_NUM(GNR_MODEL) - 1 downto 0);
    signal sena_a_odd  : std_logic_vector(ROIC_NUM(GNR_MODEL) - 1 downto 0);
    signal sena_a_even : std_logic_vector(ROIC_NUM(GNR_MODEL) - 1 downto 0);
    signal sena_b      : std_logic_vector(ROIC_NUM(GNR_MODEL) - 1 downto 0);
    signal sena_b_odd  : std_logic_vector(ROIC_NUM(GNR_MODEL) - 1 downto 0);
    signal sena_b_even : std_logic_vector(ROIC_NUM(GNR_MODEL) - 1 downto 0);
    signal saddra_a    : taddra7;
    signal saddra_b    : taddra7;
    signal sdina_a     : tdata_par;
    signal sdina_b     : tdata_par;

    signal senb         : std_logic;
    signal saddrb       : std_logic_vector(5 downto 0);
    signal saddrb_1d    : std_logic_vector(5 downto 0);
    signal sdoutb0_odd  : tdoutb;
    signal sdoutb0_even : tdoutb;
    signal sdoutb1_odd  : tdoutb;
    signal sdoutb1_even : tdoutb;
    signal sdoutb2_odd  : tdoutb;
    signal sdoutb2_even : tdoutb;
    signal sdoutb3_odd  : tdoutb;
    signal sdoutb3_even : tdoutb;

    signal swait_cnt      : std_logic_vector(15 downto 0);
    signal sdual_roic_cnt : integer range 0 to ROIC_DUAL_BY_MODEL(GNR_MODEL) - 1;
    signal sroic_cnt      : integer range 0 to ROIC_NUM(GNR_MODEL) - 1;
    signal sroic_cnt_1d   : integer range 0 to ROIC_NUM(GNR_MODEL) - 1;

    signal shsync : std_logic;
    signal svsync : std_logic;
    signal shcnt  : std_logic_vector(9 downto 0);
    signal svcnt  : std_logic_vector(11 downto 0);
    signal sdata  : std_logic_vector(63 downto 0);

    signal sreg_width  : std_logic_vector(9 downto 0);
    signal sreg_height : std_logic_vector(11 downto 0);

    signal dumm_shsync_out : std_logic;
    signal dumm_svsync_out : std_logic;
    signal dumm_shcnt_out  : std_logic_vector(9 downto 0);
    signal dumm_svcnt_out  : std_logic_vector(11 downto 0);
    signal dumm_sdata_out  : std_logic_vector(63 downto 0);

    signal hflp_shsync_out : std_logic;
    signal hflp_svsync_out : std_logic;
    signal hflp_shcnt_out  : std_logic_vector(9 downto 0);
    signal hflp_svcnt_out  : std_logic_vector(11 downto 0);
    signal hflp_sdata_out  : std_logic_vector(63 downto 0);

    signal stoggle_porta_1d : std_logic_vector(ROIC_NUM(GNR_MODEL) - 1 downto 0);
    signal stoggle_porta_2d : std_logic_vector(ROIC_NUM(GNR_MODEL) - 1 downto 0);
    -- Delay
    signal stoggle_porta_1cd : std_logic_vector(ROIC_NUM(GNR_MODEL) - 1 downto 0);
    signal stoggle_porta_2cd : std_logic_vector(ROIC_NUM(GNR_MODEL) - 1 downto 0);
    signal stoggle_porta_3cd : std_logic_vector(ROIC_NUM(GNR_MODEL) - 1 downto 0);
    signal stoggle_porta_4cd : std_logic_vector(ROIC_NUM(GNR_MODEL) - 1 downto 0);
    signal stoggle_porta_cd  : std_logic_vector(ROIC_NUM(GNR_MODEL) - 1 downto 0);
    signal stoggle_portb_1d  : std_logic;

    signal shsync_1d : std_logic;
    signal shsync_2d : std_logic;

    signal svsync_1d : std_logic;
    signal svsync_2d : std_logic;

    signal shcnt_1d : std_logic_vector(9 downto 0);
    signal shcnt_2d : std_logic_vector(9 downto 0);

    signal svcnt_1d : std_logic_vector(11 downto 0);
    signal svcnt_2d : std_logic_vector(11 downto 0);

--    signal align_done_trig_sh : std_logic_vector(15 downto 0);
    type ty_align_done_trig_sh is array (0 to ROIC_NUM(GNR_MODEL) - 1) of std_logic_vector(15 downto 0);
    signal align_done_trig_sh : ty_align_done_trig_sh;

    signal salign_done_1d : std_logic;
    signal salign_done_2d : std_logic;
    signal probe_out0     : std_logic;

--  signal sivcnt_1d : std_logic_vector(11 downto 0);
--  signal sivcnt_2d : std_logic_vector(11 downto 0);
    type ty_sivcnt is array (0 to ROIC_NUM(GNR_MODEL) - 1) of std_logic_vector(11 downto 0);
    signal sivcnt_1d : ty_sivcnt;
    signal sivcnt_2d : ty_sivcnt;

--  signal sframestart     : std_logic;
    signal sframestart     : std_logic_vector(ROIC_NUM(GNR_MODEL) - 1 downto 0);
    signal sframestart_u0d : std_logic;
    signal sframestart_u1d : std_logic;
    signal sframestart_u2d : std_logic;
    signal sdpramstart     : std_logic;

    signal stoggle_dual_roic : std_logic_vector(ROIC_NUM(GNR_MODEL) - 1 downto 0);

    COMPONENT vio_1out
        PORT (
            clk        : IN STD_LOGIC;
            probe_out0 : OUT STD_LOGIC -- _VECTOR(0 DOWNTO 0)
        );
    END COMPONENT;

begin
    ostate_dpram_data_align <= state_dpram;

-- c_vio_align : vio_1out
--   PORT MAP (
--     clk => iroic_clk,
--     probe_out0 => probe_out0
--   );
    sena_tmp <= ien_array;
--    sdina_tmp <= idata_array;
    inmap : for i in 0 to ROIC_NUM(GNR_MODEL) - 1 generate --# 231117
        sdina_tmp(i) <= idata_array((i + 1) * 16 - 1 downto i * 16);
    end generate inmap;

    --# address counter process per ROIC channel
    inaddr : for i in 0 to ROIC_NUM(GNR_MODEL) - 1 generate
        process (iroic_clk_sel(i), iroic_rstn)
        begin
            if (iroic_rstn = '0') then
                --  saddra_tmp      <= (others => (others => '0'));
                --  stoggle_porta <= (others => '0');
                saddra_tmp(i)    <= (others => '0'); --# (others => (others => '0'));
                stoggle_porta(i) <= '0'; --# (others => '0');
            elsif (iroic_clk_sel(i)'event and iroic_clk_sel(i) = '1') then

                sivcnt_1d(i) <= ivcnt;
                sivcnt_2d(i) <= sivcnt_1d(i);
                if sivcnt_2d(i) /= 0 and sivcnt_1d(i) = 0 then
                    align_done_trig_sh(i)(0) <= '1';
                else
                    align_done_trig_sh(i)(0) <= '0';
                end if;
                align_done_trig_sh(i)(align_done_trig_sh(i)'left downto 1) <=
                    align_done_trig_sh(i)(align_done_trig_sh(i)'left - 1 downto 0);

--          --### 2pix down scroll ### 221013
--          if sivcnt_2d(i) /=2 and  sivcnt_1d(i) =2 then
--            sframestart(i) <= not sframestart(i);
--          end if;

--            for i in 0 to ROIC_NUM(GNR_MODEL)-1 loop
                if align_done_trig_sh(i)(align_done_trig_sh(i)'left) = '1' then
                    saddra_tmp(i)    <= (others => '0');
                    stoggle_porta(i) <= '0'; -- can make vsync align trouble
                elsif (sena_tmp(i) = '1') then
                    if (saddra_tmp(i) = ADDRA_MAX - 1) then
                        saddra_tmp(i) <= (others => '0');
                        if (stoggle_porta(i) = '1') then
                            stoggle_porta(i) <= '0';
                        else
                            stoggle_porta(i) <= '1';
                        end if;
                    else
                        if (ROIC_BY_MODEL(GNR_MODEL) = "AFE2256") then
                            if (saddra_tmp(i)(7 downto 6) = "11") then
                                saddra_tmp(i)(5 downto 0) <= saddra_tmp(i)(5 downto 0) + '1';
                                saddra_tmp(i)(7 downto 6) <= "00";
                            else
                                saddra_tmp(i)(7 downto 6) <= saddra_tmp(i)(7 downto 6) + '1';
                            end if;
                        else
                            if (saddra_tmp(i)(7) = '1') then
                                saddra_tmp(i)(6 downto 0) <= saddra_tmp(i)(6 downto 0) + '1';
                                saddra_tmp(i)(7) <= '0';
                            else
                                saddra_tmp(i)(7) <= '1';
                            end if;
                        end if;
                    end if;
                end if;
--            end loop;
            end if;
        end process;
    end generate inaddr;

    --# data routing process per ROIC channel
    indata : for i in 0 to ROIC_NUM(GNR_MODEL) - 1 generate
        process (iroic_clk_sel(i), iroic_rstn)
        begin
            if (iroic_rstn = '0') then
--            sena0    <= (others => '0');
--            saddra0 <= (others => (others => '0'));
--            sdina0    <= (others => (others => '0'));
--            sena1    <= (others => '0');
--            saddra1 <= (others => (others => '0'));
--            sdina1    <= (others => (others => '0'));
--            sena2    <= (others => '0');
--            saddra2 <= (others => (others => '0'));
--            sdina2    <= (others => (others => '0'));
--            sena3    <= (others => '0');
--            saddra3 <= (others => (others => '0'));
--            sdina3    <= (others => (others => '0'));
                stoggle_dual_roic(i) <= '0';

                sena0(i)    <= '0';
                saddra0(i)  <= (others => '0');
                sdina0(i)   <= (others => '0');
                sena1(i)    <= '0';
                saddra1(i)  <= (others => '0');
                sdina1(i)   <= (others => '0');
                sena2(i)    <= '0';
                saddra2(i)  <= (others => '0');
                sdina2(i)   <= (others => '0');
                sena3(i)    <= '0';
                saddra3(i)  <= (others => '0');
                sdina3(i)   <= (others => '0');
                sena_a(i)   <= '0';
                saddra_a(i) <= (others => '0');
                sdina_a(i)  <= (others => '0');
                sena_b(i)   <= '0';
                saddra_b(i) <= (others => '0');
                sdina_b(i)  <= (others => '0');
            elsif (iroic_clk_sel(i)'event and iroic_clk_sel(i) = '1') then
--            for i in 0 to ROIC_NUM(GNR_MODEL)-1 loop
                if (i < ROIC_NUM(GNR_MODEL) / ROIC_DUAL_BY_MODEL(GNR_MODEL)) then
                    stoggle_dual_roic(i) <= '0';
                    if (ROIC_BY_MODEL(GNR_MODEL) = "AFE2256") then
                        case (saddra_tmp(i)(7 downto 6)) is
                            when "00" =>
                                sena0(i)   <= sena_tmp(i);
                                saddra0(i) <= saddra_tmp(i)(5 downto 0);
                                sdina0(i)  <= sdina_tmp(i);

                                sena1(i)   <= '0';
                                saddra1(i) <= (others => '0');
                                sdina1(i)  <= (others => '0');
                                sena2(i)   <= '0';
                                saddra2(i) <= (others => '0');
                                sdina2(i)  <= (others => '0');
                                sena3(i)   <= '0';
                                saddra3(i) <= (others => '0');
                                sdina3(i)  <= (others => '0');
                            when "01" =>
                                sena1(i)   <= sena_tmp(i);
                                saddra1(i) <= saddra_tmp(i)(5 downto 0);
                                sdina1(i)  <= sdina_tmp(i);

                                sena0(i)   <= '0';
                                saddra0(i) <= (others => '0');
                                sdina0(i)  <= (others => '0');
                                sena2(i)   <= '0';
                                saddra2(i) <= (others => '0');
                                sdina2(i)  <= (others => '0');
                                sena3(i)   <= '0';
                                saddra3(i) <= (others => '0');
                                sdina3(i)  <= (others => '0');
                            when "10" =>
                                sena2(i)   <= sena_tmp(i);
                                saddra2(i) <= saddra_tmp(i)(5 downto 0);
                                sdina2(i)  <= sdina_tmp(i);

                                sena0(i)   <= '0';
                                saddra0(i) <= (others => '0');
                                sdina0(i)  <= (others => '0');
                                sena1(i)   <= '0';
                                saddra1(i) <= (others => '0');
                                sdina1(i)  <= (others => '0');
                                sena3(i)   <= '0';
                                saddra3(i) <= (others => '0');
                                sdina3(i)  <= (others => '0');
                            when "11" =>
                                sena3(i)   <= sena_tmp(i);
                                saddra3(i) <= saddra_tmp(i)(5 downto 0);
                                sdina3(i)  <= sdina_tmp(i);

                                sena0(i)   <= '0';
                                saddra0(i) <= (others => '0');
                                sdina0(i)  <= (others => '0');
                                sena1(i)   <= '0';
                                saddra1(i) <= (others => '0');
                                sdina1(i)  <= (others => '0');
                                sena2(i)   <= '0';
                                saddra2(i) <= (others => '0');
                                sdina2(i)  <= (others => '0');
                            when others => NULL;
                        end case;
                    else --$ 260312 AFE3256 ADC 128Ch
                        case saddra_tmp(i)(7) is
                            when '0' =>
                                sena_a(i)   <= sena_tmp(i);
                                saddra_a(i) <= saddra_tmp(i)(6 downto 0);
                                sdina_a(i)  <= sdina_tmp(i);
                                sena_b(i)   <= '0';
                                saddra_b(i) <= (others => '0');
                                sdina_b(i)  <= (others => '0');
                            when '1' =>
                                sena_b(i)   <= sena_tmp(i);
                                saddra_b(i) <= saddra_tmp(i)(6 downto 0);
                                sdina_b(i)  <= sdina_tmp(i);
                                sena_a(i)   <= '0';
                                saddra_a(i) <= (others => '0');
                                sdina_a(i)  <= (others => '0');
                            when others => NULL;
                        end case;
                    end if;
                else
                    stoggle_dual_roic(i) <= '1';
                    if (ROIC_BY_MODEL(GNR_MODEL) = "AFE2256") then
                        case (saddra_tmp(i)(7 downto 6)) is
                            when "00" =>
                                sena3(i)   <= sena_tmp(i);
                                saddra3(i) <= not saddra_tmp(i)(5 downto 0);
                                sdina3(i)  <= sdina_tmp(i);

                                sena0(i)   <= '0';
                                saddra0(i) <= (others => '0');
                                sdina0(i)  <= (others => '0');
                                sena1(i)   <= '0';
                                saddra1(i) <= (others => '0');
                                sdina1(i)  <= (others => '0');
                                sena2(i)   <= '0';
                                saddra2(i) <= (others => '0');
                                sdina2(i)  <= (others => '0');
                            when "01" =>
                                sena2(i)   <= sena_tmp(i);
                                saddra2(i) <= not saddra_tmp(i)(5 downto 0);
                                sdina2(i)  <= sdina_tmp(i);

                                sena0(i)   <= '0';
                                saddra0(i) <= (others => '0');
                                sdina0(i)  <= (others => '0');
                                sena1(i)   <= '0';
                                saddra1(i) <= (others => '0');
                                sdina1(i)  <= (others => '0');
                                sena3(i)   <= '0';
                                saddra3(i) <= (others => '0');
                                sdina3(i)  <= (others => '0');
                            when "10" =>
                                sena1(i)   <= sena_tmp(i);
                                saddra1(i) <= not saddra_tmp(i)(5 downto 0);
                                sdina1(i)  <= sdina_tmp(i);

                                sena0(i)   <= '0';
                                saddra0(i) <= (others => '0');
                                sdina0(i)  <= (others => '0');
                                sena2(i)   <= '0';
                                saddra2(i) <= (others => '0');
                                sdina2(i)  <= (others => '0');
                                sena3(i)   <= '0';
                                saddra3(i) <= (others => '0');
                                sdina3(i)  <= (others => '0');
                            when "11" =>
                                sena0(i)   <= sena_tmp(i);
                                saddra0(i) <= not saddra_tmp(i)(5 downto 0);
                                sdina0(i)  <= sdina_tmp(i);

                                sena1(i)   <= '0';
                                saddra1(i) <= (others => '0');
                                sdina1(i)  <= (others => '0');
                                sena2(i)   <= '0';
                                saddra2(i) <= (others => '0');
                                sdina2(i)  <= (others => '0');
                                sena3(i)   <= '0';
                                saddra3(i) <= (others => '0');
                                sdina3(i)  <= (others => '0');
                            when others => NULL;
                        end case;
                    else --$ 260312 AFE3256 ADC 128Ch
                        case saddra_tmp(i)(7) is
                            when '0' =>
                                sena_b(i)   <= sena_tmp(i);
                                saddra_b(i) <= not saddra_tmp(i)(6 downto 0);
                                sdina_b(i)  <= sdina_tmp(i);
                                sena_a(i)   <= '0';
                                saddra_a(i) <= (others => '0');
                                sdina_a(i)  <= (others => '0');
                            when '1' =>
                                sena_a(i)   <= sena_tmp(i);
                                saddra_a(i) <= not saddra_tmp(i)(6 downto 0);
                                sdina_a(i)  <= sdina_tmp(i);
                                sena_b(i)   <= '0';
                                saddra_b(i) <= (others => '0');
                                sdina_b(i)  <= (others => '0');
                            when others => NULL;
                        end case;
                    end if;
                end if;
--            end loop;
            end if;
        end process;
    end generate indata;

    --# toggle delay process per ROIC channel
    gen_toggle : for i in 0 to ROIC_NUM(GNR_MODEL) - 1 generate
        process (iroic_clk_sel(i), iroic_rstn)
        begin
            if (iroic_rstn = '0') then
                stoggle_porta_1d(i) <= '0'; --# (others => '0');
                stoggle_porta_2d(i) <= '0'; --# (others => '0');
            elsif (iroic_clk_sel(i)'event and iroic_clk_sel(i) = '1') then
                stoggle_porta_1d(i) <= stoggle_porta(i);
                stoggle_porta_2d(i) <= stoggle_porta_1d(i);
            end if;
        end process;
    end generate gen_toggle;

    toggle_data : for i in 0 to ROIC_NUM(GNR_MODEL) - 1 generate
        sena0_odd(i)   <= sena0(i)  when stoggle_porta_2d(i) = '0' else '0';
        sena0_even(i)  <= sena0(i)  when stoggle_porta_2d(i) = '1' else '0';
        sena1_odd(i)   <= sena1(i)  when stoggle_porta_2d(i) = '0' else '0';
        sena1_even(i)  <= sena1(i)  when stoggle_porta_2d(i) = '1' else '0';
        sena2_odd(i)   <= sena2(i)  when stoggle_porta_2d(i) = '0' else '0';
        sena2_even(i)  <= sena2(i)  when stoggle_porta_2d(i) = '1' else '0';
        sena3_odd(i)   <= sena3(i)  when stoggle_porta_2d(i) = '0' else '0';
        sena3_even(i)  <= sena3(i)  when stoggle_porta_2d(i) = '1' else '0';
        sena_a_odd(i)  <= sena_a(i) when stoggle_porta_2d(i) = '0' else '0';
        sena_a_even(i) <= sena_a(i) when stoggle_porta_2d(i) = '1' else '0';
        sena_b_odd(i)  <= sena_b(i) when stoggle_porta_2d(i) = '0' else '0';
        sena_b_even(i) <= sena_b(i) when stoggle_porta_2d(i) = '1' else '0';
    end generate toggle_data;

    AFE2256_DPRAM : if (ROIC_BY_MODEL(GNR_MODEL) = "AFE2256") generate
        dpram_gen : for i in 0 to ROIC_NUM(GNR_MODEL) - 1 generate
            ODD0_DPRAM_16x64_64x16 : DPRAM_16x64_64x16
                port map (
                    clka   => iroic_clk_sel(i),
                    wea    => '1',
                    ena    => sena0_odd(i),
                    addra  => saddra0(i),
                    dina   => sdina0(i),
                    toggle => stoggle_dual_roic(i),
                    clkb   => iui_clk,
                    enb    => senb,
                    addrb  => saddrb(3 downto 0),
                    doutb  => sdoutb0_odd(i)
                );
            ODD1_DPRAM_16x64_64x16 : DPRAM_16x64_64x16
                port map (
                    clka   => iroic_clk_sel(i),
                    wea    => '1',
                    ena    => sena1_odd(i),
                    addra  => saddra1(i),
                    dina   => sdina1(i),
                    toggle => stoggle_dual_roic(i),
                    clkb   => iui_clk,
                    enb    => senb,
                    addrb  => saddrb(3 downto 0),
                    doutb  => sdoutb1_odd(i)
                );
            ODD2_DPRAM_16x64_64x16 : DPRAM_16x64_64x16
                port map (
                    clka   => iroic_clk_sel(i),
                    wea    => '1',
                    ena    => sena2_odd(i),
                    addra  => saddra2(i),
                    dina   => sdina2(i),
                    toggle => stoggle_dual_roic(i),
                    clkb   => iui_clk,
                    enb    => senb,
                    addrb  => saddrb(3 downto 0),
                    doutb  => sdoutb2_odd(i)
                );
            ODD3_DPRAM_16x64_64x16 : DPRAM_16x64_64x16
                port map (
                    clka   => iroic_clk_sel(i),
                    wea    => '1',
                    ena    => sena3_odd(i),
                    addra  => saddra3(i),
                    dina   => sdina3(i),
                    toggle => stoggle_dual_roic(i),
                    clkb   => iui_clk,
                    enb    => senb,
                    addrb  => saddrb(3 downto 0),
                    doutb  => sdoutb3_odd(i)
                );
            EVEN0_DPRAM_16x64_64x16 : DPRAM_16x64_64x16
                port map (
                    clka   => iroic_clk_sel(i),
                    wea    => '1',
                    ena    => sena0_even(i),
                    addra  => saddra0(i),
                    dina   => sdina0(i),
                    toggle => stoggle_dual_roic(i),
                    clkb   => iui_clk,
                    enb    => senb,
                    addrb  => saddrb(3 downto 0),
                    doutb  => sdoutb0_even(i)
                );
            EVEN1_DPRAM_16x64_64x16 : DPRAM_16x64_64x16
                port map (
                    clka   => iroic_clk_sel(i),
                    wea    => '1',
                    ena    => sena1_even(i),
                    addra  => saddra1(i),
                    dina   => sdina1(i),
                    toggle => stoggle_dual_roic(i),
                    clkb   => iui_clk,
                    enb    => senb,
                    addrb  => saddrb(3 downto 0),
                    doutb  => sdoutb1_even(i)
                );
            EVEN2_DPRAM_16x64_64x16 : DPRAM_16x64_64x16
                port map (
                    clka   => iroic_clk_sel(i),
                    wea    => '1',
                    ena    => sena2_even(i),
                    addra  => saddra2(i),
                    dina   => sdina2(i),
                    toggle => stoggle_dual_roic(i),
                    clkb   => iui_clk,
                    enb    => senb,
                    addrb  => saddrb(3 downto 0),
                    doutb  => sdoutb2_even(i)
                );
            EVEN3_DPRAM_16x64_64x16 : DPRAM_16x64_64x16
                port map (
                    clka   => iroic_clk_sel(i),
                    wea    => '1',
                    ena    => sena3_even(i),
                    addra  => saddra3(i),
                    dina   => sdina3(i),
                    toggle => stoggle_dual_roic(i),
                    clkb   => iui_clk,
                    enb    => senb,
                    addrb  => saddrb(3 downto 0),
                    doutb  => sdoutb3_even(i)
                );
        end generate dpram_gen;
    end generate AFE2256_DPRAM;

    --$ 260312 AFE3256 ADC 128Ch
    AFE3256_DPRAM : if (ROIC_BY_MODEL(GNR_MODEL) = "AFE3256") generate
        dpram_gen : for i in 0 to ROIC_NUM(GNR_MODEL) - 1 generate
            sdoutb1_odd(i)  <= sdoutb0_odd(i);
            sdoutb1_even(i) <= sdoutb0_even(i);
            sdoutb3_odd(i)  <= sdoutb2_odd(i);
            sdoutb3_even(i) <= sdoutb2_even(i);

            ODD0_DPRAM_16x128_64x32 : DPRAM_16x128_64x32
                port map (
                    clka   => iroic_clk_sel(i),
                    wea    => '1',
                    ena    => sena_a_odd(i),
                    addra  => saddra_a(i),
                    dina   => sdina_a(i),
                    toggle => stoggle_dual_roic(i),
                    clkb   => iui_clk,
                    enb    => senb,
                    addrb  => saddrb(4 downto 0),
                    doutb  => sdoutb0_odd(i)
                );
            ODD1_DPRAM_16x128_64x32 : DPRAM_16x128_64x32
                port map (
                    clka   => iroic_clk_sel(i),
                    wea    => '1',
                    ena    => sena_b_odd(i),
                    addra  => saddra_b(i),
                    dina   => sdina_b(i),
                    toggle => stoggle_dual_roic(i),
                    clkb   => iui_clk,
                    enb    => senb,
                    addrb  => saddrb(4 downto 0),
                    doutb  => sdoutb2_odd(i)
                );
            EVEN0_DPRAM_16x128_64x32 : DPRAM_16x128_64x32
                port map (
                    clka   => iroic_clk_sel(i),
                    wea    => '1',
                    ena    => sena_a_even(i),
                    addra  => saddra_a(i),
                    dina   => sdina_a(i),
                    toggle => stoggle_dual_roic(i),
                    clkb   => iui_clk,
                    enb    => senb,
                    addrb  => saddrb(4 downto 0),
                    doutb  => sdoutb0_even(i)
                );
            EVEN1_DPRAM_16x128_64x32 : DPRAM_16x128_64x32
                port map (
                    clka   => iroic_clk_sel(i),
                    wea    => '1',
                    ena    => sena_b_even(i),
                    addra  => saddra_b(i),
                    dina   => sdina_b(i),
                    toggle => stoggle_dual_roic(i),
                    clkb   => iui_clk,
                    enb    => senb,
                    addrb  => saddrb(4 downto 0),
                    doutb  => sdoutb2_even(i)
                );
        end generate dpram_gen;
    end generate AFE3256_DPRAM;

    --# DPRAM read state machine process
    process (iui_clk)
    begin
        if (iui_clk'event and iui_clk = '1') then
            if (iui_rstn = '0') then
                state_dpram    <= s_IDLE;

                swait_cnt      <= (others => '0');
                sdual_roic_cnt <= 0;

                senb           <= '0';
                saddrb         <= (others => '0');
                stoggle_portb  <= '0';

                shsync <= '0';
                svsync <= '0';
                shcnt  <= (others => '0');
                svcnt  <= (others => '0');
            else

                --### 2pixel downscroll //221013mbh
                sframestart_u0d <= sframestart(0);
                sframestart_u1d <= sframestart_u0d;
                sframestart_u2d <= sframestart_u1d;
                if sframestart_u2d /= sframestart_u1d then
                    sdpramstart <= '1';
                else
                    sdpramstart <= '0';
                end if;

                --###

                case (state_dpram) is
                    when s_IDLE =>

                        state_dpram <= s_READY;
--                    --### 2pixel downscroll
--                    if sdpramstart = '1' then
--                        state_dpram <= s_READY;
--                    end if;

                        shsync <= '0';
                        svsync <= '0';
                        shcnt  <= (others => '0');
                        svcnt  <= (others => '0');

                    when s_READY =>
                        if (stoggle_porta_cd = ALL_HIGH) then
                            state_dpram    <= s_DATA_ODD;
                            sdual_roic_cnt <= 0;
                            sroic_cnt      <= 0;

                            shsync <= '1';
                            svsync <= '1';
                            shcnt  <= (others => '0');
                            svcnt  <= svcnt;

                            senb          <= '1';
                            saddrb        <= (others => '0');
                            stoggle_portb <= '0';
                        end if;

                    when s_WAIT_ODD =>
                        if (sdual_roic_cnt = ROIC_DUAL_BY_MODEL(GNR_MODEL) - 1) then
                            if (stoggle_porta_cd = ALL_HIGH) then
                                state_dpram    <= s_DATA_ODD;
                                sdual_roic_cnt <= 0;
                                sroic_cnt      <= 0;

                                shsync <= '1';
                                svsync <= '1';
                                shcnt  <= (others => '0');
                                svcnt  <= svcnt;

                                senb          <= '1';
                                saddrb        <= (others => '0');
                                stoggle_portb <= '0';
                            end if;
                        else
                            if (swait_cnt >= 15) then
                                state_dpram    <= s_DATA_EVEN;
                                swait_cnt      <= (others => '0');
                                sdual_roic_cnt <= sdual_roic_cnt + 1;
                                sroic_cnt      <= sroic_cnt + 1; -- ### bug upper side image copy to lower / 201230 mbh

                                shsync <= '1';
                                svsync <= '1';
                                shcnt  <= (others => '0');
                                svcnt  <= svcnt;

                                senb   <= '1';
                                saddrb <= (others => '0');
                            else
                                swait_cnt <= swait_cnt + '1';
                            end if;
                        end if;

                    when s_DATA_ODD =>
                        if (shcnt = sreg_width - 1) then
                            senb <= '0';

                            if (svcnt = sreg_height - 1) then
                                state_dpram <= s_IDLE;
                                svsync      <= '0';
                                svcnt       <= (others => '0');
                            else
                                state_dpram <= s_WAIT_EVEN;
                                svsync      <= '1';
                                svcnt       <= svcnt + '1';
                            end if;

                            shsync <= '0';
                            shcnt  <= (others => '0');
                            saddrb <= (others => '0');
                        else
                            if (saddrb = ADDRB_MAX - 1) then -- 64
                                saddrb    <= (others => '0');
                                sroic_cnt <= sroic_cnt + 1;
                            else
                                saddrb <= saddrb + '1';
                            end if;
                            senb  <= '1';
                            shcnt <= shcnt + '1';
                        end if;

                    when s_WAIT_EVEN =>
                        if (sdual_roic_cnt = ROIC_DUAL_BY_MODEL(GNR_MODEL) - 1) then
                            if (stoggle_porta_cd = ALL_LOW) then
                                state_dpram    <= s_DATA_EVEN;
                                sdual_roic_cnt <= 0;
                                sroic_cnt      <= 0;

                                shsync <= '1';
                                svsync <= '1';
                                shcnt  <= (others => '0');
                                svcnt  <= svcnt;

                                senb          <= '1';
                                saddrb        <= (others => '0');
                                stoggle_portb <= '1';
                            end if;
                        else
                            if (swait_cnt >= 15) then
                                state_dpram    <= s_DATA_ODD;
                                swait_cnt      <= (others => '0');
                                sdual_roic_cnt <= sdual_roic_cnt + 1;
                                sroic_cnt      <= sroic_cnt + 1; -- ### bug upper side image copy to lower / 201230 mbh

                                shsync <= '1';
                                svsync <= '1';
                                shcnt  <= (others => '0');
                                svcnt  <= svcnt;

                                senb   <= '1';
                                saddrb <= (others => '0');
                            else
                                swait_cnt <= swait_cnt + '1';
                            end if;
                        end if;

                    when s_DATA_EVEN =>
                        if (shcnt = sreg_width - 1) then
                            senb <= '0';

                            if (svcnt = sreg_height - 1) then
                                state_dpram <= s_IDLE;
                                svsync      <= '0';
                                svcnt       <= (others => '0');
                            else
                                state_dpram <= s_WAIT_ODD;
                                svsync      <= '1';
                                svcnt       <= svcnt + '1';
                            end if;

                            shsync <= '0';
                            shcnt  <= (others => '0');
                            saddrb <= (others => '0');
                        else
                            if (saddrb = ADDRB_MAX - 1) then
                                saddrb    <= (others => '0');
                                sroic_cnt <= sroic_cnt + 1;
                            else
                                saddrb <= saddrb + '1';
                            end if;
                            senb  <= '1';
                            shcnt <= shcnt + '1';
                        end if;
                end case;

            end if;
        end if;
    end process;

    --# address and roic counter 1-delay process
    process (iui_clk)
    begin
        if (iui_clk'event and iui_clk = '1') then
            if (iui_rstn = '0') then
                saddrb_1d    <= (others => '0');
                sroic_cnt_1d <= 0;
            else
                saddrb_1d    <= saddrb;
                sroic_cnt_1d <= sroic_cnt;
            end if;
        end if;
    end process;

--*     process (iui_clk, iui_rstn)
--*     begin
--*         if(iui_rstn = '0') then
--*             sdata <= (others => '0');
--*         elsif (iui_clk'event and iui_clk = '1') then
--*             if(shsync_1d = '1') then
--*                 if(stoggle_portb_1d = '0') then
--*
--*                     case (saddrb_1d(5 downto 4)) is
--*                         when "00" => sdata    <= sdoutb0_odd(sroic_cnt_1d);
--*                         when "01" => sdata    <= sdoutb1_odd(sroic_cnt_1d);
--*                         when "10" => sdata    <= sdoutb2_odd(sroic_cnt_1d);
--*                         when "11" => sdata    <= sdoutb3_odd(sroic_cnt_1d);
--*                         when others => sdata  <= sdoutb0_odd(sroic_cnt_1d);
--*                     end case;
--*
--*                 else
--*
--*                     case (saddrb_1d(5 downto 4)) is
--*                         when "00" => sdata    <= sdoutb0_even(sroic_cnt_1d);
--*                         when "01" => sdata    <= sdoutb1_even(sroic_cnt_1d);
--*                         when "10" => sdata    <= sdoutb2_even(sroic_cnt_1d);
--*                         when "11" => sdata    <= sdoutb3_even(sroic_cnt_1d);
--*                         when others => sdata  <= sdoutb0_even(sroic_cnt_1d);
--*                     end case;
--*
--*                 end if;
--*             else
--*                 sdata <= (others => '0');
--*             end if;
--*         end if;
--*     end process;

    --* ADC REV v0.00.08
    --# DPRAM output data mux with ADC reverse support
    process (iui_clk)
    begin
        if (iui_clk'event and iui_clk = '1') then
            if (iui_rstn = '0') then
                sdata <= (others => '0');
            else
                if (shsync_1d = '1') then
                    if (stoggle_portb_1d = '0') then
                        if (ADC_REV = '1') then
                            case (saddrb_1d(5 downto 4)) is
                                when "00"   => sdata <= sdoutb3_odd(sroic_cnt_1d);
                                when "01"   => sdata <= sdoutb2_odd(sroic_cnt_1d);
                                when "10"   => sdata <= sdoutb1_odd(sroic_cnt_1d);
                                when "11"   => sdata <= sdoutb0_odd(sroic_cnt_1d);
                                when others => sdata <= sdoutb3_odd(sroic_cnt_1d);
                            end case;
                        else
                            case (saddrb_1d(5 downto 4)) is
                                when "00"   => sdata <= sdoutb0_odd(sroic_cnt_1d);
                                when "01"   => sdata <= sdoutb1_odd(sroic_cnt_1d);
                                when "10"   => sdata <= sdoutb2_odd(sroic_cnt_1d);
                                when "11"   => sdata <= sdoutb3_odd(sroic_cnt_1d);
                                when others => sdata <= sdoutb0_odd(sroic_cnt_1d);
                            end case;
                        end if;

                    else
                        if (ADC_REV = '1') then
                            case (saddrb_1d(5 downto 4)) is
                                when "00"   => sdata <= sdoutb3_even(sroic_cnt_1d);
                                when "01"   => sdata <= sdoutb2_even(sroic_cnt_1d);
                                when "10"   => sdata <= sdoutb1_even(sroic_cnt_1d);
                                when "11"   => sdata <= sdoutb0_even(sroic_cnt_1d);
                                when others => sdata <= sdoutb3_even(sroic_cnt_1d);
                            end case;
                        else
                            case (saddrb_1d(5 downto 4)) is
                                when "00"   => sdata <= sdoutb0_even(sroic_cnt_1d);
                                when "01"   => sdata <= sdoutb1_even(sroic_cnt_1d);
                                when "10"   => sdata <= sdoutb2_even(sroic_cnt_1d);
                                when "11"   => sdata <= sdoutb3_even(sroic_cnt_1d);
                                when others => sdata <= sdoutb0_even(sroic_cnt_1d);
                            end case;
                        end if;
                    end if;
                else
                    sdata <= (others => '0');
                end if;
            end if;
        end if;
    end process;

    --# register width/height latch process
    process (iui_clk)
    begin
        if (iui_clk'event and iui_clk = '1') then
            if (iui_rstn = '0') then
                sreg_width  <= (others => '0');
                sreg_height <= (others => '0');
            else
                if (svsync_2d = '0') then
                    sreg_width  <= conv_std_logic_vector((ROIC_NUM2(GNR_MODEL) * ROIC_MAX_CH(GNR_MODEL)) / 4, 10);
                    sreg_height <= ireg_height;
                end if;
            end if;
        end if;
    end process;

    nodummy : if (ROIC_DUMMY_CH(GNR_MODEL) = 0) generate
    begin
        dumm_shsync_out <= shsync_2d;
        dumm_svsync_out <= svsync_2d;
        dumm_shcnt_out  <= shcnt_2d;
        dumm_svcnt_out  <= svcnt_2d;
        dumm_sdata_out  <= sdata;
    end generate nodummy;

    dummy : if (ROIC_DUMMY_CH(GNR_MODEL) > 0) generate

        component TI_ERASE_DUMMY
            generic (GNR_MODEL : string := "EXT1616R");
            port (
                iui_clk  : in  std_logic;
                iui_rstn : in  std_logic;

                ihsync : in    std_logic;
                ivsync : in    std_logic;
                ihcnt  : in    std_logic_vector(9 downto 0);
                ivcnt  : in    std_logic_vector(11 downto 0);
                idata  : in    std_logic_vector(63 downto 0);

                ireg_width  : in    std_logic_vector(11 downto 0);
                ireg_height : in    std_logic_vector(11 downto 0);

                ohsync : out   std_logic;
                ovsync : out   std_logic;
                ohcnt  : out   std_logic_vector(9 downto 0);
                ovcnt  : out   std_logic_vector(11 downto 0);
                odata  : out   std_logic_vector(63 downto 0)
            );
        end component;

    begin

        U_TI_ERASE_DUMMY : TI_ERASE_DUMMY
            generic map (GNR_MODEL => GNR_MODEL)
            port map (
                iui_clk  => iui_clk,
                iui_rstn => iui_rstn,

                ihsync => shsync_2d,
                ivsync => svsync_2d,
                ihcnt  => shcnt_2d,
                ivcnt  => svcnt_2d,
                idata  => sdata,

                ireg_width  => ireg_width,
                ireg_height => ireg_height,

                ohsync => dumm_shsync_out,
                ovsync => dumm_svsync_out,
                ohcnt  => dumm_shcnt_out,
                ovcnt  => dumm_svcnt_out,
                odata  => dumm_sdata_out
            );
    end generate dummy;

-- ### h flip fucntion 210611 ###
    nohflip : if (GLB_H_FLIP = '0') generate
    begin
        hflp_shsync_out <= dumm_shsync_out;
        hflp_svsync_out <= dumm_svsync_out;
        hflp_shcnt_out  <= dumm_shcnt_out;
        hflp_svcnt_out  <= dumm_svcnt_out;
        hflp_sdata_out  <= dumm_sdata_out;
    end generate nohflip;

    hflip : if (GLB_H_FLIP = '1') generate

        component TI_HORIZONTAL_FLIP
            generic (GNR_MODEL : string := "EXT1616R");
            port (
                iui_clk  : in  std_logic;
                iui_rstn : in  std_logic;

                ihsync : in    std_logic;
                ivsync : in    std_logic;
                ihcnt  : in    std_logic_vector(9 downto 0);
                ivcnt  : in    std_logic_vector(11 downto 0);
                idata  : in    std_logic_vector(63 downto 0);

                ireg_width  : in    std_logic_vector(11 downto 0);
                ireg_height : in    std_logic_vector(11 downto 0);

                ohsync : out   std_logic;
                ovsync : out   std_logic;
                ohcnt  : out   std_logic_vector(9 downto 0);
                ovcnt  : out   std_logic_vector(11 downto 0);
                odata  : out   std_logic_vector(63 downto 0)
            );
        end component;

    begin

        U_TI_HORIZONTAL_FLIP : TI_HORIZONTAL_FLIP
            generic map (GNR_MODEL => GNR_MODEL)
            port map (
                iui_clk  => iui_clk,
                iui_rstn => iui_rstn,

                ihsync => dumm_shsync_out,
                ivsync => dumm_svsync_out,
                ihcnt  => dumm_shcnt_out,
                ivcnt  => dumm_svcnt_out,
                idata  => dumm_sdata_out,

                ireg_width  => ireg_width,
                ireg_height => ireg_height,

                ohsync => hflp_shsync_out,
                ovsync => hflp_svsync_out,
                ohcnt  => hflp_shcnt_out,
                ovcnt  => hflp_svcnt_out,
                odata  => hflp_sdata_out
            );

    end generate hflip;

    ohsync <= hflp_shsync_out;
    ovsync <= hflp_svsync_out;
    ohcnt  <= hflp_shcnt_out;
    ovcnt  <= hflp_svcnt_out;
    odata  <= hflp_sdata_out;
--# make defect #230919
-- odata  <=
--             (others=> '0') when hflp_shcnt_out=1          and hflp_svcnt_out=1          else
--             (others=> '0') when hflp_shcnt_out=(1648/4)-2 and hflp_svcnt_out=1644-2     else
--             (others=> '0') when hflp_shcnt_out=(1648/4)-2 and hflp_svcnt_out=(1644/2)-2 else
--
--             (others=> '0') when hflp_svcnt_out=100 and hflp_shcnt_out=100 else
--             (others=> '0') when hflp_svcnt_out=100 and hflp_shcnt_out=101 else
--             (others=> '0') when hflp_svcnt_out=100 and hflp_shcnt_out=102 else
--             (others=> '0') when hflp_svcnt_out=101 and hflp_shcnt_out=101 else
--
--             (others=> '0') when hflp_svcnt_out=100 and hflp_shcnt_out=105 else
--             (others=> '0') when hflp_svcnt_out=101 and hflp_shcnt_out=105 else
--             (others=> '0') when hflp_svcnt_out=102 and hflp_shcnt_out=105 else
--             (others=> '0') when hflp_svcnt_out=103 and hflp_shcnt_out=105 else
--             (others=> '0') when hflp_svcnt_out=104 and hflp_shcnt_out=105 else
--             hflp_sdata_out;

--# move to upside 241202
--process (iroic_clk, iroic_rstn)
--begin
--    if(iroic_rstn = '0') then
--        stoggle_porta_1d <= (others => '0');
--        stoggle_porta_2d <= (others => '0');
--    elsif (iroic_clk'event and iroic_clk = '1') then
--        stoggle_porta_1d  <= stoggle_porta;
--        stoggle_porta_2d  <= stoggle_porta_1d;
--    end if;
--end process;

    --# signal delay and toggle CDC process
    process (iui_clk)
    begin
        if (iui_clk'event and iui_clk = '1') then
            if (iui_rstn = '0') then
                shsync_1d <= '0';
                svsync_1d <= '0';
                svcnt_1d  <= (others => '0');
                shcnt_1d  <= (others => '0');
                shsync_2d <= '0';
                svsync_2d <= '0';
                svcnt_2d  <= (others => '0');
                shcnt_2d  <= (others => '0');
            else
                stoggle_porta_1cd <= stoggle_porta;
                stoggle_porta_2cd <= stoggle_porta_1cd;
                stoggle_porta_3cd <= stoggle_porta_2cd;
                stoggle_porta_4cd <= stoggle_porta_3cd;
                stoggle_porta_cd  <= stoggle_porta_4cd;
                stoggle_portb_1d  <= stoggle_portb;

                shsync_1d <= shsync;
                svsync_1d <= svsync;
                svcnt_1d  <= svcnt;
                shcnt_1d  <= shcnt;
                shsync_2d <= shsync_1d;
                svsync_2d <= svsync_1d;
                svcnt_2d  <= svcnt_1d;
                shcnt_2d  <= shcnt_1d;
            end if;
        end if;
    end process;

    orefvcnt <= svcnt; -- 210205

    ila_debug : if (GEN_ILA_data_align = "ON") generate
    --* ila_debug : if(SIMULATION = "OFF") generate
        component ILA_DATA_ALIGN
            port (
                clk     : in    std_logic;
                probe0  : in    std_logic_vector(4 downto 0);
--              probe0  : in    std_logic_vector(11 downto 0);
                probe1  : in    std_logic_vector(7 downto 0);
                probe2  : in    std_logic_vector(7 downto 0);
                probe3  : in    std_logic_vector(7 downto 0);
                probe4  : in    std_logic_vector(7 downto 0);
                probe5  : in    std_logic_vector(15 downto 0);
                probe6  : in    std_logic_vector(15 downto 0);
                probe7  : in    std_logic_vector(15 downto 0);
                probe8  : in    std_logic_vector(15 downto 0);
                probe9  : in    tstate_dpram_data_align;
                probe10 : in    std_logic;
                probe11 : in    std_logic;
                probe12 : in    std_logic_vector(9 downto 0);
                probe13 : in    std_logic_vector(11 downto 0);
                probe14 : in    std_logic_vector(63 downto 0);
                probe15 : in    std_logic;
                probe16 : in    std_logic;
                probe17 : in    std_logic_vector(9 downto 0);
                probe18 : in    std_logic_vector(11 downto 0);
                probe19 : in    std_logic_vector(63 downto 0);
                probe20 : in    std_logic_vector(11 downto 0)
            );
        end component;

    begin
        U0_ILA_DATA_ALIGN : ILA_DATA_ALIGN
            port map (
                clk     => iroic_clk,
                probe0  => sena_tmp(6 downto 0),                              -- single7 dual14
                probe1  => saddra_tmp(0),                                      -- 8
                probe2  => saddra_tmp(1),                                      -- 8
                probe3  => saddra_tmp(2),                                      -- 8
                probe4  => align_done_trig_sh(7) & stoggle_porta(6 downto 0), -- 8
                probe5  => sdina_tmp(0),                                       -- 16
                probe6  => sdina_tmp(1),                                       -- 16
                probe7  => sdina_tmp(2),                                       -- 16
                probe8  => sdina_tmp(3),                                       -- 16
                probe9  => state_dpram,                                        -- 3
                probe10 => shsync_2d,                                          -- 1
                probe11 => svsync_2d,                                          -- 1
                probe12 => shcnt_2d,                                           -- 10
                probe13 => svcnt_2d,                                           -- 12
                probe14 => sdata,                                              -- 64
                probe15 => hflp_shsync_out,                                    -- 1
                probe16 => hflp_svsync_out,                                    -- 1
                probe17 => hflp_shcnt_out,                                     -- 10
                probe18 => hflp_svcnt_out,                                     -- 12
                probe19 => hflp_sdata_out,                                     -- 64
                probe20 => ivcnt                                               -- 12
            );
    end generate ila_debug;

    ila_debug_video : if (GEN_ILA_data_align_video = "ON") generate
    --* ila_debug_video : if(SIMULATION = "OFF") generate
        component ILA_DATA_ALIGN_VIDEO
            port (
                clk     : in    std_logic;
                probe0  : in    tstate_dpram_data_align;
                probe1  : in    std_logic;
                probe2  : in    std_logic;
                probe3  : in    std_logic_vector(9 downto 0);
                probe4  : in    std_logic_vector(11 downto 0);
                probe5  : in    std_logic_vector(63 downto 0);
                probe6  : in    std_logic;
                probe7  : in    std_logic;
                probe8  : in    std_logic_vector(9 downto 0);
                probe9  : in    std_logic_vector(11 downto 0);
                probe10 : in    std_logic_vector(63 downto 0);
                probe11 : in    std_logic_vector(11 downto 0)
            );
        end component;

        COMPONENT ila_align_2pixvertical
            PORT (
                clk     : IN STD_LOGIC;
                probe0  : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
                probe1  : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
                probe2  : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
                probe3  : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
                probe4  : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
                probe5  : IN tstate_dpram_data_align;
                probe6  : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
                probe7  : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
                probe8  : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
                probe9  : IN STD_LOGIC_VECTOR(11 DOWNTO 0);
                probe10 : IN STD_LOGIC_VECTOR(15 DOWNTO 0)
            );
        END COMPONENT;

    begin
--  U0_ILA_DATA_ALIGN_VIDEO : ILA_DATA_ALIGN_VIDEO
--      port map (
--          clk        => iui_clk,
--          probe0  => state_dpram,   -- 3
--          probe1  => shsync_2d,      -- 1
--          probe2  => svsync_2d,      -- 1
--          probe3  => shcnt_2d,      -- 10
--          probe4  => svcnt_2d,      -- 12
--          probe5  => sdata,          -- 64
--          probe6  => hflp_shsync_out,      -- 1
--          probe7  => hflp_svsync_out,      -- 1
--          probe8  => hflp_shcnt_out,      -- 10
--          probe9  => hflp_svcnt_out,      -- 12
--          probe10 => hflp_sdata_out,      -- 64
--          probe11 => ivcnt          -- 12
--      );

        u_ila_align_2pixvertical : ila_align_2pixvertical
            PORT MAP (
                clk       => iui_clk,
                probe0(0) => align_done_trig_sh(0)(7),            -- 1
                probe1    => saddra_tmp(0),                        -- 8
                probe2    => saddra_tmp(4),                        -- 8
                probe3    => (others => '0'), --# x"0000" + stoggle_porta -- 16
                probe4    => (others => '0'), --# x"0000" + ivcnt         -- 16
                probe5    => state_dpram,                          -- 3
                probe6(0) => shsync,                               -- 1
                probe7(0) => svsync,                               -- 1
                probe8    => shcnt,                                -- 10
                probe9    => svcnt,                                -- 12
                probe10   => sdata(16 - 1 downto 0)               -- 16
            );

    end generate ila_debug_video;

end architecture behavioral;
