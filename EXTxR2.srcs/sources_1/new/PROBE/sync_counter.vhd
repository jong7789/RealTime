----------------------------------------------------------------------------------
-- Company: DRTech
-- Engineer: bhmoon
--
-- Create Date: 2021/03/25 09:10:51
-- Design Name:
-- Module Name: sync_counter - Behavioral
-- Project Name:
-- Target Devices:
-- Tool Versions:
-- Description:
--
-- Dependencies:
--
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
----------------------------------------------------------------------------------

library IEEE;
    use IEEE.STD_LOGIC_1164.ALL;
    use IEEE.STD_LOGIC_ARITH.ALL;
    use IEEE.STD_LOGIC_UNSIGNED.ALL;

library UNISIM;
    use UNISIM.VComponents.all;

entity sync_counter is
    generic (
        sysclkhz : integer   := 100_000_000;
        vio      : std_logic := '1';
        para     : integer -- := 4 -- 4 or 1
    );
    port (
        ISYSCLK : in    std_logic;

        ICLK           : in    std_logic;
        IVSYNC         : in    std_logic;
        IHSYNC         : in    std_logic;
        IDATA          : in    std_logic_vector(16 * para - 1 downto 0);
        IREG_CTRL      : in    std_logic_vector(32 - 1 downto 0);
        OREG_CNT       : out   std_logic_vector(32 - 1 downto 0);
        OREG_DATA_AvCn : out   std_logic_vector(32 - 1 downto 0);
        OREG_DATA_BgLw : out   std_logic_vector(32 - 1 downto 0)
    );
end entity sync_counter;

architecture behavioral of sync_counter is

    constant ms500 : integer := sysclkhz / 2;
    constant ms100 : integer := sysclkhz / 10;

    -- ##### img_avg #####
