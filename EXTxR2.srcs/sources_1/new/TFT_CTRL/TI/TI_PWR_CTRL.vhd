library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;

use WORK.TOP_HEADER.ALL;

entity TI_PWR_CTRL is
generic ( GNR_MODEL : string  := "EXT1616R" );
port (
    imain_clk           : in    std_logic;
    imain_rstn          : in    std_logic;

    ireg_pwr_mode       : in    std_logic;
    ireg_erase_en       : in    std_logic;
    ireg_erase_time     : in    std_logic_vector(31 downto 0);

    ireg_pwdac_cmd       : in  std_logic_vector(16 - 1 downto 0);
    ireg_pwdac_ticktime  : in  std_logic_vector(32 - 1 downto 0);
    ireg_pwdac_tickinc   : in  std_logic_vector(12 - 1 downto 0);
    ireg_pwdac_trig      : in  std_logic;
    oreg_pwdac_currlevel : out std_logic_vector(16 - 1 downto 0);

    itft_busy           : in    std_logic;

    opwr_en             : out   std_logic_vector(PWR_NUM(GNR_MODEL)-1 downto 0);
    opwr_done           : out   std_logic;
    oerase_done         : out   std_logic
);
end TI_PWR_CTRL;

architecture Behavioral of TI_PWR_CTRL is

    type tstate_pwr    is (
                            s_IDLE,
                            s_ERASE,
                            s_FINISH
                        );

    signal state_pwr     : tstate_pwr;

    signal spwr_cnt      : std_logic_vector(31 downto 0);
    signal spwr_done     : std_logic;
    signal serase_done   : std_logic;
    signal sreg_pwr_mode : std_logic;

    signal serase_en     : std_logic;
    signal serase_cnt    : std_logic_vector(31 downto 0);
    signal serase_time   : std_logic_vector(31 downto 0);

    signal stime_1st   : integer := (1 * T_1MS(GNR_MODEL));
    signal stime_2nd   : integer := (2 * T_1MS(GNR_MODEL));
    signal stime_3rd   : integer := (3 * T_1MS(GNR_MODEL));
    signal stime_4th   : integer := (4 * T_1MS(GNR_MODEL));
    signal stime_5th   : integer := (5 * T_1MS(GNR_MODEL));
    signal stime_6th   : integer := (6 * T_1MS(GNR_MODEL));
    signal stime_final : integer := (7 * T_1MS(GNR_MODEL));

    signal sreg_erase_en_1d     : std_logic;
    signal sreg_erase_en_2d     : std_logic;
    signal sreg_erase_en_3d     : std_logic;
    signal sreg_erase_time_1d   : std_logic_vector(31 downto 0);
    signal sreg_erase_time_2d   : std_logic_vector(31 downto 0);
    signal sreg_erase_time_3d   : std_logic_vector(31 downto 0);

    signal shv_pwr_en    : std_logic := '0';
    signal shv_sw        : std_logic := '0';
    signal shvr_sw       : std_logic := 'Z';
    signal shv_dac_dq    : std_logic := '0';
    signal shv_dac_clk   : std_logic := '0';
    signal shv_dac_syncn : std_logic := '0';

