library IEEE;
    use IEEE.STD_LOGIC_1164.ALL;
    use IEEE.STD_LOGIC_ARITH.ALL;
    use IEEE.STD_LOGIC_UNSIGNED.ALL;

    use WORK.TOP_HEADER.ALL;

entity CAL_FPS is
generic (
    GNR_MODEL : string := "EXT1616R"
);
port (
    imain_clk          : in  std_logic;
    imain_rstn         : in  std_logic;

    iext_trig          : in  std_logic;

    oreg_ext_exp_time  : out std_logic_vector(31 downto 0);
    oreg_ext_frame_time : out std_logic_vector(31 downto 0)
);
end CAL_FPS;

architecture Behavioral of CAL_FPS is

    type tstate_trig is (
        s_IDLE,
        s_EWT,
        s_SCAN,
        s_CAL
    );

    signal state_trig  : tstate_trig;

    signal slow_cnt    : std_logic_vector(31 downto 0);
    signal sall_cnt    : std_logic_vector(31 downto 0);
    signal sexp_time   : std_logic_vector(31 downto 0);
    signal sframe_time : std_logic_vector(31 downto 0);

begin

    --# External trigger FPS calculation state machine
    process(imain_clk)
    begin
        if(imain_clk'event and imain_clk = '1') then
            if(imain_rstn = '0') then
                state_trig  <= s_IDLE;

                slow_cnt    <= (others => '0');
                sall_cnt    <= (others => '0');
                sexp_time   <= (others => '0');
                sframe_time <= (others => '0');
            else
                case (state_trig) is
                    when s_IDLE  =>
                        if(iext_trig = '1') then
                            state_trig <= s_EWT;
                        end if;

                        slow_cnt <= (others => '0');
                        sall_cnt <= (others => '0');

                    when s_EWT   =>
                        if(iext_trig = '0') then
                            state_trig <= s_SCAN;
                        else
                            if(sall_cnt >= T_10S(GNR_MODEL)) then
                                state_trig <= s_IDLE;
                            end if;
                        end if;

                        slow_cnt <= slow_cnt + '1';
                        sall_cnt <= sall_cnt + '1';

                    when s_SCAN  =>
                        if(iext_trig = '1') then
                            state_trig <= s_CAL;
                        else
                            if(sall_cnt >= T_10S(GNR_MODEL)) then
                                state_trig <= s_IDLE;
                            end if;
                        end if;

                        sall_cnt <= sall_cnt + '1';

                    when s_CAL   =>
                        state_trig  <= s_IDLE;
                        sexp_time   <= slow_cnt;
                        sframe_time <= sall_cnt;

                    when others  =>
                        NULL;
                end case;
            end if;
        end if;
    end process;

    oreg_ext_exp_time   <= sexp_time;
    oreg_ext_frame_time <= sframe_time;

end Behavioral;