--  constant para : integer := 4; -- b'64 =4 or b'16=1

    component IMG_AVG
        generic (
            para : integer -- := 4 -- 4 or 1
        );
        port (
            iclk   : in    std_logic;
            ivsync : in    std_logic;
            ihsync : in    std_logic;
            idata  : in    std_logic_vector((para * 16) - 1 downto 0);

            oreg_img_avg : out   std_logic_vector(32 - 1 downto 0)
        );
    end component;

    signal clk  : std_logic;
    signal sclk : std_logic;

    signal VsyncSh : std_logic_vector(8 - 1 downto 0) := (others => '0');
    signal HsyncSh : std_logic_vector(8 - 1 downto 0) := (others => '0');

    type   type_dsh is array (8 - 1 downto 0) of std_logic_vector(16 * para - 1 downto 0);
    signal datash    : type_dsh := (others => (others => '0'));
    signal DataLatch : std_logic_vector(16 - 1 downto 0) := (others => '0');
    signal DataTrigLatch : std_logic_vector(16 - 1 downto 0) := (others => '0');

    signal HLenCnt : std_logic_vector(16 - 1 downto 0) := (others => '0');
    signal HLenLat : std_logic_vector(16 - 1 downto 0) := (others => '0');
    signal HNumCnt : std_logic_vector(16 - 1 downto 0) := (others => '0');
    signal HNumLat : std_logic_vector(16 - 1 downto 0) := (others => '0');

    signal sysVsyncSh : std_logic_vector(8 - 1 downto 0) := (others => '0');
    signal VDeadCnt   : std_logic_vector(32 - 1 downto 0) := (others => '0');
    signal VDead      : std_logic := '0';

    signal sysHsyncSh : std_logic_vector(8 - 1 downto 0) := (others => '0');
    signal HDeadCnt   : std_logic_vector(32 - 1 downto 0) := (others => '0');
    signal HDead      : std_logic := '0';

    signal sreg_img_avg : std_logic_vector(32 - 1 downto 0) := (others => '0');

    signal Big    : std_logic_vector(16 - 1 downto 0) := (others => '0');
    signal Low    : std_logic_vector(16 - 1 downto 0) := (others => '1');
    signal BigLat : std_logic_vector(16 - 1 downto 0) := (others => '0');
    signal LowLat : std_logic_vector(16 - 1 downto 0) := (others => '1');

    signal Big1  : std_logic_vector(16 - 1 downto 0) := (others => '0');
    signal Low1  : std_logic_vector(16 - 1 downto 0) := (others => '1');
    signal Big2  : std_logic_vector(16 - 1 downto 0) := (others => '0');
    signal Low2  : std_logic_vector(16 - 1 downto 0) := (others => '1');
    signal Big3  : std_logic_vector(16 - 1 downto 0) := (others => '0');
    signal Low3  : std_logic_vector(16 - 1 downto 0) := (others => '1');
    signal Big4  : std_logic_vector(16 - 1 downto 0) := (others => '0');
    signal Low4  : std_logic_vector(16 - 1 downto 0) := (others => '1');

    signal Big12 : std_logic_vector(16 - 1 downto 0) := (others => '0');
    signal Low12 : std_logic_vector(16 - 1 downto 0) := (others => '1');
    signal Big34 : std_logic_vector(16 - 1 downto 0) := (others => '0');
    signal Low34 : std_logic_vector(16 - 1 downto 0) := (others => '1');

    signal s1sCnt  : std_logic_vector(32 - 1 downto 0) := (others => '0');
    signal s1sTrig : std_logic := '0';
    -- signal frameCnt : std_logic_vector(8  - 1 downto 0) := (others => '1');
    --# frame use 7bit and msb 1bit make 8 times with 7 bit
    signal frameCnt       : std_logic_vector(10 - 1 downto 0) := (others => '1');
    signal frameCntLat    : std_logic_vector(8 - 1 downto 0)  := (others => '1');
    signal Dead           : std_logic := '0';

    signal sreg_sync_ctrl_d0 : std_logic_vector(32 - 1 downto 0) := (others => '0');
    signal sreg_sync_ctrl_d1 : std_logic_vector(32 - 1 downto 0) := (others => '0');
    signal sreg_sync_ctrl_d2 : std_logic_vector(32 - 1 downto 0) := (others => '0');
    signal HLenTrigLat       : std_logic_vector(16 - 1 downto 0) := (others => '0');
    signal HNumTrigLat       : std_logic_vector(16 - 1 downto 0) := (others => '0');
    signal frameFreerunCnt   : std_logic_vector(8 - 1 downto 0)  := (others => '0');

    signal pixelCnt    : std_logic_vector(32 - 1 downto 0) := (others => '0');
    signal pixelCntLat : std_logic_vector(32 - 1 downto 0) := (others => '0');

    signal totframeCnt : std_logic_vector(16 - 1 downto 0) := (others => '0');

begin

    -- ###############
    -- ##### vio #####

    debug_gen : if (vio = '1') generate

        component vio_sync_counter
            port (
                clk       : in    std_logic;
                probe_in0 : in    std_logic; -- _VECTOR(0 DOWNTO 0);
                probe_in1 : in    std_logic; -- _VECTOR(0 DOWNTO 0);
                probe_in2 : in    std_logic_vector(15 downto 0);
                probe_in3 : in    std_logic_vector(15 downto 0);
                probe_in4 : in    std_logic_vector(15 downto 0);
                probe_in5 : in    std_logic_vector(15 downto 0);
                probe_in6 : in    std_logic_vector(15 downto 0);
                probe_in7 : in    std_logic_vector(15 downto 0)
            );
        end component;

        component ila_sync_counter
            port (
                clk    : in    std_logic;
                probe0 : in    std_logic; -- _VECTOR(0 DOWNTO 0);
                probe1 : in    std_logic; -- _VECTOR(0 DOWNTO 0);
                probe2 : in    std_logic_vector(15 downto 0);
                probe3 : in    std_logic_vector(15 downto 0);
                probe4 : in    std_logic_vector(15 downto 0)
            );
        end component;

    begin