begin

    SIM : if(SIMULATION = "ON") generate
    begin
        stime_1st           <= (1 * T_1US(GNR_MODEL));
        stime_2nd           <= (2 * T_1US(GNR_MODEL));
        stime_3rd           <= (3 * T_1US(GNR_MODEL));
        stime_final         <= (7 * T_1US(GNR_MODEL));
    end generate;

    process(imain_clk, imain_rstn)
    begin
        if(imain_rstn = '0') then
            sreg_pwr_mode       <= '0';
        elsif(imain_clk'event and imain_clk = '1') then
            if(itft_busy = '0') then
                sreg_pwr_mode       <= ireg_pwr_mode;
            end if;
        end if;
    end process;

    process(imain_clk, imain_rstn)
    begin
        if(imain_rstn = '0') then
            serase_en       <= '0';
            serase_cnt      <= (others => '0');
            serase_time     <= (others => '0');
            serase_done     <= '1';
        elsif(imain_clk'event and imain_clk = '1') then
            case state_pwr is
                when s_IDLE     =>
                                    if(sreg_erase_en_3d = '1') then
                                        state_pwr       <= s_ERASE;
                                        serase_en       <= '1';
                                        serase_time     <= sreg_erase_time_3d;
                                        serase_cnt      <= (others => '0');
                                        serase_done     <= '0';
                                    end if;
                when s_ERASE    =>
                                    if(serase_cnt >= serase_time) then
                                        state_pwr       <= s_FINISH;
                                        serase_en       <= '0';
                                        serase_cnt      <= (others => '0');
                                        serase_done     <= '1';
                                    else
                                        serase_en       <= '1';
                                        serase_cnt      <= serase_cnt + '1';
                                    end if;
                when s_FINISH   =>
                                    if(sreg_erase_en_3d = '0') then
                                        state_pwr       <= s_IDLE;
                                    end if;
                when others     =>
                                    NULL;
            end case;
        end if;
    end process;

    process(imain_clk, imain_rstn)
    begin
        if(imain_rstn = '0') then
            sreg_erase_en_1d        <= '0';
            sreg_erase_en_2d        <= '0';
            sreg_erase_en_3d        <= '0';
            sreg_erase_time_1d      <= (others => '0');
            sreg_erase_time_2d      <= (others => '0');
            sreg_erase_time_3d      <= (others => '0');
        elsif(imain_clk'event and imain_clk = '1') then
            sreg_erase_en_1d        <= ireg_erase_en;
            sreg_erase_en_2d        <= sreg_erase_en_1d;
            sreg_erase_en_3d        <= sreg_erase_en_2d;
            sreg_erase_time_1d      <= ireg_erase_time;
            sreg_erase_time_2d      <= sreg_erase_time_1d;
            sreg_erase_time_3d      <= sreg_erase_time_2d;
        end if;
    end process;

    -- jyp 241030
    EXT1024 : if(GNR_MODEL = "EXT1024R") generate

    signal spwr_vgh_en          : std_logic;
    signal spwr_vbias_en        : std_logic;
    signal spwr_gate_3v3_en     : std_logic;
    signal spwr_vgl_en          : std_logic;
    signal spwr_roic_en         : std_logic;
    signal spwr_roic_avdd1_en   : std_logic;
    signal spwr_roic_avdd2_en   : std_logic;

    begin

        process(imain_clk, imain_rstn)
        begin
            if(imain_rstn = '0') then

                spwr_cnt            <= (others => '0');
                spwr_vgh_en         <= '0';
                spwr_vbias_en       <= '0';
                spwr_gate_3v3_en    <= '0';
                spwr_vgl_en         <= '0';
                spwr_roic_en        <= '0';
                spwr_roic_avdd1_en  <= '0';
                spwr_roic_avdd2_en  <= '0';
                spwr_done           <= '0';
                
            elsif(imain_clk'event and imain_clk = '1') then
                if(sreg_pwr_mode = '1') then
                    spwr_cnt            <= (others => '0');
                    spwr_vgh_en         <= '0';
                    spwr_vbias_en       <= '0';
                    spwr_gate_3v3_en    <= '0';
                    spwr_vgl_en         <= '0';
                    spwr_roic_en        <= '0'; 
                    spwr_roic_avdd1_en  <= '0';
                    spwr_roic_avdd2_en  <= '0';
                    spwr_done           <= '0';
                else
--$$$$$$$$$$$$$$$$$$$$$$$$$$$ 250509 default
--                    if (spwr_cnt = stime_final - 1) then
--                        spwr_done           <= '1';
--                        spwr_vgh_en         <= '1';
--                        spwr_vbias_en       <= '1';
--                        spwr_gate_3v3_en    <= '1';
--                        spwr_vgl_en         <= '1';
--                        spwr_roic_en        <= '1'; --$ 1024R roic en change 0 -> 1
--                        spwr_roic_avdd1_en  <= '1';
--                        spwr_roic_avdd2_en  <= '1';
--$$$$$$$$$$$$$$$$$$$$$$$$$$
                    if (spwr_cnt = stime_1st - 1) then
                        spwr_done           <= '1';
                        spwr_vgh_en         <= '1';
                        spwr_vbias_en       <= '1';
                        spwr_gate_3v3_en    <= '1';
                        spwr_vgl_en         <= '1';
                        spwr_roic_en        <= '1'; --$ 1024R roic en change 0 -> 1
                        spwr_roic_avdd1_en  <= '1';
                        spwr_roic_avdd2_en  <= '1';
                    else
                        if (spwr_cnt = stime_1st - 1) then
                            NULL;
                        end if;
                        spwr_cnt        <= spwr_cnt + '1';
                        spwr_done       <= '0';
                    end if;
                end if;
            end if;
        end process;

        opwr_en(0)      <= spwr_vbias_en when serase_en = '0' else '0';
        opwr_en(1)      <= spwr_vgh_en;
        opwr_en(2)      <= spwr_gate_3v3_en;
        opwr_en(3)      <= spwr_vgl_en;
        opwr_en(4)      <= spwr_roic_en;
        opwr_en(5)      <= spwr_roic_avdd1_en;
        opwr_en(6)      <= spwr_roic_avdd2_en;

    end generate;

    EXT1616 : if(GNR_MODEL = "EXT1616R") generate

        signal spwr_vgh_en          : std_logic;
        signal spwr_vbias_en        : std_logic;
        signal spwr_gate_3v3_en     : std_logic;
        signal spwr_vgl_en          : std_logic;
        signal spwr_roic_en         : std_logic;
        signal spwr_r1_avdd1_en         : std_logic;
        signal spwr_r1_avdd2_en         : std_logic;
        signal spwr_r2_avdd1_en         : std_logic;
        signal spwr_r2_avdd2_en         : std_logic;

    begin

        process(imain_clk, imain_rstn)
        begin
            if(imain_rstn = '0') then
                spwr_cnt            <= (others => '0');
                spwr_vgh_en         <= '0';
                spwr_vbias_en       <= '0';
                spwr_gate_3v3_en    <= '0';
                spwr_vgl_en         <= '0';
                spwr_roic_en        <= '1';
                spwr_r1_avdd1_en    <= '0';
                spwr_r1_avdd2_en    <= '0';
                spwr_r2_avdd1_en    <= '0';
                spwr_r2_avdd2_en    <= '0';
                spwr_done           <= '0';
            elsif(imain_clk'event and imain_clk = '1') then
                if(sreg_pwr_mode = '1') then
                    spwr_cnt            <= (others => '0');
                    spwr_vgh_en         <= '0';
                    spwr_vbias_en       <= '0';
                    spwr_gate_3v3_en    <= '0';
                    spwr_vgl_en         <= '0';
                    spwr_roic_en        <= '1';
                    spwr_r1_avdd1_en    <= '0';
                    spwr_r1_avdd2_en    <= '0';
                    spwr_r2_avdd1_en    <= '0';
                    spwr_r2_avdd2_en    <= '0';
                    spwr_done           <= '0';
                else
                    if(spwr_cnt = stime_final - 1) then
                        spwr_done           <= '1';
                        spwr_vgh_en         <= '1';
                        spwr_vbias_en       <= '1';
                        spwr_gate_3v3_en    <= '1';
                        spwr_vgl_en         <= '1';
                        spwr_roic_en        <= '0';
                        spwr_r1_avdd1_en    <= '1';
                        spwr_r1_avdd2_en    <= '1';
                        spwr_r2_avdd1_en    <= '1';
                        spwr_r2_avdd2_en    <= '1';
                    else
                        if(spwr_cnt = stime_1st - 1) then
                            NULL;
                        end if;
                        spwr_cnt        <= spwr_cnt + '1';
                        spwr_done       <= '0';
                    end if;
                end if;
            end if;
        end process;

        opwr_en(0)      <= spwr_vgh_en;
        opwr_en(1)      <= spwr_vbias_en when serase_en = '0' else '0';
        opwr_en(2)      <= spwr_gate_3v3_en;
        opwr_en(3)      <= spwr_vgl_en;
        opwr_en(4)      <= spwr_roic_en;
        opwr_en(5)      <= spwr_r1_avdd1_en;
        opwr_en(6)      <= spwr_r1_avdd2_en;
        opwr_en(7)      <= spwr_r2_avdd1_en;
        opwr_en(8)      <= spwr_r2_avdd2_en;

    end generate;

    EXT4343 : if(GNR_MODEL = "EXT4343R"     or 
                 GNR_MODEL = "EXT4343R_1"   or 
                 GNR_MODEL = "EXT4343R_2"   or 
                 GNR_MODEL = "EXT4343R_3"   or 
                 GNR_MODEL = "EXT4343RC"    or 
                 GNR_MODEL = "EXT4343RC_1"  or 
                 GNR_MODEL = "EXT4343RC_2"  or 
                 GNR_MODEL = "EXT4343RC_3"  or
                 GNR_MODEL = "EXT4343RI_2"  or 
                 GNR_MODEL = "EXT4343RCI_1" or
                 GNR_MODEL = "EXT4343RCI_2" or
                 GNR_MODEL = "EXT4343R_4"   or
                 GNR_MODEL = "EXT4343RI_4"
                                       ) generate
        -- SEQ 1
        signal spwr_n_bias_aen          : std_logic;
        signal spwr_pgate_on            : std_logic;
        -- SEQ 2
        signal spwr_vgl_en              : std_logic;
        -- SEQ 3
        signal spwr_vgh_en              : std_logic;
        -- Added for ROIC B'd
        signal spwr_roic_en_l           : std_logic;
        signal spwr_roic_en_r           : std_logic;

    begin

        process(imain_clk, imain_rstn)
        begin
            if(imain_rstn = '0') then
                spwr_cnt                <= (others => '0');
                spwr_n_bias_aen         <= '0';
                spwr_pgate_on           <= '0';
                spwr_vgl_en             <= '0';
                spwr_vgh_en             <= '0';
                spwr_roic_en_l          <= '1';
                spwr_roic_en_r          <= '1';
                spwr_done               <= '0';
            elsif(imain_clk'event and imain_clk = '1') then
                if(sreg_pwr_mode = '1') then
                    spwr_cnt                <= (others => '0');
                    spwr_n_bias_aen         <= '0';
                    spwr_pgate_on           <= '0';
                    spwr_vgl_en             <= '0';
                    spwr_vgh_en             <= '0';
                    spwr_done               <= '0';
                else
                    if(spwr_cnt = stime_final - 1) then
                        spwr_done           <= '1';
                    else
                        if(spwr_cnt = stime_1st - 1) then
                            spwr_n_bias_aen     <= '1';
                            spwr_pgate_on       <= '1';
                        elsif(spwr_cnt = stime_2nd - 1) then
                            spwr_vgl_en         <= '1';
                        elsif(spwr_cnt = stime_3rd - 1) then
                            spwr_vgh_en         <= '1';
                        end if;
                        spwr_cnt        <= spwr_cnt + '1';
                        spwr_done       <= '0';
                    end if;
                end if;
            end if;
        end process;

        opwr_en(0)      <= spwr_n_bias_aen      when serase_en = '0' else '0';
        opwr_en(1)      <= spwr_pgate_on;
        opwr_en(2)      <= spwr_vgl_en;
        opwr_en(3)      <= spwr_vgh_en;
        opwr_en(4)      <= spwr_roic_en_l;
        --* 4343R_TI_S
        --* opwr_en(5)      <= spwr_roic_en_r;

    end generate;

     EXT2430 : if(GNR_MODEL = "EXT2430R"  ) or
                 (GNR_MODEL = "EXT2430RI"   ) or
                 (GNR_MODEL = "EXT2832R"   ) or
                 (GNR_MODEL = "EXT2832R_2" ) generate

        signal spwr_vgh_en          : std_logic;
        signal spwr_vbias_en        : std_logic;
        signal spwr_gate_3v3_en     : std_logic;
        signal spwr_vgl_en          : std_logic;
        signal spwr_roic_en         : std_logic;
        signal spwr_r1_avdd1_en     : std_logic;
        signal spwr_r1_avdd2_en     : std_logic;
        signal spwr_r2_avdd1_en     : std_logic;
        signal spwr_r2_avdd2_en     : std_logic;

    begin

        process(imain_clk, imain_rstn)
        begin
            if(imain_rstn = '0') then
                spwr_cnt            <= (others => '0');
                spwr_vgh_en         <= '0';
                spwr_vbias_en       <= '0';
                spwr_gate_3v3_en    <= '0';
                spwr_vgl_en         <= '0';
                spwr_roic_en        <= '1';
                spwr_r1_avdd1_en    <= '0';
                spwr_r1_avdd2_en    <= '0';
                spwr_r2_avdd1_en    <= '0';
                spwr_r2_avdd2_en    <= '0';
                spwr_done           <= '0';
            elsif(imain_clk'event and imain_clk = '1') then
                if(sreg_pwr_mode = '1') then
                    spwr_cnt            <= (others => '0');
                    spwr_vgh_en         <= '0';
                    spwr_vbias_en       <= '0';
                    spwr_gate_3v3_en    <= '0';
                    spwr_vgl_en         <= '0';
                    spwr_roic_en        <= '1';
                    spwr_r1_avdd1_en    <= '0';
                    spwr_r1_avdd2_en    <= '0';
                    spwr_r2_avdd1_en    <= '0';
                    spwr_r2_avdd2_en    <= '0';
                    spwr_done           <= '0';
                else
                    if(spwr_cnt = stime_final - 1) then
                        spwr_done           <= '1';
                        spwr_vgh_en         <= '1';
                        spwr_vbias_en       <= '1';
                        spwr_gate_3v3_en    <= '1';
                        spwr_vgl_en         <= '1';
                        spwr_roic_en        <= '0';
                        spwr_r1_avdd1_en    <= '1';
                        spwr_r1_avdd2_en    <= '1';
                        spwr_r2_avdd1_en    <= '1';
                        spwr_r2_avdd2_en    <= '1';
                    else
                        if(spwr_cnt = stime_1st - 1) then
                            NULL;
                        end if;
                        spwr_cnt        <= spwr_cnt + '1';
                        spwr_done       <= '0';
                    end if;
                end if;
            end if;
        end process;

        opwr_en(0)      <= spwr_vgh_en;
        opwr_en(1)      <= spwr_vbias_en when serase_en = '0' else '0';
        opwr_en(2)      <= spwr_gate_3v3_en;
        opwr_en(3)      <= spwr_vgl_en;
        opwr_en(4)      <= spwr_roic_en;
        opwr_en(5)      <= spwr_r1_avdd1_en;
        opwr_en(6)      <= spwr_r1_avdd2_en;
--      opwr_en(7)      <= spwr_r2_avdd1_en;
--      opwr_en(8)      <= spwr_r2_avdd2_en;

    end generate;

    EXT810R : if(GNR_MODEL = "EXT810R") generate

    component DAC_SPI_CTRL is
        port (
            i_clk  : in    std_logic; -- 100 MHz
            i_rstn : in    std_logic;

            i_reg_pwdac_cmd       : in    std_logic_vector(16 - 1 downto 0);
            i_reg_pwdac_ticktime  : in    std_logic_vector(32 - 1 downto 0);
            i_reg_pwdac_tickinc   : in    std_logic_vector(12 - 1 downto 0);
            i_reg_pwdac_trig      : in    std_logic;
            o_reg_pwdac_currlevel : out   std_logic_vector(16 - 1 downto 0);

            o_clk   : out   std_logic;
            o_syncn : out   std_logic;
            o_data  : out   std_logic
        );
    end component dac_spi_ctrl;
    signal spwdac_cmd          : std_logic_vector(16 - 1 downto 0) := (others=> '0');
    signal spwdac_ticktime     : std_logic_vector(32 - 1 downto 0) := (others=> '0');
    signal spwdac_tickinc      : std_logic_vector(12 - 1 downto 0) := (others=> '0');
    signal spwdac_trig         : std_logic := '0';
    signal sreg_pwdac_cmd0     : std_logic_vector(16 - 1 downto 0) := (others=> '0');
    signal sreg_pwdac_ticktime0: std_logic_vector(32 - 1 downto 0) := (others=> '0');
    signal sreg_pwdac_tickinc0 : std_logic_vector(12 - 1 downto 0) := (others=> '0');
    signal sreg_pwdac_trig0    : std_logic := '0';
    signal sreg_pwdac_cmd1     : std_logic_vector(16 - 1 downto 0) := (others=> '0');
    signal sreg_pwdac_ticktime1: std_logic_vector(32 - 1 downto 0) := (others=> '0');
    signal sreg_pwdac_tickinc1 : std_logic_vector(12 - 1 downto 0) := (others=> '0');
    signal sreg_pwdac_trig1    : std_logic := '0';
    signal sreg_pwdac_cmd      : std_logic_vector(16 - 1 downto 0) := (others=> '0');
    signal sreg_pwdac_ticktime : std_logic_vector(32 - 1 downto 0) := (others=> '0');
    signal sreg_pwdac_tickinc  : std_logic_vector(12 - 1 downto 0) := (others=> '0');
    signal sreg_pwdac_trig     : std_logic := '0';
    signal smux_pwdac_cmd      : std_logic_vector(16 - 1 downto 0) := (others=> '0');
    signal smux_pwdac_ticktime : std_logic_vector(32 - 1 downto 0) := (others=> '0');
    signal smux_pwdac_tickinc  : std_logic_vector(12 - 1 downto 0) := (others=> '0');
    signal smux_pwdac_trig     : std_logic := '0';

    -- SEQ 1
    signal spwr_n_bias_aen : std_logic;
    signal spwr_pgate_on   : std_logic;
    -- SEQ 2
    signal spwr_vgl_en     : std_logic;
    -- SEQ 3
    signal spwr_vgh_en     : std_logic;
    -- Added for ROIC B'd
    signal spwr_roic_en_l  : std_logic;
    signal spwr_roic_en_r  : std_logic;

    begin

        process(imain_clk, imain_rstn)
        begin
            if(imain_rstn = '0') then
                spwr_cnt        <= (others => '0');
                spwr_n_bias_aen <= '0';
                spwr_pgate_on   <= '0';
                spwr_vgl_en     <= '0';
                spwr_vgh_en     <= '0';
                spwr_roic_en_l  <= '1';
                spwr_roic_en_r  <= '1';
                spwdac_cmd      <= (others=> '0');
                spwdac_ticktime <= (others=> '0');
                spwdac_tickinc  <= (others=> '0');
                spwdac_trig     <= '0';

                spwr_done               <= '0';

                shvr_sw            <= 'Z';
            elsif(imain_clk'event and imain_clk = '1') then
                shvr_sw            <= 'Z';
                if(sreg_pwr_mode = '1') then
                    spwr_cnt        <= (others => '0');
                    spwr_n_bias_aen <= '0';
                    spwr_pgate_on   <= '0';
                    spwr_vgl_en     <= '0';
                    spwr_vgh_en     <= '0';
                    spwr_done       <= '0';

                    shv_pwr_en      <= '0';
                    shv_sw          <= '0';
                    spwdac_cmd      <= (others => '0'); 
                    spwdac_ticktime <= (others => '0');  
                    spwdac_tickinc  <= (others => '0');  
                    spwdac_trig     <= '0';
                else
                    if(spwr_cnt = stime_final - 1) then
                        spwr_done   <= '1';
                    else
                        spwr_cnt  <= spwr_cnt + '1';
                        spwr_done <= '0';
                        if(spwr_cnt = stime_1st - 1) then
                            spwr_n_bias_aen     <= '1';
                            spwr_pgate_on       <= '1';
                        elsif(spwr_cnt = stime_2nd - 1) then
                            spwr_vgl_en         <= '1';
                        elsif(spwr_cnt = stime_3rd - 1) then
                            spwr_vgh_en         <= '1';
                        elsif(spwr_cnt = stime_4th - 1) then
                             shv_pwr_en         <= '1';
                        elsif(spwr_cnt = stime_5th - 1) then
                             shv_sw             <= '1';
                        elsif(spwr_cnt = stime_6th - 1) then
                             --# 256 level
                             spwdac_cmd <= "00" & INIT_PWDAC_LEVEL & "00";
                             --# 1 tick time 100=1/25MHz*100=4us
                             spwdac_ticktime <= INIT_PWDAC_TICKTIME;
                             --# 1 increment
                             spwdac_tickinc <= INIT_PWDAC_TICKINC;
                             --# trigger
                             spwdac_trig <= '1';
                        end if;
                    end if;

                end if;
            end if;
        end process;

        --### cdc ###
        process(imain_clk)
        begin
            if imain_clk'event and imain_clk='1' then
                --
                sreg_pwdac_cmd0      <= ireg_pwdac_cmd      ;
                sreg_pwdac_ticktime0 <= ireg_pwdac_ticktime ;
                sreg_pwdac_tickinc0  <= ireg_pwdac_tickinc  ;
                sreg_pwdac_trig0     <= ireg_pwdac_trig     ;
                sreg_pwdac_cmd1      <= sreg_pwdac_cmd0     ;
                sreg_pwdac_ticktime1 <= sreg_pwdac_ticktime0;
                sreg_pwdac_tickinc1  <= sreg_pwdac_tickinc0 ;
                sreg_pwdac_trig1     <= sreg_pwdac_trig0    ;
                sreg_pwdac_cmd       <= sreg_pwdac_cmd1     ;
                sreg_pwdac_ticktime  <= sreg_pwdac_ticktime1;
                sreg_pwdac_tickinc   <= sreg_pwdac_tickinc1 ;
                sreg_pwdac_trig      <= sreg_pwdac_trig1    ;

                if spwr_done = '0' then
                    smux_pwdac_cmd      <=  spwdac_cmd     ;
                    smux_pwdac_ticktime <=  spwdac_ticktime;
                    smux_pwdac_tickinc  <=  spwdac_tickinc ;
                    smux_pwdac_trig     <=  spwdac_trig    ;
                else
                    smux_pwdac_cmd      <=  sreg_pwdac_cmd     ;
                    smux_pwdac_ticktime <=  sreg_pwdac_ticktime;
                    smux_pwdac_tickinc  <=  sreg_pwdac_tickinc ;
                    smux_pwdac_trig     <=  sreg_pwdac_trig    ;
                end if;
                --
            end if;
        end process;

    u_dac : DAC_SPI_CTRL
    port map (
        i_clk                =>  imain_clk         ,
        i_rstn               =>  imain_rstn        ,
        i_reg_pwdac_cmd      =>  smux_pwdac_cmd     ,
        i_reg_pwdac_ticktime =>  smux_pwdac_ticktime,
        i_reg_pwdac_tickinc  =>  smux_pwdac_tickinc ,
        i_reg_pwdac_trig     =>  smux_pwdac_trig    ,
        o_reg_pwdac_currlevel=>  oreg_pwdac_currlevel,
        o_clk                =>  shv_dac_clk       ,
        o_syncn              =>  shv_dac_syncn     ,
        o_data               =>  shv_dac_dq
    );

        opwr_en(0)      <= spwr_n_bias_aen when serase_en = '0' else '0';
        opwr_en(1)      <= spwr_pgate_on;
        opwr_en(2)      <= spwr_vgl_en;
        opwr_en(3)      <= spwr_vgh_en;
        opwr_en(4)      <= spwr_roic_en_l;
        opwr_en(5)      <= shv_pwr_en;
        opwr_en(6)      <= shv_sw;
        opwr_en(7)      <= shvr_sw;
        opwr_en(8)      <= shv_dac_dq;
        opwr_en(9)      <= shv_dac_clk;
        opwr_en(10)     <= shv_dac_syncn;

--### xdc map ###                                             4343rc    810
-- set_property PACKAGE_PIN  D26  [get_ports {PWR_EN[5]}] ; # DIO2_2    HV_PWR_EN
-- set_property PACKAGE_PIN  E25  [get_ports {PWR_EN[6]}] ; # DIO2_3    HV_SW
-- set_property PACKAGE_PIN  E26  [get_ports {PWR_EN[7]}] ; # DIO2_4    HVR_SW
-- set_property PACKAGE_PIN  F25  [get_ports {PWR_EN[8]}] ; # DIO2_5    DQ
-- set_property PACKAGE_PIN  G25  [get_ports {PWR_EN[9]}] ; # DIO2_6    CLK/CONV
-- set_property PACKAGE_PIN  G26  [get_ports {PWR_EN[10]}]; # INDL/R    \SYNC

    end generate;

    EXT2430RD : if(GNR_MODEL = "EXT2430RD") generate

    component DAC_SPI_CTRL is
        port (
            i_clk  : in    std_logic; -- 100 MHz
            i_rstn : in    std_logic;

            i_reg_pwdac_cmd       : in    std_logic_vector(16 - 1 downto 0);
            i_reg_pwdac_ticktime  : in    std_logic_vector(32 - 1 downto 0);
            i_reg_pwdac_tickinc   : in    std_logic_vector(12 - 1 downto 0);
            i_reg_pwdac_trig      : in    std_logic;
            o_reg_pwdac_currlevel : out   std_logic_vector(16 - 1 downto 0);

            o_clk   : out   std_logic;
            o_syncn : out   std_logic;
            o_data  : out   std_logic
        );
    end component dac_spi_ctrl;
    signal spwdac_cmd          : std_logic_vector(16 - 1 downto 0) := (others=> '0');
    signal spwdac_ticktime     : std_logic_vector(32 - 1 downto 0) := (others=> '0');
    signal spwdac_tickinc      : std_logic_vector(12 - 1 downto 0) := (others=> '0');
    signal spwdac_trig         : std_logic := '0';
    signal sreg_pwdac_cmd0     : std_logic_vector(16 - 1 downto 0) := (others=> '0');
    signal sreg_pwdac_ticktime0: std_logic_vector(32 - 1 downto 0) := (others=> '0');
    signal sreg_pwdac_tickinc0 : std_logic_vector(12 - 1 downto 0) := (others=> '0');
    signal sreg_pwdac_trig0    : std_logic := '0';
    signal sreg_pwdac_cmd1     : std_logic_vector(16 - 1 downto 0) := (others=> '0');
    signal sreg_pwdac_ticktime1: std_logic_vector(32 - 1 downto 0) := (others=> '0');
    signal sreg_pwdac_tickinc1 : std_logic_vector(12 - 1 downto 0) := (others=> '0');
    signal sreg_pwdac_trig1    : std_logic := '0';
    signal sreg_pwdac_cmd      : std_logic_vector(16 - 1 downto 0) := (others=> '0');
    signal sreg_pwdac_ticktime : std_logic_vector(32 - 1 downto 0) := (others=> '0');
    signal sreg_pwdac_tickinc  : std_logic_vector(12 - 1 downto 0) := (others=> '0');
    signal sreg_pwdac_trig     : std_logic := '0';
    signal smux_pwdac_cmd      : std_logic_vector(16 - 1 downto 0) := (others=> '0');
    signal smux_pwdac_ticktime : std_logic_vector(32 - 1 downto 0) := (others=> '0');
    signal smux_pwdac_tickinc  : std_logic_vector(12 - 1 downto 0) := (others=> '0');
    signal smux_pwdac_trig     : std_logic := '0';

    -- SEQ 1
    signal spwr_n_bias_aen : std_logic;
    signal spwr_pgate_on   : std_logic;
    -- SEQ 2
    signal spwr_vgl_en     : std_logic;
    -- SEQ 3
    signal spwr_vgh_en     : std_logic;
    -- Added for ROIC B'd
    signal spwr_roic_en_l  : std_logic;
    signal spwr_roic_en_r  : std_logic;

        signal spwr_gate_3v3_en     : std_logic;
        signal spwr_r1_avdd1_en     : std_logic;
        signal spwr_r1_avdd2_en     : std_logic;
    begin

        process(imain_clk, imain_rstn)
        begin
            if(imain_rstn = '0') then
                spwr_cnt        <= (others => '0');
                spwr_n_bias_aen <= '0';
                spwr_pgate_on   <= '0';
                spwr_vgl_en     <= '0';
                spwr_vgh_en     <= '0';
                spwr_roic_en_l  <= '1';
                spwr_roic_en_r  <= '1';
                spwr_done       <= '0';
                spwr_gate_3v3_en <= '0';
                spwr_r1_avdd1_en <= '0';
                spwr_r1_avdd2_en <= '0';
                spwdac_cmd      <= (others=> '0');
                spwdac_ticktime <= (others=> '0');
                spwdac_tickinc  <= (others=> '0');
                spwdac_trig     <= '0';

                spwr_done               <= '0';

                shvr_sw            <= 'Z';
            elsif(imain_clk'event and imain_clk = '1') then
                shvr_sw            <= 'Z';
                if(sreg_pwr_mode = '1') then
                    spwr_cnt        <= (others => '0');
                    spwr_n_bias_aen <= '0';
                    spwr_pgate_on   <= '0';
                    spwr_vgl_en     <= '0';
                    spwr_vgh_en     <= '0';
                    spwr_roic_en_l  <= '1';
                    spwr_roic_en_r  <= '1';
                    spwr_done       <= '0';
                    spwr_gate_3v3_en <= '0';
                    spwr_r1_avdd1_en <= '0';
                    spwr_r1_avdd2_en <= '0';

                    shv_pwr_en      <= '0';
                    shv_sw          <= '0';
                    spwdac_cmd      <= (others => '0'); 
                    spwdac_ticktime <= (others => '0');  
                    spwdac_tickinc  <= (others => '0');  
                    spwdac_trig     <= '0';
                else
                    if(spwr_cnt = stime_final - 1) then
                        spwr_done   <= '1';
                    else
                        spwr_cnt  <= spwr_cnt + '1';
                        spwr_done <= '0';
                        if(spwr_cnt = stime_1st - 1) then
                            spwr_n_bias_aen     <= '1';
                            spwr_pgate_on       <= '1';
                        elsif(spwr_cnt = stime_2nd - 1) then
                            spwr_vgl_en         <= '1';
                            spwr_roic_en_l  <= '0';
                        elsif(spwr_cnt = stime_3rd - 1) then
                            spwr_vgh_en      <= '1';
                            spwr_gate_3v3_en <= '1';
                            spwr_r1_avdd1_en <= '1';
                            spwr_r1_avdd2_en <= '1';
                        elsif(spwr_cnt = stime_4th - 1) then
                             shv_pwr_en         <= '1';
                        elsif(spwr_cnt = stime_5th - 1) then
                             shv_sw             <= '1';
                        elsif(spwr_cnt = stime_6th - 1) then
                             --# 256 level
                             spwdac_cmd <= "00" & INIT_PWDAC_LEVEL & "00";
                             --# 1 tick time 100=1/25MHz*100=4us
                             spwdac_ticktime <= INIT_PWDAC_TICKTIME;
                             --# 1 increment
                             spwdac_tickinc <= INIT_PWDAC_TICKINC;
                             --# trigger
                             spwdac_trig <= '1';
                        end if;
                    end if;

                end if;
            end if;
        end process;

        --### cdc ###
        process(imain_clk)
        begin
            if imain_clk'event and imain_clk='1' then
                --
                sreg_pwdac_cmd0      <= ireg_pwdac_cmd      ;
                sreg_pwdac_ticktime0 <= ireg_pwdac_ticktime ;
                sreg_pwdac_tickinc0  <= ireg_pwdac_tickinc  ;
                sreg_pwdac_trig0     <= ireg_pwdac_trig     ;
                sreg_pwdac_cmd1      <= sreg_pwdac_cmd0     ;
                sreg_pwdac_ticktime1 <= sreg_pwdac_ticktime0;
                sreg_pwdac_tickinc1  <= sreg_pwdac_tickinc0 ;
                sreg_pwdac_trig1     <= sreg_pwdac_trig0    ;
                sreg_pwdac_cmd       <= sreg_pwdac_cmd1     ;
                sreg_pwdac_ticktime  <= sreg_pwdac_ticktime1;
                sreg_pwdac_tickinc   <= sreg_pwdac_tickinc1 ;
                sreg_pwdac_trig      <= sreg_pwdac_trig1    ;

                if spwr_done = '0' then
                    smux_pwdac_cmd      <=  spwdac_cmd     ;
                    smux_pwdac_ticktime <=  spwdac_ticktime;
                    smux_pwdac_tickinc  <=  spwdac_tickinc ;
                    smux_pwdac_trig     <=  spwdac_trig    ;
                else
                    smux_pwdac_cmd      <=  sreg_pwdac_cmd     ;
                    smux_pwdac_ticktime <=  sreg_pwdac_ticktime;
                    smux_pwdac_tickinc  <=  sreg_pwdac_tickinc ;
                    smux_pwdac_trig     <=  sreg_pwdac_trig    ;
                end if;
                --
            end if;
        end process;

    u_dac : DAC_SPI_CTRL
    port map (
        i_clk                =>  imain_clk         ,
        i_rstn               =>  imain_rstn        ,
        i_reg_pwdac_cmd      =>  smux_pwdac_cmd     ,
        i_reg_pwdac_ticktime =>  smux_pwdac_ticktime,
        i_reg_pwdac_tickinc  =>  smux_pwdac_tickinc ,
        i_reg_pwdac_trig     =>  smux_pwdac_trig    ,
        o_reg_pwdac_currlevel=>  oreg_pwdac_currlevel,
        o_clk                =>  shv_dac_clk       ,
        o_syncn              =>  shv_dac_syncn     ,
        o_data               =>  shv_dac_dq
    );

        opwr_en(0)      <= spwr_vgh_en;
        opwr_en(1)      <= shv_dac_dq;
        opwr_en(2)      <= spwr_gate_3v3_en;
        opwr_en(3)      <= spwr_vgl_en;
        opwr_en(4)      <= spwr_roic_en_l;
        opwr_en(5)      <= spwr_r1_avdd1_en;
        opwr_en(6)      <= spwr_r1_avdd2_en;
        opwr_en(7)      <= shv_dac_clk;
        opwr_en(8)      <= shv_dac_syncn;
        opwr_en(9)      <= shv_sw;
        opwr_en(10)     <= shvr_sw;

--# PWR
--set_property PACKAGE_PIN D11 [get_ports { PWR_EN[0]  }]; # VGH_EN   IO_L14N_T2_SRCC_16
--set_property PACKAGE_PIN C12 [get_ports { PWR_EN[1]  }]; # VBIAS_EN  #UR ADC_ADI ###############################
--set_property PACKAGE_PIN L22 [get_ports { PWR_EN[2]  }]; # GATE_3.3V_EN IO_L23P_T3_A03_D19_14
--set_property PACKAGE_PIN F10 [get_ports { PWR_EN[3]  }]; # VGL_EN   IO_L11N_T1_SRCC_16
--set_property PACKAGE_PIN F14 [get_ports { PWR_EN[4]  }]; # ROIC_EN   IO_L15P_T2_DQS_16
--set_property PACKAGE_PIN C13 [get_ports { PWR_EN[5]  }]; # R1_AVDD1_EN  IO_L19N_T3_VREF_16
--set_property PACKAGE_PIN B15 [get_ports { PWR_EN[6]  }]; # R1_AVDD2_EN  IO_L23P_T3_16
--set_property PACKAGE_PIN E12 [get_ports { PWR_EN[7]  }]; # R2_AVDD1_EN  #UR ADC_SCLK ###########################
--set_property PACKAGE_PIN D13 [get_ports { PWR_EN[8]  }]; # R2_AVDD2_EN  #UR ADC_nSYNQ ##########################

--### xdc map ###                                             4343rc    810
-- set_property PACKAGE_PIN  D26  [get_ports {PWR_EN[5]}] ; # DIO2_2    HV_PWR_EN
-- set_property PACKAGE_PIN  E25  [get_ports {PWR_EN[6]}] ; # DIO2_3    HV_SW
-- set_property PACKAGE_PIN  E26  [get_ports {PWR_EN[7]}] ; # DIO2_4    HVR_SW
-- set_property PACKAGE_PIN  F25  [get_ports {PWR_EN[8]}] ; # DIO2_5    DQ
-- set_property PACKAGE_PIN  G25  [get_ports {PWR_EN[9]}] ; # DIO2_6    CLK/CONV
-- set_property PACKAGE_PIN  G26  [get_ports {PWR_EN[10]}]; # INDL/R    \SYNC

    end generate;
    
    EXT4343RD : if(GNR_MODEL = "EXT4343RD") or
                  (GNR_MODEL = "EXT3643R" ) generate

    signal spwr_vgh_en          : std_logic;
    signal spwr_vbias_en        : std_logic;
    signal spwr_gate_3v3_en     : std_logic;
    signal spwr_vgl_en          : std_logic;
    signal spwr_roic_en         : std_logic;
    signal spwr_roic_avdd_en    : std_logic;

    begin

        process(imain_clk, imain_rstn)
        begin
            if(imain_rstn = '0') then

                spwr_cnt            <= (others => '0');
                spwr_vgh_en         <= '0';
                spwr_vbias_en       <= '0';
                spwr_gate_3v3_en    <= '0';
                spwr_vgl_en         <= '0';
                spwr_roic_en        <= '0';
                spwr_roic_avdd_en   <= '0';
                spwr_done           <= '0';
                
            elsif(imain_clk'event and imain_clk = '1') then
                if(sreg_pwr_mode = '1') then
                    spwr_cnt            <= (others => '0');
                    spwr_vgh_en         <= '0';
                    spwr_vbias_en       <= '0';
                    spwr_gate_3v3_en    <= '0';
                    spwr_vgl_en         <= '0';
                    spwr_roic_en        <= '0'; 
                    spwr_roic_avdd_en   <= '0';
                    spwr_done           <= '0';
                else
                    if (spwr_cnt = stime_1st - 1) then
                        spwr_done           <= '1';
                        spwr_vgh_en         <= '1';
                        spwr_vbias_en       <= '1';
                        spwr_gate_3v3_en    <= '1';
                        spwr_vgl_en         <= '1';
                        spwr_roic_en        <= '1';
                        spwr_roic_avdd_en   <= '1';
                    else
                        if (spwr_cnt = stime_1st - 1) then
                            NULL;
                        end if;
                        spwr_cnt        <= spwr_cnt + '1';
                        spwr_done       <= '0';
                    end if;
                end if;
            end if;
        end process;

        opwr_en(0)      <= spwr_vbias_en when serase_en = '0' else '0';
        opwr_en(1)      <= spwr_vgh_en;
        opwr_en(2)      <= spwr_gate_3v3_en;
        opwr_en(3)      <= spwr_vgl_en;
        opwr_en(4)      <= spwr_roic_en;
        opwr_en(5)      <= spwr_roic_avdd_en;
    end generate;

    opwr_done       <= spwr_done;
    oerase_done     <= serase_done;

end Behavioral;
