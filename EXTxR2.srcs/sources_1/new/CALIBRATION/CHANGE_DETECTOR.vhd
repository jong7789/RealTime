----------------------------------------------------------------------------------
-- Company: drt
-- Engineer: mbh
--
-- Create Date: 2022/03/23 11:43:49
-- Design Name:
-- Module Name: change_detector - Behavioral
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
    use IEEE.STD_LOGIC_UNSIGNED.ALL;
    use IEEE.STD_LOGIC_ARITH.ALL;
--  use WORK.TOP_HEADER.ALL;

library UNISIM;
    use UNISIM.VComponents.all;

entity change_detector is
    port (
        clk              : in  std_logic;
        i_reg_width      : in  std_logic_vector(12 - 1 downto 0);
        i_reg_height     : in  std_logic_vector(12 - 1 downto 0);
        i_reg_chgdet_en  : in  std_logic;
        i_reg_chgdet_md  : in  std_logic;
        i_reg_chgSense   : in  std_logic_vector(4 - 1 downto 0);
        i_reg_AccPageLim : in  std_logic_vector(16 - 1 downto 0);
        o_reg_chgdet     : out std_logic_vector(8 - 1 downto 0);

        o_chgdet_osd_en : out std_logic;
        o_chgdet_osd_da : out std_logic_vector(16 - 1 downto 0);

        i_Hsyn   : in  std_logic;
        i_Vsyn   : in  std_logic;
        i_Hcnt   : in  std_logic_vector(12 - 1 downto 0);
        i_Vcnt   : in  std_logic_vector(12 - 1 downto 0);
        i_Data   : in  std_logic_vector(16 - 1 downto 0);
        o_change : out std_logic
    );
end entity change_detector;

architecture behavioral of change_detector is

    component blk_mem_32bx256
        port (
            clka  : in  std_logic;
            wea   : in  std_logic_vector(0 downto 0);
            addra : in  std_logic_vector(7 downto 0);
            dina  : in  std_logic_vector(31 downto 0);
            douta : out std_logic_vector(31 downto 0);
            clkb  : in  std_logic;
            web   : in  std_logic_vector(0 downto 0);
            addrb : in  std_logic_vector(7 downto 0);
            dinb  : in  std_logic_vector(31 downto 0);
            doutb : out std_logic_vector(31 downto 0)
        );
    end component;

    component div_u32_DIV_u16
        port (
            aclk                   : in  std_logic;
            s_axis_divisor_tvalid  : in  std_logic;
            s_axis_divisor_tdata   : in  std_logic_vector(15 downto 0);
            s_axis_dividend_tvalid : in  std_logic;
            s_axis_dividend_tdata  : in  std_logic_vector(31 downto 0);
            m_axis_dout_tvalid     : out std_logic;
            m_axis_dout_tdata      : out std_logic_vector(47 downto 0)
        );
    end component;

    component calc_16sub16_17
        port (
            A   : in  std_logic_vector(15 downto 0);
            B   : in  std_logic_vector(15 downto 0);
            CLK : in  std_logic;
            CE  : in  std_logic;
            S   : out std_logic_vector(16 downto 0)
        );
    end component;

    component vio_chgdet
        port (
            clk       : in std_logic;
            probe_in0 : in std_logic_vector(15 downto 0);
            probe_in1 : in std_logic_vector(15 downto 0);
            probe_in2 : in std_logic_vector(0 downto 0);
            probe_in3 : in std_logic_vector(0 downto 0);
            probe_in4 : in std_logic_vector(0 downto 0)
        );
    end component;

    component ila_chgdet
        port (
            clk     : in std_logic;
            probe0  : in std_logic_vector(0 downto 0);
            probe1  : in std_logic_vector(0 downto 0);
            probe2  : in std_logic_vector(0 downto 0);
            probe3  : in std_logic_vector(7 downto 0);
            probe4  : in std_logic_vector(31 downto 0);
            probe5  : in std_logic_vector(31 downto 0);
            probe6  : in std_logic_vector(0 downto 0);
            probe7  : in std_logic_vector(7 downto 0);
            probe8  : in std_logic_vector(31 downto 0);
            probe9  : in std_logic_vector(31 downto 0);
            probe10 : in std_logic_vector(0 downto 0);
            probe11 : in std_logic_vector(15 downto 0);
            probe12 : in std_logic_vector(7 downto 0);
            probe13 : in std_logic_vector(31 downto 0);
            probe14 : in std_logic_vector(31 downto 0);
            probe15 : in std_logic_vector(0 downto 0);
            probe16 : in std_logic_vector(15 downto 0);
            probe17 : in std_logic_vector(15 downto 0);
            probe18 : in std_logic_vector(15 downto 0)
        );
    end component;

    type   type_reg12b is array (3 - 1 downto 0) of std_logic_vector(12 - 1 downto 0);
    signal reg_width_shft  : type_reg12b := (others => (others => '0'));
    signal reg_height_shft : type_reg12b := (others => (others => '0'));

    type   type_sm is (sm_idle, sm_1, sm_2, sm_end);
    signal sm_compare      : type_sm := sm_idle;
    signal next_sm_compare : type_sm := sm_idle;
    signal smCnt           : std_logic_vector(16 - 1 downto 0) := (others => '0');

    signal reg_en       : std_logic;
    signal reg_osd_mode : std_logic;

    signal Hsyn_p0 : std_logic;
    signal Hsyn_p1 : std_logic;
    signal Hsyn_p2 : std_logic;
    signal Hsyn_p3 : std_logic;
    signal Vsyn_p0 : std_logic;
    signal Vsyn_p1 : std_logic;
    signal Vsyn_p2 : std_logic;
    signal Vsyn_p3 : std_logic;
    signal Hcnt_p0 : std_logic_vector(12 - 1 downto 0);
    signal Hcnt_p1 : std_logic_vector(12 - 1 downto 0);
    signal Hcnt_p2 : std_logic_vector(12 - 1 downto 0);
    signal Hcnt_p3 : std_logic_vector(12 - 1 downto 0);
    signal Vcnt_p0 : std_logic_vector(12 - 1 downto 0);
    signal Vcnt_p1 : std_logic_vector(12 - 1 downto 0);
    signal Vcnt_p2 : std_logic_vector(12 - 1 downto 0);
    signal Vcnt_p3 : std_logic_vector(12 - 1 downto 0);
    signal Data_p0 : std_logic_vector(16 - 1 downto 0);
    signal Data_p1 : std_logic_vector(16 - 1 downto 0);
    signal Data_p2 : std_logic_vector(16 - 1 downto 0);
    signal Data_p3 : std_logic_vector(16 - 1 downto 0);