--        u_vio_sync_counter : vio_sync_counter
--            port map (
--                clk       => clk,
--                probe_in0 => VDead,
--                probe_in1 => HDead,
--                probe_in2 => HLenLat,
--                probe_in3 => HNumLat,
--                probe_in4 => DataLatch,
--                probe_in5 => sreg_img_avg(16 - 1 downto 0),
--                probe_in6 => LowLat,
--                probe_in7 => BigLat
--            );
        u_ila_sync_counter : ila_sync_counter
            port map (
                clk    => clk,
                probe0 => IVSYNC,                  -- 1
                probe1 => IHSYNC,                  -- 1
                probe2 => IDATA(16 - 1 downto 0),  -- 16
                probe3 => HLenCnt,                 -- 16
                probe4 => HNumCnt                  -- 16
            );

    end generate debug_gen;

    -- #########################
    -- ##### sysclk domain #####
    -- ##### dead check  #####

    sclk <= ISYSCLK;

    --# frame rate count, vsync dead check, and total frame count in sysclk domain
    process (sclk)
    begin
        if sclk'event and sclk = '1' then
            --
            sysVsyncSh <= sysVsyncSh(sysVsyncSh'left - 1 downto 0) & ivsync;
            -- ##### frame rate count
            if s1sCnt < sysclkhz then
                s1sCnt  <= s1sCnt + '1';
                s1sTrig <= '0';
            else
                s1sCnt  <= (others => '0');
                s1sTrig <= '1';
            end if;

            if s1sTrig = '1' then
                if frameCnt < 2 ** 7 - 1 then --# 230515
                    frameCntLat <= '0' & frameCnt(7 - 1 downto 0);
                else --# if over 127, 3 bit shift
                    frameCntLat <= '1' & frameCnt(10 - 1 downto 3);
                end if;
                frameCnt <= (others => '0');
            else
                if sysVsyncSh(4) = '1' and sysVsyncSh(3) = '0' and
                   --# frameCnt < 2**8-1 then
                   frameCnt < 2 ** 10 - 1 then
                    frameCnt <= frameCnt + '1';
                end if;
            end if;

            -- ##### Dead check V

            if sysVsyncSh(4) /= sysVsyncSh(3) then
                VDeadCnt <= (others => '0');
            elsif VDeadCnt < ms500 then -- 0.5 sec
                VDeadCnt <= VDeadCnt + '1';
            end if;

            if VDeadCnt = ms500 then
                VDead <= '1';
            else
                VDead <= '0';
            end if;

            if sysVsyncSh(4) = '1' and sysVsyncSh(3) = '0' then
                totframeCnt <= totframeCnt + '1';
            end if;

            --
        end if;
    end process;

    --# hsync dead check in sysclk domain
    process (sclk) -- dead check H
    begin
        if sclk'event and sclk = '1' then
            --
            sysHsyncSh <= sysHsyncSh(sysHsyncSh'left - 1 downto 0) & ihsync;

            if sysHsyncSh(4) /= sysHsyncSh(3) then
                HDeadCnt <= (others => '0');
            elsif HDeadCnt < ms100 then
                HDeadCnt <= HDeadCnt + '1';
            end if;

            if HDeadCnt = ms100 then -- 0.1 sec
                HDead <= '1';
            else
                HDead <= '0';
            end if;
            --
        end if;
    end process;

    -- ############################
    -- ##### video clk domain #####
    -- ##### sync counter    #####

    clk <= ICLK;

    --# sync counter: h-length, h-number, data latch in video clk domain
    process (clk)
    begin
        if clk'event and clk = '1' then
            --
            VsyncSh <= VsyncSh(VsyncSh'left - 1 downto 0) & ivsync;
            HsyncSh <= HsyncSh(HsyncSh'left - 1 downto 0) & ihsync;
--          datash  <= datash(datash'left - 1 downto 0) & IDATA;
            datash(0) <= IDATA;

            if HsyncSh(0) = '1' then -- ### H Length
                HLenCnt <= HLenCnt + '1';
            elsif HsyncSh(1) = '1' and HsyncSh(0) = '0' then
                HLenLat <= HLenCnt;
                HLenCnt <= (others => '0');
            end if;

            if VsyncSh(0) = '1' and -- ### H Number
               HsyncSh(1) = '1' and HsyncSh(0) = '0' then
                HNumCnt <= HNumCnt + '1';
            elsif VsyncSh(1) = '1' and VsyncSh(0) = '0' then
                HNumLat <= HNumCnt;
                HNumCnt <= (others => '0');
            end if;

--            if HLenLat(16 - 1 downto 1) = HLenCnt and -- center pixel position
--               HNumLat(16 - 1 downto 1) = HNumCnt then
--                DataLatch <= datash(0)(16 - 1 downto 0);
--            end if;

            if para = 1 then
                if sreg_sync_ctrl_d2(16 * 1 - 1 downto 16 * 0) = HLenCnt and --# pixel REG 0x24C position 240904
                   sreg_sync_ctrl_d2(16 * 2 - 1 downto 16 * 1) = HNumCnt then
                    DataLatch <= datash(0)(16 - 1 downto 0);
                end if;
            elsif para = 4 then
                if sreg_sync_ctrl_d2(16 - 1 downto 2) = HLenCnt and --# pixel REG 0x24C position 240904
                   sreg_sync_ctrl_d2(16 + 16 - 1 downto 16) = HNumCnt then
                    case sreg_sync_ctrl_d2(1 downto 0) is
                        when "00"   => DataLatch <= datash(0)(16 * 1 - 1 downto 16 * 0);
                        when "01"   => DataLatch <= datash(0)(16 * 2 - 1 downto 16 * 1);
                        when "10"   => DataLatch <= datash(0)(16 * 3 - 1 downto 16 * 2);
                        when "11"   => DataLatch <= datash(0)(16 * 4 - 1 downto 16 * 3);
                        when others => null;
                    end case;
                end if;
            end if;

            if VsyncSh(1) = '1' and VsyncSh(0) = '0' then
                frameFreerunCnt <= frameFreerunCnt + '1';
            end if;
            sreg_sync_ctrl_d0 <= IREG_CTRL;
            sreg_sync_ctrl_d1 <= sreg_sync_ctrl_d0;
            sreg_sync_ctrl_d2 <= sreg_sync_ctrl_d1;
--            if sreg_sync_ctrl_d2(0) /= sreg_sync_ctrl_d1(0) then
--                HNumTrigLat <= HNumCnt;
--                HLenTrigLat <= HLenCnt;
--                DataTrigLatch <= datash(0)(16 - 1 downto 0);
--            end if;
            --
        end if;
    end process;

    -- ###################
    -- ##### IMG AVG #####
--c_IMG_AVG0 : IMG_AVG
--    generic map (
--        para => para -- 4 or 1
--    )
--    port map (
--        iclk         => ICLK,
--        ivsync       => IVSYNC,
--        ihsync       => IHSYNC,
--        idata        => IDATA,
--        oreg_img_avg => sreg_img_avg
--    );

    -- ########################
    -- ##### Bigest lowest ####
    --# find biggest and lowest pixel values per frame
    process (clk)
    begin
        if clk'event and clk = '1' then
            --
            if VsyncSh(0) = '1' and HsyncSh(0) = '1' then
                if para = 4 then
                    if Big1 < datash(0)(16 * 1 - 1 downto 16 * 0) then Big1 <= datash(0)(16 * 1 - 1 downto 16 * 0); end if;
                    if Big2 < datash(0)(16 * 2 - 1 downto 16 * 1) then Big2 <= datash(0)(16 * 2 - 1 downto 16 * 1); end if;
                    if Big3 < datash(0)(16 * 3 - 1 downto 16 * 2) then Big3 <= datash(0)(16 * 3 - 1 downto 16 * 2); end if;
                    if Big4 < datash(0)(16 * 4 - 1 downto 16 * 3) then Big4 <= datash(0)(16 * 4 - 1 downto 16 * 3); end if;
                    if Big1  > Big2  then Big12 <= Big1;  else Big12 <= Big2;  end if;
                    if Big3  > Big4  then Big34 <= Big3;  else Big34 <= Big4;  end if;
                    if Big12 > Big34 then Big   <= Big12; else Big   <= Big34; end if;
                    if Low1 > datash(0)(16 * 1 - 1 downto 16 * 0) then Low1 <= datash(0)(16 * 1 - 1 downto 16 * 0); end if;
                    if Low2 > datash(0)(16 * 2 - 1 downto 16 * 1) then Low2 <= datash(0)(16 * 2 - 1 downto 16 * 1); end if;
                    if Low3 > datash(0)(16 * 3 - 1 downto 16 * 2) then Low3 <= datash(0)(16 * 3 - 1 downto 16 * 2); end if;
                    if Low4 > datash(0)(16 * 4 - 1 downto 16 * 3) then Low4 <= datash(0)(16 * 4 - 1 downto 16 * 3); end if;
                    if Low1  < Low2  then Low12 <= Low1;  else Low12 <= Low2;  end if;
                    if Low3  < Low4  then Low34 <= Low3;  else Low34 <= Low4;  end if;
                    if Low12 < Low34 then Low   <= Low12; else Low   <= Low34; end if;
                else
                    if Big < datash(0) then
                        Big <= datash(0);
                    end if;
                    if datash(0) < Low then
                        Low <= datash(0);
                    end if;
                end if;
            elsif VsyncSh(1) = '1' and VsyncSh(0) = '0' then

                BigLat <= Big;
                LowLat <= Low;
                Big    <= (others => '0');
                Low    <= (others => '1');

                Big1  <= (others => '0');
                Big2  <= (others => '0');
                Big3  <= (others => '0');
                Big4  <= (others => '0');
                Big12 <= (others => '0');
                Big34 <= (others => '0');
                Low1  <= (others => '1');
                Low2  <= (others => '1');
                Low3  <= (others => '1');
                Low4  <= (others => '1');
                Low12 <= (others => '1');
                Low34 <= (others => '1');
            end if;
            --
        end if;
    end process;

    -- ############################
    -- ##### data pixel counter ###
    --# count active pixels per frame
    process (clk)
    begin
        if clk'event and clk = '1' then
            --
            if VsyncSh(0) = '1' then
                if HsyncSh(0) = '1' then
                    pixelCnt <= pixelCnt + '1';
                end if;
            elsif VsyncSh(1) = '1' and VsyncSh(0) = '0' then
                pixelCntLat <= pixelCnt;
                pixelCnt    <= (others => '0');
            end if;
            --
        end if;
    end process;

    -- ###################
    -- ##### OUT PORT ####
    Dead <= '1' when frameCntLat = 0 or VDead = '1' or HDead = '1' else
            '0';
    -- #################################
    -- ### normal sync counter latch ###
    OREG_CNT <= frameCntLat &
                HNumLat(12 - 1 downto 0) &
                HLenLat(12 - 1 downto 0) when Dead = '0' else
                (others => '0');
    -- OREG_DATA_AVCN <= sreg_img_avg(16 - 1 downto 0)  & DataLatch;
    OREG_DATA_AVCN <= totframeCnt & DataLatch; --# 240809 total vsync counter
    OREG_DATA_BGLW <= BigLat & LowLat;
    -- ###############################

--OREG_DATA_AVCN <= sreg_img_avg(16 - 1 downto 0)  & BigLat;
--OREG_DATA_BGLW <= pixelCntLat;
    -- ###############################
    -- ### Trigger cnt, data latch ###
--OREG_CNT       <= frameFreerunCnt &
--                  HNumTrigLat(12 - 1 downto 0) &
--                  HLenTrigLat(12 - 1 downto 0) when Dead = '0' else
--                  (others=>'0');
--OREG_DATA_AVCN <= sreg_img_avg(16 - 1 downto 0)  & DataTrigLatch;
--OREG_DATA_BGLW <= BigLat & LowLat;

end architecture behavioral;
