library IEEE;
    use IEEE.STD_LOGIC_1164.ALL;
    use IEEE.STD_LOGIC_UNSIGNED.ALL;
    use IEEE.STD_LOGIC_ARITH.ALL;

    use WORK.TOP_HEADER.ALL;

entity TPC_PROC is
port (
    idata_clk       : in  std_logic;
    idata_rstn      : in  std_logic;

    ireg_gain_cal   : in  std_logic;
    ireg_offset_cal : in  std_logic;

    ireg_mpc_ctrl   : in  std_logic_vector(3 downto 0);
    ireg_mpc_num    : in  std_logic_vector(3 downto 0);
    ireg_mpc_point0 : in  std_logic_vector(15 downto 0);
    ireg_mpc_point1 : in  std_logic_vector(15 downto 0);
    ireg_mpc_point2 : in  std_logic_vector(15 downto 0);
    ireg_mpc_point3 : in  std_logic_vector(15 downto 0);

    itpc_rdata      : in  std_logic_vector(127 downto 0);
    iavg_rinfo      : in  std_logic_vector(31 downto 0);

    ihsync          : in  std_logic;
    ivsync          : in  std_logic;
    ivcnt           : in  std_logic_vector(11 downto 0);
    ihcnt           : in  std_logic_vector(11 downto 0);
    idata           : in  std_logic_vector(15 downto 0);

    ohsync          : out std_logic;
    ovsync          : out std_logic;
    ovcnt           : out std_logic_vector(11 downto 0);
    ohcnt           : out std_logic_vector(11 downto 0);
    odata           : out std_logic_vector(23 downto 0)
);
end TPC_PROC;