--  !size
    signal reg_width        : std_logic_vector(12 - 1 downto 0) := (others => '0');
    signal reg_height       : std_logic_vector(12 - 1 downto 0) := (others => '0');
    signal brick_width      : std_logic_vector(8 - 1 downto 0)  := (others => '0');
    signal brick_height     : std_logic_vector(8 - 1 downto 0)  := (others => '0');
    signal brick_total      : std_logic_vector(16 - 1 downto 0) := (others => '0');
    signal brick_total_mask : std_logic_vector(16 - 1 downto 0) := (others => '0');

    signal bx_cnt        : std_logic_vector(12 - 1 downto 0) := (others => '0');
    signal by_cnt        : std_logic_vector(12 - 1 downto 0) := (others => '0');
    signal bx_addr       : std_logic_vector(5 - 1 downto 0)  := (others => '0');
    signal by_addr       : std_logic_vector(5 - 1 downto 0)  := (others => '0');
    signal b_addr_toggle : std_logic := '0';
    signal de_p1         : std_logic := '0';
    signal de_p2         : std_logic := '0';
    signal de_p3         : std_logic := '0';

    signal g0_brick_wea_p1   : std_logic;
    signal g1_brick_wea_p1   : std_logic;
    signal bxy_addr_p1       : std_logic_vector(7 downto 0)  := (others => '0');
    signal brick_addra_p1    : std_logic_vector(7 downto 0)  := (others => '0');
    signal brick_dina_p1     : std_logic_vector(31 downto 0) := (others => '0');
    signal g0_brick_douta_p2 : std_logic_vector(31 downto 0) := (others => '0');
    signal g1_brick_douta_p2 : std_logic_vector(31 downto 0) := (others => '0');
    signal g0_brick_web_p2   : std_logic;
    signal g1_brick_web_p2   : std_logic;
    signal brick_addrb_p2    : std_logic_vector(7 downto 0)  := (others => '0');
    signal g0_brick_dinb_p2  : std_logic_vector(31 downto 0) := (others => '0');
    signal g1_brick_dinb_p2  : std_logic_vector(31 downto 0) := (others => '0');
    signal g0_brick_doutb_p3 : std_logic_vector(31 downto 0) := (others => '0');
    signal g1_brick_doutb_p3 : std_logic_vector(31 downto 0) := (others => '0');

    signal compare_en         : std_logic := '0';
    signal compare_en_p1      : std_logic := '0';
    signal compare_addr       : std_logic_vector(7 downto 0)  := (others => '0');
    signal g0_compare_data_p1 : std_logic_vector(31 downto 0) := (others => '0');
    signal g1_compare_data_p1 : std_logic_vector(31 downto 0) := (others => '0');

    signal g0_load_data_p2 : std_logic_vector(31 downto 0)    := (others => '0');
    signal g1_load_data_p2 : std_logic_vector(31 downto 0)    := (others => '0');
    signal brick_addra_p2  : std_logic_vector(8 - 1 downto 0) := (others => '0');
    signal frame_trigger   : std_logic := '0';

    signal g0_div_en        : std_logic;
    signal g0_div_data      : std_logic_vector(47 downto 0);
    signal g1_div_en        : std_logic;
    signal g1_div_data      : std_logic_vector(47 downto 0);
    signal diff_data_p2     : std_logic_vector(17 - 1 downto 0) := (others => '0');
    signal diff_data_u16_p2 : std_logic_vector(16 - 1 downto 0) := (others => '0');
    signal g0_div_data_cut  : std_logic_vector(16 - 1 downto 0);
    signal g1_div_data_cut  : std_logic_vector(16 - 1 downto 0);

    signal diff_en_p1             : std_logic := '0';
    signal diff_en_p2             : std_logic := '0';
    signal diff_en_p3             : std_logic := '0';
    signal max_diff_data          : std_logic_vector(16 - 1 downto 0) := (others => '0');
    signal curr_max_diff_data_lat : std_logic_vector(16 - 1 downto 0) := (others => '0');

    constant COMP_FRAME_NUM         : integer := 16;
    signal   max_diff_en_lat        : std_logic := '0';
    signal   frame_diff_max_cnt     : std_logic_vector(4 - 1 downto 0)  := (others => '0');
    signal   prev_diff_en_p0        : std_logic := '0';
    signal   prev_max_diff_data     : std_logic_vector(16 - 1 downto 0) := (others => '0');
    signal   prev_max_diff_data_lat : std_logic_vector(16 - 1 downto 0) := (others => '0');
    signal   change_det_flag        : std_logic := '0';
    signal   stable_flag            : std_logic := '0';
    signal   stable_flag_p1         : std_logic := '0';
    signal   change_det_flag_p1     : std_logic := '0';
    signal   change_det_tick        : std_logic := '0';

    type   type_16_b16 is array (16 - 1 downto 0) of std_logic_vector(16 - 1 downto 0);
    signal max_diff_data_shft : type_16_b16 := (others => (others => '0'));

    signal reg_chgSense_ofs : std_logic_vector(2 - 1 downto 0)  := (others => '0');
    signal sel_chgSense_ofs : std_logic_vector(17 - 1 downto 0) := (others => '0');

    signal reg_chgSense_per : std_logic_vector(2 - 1 downto 0)  := (others => '0');
    signal sel_chgSense_per : std_logic_vector(17 - 1 downto 0) := (others => '0');

    signal change_keep_cnt : std_logic_vector(32 - 1 downto 0) := (others => '0');
    signal change_det1sec  : std_logic := '0';
    signal de_p2_toggle   : std_logic := '0';
    signal reg_AccPageLim : std_logic_vector(16 - 1 downto 0) := (others => '0');

    signal out_avg_en : std_logic := '0';
    signal out_avg_da : std_logic_vector(16 - 1 downto 0) := (others => '0');
    signal out_dif_en : std_logic := '0';
    signal out_dif_da : std_logic_vector(16 - 1 downto 0) := (others => '0');

-- !begin

begin
    reg_en           <= i_reg_chgdet_en;
    reg_osd_mode     <= i_reg_chgdet_md;
    reg_chgSense_ofs <= i_reg_chgSense(1 downto 0);
    reg_chgSense_per <= i_reg_chgSense(3 downto 2);
--  reg_chgSense_thres <= i_reg_chgSense; --- not using

--  font ogre
--       _                __ _   __
--  ___ (_) ____  ___    / // | / /_
-- / __|| ||_  / / _ \  / / | || '_ \
-- \__ \| | / / |  __/ / /  | || (_) |
-- |___/|_|/___| \___|/_/   |_| \___/
--  !size
    --# register width/height shift and brick size calculation
    process (clk)
    begin
        if clk'event and clk = '1' then
            --
            reg_width_shft  <= reg_width_shft(reg_width_shft'high - 1 downto 0) & i_reg_width;
            reg_width       <= reg_width_shft(reg_width_shft'high);
            reg_height_shft <= reg_height_shft(reg_height_shft'high - 1 downto 0) & i_reg_height;
            reg_height      <= reg_height_shft(reg_height_shft'high);
            brick_width     <= reg_width(12 - 1 downto 4);  -- b'8 <= b'12/16
            brick_height    <= reg_height(12 - 1 downto 4); -- b'8 <= b'12/16
            --
        end if;
    end process;

--  _            _        _                 _      _
-- | |__   _ __ (_)  ___ | | __   __ _   __| |  __| | _ __
-- | '_ \ | '__|| | / __|| |/ /  / _` | / _` | / _` || '__|
-- | |_) || |   | || (__ |   <  | (_| || (_| || (_| || |
-- |_.__/ |_|   |_| \___||_|\_\  \__,_| \__,_| \__,_||_|
-- !baddr
    --# brick address generation and frame trigger (phase 1 <= 0)
    -- phase 1 <= 0
    process (clk)
    begin
        if clk'event and clk = '1' then
            --
            Hsyn_p3 <= Hsyn_p2; Hsyn_p2 <= Hsyn_p1; Hsyn_p1 <= Hsyn_p0; Hsyn_p0 <= i_Hsyn;
            Vsyn_p3 <= Vsyn_p2; Vsyn_p2 <= Vsyn_p1; Vsyn_p1 <= Vsyn_p0; Vsyn_p0 <= i_Vsyn;
            Hcnt_p3 <= Hcnt_p2; Hcnt_p2 <= Hcnt_p1; Hcnt_p1 <= Hcnt_p0; Hcnt_p0 <= i_Hcnt;
            Vcnt_p3 <= Vcnt_p2; Vcnt_p2 <= Vcnt_p1; Vcnt_p1 <= Vcnt_p0; Vcnt_p0 <= i_Vcnt;
            Data_p3 <= Data_p2; Data_p2 <= Data_p1; Data_p1 <= Data_p0; Data_p0 <= i_Data;
            -- ### brick x address ###
            if Hsyn_p0 = '1' and Vsyn_p0 = '1' then
                if bx_cnt < brick_width - 1 then
                    bx_cnt <= bx_cnt + '1';
                else
                    bx_cnt  <= (others => '0');
                    bx_addr <= bx_addr + '1';
                end if;
            else
                bx_cnt  <= (others => '0');
                bx_addr <= (others => '0');
            end if;

            -- ### y address ###
            if Vsyn_p0 = '1' then
                if Hsyn_p1 = '1' and Hsyn_p0 = '0' then --# fall edge
                    if by_cnt < brick_height - 1 then
                        by_cnt <= by_cnt + '1';
                    else
                        by_cnt  <= (others => '0');
                        by_addr <= by_addr + '1';
                    end if;
                end if;
            else
                by_cnt  <= (others => '0');
                by_addr <= (others => '0');
            end if;

            -- ### gen de ###
            bxy_addr_p1 <= by_addr(4 - 1 downto 0) & bx_addr(4 - 1 downto 0);
            if Hsyn_p0 = '1' and Vsyn_p0 = '1' and
               bx_addr < 16 and by_addr < 16 then
                de_p1 <= '1';
            else
                de_p1 <= '0';
            end if;

            -- ### frame_trigger ###
            if Vsyn_p1 = '1' and Vsyn_p0 = '0' then  --# fall edge
                b_addr_toggle <= not b_addr_toggle;    --# frame toggle
                frame_trigger <= '1';
            else
                frame_trigger <= '0';
            end if;

            --
        end if;
    end process;

--  _
-- | |__          _ __   __ _  _ __ ___
-- | '_ \  _____ | '__| / _` || '_ ` _ \
-- | |_) ||_____|| |   | (_| || | | | | |
-- |_.__/        |_|    \__,_||_| |_| |_|
-- !bram
    g0_brick_wea_p1 <= '0';
    g1_brick_wea_p1 <= '0';
    brick_addra_p1  <= compare_addr when compare_en = '1' else
                       bxy_addr_p1;
    brick_dina_p1   <= (others => '0');
    g0_load_data_p2 <= g0_brick_douta_p2;
    g1_load_data_p2 <= g1_brick_douta_p2;
    u_mem_32bx256_g0 : blk_mem_32bx256
        port map (
            -- phase 2 <= 1
            clka   => clk,
            wea(0) => g0_brick_wea_p1,
            addra  => brick_addra_p1,
            dina   => brick_dina_p1,
            douta  => g0_brick_douta_p2,
            -- phase 3 <= 2
            clkb   => clk,
            web(0) => g0_brick_web_p2,
            addrb  => brick_addrb_p2,
            dinb   => g0_brick_dinb_p2,
            doutb  => g0_brick_doutb_p3
        );
    u_mem_32bx256_g1 : blk_mem_32bx256
        port map (
            clka   => clk,
            wea(0) => g1_brick_wea_p1,
            addra  => brick_addra_p1,
            dina   => brick_dina_p1,
            douta  => g1_brick_douta_p2,
            clkb   => clk,
            web(0) => g1_brick_web_p2,
            addrb  => brick_addrb_p2,
            dinb   => g1_brick_dinb_p2,
            doutb  => g1_brick_doutb_p3
        );
    -- # it is reading a data and writing to '0' simultinous by compare_en.
    g0_brick_web_p2 <= compare_en_p1 and (b_addr_toggle) when compare_en_p1 = '1' else
                       de_p2_toggle and (b_addr_toggle);
    g1_brick_web_p2 <= compare_en_p1 and (not b_addr_toggle) when compare_en_p1 = '1' else
                       de_p2_toggle and (not b_addr_toggle);
    brick_addrb_p2  <= brick_addra_p2; -- # always 1 delayed signal from addra.
    -- ### immediately add A Out -> B In ###
    g0_brick_dinb_p2 <= (others => '0') when compare_en_p1 = '1' else g0_load_data_p2 + Data_p2;
    g1_brick_dinb_p2 <= (others => '0') when compare_en_p1 = '1' else g1_load_data_p2 + Data_p2;

    --# de pipeline and toggle generation
    process (clk)
    begin
        if clk'event and clk = '1' then
            --
            de_p2          <= de_p1;
            de_p3          <= de_p2;
            brick_addra_p2 <= brick_addra_p1;
            -- ### It save only half of data !!! ###
            if de_p2 = '1' then
                de_p2_toggle <= not de_p2_toggle;
            else
                de_p2_toggle <= '0';
            end if;
            --
        end if;
    end process;

--   ___   ___   _ __ ___   _ __    __ _  _ __   ___
--  / __| / _ \ | '_ ` _ \ | '_ \  / _` || '__| / _ \
-- | (__ | (_) || | | | | || |_) || (_| || |   |  __/
--  \___| \___/ |_| |_| |_|| .__/  \__,_||_|    \___|
-- !comp                   |_|
    --# compare state machine sync process
    SYNC_PROC : process (clk)
    begin
        if (clk'event and clk = '1') then
            --
            sm_compare <= next_sm_compare;

            if sm_compare = sm_idle then
                smCnt <= (others => '0');
            elsif sm_compare /= next_sm_compare then
                smCnt <= (others => '0');
            else
                smCnt <= smCnt + '1';
            end if;
            --
        end if;
    end process;

    --# compare state machine next state decode
    NEXT_STATE_DECODE : process (sm_compare, smCnt, frame_trigger)
    begin
        next_sm_compare <= sm_compare;

        case (sm_compare) is
            when sm_idle =>
                if frame_trigger = '1' then
                    next_sm_compare <= sm_1;
                end if;
            when sm_1 =>
                if 256 - 1 <= smCnt then
                    next_sm_compare <= sm_2;
                end if;
            when sm_2 =>
                next_sm_compare <= sm_end;
            when sm_end =>
                next_sm_compare <= sm_idle;
            when others =>
                next_sm_compare <= sm_idle;
        end case;

    end process;

    --# compare state machine output decode
    OUTPUT_DECODE : process (sm_compare, smCnt)
    begin
        if sm_compare = sm_1 then
            compare_en   <= '1';
            compare_addr <= smCnt(8 - 1 downto 0);
        else
            compare_en   <= '0';
            compare_addr <= (others => '0');
        end if;
    end process;

    --# compare enable pipeline and brick total calculation
    process (clk)
    begin
        if clk'event and clk = '1' then
            --
            compare_en_p1 <= compare_en;
            brick_total   <= brick_width * brick_height;
            --
        end if;
    end process;

    g0_compare_data_p1 <= g0_brick_douta_p2;
    g1_compare_data_p1 <= g1_brick_douta_p2;

--      _  _
--   __| |(_)__   __
--  / _` || |\ \ / /
-- | (_| || | \ V /
--  \__,_||_|  \_/
-- !div
-- In the bram, I saved half of data(cause same address access), so divider also should be a half.
    brick_total_mask <= '0' & brick_total(16 - 1 downto 1) when compare_en_p1 = '1' else (others => '0');
    u_div_g0 : div_u32_DIV_u16
        port map (
            aclk                   => clk,
            s_axis_divisor_tvalid  => compare_en_p1,
            s_axis_divisor_tdata   => brick_total_mask,
            s_axis_dividend_tvalid => compare_en_p1,
            s_axis_dividend_tdata  => g0_compare_data_p1,
            m_axis_dout_tvalid     => g0_div_en,
            m_axis_dout_tdata      => g0_div_data
        );
    u_div_g1 : div_u32_DIV_u16
        port map (
            aclk                   => clk,
            s_axis_divisor_tvalid  => compare_en_p1,
            s_axis_divisor_tdata   => brick_total_mask,
            s_axis_dividend_tvalid => compare_en_p1,
            s_axis_dividend_tdata  => g1_compare_data_p1,
            m_axis_dout_tvalid     => g1_div_en,
            m_axis_dout_tdata      => g1_div_data
        );
    g0_div_data_cut <= g0_div_data(32 - 1 downto 16);
    g1_div_data_cut <= g1_div_data(32 - 1 downto 16);

    --# out_avg group selection based on toggle
    --### out_avg group selection ###
    process (clk)
    begin
        if clk'event and clk = '1' then
            --
            if b_addr_toggle = '0' then --# group selection
                out_avg_en <= g1_div_en;
                out_avg_da <= g1_div_data(32 - 1 downto 16);
            else
                out_avg_en <= g0_div_en;
                out_avg_da <= g0_div_data(32 - 1 downto 16);
            end if;
            --
        end if;
    end process;

--              _
--  ___  _   _ | |__
-- / __|| | | || '_ \
-- \__ \| |_| || |_) |
-- |___/ \__,_||_.__/
-- !sub
    u_sub : calc_16sub16_17
        port map (
            A   => g0_div_data_cut,
            B   => g1_div_data_cut,
            CLK => CLK,
            CE  => g0_div_en,
            S   => diff_data_p2
        );

    --# diff enable pipeline
    process (clk)
    begin
        if clk'event and clk = '1' then
            --
            diff_en_p1 <= g0_div_en;
            diff_en_p2 <= diff_en_p1;
            diff_en_p3 <= diff_en_p2;
            --
        end if;
    end process;

    -- ### b'16unsigned <= absolute(b'17signed)
    diff_data_u16_p2 <= (diff_data_p2(diff_data_p2'left - 1 downto 0)) when
                        (diff_data_p2(diff_data_p2'left)) = '0' else
                        (not diff_data_p2(diff_data_p2'left - 1 downto 0)) + '1';
--      _  _   __   __
--   __| |(_) / _| / _|  _ __ ___    __ _ __  __
--  / _` || || |_ | |_  | '_ ` _ \  / _` |\ \/ /
-- | (_| || ||  _||  _| | | | | | || (_| | >  <
--  \__,_||_||_|  |_|   |_| |_| |_| \__,_|/_/\_\
-- !max
    --# max diff detection, shift register, sensitivity and stable flag logic
    process (clk)

        variable prev_diff_en : std_logic := '0';

    begin
        if clk'event and clk = '1' then
            --
            -- ### diff out for OSD ###
            out_dif_en <= diff_en_p2;
            out_dif_da <= diff_data_u16_p2;

            -- ### finding current max diff
            if diff_en_p2 = '1' then
                if max_diff_data < diff_data_u16_p2 then
                    max_diff_data <= diff_data_u16_p2;
                end if;
            else
                max_diff_data <= (others => '0');
            end if;

            -- ### latch current max diff
            if diff_en_p3 = '1' and diff_en_p2 = '0' then
                curr_max_diff_data_lat <= max_diff_data;
                max_diff_en_lat        <= '1';
            else
                max_diff_en_lat <= '0';
            end if;

            -- ### prev shift page is from acc page limit value.
            if max_diff_en_lat = '1' then
                frame_diff_max_cnt <= (others => '0');
            elsif frame_diff_max_cnt < i_reg_AccPageLim(4 - 1 downto 0) then
                prev_diff_en := '1';
                frame_diff_max_cnt <= frame_diff_max_cnt + '1'; -- # 4'b
            else
                prev_diff_en := '0';
            end if;

            -- ### prev max value shifting ###
            reg_AccPageLim <= i_reg_AccPageLim;
            if reg_AccPageLim /= i_reg_AccPageLim then
                max_diff_data_shft <= (others => (others => '0')); -- shift reg reset
            elsif max_diff_en_lat = '1' then
                max_diff_data_shft <= max_diff_data_shft
                                      (max_diff_data_shft'high - 1 downto 0) &
                                      curr_max_diff_data_lat;
            end if;

            -- ### finding prev max
            prev_diff_en_p0 <= prev_diff_en;
            if prev_diff_en_p0 = '1' and prev_diff_en = '0' then
                prev_max_diff_data_lat <= prev_max_diff_data;
            elsif prev_diff_en = '1' then
                if prev_max_diff_data <= max_diff_data_shft(conv_integer(frame_diff_max_cnt)) then
                    prev_max_diff_data <= max_diff_data_shft(conv_integer(frame_diff_max_cnt));
                end if;
            else
                prev_max_diff_data <= (others => '0');
            end if;

            -- ### sensitivity selection ###
            case (reg_chgSense_ofs) is
                when "00"   => sel_chgSense_ofs <= conv_std_logic_vector(16, 17);
                when "01"   => sel_chgSense_ofs <= conv_std_logic_vector(32, 17);
                when "10"   => sel_chgSense_ofs <= conv_std_logic_vector(64, 17);
                when "11"   => sel_chgSense_ofs <= conv_std_logic_vector(128, 17);
                when others => sel_chgSense_ofs <= conv_std_logic_vector(16, 17);
            end case;

            case (reg_chgSense_per) is
                when "00"   => sel_chgSense_per <= '0' & x"0000" + prev_max_diff_data_lat(16 - 1 downto 3); --  12%
                when "01"   => sel_chgSense_per <= '0' & x"0000" + prev_max_diff_data_lat(16 - 1 downto 2); --  25%
                when "10"   => sel_chgSense_per <= '0' & x"0000" + prev_max_diff_data_lat(16 - 1 downto 1); --  50%
                when "11"   => sel_chgSense_per <= '0' & x"0000" + prev_max_diff_data_lat(16 - 1 downto 0); -- 100%
                when others => sel_chgSense_per <= '0' & x"0000" + prev_max_diff_data_lat(16 - 1 downto 3); --  12%
            end case;

            -- ### judge stable detection  ###
            if max_diff_en_lat = '1' then -- # check in range
                if (prev_max_diff_data_lat < curr_max_diff_data_lat + sel_chgSense_per and
                    curr_max_diff_data_lat < prev_max_diff_data_lat + sel_chgSense_per) or
                    curr_max_diff_data_lat < sel_chgSense_ofs then
                    stable_flag <= '1';
                else
                    stable_flag <= '0';
                end if;
            end if;

            stable_flag_p1 <= stable_flag;
            if stable_flag_p1 = '0' and stable_flag = '1' then
                change_det_tick <= '1';
            else
                change_det_tick <= '0';
            end if;
            --
        end if;
    end process;

--  _
-- / | ___   ___   ___
-- | |/ __| / _ \ / __|
-- | |\__ \|  __/| (__
-- |_||___/ \___| \___|
-- !1sec
-- change_det1sec flag keep signal for 1 second.
    --# change detection 1-second keep timer
    process (clk)
    begin
        if clk'event and clk = '1' then
            --
            if change_det_tick = '1' then
                change_keep_cnt <= (others => '0');
            else
                if change_keep_cnt < 200_000_000 then -- 200MHz
                    change_keep_cnt <= change_keep_cnt + '1';
                end if;
            end if;

            if change_keep_cnt < 200_000_000 then
                change_det1sec <= '1';
            else
                change_det1sec <= '0';
            end if;

            --
        end if;
    end process;

--                _
--   ___   _   _ | |_
--  / _ \ | | | || __|
-- | (_) || |_| || |_
--  \___/  \__,_| \__|
-- !out
    o_reg_chgdet <= b"000_0000" & change_det1sec when reg_en = '1' else
                    (others => '0');
--  o_change     <= change_det_tick when reg_en ='1' else '0';
    o_change <= not stable_flag when reg_en = '1' else '0'; --# acc bypass during unstable
-- ### osd out ###
    o_chgdet_osd_en <= out_avg_en when reg_osd_mode = '0' else out_dif_en;
    o_chgdet_osd_da <= out_avg_da when reg_osd_mode = '0' else out_dif_da;

--  _  _
-- (_)| |  __ _
-- | || | / _` |
-- | || || (_| |
-- |_||_| \__,_|
-- !ila

--  u_vio_chgdet : vio_chgdet
--      port map (
--          clk          => clk,
--          probe_in0    => prev_max_diff_data_lat, -- 16
--          probe_in1    => curr_max_diff_data_lat, -- 16
--          probe_in2(0) => change_det_tick,        -- 1
--          probe_in3(0) => change_det1sec,         -- 1
--          probe_in4(0) => reg_en                  --1
--      );
--
--  u_ila_chgdet : ila_chgdet
--      port map (
--          clk         => clk,
--          probe0  (0) => compare_en,        -- 1
--          probe1  (0) => b_addr_toggle,     -- 1
--          probe2  (0) => g0_brick_web_p2,   -- 1
--          probe3      => brick_addrb_p2,    -- 8
--          probe4      => g0_brick_dinb_p2,  -- 32
--          probe5      => g0_brick_doutb_p3, -- 32
--          probe6  (0) => g1_brick_web_p2,   -- 1
--          probe7      => brick_addrb_p2,    -- 8
--          probe8      => g1_brick_dinb_p2,  -- 32
--          probe9      => g1_brick_doutb_p3, -- 32
--          probe10 (0) => diff_en_p2,        -- 1
--          probe11     => diff_data_u16_p2,  -- 16
--          probe12     => brick_addra_p1,    -- 8
--          probe13     => g0_brick_douta_p2, -- 32
--          probe14     => g1_brick_douta_p2, -- 32
--          probe15 (0) => g0_div_en,         -- 1
--          probe16     => g0_div_data_cut,   -- 16
--          probe17     => g1_div_data_cut,   -- 16
--          probe18     => Data_p2            -- 16
--      );

---------------------------------------------------------------------------------------------
--          case (reg_chgSense_thres) is
--              when x"0" => sel_chgSense_thres <= conv_std_logic_vector(0, 17);
--              when x"1" => sel_chgSense_thres <= conv_std_logic_vector(1, 17);
--              when x"2" => sel_chgSense_thres <= conv_std_logic_vector(2, 17);
--              when x"3" => sel_chgSense_thres <= conv_std_logic_vector(4, 17);
--              when x"4" => sel_chgSense_thres <= conv_std_logic_vector(8, 17);
--              when x"5" => sel_chgSense_thres <= conv_std_logic_vector(16, 17);
--              when x"6" => sel_chgSense_thres <= conv_std_logic_vector(32, 17);
--              when x"7" => sel_chgSense_thres <= conv_std_logic_vector(64, 17);
--              when x"8" => sel_chgSense_thres <= conv_std_logic_vector(128, 17);
--              when x"9" => sel_chgSense_thres <= conv_std_logic_vector(256, 17);
--              when x"A" => sel_chgSense_thres <= conv_std_logic_vector(512, 17);
--              when x"B" => sel_chgSense_thres <= conv_std_logic_vector(1024, 17);
--              when x"C" => sel_chgSense_thres <= conv_std_logic_vector(2048, 17);
--              when x"D" => sel_chgSense_thres <= conv_std_logic_vector(4096, 17);
--              when x"E" => sel_chgSense_thres <= conv_std_logic_vector(8192, 17);
--              when x"F" => sel_chgSense_thres <= conv_std_logic_vector(16384, 17);
--          end case;

            -- ### judge change detection  ###
--          if max_diff_en_lat = '1' then
--              if  sel_chgSense_per < curr_max_diff_data_lat and
--                  sel_chgSense_ofs < curr_max_diff_data_lat then
--                  change_det_flag <= '1';
--              else
--                  change_det_flag <= '0';
--              end if;
--          end if;
--
--          change_det_flag_p1 <= change_det_flag;
--          if change_det_flag_p1='0' and change_det_flag='1' then
--              change_det_tick <= '1';
--          else
--              change_det_tick <= '0';
--          end if;

            -- ### judge stable detection  ###
--          if max_diff_en_lat = '1' then
--              if  curr_max_diff_data_lat < sel_chgSense_ofs and
--                  curr_max_diff_data_lat < sel_chgSense_per then
--                  stable_flag <= '1';
--              else
--                  stable_flag <= '0';
--              end if;
--          end if;

            -- ### judge stable detection  ###
--          if max_diff_en_lat = '1' then -- # check in range
--              if  prev_max_diff_data_lat < ('0' & curr_max_diff_data_lat) + sel_chgSense_thres and
--                  curr_max_diff_data_lat < ('0' & prev_max_diff_data_lat) + sel_chgSense_thres then
--                  stable_flag <= '1';
--              else
--                  stable_flag <= '0';
--              end if;
--          end if;
end architecture behavioral;

--# unused signals (moved from architecture declaration):
--# signal reg_chgOsd_mode : std_logic := '0';