architecture Behavioral of TPC_PROC is

    constant DN100 : std_logic_vector(15 downto 0) := x"0064";

    component MULTI_16x16
    port (
        clk : in  std_logic;
        ce  : in  std_logic;
        a   : in  std_logic_vector(15 downto 0);
        b   : in  std_logic_vector(15 downto 0);
        p   : out std_logic_vector(31 downto 0)
    );
    end component;

    component sub_u24_s16
    port (
        A : in  std_logic_vector(23 downto 0);
        B : in  std_logic_vector(15 downto 0);
        S : out std_logic_vector(25 downto 0)
    );
    end component;

    signal sgain_cal   : std_logic;
    signal soffset_cal : std_logic;
    signal smpc_num    : std_logic_vector(3 downto 0);
    signal smpc_point0 : std_logic_vector(15 downto 0);
    signal smpc_point1 : std_logic_vector(15 downto 0);
    signal smpc_point2 : std_logic_vector(15 downto 0);
    signal smpc_point3 : std_logic_vector(15 downto 0);

    signal shsync_gain_cal  : std_logic;
    signal svsync_gain_cal  : std_logic;
    signal svcnt_gain_cal   : std_logic_vector(11 downto 0);
    signal shcnt_gain_cal   : std_logic_vector(11 downto 0);
    signal sdata_gain_cal   : std_logic_vector(23 downto 0);
    signal shsync_offset_cal : std_logic;
    signal svsync_offset_cal : std_logic;
    signal svcnt_offset_cal : std_logic_vector(11 downto 0);
    signal shcnt_offset_cal : std_logic_vector(11 downto 0);
    signal sdata_offset_cal : std_logic_vector(23 downto 0);
    signal shsync_out       : std_logic;
    signal svsync_out       : std_logic;
    signal svcnt_out        : std_logic_vector(11 downto 0);
    signal shcnt_out        : std_logic_vector(11 downto 0);
    signal sdata_out        : std_logic_vector(23 downto 0);

    signal scoeff_gain   : std_logic_vector(15 downto 0);
    signal scoeff_offset : std_logic_vector(15 downto 0);

    signal smulti_data : std_logic_vector(31 downto 0);

    signal shsync_1d : std_logic;
    signal shsync_2d : std_logic;
    signal shsync_3d : std_logic;
    signal shsync_4d : std_logic;
    signal svsync_1d : std_logic;
    signal svsync_2d : std_logic;
    signal svsync_3d : std_logic;
    signal svsync_4d : std_logic;
    signal shcnt_1d  : std_logic_vector(11 downto 0);
    signal shcnt_2d  : std_logic_vector(11 downto 0);
    signal shcnt_3d  : std_logic_vector(11 downto 0);
    signal shcnt_4d  : std_logic_vector(11 downto 0);
    signal svcnt_1d  : std_logic_vector(11 downto 0);
    signal svcnt_2d  : std_logic_vector(11 downto 0);
    signal svcnt_3d  : std_logic_vector(11 downto 0);
    signal svcnt_4d  : std_logic_vector(11 downto 0);
    signal sdata_1d  : std_logic_vector(15 downto 0);
    signal sdata_2d  : std_logic_vector(15 downto 0);
    signal sdata_3d  : std_logic_vector(15 downto 0);
    signal sdata_4d  : std_logic_vector(15 downto 0);

    signal scoeff_offset_1d : std_logic_vector(15 downto 0);
    signal scoeff_offset_2d : std_logic_vector(15 downto 0);
    signal scoeff_offset_3d : std_logic_vector(15 downto 0);
    signal scoeff_offset_4d : std_logic_vector(15 downto 0);
    signal sreg_gain_cal_1d : std_logic;
    signal sreg_gain_cal_2d : std_logic;
    signal sreg_gain_cal_3d : std_logic;
    signal sreg_offset_cal_1d : std_logic;
    signal sreg_offset_cal_2d : std_logic;
    signal sreg_offset_cal_3d : std_logic;
    signal sreg_mpc_num_1d    : std_logic_vector(3 downto 0);
    signal sreg_mpc_num_2d    : std_logic_vector(3 downto 0);
    signal sreg_mpc_num_3d    : std_logic_vector(3 downto 0);
    signal sreg_mpc_point0_1d : std_logic_vector(15 downto 0);
    signal sreg_mpc_point0_2d : std_logic_vector(15 downto 0);
    signal sreg_mpc_point0_3d : std_logic_vector(15 downto 0);
    signal sreg_mpc_point1_1d : std_logic_vector(15 downto 0);
    signal sreg_mpc_point1_2d : std_logic_vector(15 downto 0);
    signal sreg_mpc_point1_3d : std_logic_vector(15 downto 0);
    signal sreg_mpc_point2_1d : std_logic_vector(15 downto 0);
    signal sreg_mpc_point2_2d : std_logic_vector(15 downto 0);
    signal sreg_mpc_point2_3d : std_logic_vector(15 downto 0);
    signal sreg_mpc_point3_1d : std_logic_vector(15 downto 0);
    signal sreg_mpc_point3_2d : std_logic_vector(15 downto 0);
    signal sreg_mpc_point3_3d : std_logic_vector(15 downto 0);

    signal sub_offset26b : std_logic_vector(25 downto 0);

begin

    --# Latch calibration control and MPC parameters on vsync boundary
    process(idata_clk)
    begin
        if (idata_clk'event and idata_clk = '1') then
            if (idata_rstn = '0') then
                sgain_cal   <= '0';
                soffset_cal <= '0';

                smpc_num    <= (others => '0');
                smpc_point0 <= (others => '0');
                smpc_point1 <= (others => '0');
                smpc_point2 <= (others => '0');
                smpc_point3 <= (others => '0');
            else
                if (svsync_offset_cal = '0') then
                    sgain_cal   <= sreg_gain_cal_3d;
                    soffset_cal <= sreg_offset_cal_3d;
                end if;
                smpc_num    <= sreg_mpc_num_3d;
                smpc_point0 <= sreg_mpc_point0_3d;
                smpc_point1 <= sreg_mpc_point1_3d;
                smpc_point2 <= sreg_mpc_point2_3d;
                smpc_point3 <= sreg_mpc_point3_3d;
            end if;
        end if;
    end process;

    --# Select TPC gain/offset coefficients based on MPC point count and pixel value
    process(idata_clk)
    begin
        if (idata_clk'event and idata_clk = '1') then
            if (idata_rstn = '0') then
                scoeff_gain   <= (others => '0');
                scoeff_offset <= (others => '0');
            else
                if (sgain_cal = '1') then
                    case smpc_num is
                        when x"2" =>
                            scoeff_gain   <= itpc_rdata(31 downto 16);
                            scoeff_offset <= itpc_rdata(15 downto 0);

                        when x"3" =>
                            if (idata < smpc_point0) then
                                scoeff_gain   <= itpc_rdata(31 downto 16);
                                scoeff_offset <= itpc_rdata(15 downto 0);
                            else
                                scoeff_gain   <= itpc_rdata(63 downto 48);
                                scoeff_offset <= itpc_rdata(47 downto 32);
                            end if;

                        when x"4" =>
                            if (idata < smpc_point0) then
                                scoeff_gain   <= itpc_rdata(31 downto 16);
                                scoeff_offset <= itpc_rdata(15 downto 0);
                            elsif (idata < smpc_point1) then
                                scoeff_gain   <= itpc_rdata(63 downto 48);
                                scoeff_offset <= itpc_rdata(47 downto 32);
                            else
                                scoeff_gain   <= itpc_rdata(95 downto 80);
                                scoeff_offset <= itpc_rdata(79 downto 64);
                            end if;

                        when x"5" =>
                            if (idata < smpc_point0) then
                                scoeff_gain   <= itpc_rdata(31 downto 16);
                                scoeff_offset <= itpc_rdata(15 downto 0);
                            elsif (idata < smpc_point1) then
                                scoeff_gain   <= itpc_rdata(63 downto 48);
                                scoeff_offset <= itpc_rdata(47 downto 32);
                            elsif (idata < smpc_point2) then
                                scoeff_gain   <= itpc_rdata(95 downto 80);
                                scoeff_offset <= itpc_rdata(79 downto 64);
                            else
                                scoeff_gain   <= itpc_rdata(127 downto 112);
                                scoeff_offset <= itpc_rdata(111 downto 96);
                            end if;

                        when others =>
                            scoeff_gain   <= (others => '0');
                            scoeff_offset <= (others => '0');
                    end case;
                elsif (soffset_cal = '1') then
                    if (smpc_num /= 0) then
                        scoeff_gain   <= (others => '0');
                        scoeff_offset <= iavg_rinfo(31 downto 16) - DN100;
                    else
                        scoeff_gain   <= (others => '0');
                        scoeff_offset <= (others => '0');
                    end if;
                else
                    scoeff_gain   <= (others => '0');
                    scoeff_offset <= (others => '0');
                end if;
            end if;
        end if;
    end process;

    U0_MULTI_16x16 : MULTI_16x16 -- 3 Delay (Total 4 Delay)
    port map (
        clk => idata_clk,
        ce  => idata_rstn,
        a   => sdata_1d,
        b   => scoeff_gain,
        p   => smulti_data
    );

    --# Apply gain calibration to pixel data
    process(idata_clk)
    begin
        if (idata_clk'event and idata_clk = '1') then
            if (idata_rstn = '0') then
                shsync_gain_cal <= '0';
                svsync_gain_cal <= '0';
                svcnt_gain_cal  <= (others => '0');
                shcnt_gain_cal  <= (others => '0');
                sdata_gain_cal  <= (others => '0');
            else
                shsync_gain_cal <= shsync_4d;
                svsync_gain_cal <= svsync_4d;
                svcnt_gain_cal  <= svcnt_4d;
                shcnt_gain_cal  <= shcnt_4d;

                if (sgain_cal = '1') then
                    sdata_gain_cal <= smulti_data(31 downto 8);
                else
                    sdata_gain_cal <= (x"00" & sdata_4d);
                end if;
            end if;
        end if;
    end process;

    --# Apply offset calibration with signed subtraction and saturation
    process(idata_clk)
    begin
        if (idata_clk'event and idata_clk = '1') then
            if (idata_rstn = '0') then
                shsync_offset_cal <= '0';
                svsync_offset_cal <= '0';
                svcnt_offset_cal  <= (others => '0');
                shcnt_offset_cal  <= (others => '0');
                sdata_offset_cal  <= (others => '0');
            else
                shsync_offset_cal <= shsync_gain_cal;
                svsync_offset_cal <= svsync_gain_cal;
                svcnt_offset_cal  <= svcnt_gain_cal;
                shcnt_offset_cal  <= shcnt_gain_cal;

--              if(soffset_cal = '1') then
--                  if(sdata_gain_cal > scoeff_offset_4d) then
--                      sdata_offset_cal    <= sdata_gain_cal - scoeff_offset_4d;
--                  else
--                      sdata_offset_cal    <= (others => '0');
--                  end if;
--              else
--                  sdata_offset_cal    <= sdata_gain_cal;
--              end if;
                -- ### offset signed 16 bit mbh210113
                if (soffset_cal = '1') then
                    if sub_offset26b(26 - 1) = '1' then -- minus
                        sdata_offset_cal <= (others => '0');
                    --elsif 2**24-1 < sub_offset26b then  -- 24b over
                    elsif sub_offset26b(24) = '1' then -- 24b over
                        sdata_offset_cal <= (others => '1');
                    else
                        sdata_offset_cal <= sub_offset26b(24 - 1 downto 0);
                    end if;
                else
                    sdata_offset_cal <= sdata_gain_cal;
                end if;
            end if;
        end if;
    end process;

    u_sub_u24_s16 : sub_u24_s16
    port map (
        A => sdata_gain_cal,   -- 24b
        B => scoeff_offset_4d, -- 16b
        S => sub_offset26b     -- 26b
    );

    --# Register output signals
    process(idata_clk)
    begin
        if (idata_clk'event and idata_clk = '1') then
            if (idata_rstn = '0') then
                shsync_out <= '0';
                svsync_out <= '0';
                svcnt_out  <= (others => '0');
                shcnt_out  <= (others => '0');
                sdata_out  <= (others => '0');
            else
                shsync_out <= shsync_offset_cal;
                svsync_out <= svsync_offset_cal;
                svcnt_out  <= svcnt_offset_cal;
                shcnt_out  <= shcnt_offset_cal;
                sdata_out  <= sdata_offset_cal;
            end if;
        end if;
    end process;

    ohsync <= shsync_out;
    ovsync <= svsync_out;
    ovcnt  <= svcnt_out;
    ohcnt  <= shcnt_out;
    odata  <= sdata_out;

    --# Delay pipeline for sync/count/data and register inputs (3-stage)
    process(idata_clk)
    begin
        if (idata_clk'event and idata_clk = '1') then
            if (idata_rstn = '0') then
                shsync_1d <= '0';
                shsync_2d <= '0';
                shsync_3d <= '0';
                shsync_4d <= '0';
                svsync_1d <= '0';
                svsync_2d <= '0';
                svsync_3d <= '0';
                svsync_4d <= '0';
                svcnt_1d  <= (others => '0');
                svcnt_2d  <= (others => '0');
                svcnt_3d  <= (others => '0');
                svcnt_4d  <= (others => '0');
                shcnt_1d  <= (others => '0');
                shcnt_2d  <= (others => '0');
                shcnt_3d  <= (others => '0');
                shcnt_4d  <= (others => '0');
                sdata_1d  <= (others => '0');
                sdata_2d  <= (others => '0');
                sdata_3d  <= (others => '0');
                sdata_4d  <= (others => '0');

                scoeff_offset_1d <= (others => '0');
                scoeff_offset_2d <= (others => '0');
                scoeff_offset_3d <= (others => '0');
                scoeff_offset_4d <= (others => '0');

                sreg_gain_cal_1d   <= '0';
                sreg_gain_cal_2d   <= '0';
                sreg_gain_cal_3d   <= '0';
                sreg_offset_cal_1d <= '0';
                sreg_offset_cal_2d <= '0';
                sreg_offset_cal_3d <= '0';
                sreg_mpc_num_1d    <= (others => '0');
                sreg_mpc_num_2d    <= (others => '0');
                sreg_mpc_num_3d    <= (others => '0');
                sreg_mpc_point0_1d <= (others => '0');
                sreg_mpc_point0_2d <= (others => '0');
                sreg_mpc_point0_3d <= (others => '0');
                sreg_mpc_point1_1d <= (others => '0');
                sreg_mpc_point1_2d <= (others => '0');
                sreg_mpc_point1_3d <= (others => '0');
                sreg_mpc_point2_1d <= (others => '0');
                sreg_mpc_point2_2d <= (others => '0');
                sreg_mpc_point2_3d <= (others => '0');
                sreg_mpc_point3_1d <= (others => '0');
                sreg_mpc_point3_2d <= (others => '0');
                sreg_mpc_point3_3d <= (others => '0');
            else
                shsync_1d <= ihsync;
                shsync_2d <= shsync_1d;
                shsync_3d <= shsync_2d;
                shsync_4d <= shsync_3d;
                svsync_1d <= ivsync;
                svsync_2d <= svsync_1d;
                svsync_3d <= svsync_2d;
                svsync_4d <= svsync_3d;
                svcnt_1d  <= ivcnt;
                svcnt_2d  <= svcnt_1d;
                svcnt_3d  <= svcnt_2d;
                svcnt_4d  <= svcnt_3d;
                shcnt_1d  <= ihcnt;
                shcnt_2d  <= shcnt_1d;
                shcnt_3d  <= shcnt_2d;
                shcnt_4d  <= shcnt_3d;
                sdata_1d  <= idata;
                sdata_2d  <= sdata_1d;
                sdata_3d  <= sdata_2d;
                sdata_4d  <= sdata_3d;

                scoeff_offset_1d <= scoeff_offset;
                scoeff_offset_2d <= scoeff_offset_1d;
                scoeff_offset_3d <= scoeff_offset_2d;
                scoeff_offset_4d <= scoeff_offset_3d;

                sreg_gain_cal_1d   <= ireg_gain_cal;
                sreg_gain_cal_2d   <= sreg_gain_cal_1d;
                sreg_gain_cal_3d   <= sreg_gain_cal_2d;
                sreg_offset_cal_1d <= ireg_offset_cal;
                sreg_offset_cal_2d <= sreg_offset_cal_1d;
                sreg_offset_cal_3d <= sreg_offset_cal_2d;
                sreg_mpc_num_1d    <= ireg_mpc_num;
                sreg_mpc_num_2d    <= sreg_mpc_num_1d;
                sreg_mpc_num_3d    <= sreg_mpc_num_2d;
                sreg_mpc_point0_1d <= ireg_mpc_point0;
                sreg_mpc_point0_2d <= sreg_mpc_point0_1d;
                sreg_mpc_point0_3d <= sreg_mpc_point0_2d;
                sreg_mpc_point1_1d <= ireg_mpc_point1;
                sreg_mpc_point1_2d <= sreg_mpc_point1_1d;
                sreg_mpc_point1_3d <= sreg_mpc_point1_2d;
                sreg_mpc_point2_1d <= ireg_mpc_point2;
                sreg_mpc_point2_2d <= sreg_mpc_point2_1d;
                sreg_mpc_point2_3d <= sreg_mpc_point2_2d;
                sreg_mpc_point3_1d <= ireg_mpc_point3;
                sreg_mpc_point3_2d <= sreg_mpc_point3_1d;
                sreg_mpc_point3_3d <= sreg_mpc_point3_2d;
            end if;
        end if;
    end process;

end Behavioral;
