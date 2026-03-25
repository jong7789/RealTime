library IEEE;
    use IEEE.STD_LOGIC_1164.ALL;
    use IEEE.STD_LOGIC_UNSIGNED.ALL;
    use IEEE.STD_LOGIC_ARITH.ALL;

    use WORK.TOP_HEADER.ALL;

entity MASK_PARA4 is
port (
    clk          : in  std_logic;
    rstn         : in  std_logic;

    i_reg_width  : in  std_logic_vector(12 - 1 downto 0);
    i_reg_height : in  std_logic_vector(12 - 1 downto 0);

    i_hsyn       : in  std_logic;
    i_vsyn       : in  std_logic;
    i_vcnt       : in  std_logic_vector(12 - 1 downto 0);
    i_hcnt       : in  std_logic_vector(12 - 1 downto 0);
    i_data       : in  std_logic_vector(64 - 1 downto 0);

    o_hsyn_2x2   : out std_logic;
    o_vsyn_2x2   : out std_logic;
    o_hcnt_2x2   : out std_logic_vector(12 - 1 downto 0);
    o_vcnt_2x2   : out std_logic_vector(12 - 1 downto 0);

    o_data_1x1   : out std_logic_vector(64 - 1 downto 0);
    o_data_1x2   : out std_logic_vector(64 - 1 downto 0);
    o_data_1x3   : out std_logic_vector(64 - 1 downto 0);
    o_data_2x1   : out std_logic_vector(64 - 1 downto 0);
    o_data_2x2   : out std_logic_vector(64 - 1 downto 0);
    o_data_2x3   : out std_logic_vector(64 - 1 downto 0);
    o_data_3x1   : out std_logic_vector(64 - 1 downto 0);
    o_data_3x2   : out std_logic_vector(64 - 1 downto 0);
    o_data_3x3   : out std_logic_vector(64 - 1 downto 0)
);
end MASK_PARA4;

architecture Behavioral of MASK_PARA4 is

    COMPONENT mmr_64x1024
    PORT (
        clka  : IN  STD_LOGIC;
        wea   : IN  STD_LOGIC_VECTOR(0 DOWNTO 0);
        addra : IN  STD_LOGIC_VECTOR(9 DOWNTO 0);
        dina  : IN  STD_LOGIC_VECTOR(63 DOWNTO 0);
        douta : OUT STD_LOGIC_VECTOR(63 DOWNTO 0);
        clkb  : IN  STD_LOGIC;
        web   : IN  STD_LOGIC_VECTOR(0 DOWNTO 0);
        addrb : IN  STD_LOGIC_VECTOR(9 DOWNTO 0);
        dinb  : IN  STD_LOGIC_VECTOR(63 DOWNTO 0);
        doutb : OUT STD_LOGIC_VECTOR(63 DOWNTO 0)
    );
    END COMPONENT;

    constant SHF_REG_NUM : integer := 3;

    type ty_reg_shf12b is array (SHF_REG_NUM - 1 downto 0) of std_logic_vector(12 - 1 downto 0);
    signal shf_reg_width : ty_reg_shf12b;
    signal shf_reg_heigh : ty_reg_shf12b;

    constant SHF_VID_NUM : integer := 8;

    signal shf_vsyn : std_logic_vector(SHF_VID_NUM - 1 downto 0) := (others => '0');
    signal shf_hsyn : std_logic_vector(SHF_VID_NUM - 1 downto 0) := (others => '0');

    type ty_vid_shf12b is array (SHF_VID_NUM - 1 downto 0) of std_logic_vector(12 - 1 downto 0);
    signal shf_vcnt : ty_vid_shf12b;
    signal shf_hcnt : ty_vid_shf12b;

    type ty_vid_shf64b is array (SHF_VID_NUM - 1 downto 0) of std_logic_vector(64 - 1 downto 0);
    signal shf_data : ty_vid_shf64b;
    signal shf_rdd0 : ty_vid_shf64b;
    signal shf_rdd1 : ty_vid_shf64b;

    signal shf_gvsyn : std_logic_vector(SHF_VID_NUM - 1 downto 0) := (others => '0');
    signal shf_ghsyn : std_logic_vector(SHF_VID_NUM - 1 downto 0) := (others => '0');
    signal shf_gvcnt : ty_vid_shf12b;
    signal shf_ghcnt : ty_vid_shf12b;

    signal width     : std_logic_vector(12 - 1 downto 0) := (others => '0');
    signal heigh     : std_logic_vector(12 - 1 downto 0) := (others => '0');
    signal hcnt      : std_logic_vector(12 - 1 downto 0) := (others => '0');
    signal vcnt      : std_logic_vector(12 - 1 downto 0) := (others => '0');
    signal gen_hsyn  : std_logic;
    signal gen_hsyn0 : std_logic;
    signal gen_vsyn  : std_logic;
    signal gen_hcnt  : std_logic_vector(12 - 1 downto 0) := (others => '0');
    signal gen_vcnt  : std_logic_vector(12 - 1 downto 0) := (others => '0');

    signal wea0 : std_logic;
    signal wea1 : std_logic;

    signal rdline0  : std_logic_vector(64 - 1 downto 0) := (others => '0');
    signal rdline1  : std_logic_vector(64 - 1 downto 0) := (others => '0');
    signal rdline00 : std_logic_vector(64 - 1 downto 0) := (others => '0');
    signal rdline01 : std_logic_vector(64 - 1 downto 0) := (others => '0');

    type type_sm_gensync is (st_idle, st_start, st_line, st_line_end, st_frame_end, st_line_wait);
--    type type_sm_gensync is (st_idle, st_start, st_line, st_line_wait);
    signal state : type_sm_gensync;

    signal hsyn0 : std_logic;
    signal hsyn1 : std_logic;

    signal waitcnt : std_logic_vector(16 - 1 downto 0) := (others => '0');

    signal hsyn_2x2 : std_logic;
    signal vsyn_2x2 : std_logic;
    signal hcnt_2x2 : std_logic_vector(12 - 1 downto 0);
    signal vcnt_2x2 : std_logic_vector(12 - 1 downto 0);

    signal data_1x1 : std_logic_vector(64 - 1 downto 0);
    signal data_1x2 : std_logic_vector(64 - 1 downto 0);
    signal data_1x3 : std_logic_vector(64 - 1 downto 0);
    signal data_2x1 : std_logic_vector(64 - 1 downto 0);
    signal data_2x2 : std_logic_vector(64 - 1 downto 0);
    signal data_2x3 : std_logic_vector(64 - 1 downto 0);
    signal data_3x1 : std_logic_vector(64 - 1 downto 0);
    signal data_3x2 : std_logic_vector(64 - 1 downto 0);
    signal data_3x3 : std_logic_vector(64 - 1 downto 0);

    signal blank_cnt : std_logic_vector(16 - 1 downto 0) := (others => '0');
    signal blank_num : std_logic_vector(16 - 1 downto 0) := (others => '0');

    component ila_mask_para4
    port (
        clk     : in std_logic;
        probe0  : in type_sm_gensync;
        probe1  : in std_logic_vector(11 downto 0);
        probe2  : in std_logic_vector(11 downto 0);
        probe3  : in std_logic;
        probe4  : in std_logic;
        probe5  : in std_logic_vector(11 downto 0);
        probe6  : in std_logic_vector(11 downto 0);
        probe7  : in std_logic;
        probe8  : in std_logic;
        probe9  : in std_logic_vector(11 downto 0);
        probe10 : in std_logic_vector(15 downto 0)
    );
    end component;

begin

    U0_ILA_MASK : ila_mask_para4
    port map (
        clk     => clk,
        probe0  => state,
        probe1  => vcnt,
        probe2  => hcnt,
        probe3  => gen_vsyn,
        probe4  => gen_hsyn,
        probe5  => gen_vcnt,
        probe6  => gen_hcnt,
        probe7  => i_vsyn,
        probe8  => i_hsyn,
        probe9  => i_vcnt,
        probe10 => blank_cnt
    );

-- ▀█ █░░ █ █▄░█ █▀▀   █▄▄ █░█ █▀▀
-- █▄ █▄▄ █ █░▀█ ██▄   █▄█ █▄█ █▀░ %2line buffer
    wea0 <= (not shf_vcnt(0)(0)) and shf_hsyn(0);
    wea1 <= (    shf_vcnt(0)(0)) and shf_hsyn(0);

    u_linebuf0 : mmr_64x1024
    port map (
        clka   => clk,
        wea(0) => wea0,
        addra  => shf_hcnt(0)(10 - 1 downto 0),
        dina   => shf_data(0),
        douta  => OPEN,
        clkb   => clk,
        web(0) => '0',
        addrb  => i_hcnt(10 - 1 downto 0),
        dinb   => (others => '0'),
        doutb  => rdline0
    );

    u_linebuf1 : mmr_64x1024
    port map (
        clka   => clk,
        wea(0) => wea1,
        addra  => shf_hcnt(0)(10 - 1 downto 0),
        dina   => shf_data(0),
        douta  => OPEN,
        clkb   => clk,
        web(0) => '0',
        addrb  => i_hcnt(10 - 1 downto 0),
        dinb   => (others => '0'),
        doutb  => rdline1
    );

    rdline00 <= rdline0 when wea0 = '1' else rdline1;
    rdline01 <= rdline1 when wea0 = '1' else rdline0;

    --$260128 integrate sm
    --# State machine for sync generation, blank counting, and gen_sync output
    process(clk)
    begin
        if (clk'event and clk = '1') then
            hsyn0 <= i_hsyn;
            hsyn1 <= hsyn0;

            --█▀ █▀▄▀█
            --▄█ █░▀░█ --$sm
            case (state) is
                when st_idle =>
                    if (i_vcnt = 1 and hsyn0 = '0' and i_hsyn = '1') then
                        state <= st_start;
                    end if;

                    gen_vsyn <= '0';
                    gen_hsyn <= '0';
                    vcnt     <= (others => '0');
                when st_start =>
                    if (hsyn1 = '0' and hsyn0 = '1') then
                        state <= st_line;
                    end if;

                    gen_vsyn <= '1';
                    gen_hsyn <= '1';
                when st_line =>
                    if (hcnt = width - 2) then
                        state <= st_line_end;
                    end if;

                    gen_hsyn <= '1';
                    hcnt     <= hcnt + '1';
                    waitcnt  <= (others => '0');
                when st_line_end =>
                    if (vcnt >= heigh - 1) then
                        state    <= st_frame_end;
                        gen_vsyn <= '0';
                    else
                        state <= st_line_wait;
                    end if;

                    gen_hsyn <= '0';
                    hcnt     <= (others => '0');
                    vcnt     <= vcnt + '1';
                when st_line_wait =>
                    if (waitcnt >= blank_num - 1) then
                        state    <= st_line;
                        gen_hsyn <= '1';
                    else
                        waitcnt  <= waitcnt + '1';
                        gen_hsyn <= '0';
                    end if;

                when st_frame_end =>
                    state <= st_idle;
            end case;

            -- █▀▀ █▀▀ █▄░█   █▀ █▄█ █▄░█ █▀▀
            -- █▄█ ██▄ █░▀█   ▄█ ░█░ █░▀█ █▄▄--$gen sync
            gen_hsyn0 <= gen_hsyn;

            if gen_hsyn = '1' then
                gen_hcnt <= gen_hcnt + '1';
            else
                gen_hcnt <= (others => '0');
            end if;

            if gen_vsyn = '0' then
                gen_vcnt <= (others => '0');
            elsif gen_hsyn0 = '1' and gen_hsyn = '0' then
                gen_vcnt <= gen_vcnt + '1';
            end if;

            -- █▄▄ █░░ █▄▀   █▀▀ █▄░█ ▀█▀
            -- █▄█ █▄▄ █░█   █▄▄ █░▀█ ░█░ %blank cnt
            if i_vsyn = '1' and i_hsyn = '0' then
                blank_cnt <= blank_cnt + '1';
            elsif i_hsyn = '1' and hsyn0 = '0' then
                blank_num <= blank_cnt;
                blank_cnt <= (others => '0');
            end if;
        end if;
    end process;

--    SYNC_PROC: process (clk)
--    begin
--        if (clk'event and clk = '1') then

--            state <= next_state;
--            hsyn0 <= i_hsyn;
--            hsyn1 <= hsyn0;

--            -- █▀▀ █▀▀ █▄░█   █▀ █▄█ █▄░█ █▀▀
--            -- █▄█ ██▄ █░▀█   ▄█ ░█░ █░▀█ █▄▄ %gen sync
--            if state = st_line then
--                hcnt <= hcnt + '1';
--            else
--                hcnt <= (others=>'0');
--            end if;

--            if state = st_idle then
--                vcnt <= (others =>'0');
--            elsif state = st_line_end then
--                vcnt <= vcnt + '1';
--            end if;

--            if state = st_line then
--                gen_hsyn <= '1';
--            else
--                gen_hsyn <= '0';
--            end if;
--            gen_hsyn0 <= gen_hsyn;

--            if state = st_idle then
--                gen_vsyn <= '0';
--            else
--                gen_vsyn <= '1';
--            end if;

--            if gen_hsyn = '1' then
--                gen_hcnt <= gen_hcnt + '1';
--            else
--                gen_hcnt <= (others=>'0');
--            end if;

--            if gen_vsyn = '0' then
--                gen_vcnt <= (others=>'0');
--            elsif gen_hsyn0='1' and gen_hsyn='0' then
--                gen_vcnt <= gen_vcnt + '1';
--            end if;
--            -- █▄▄ █░░ █▄▀   █▀▀ █▄░█ ▀█▀
--            -- █▄█ █▄▄ █░█   █▄▄ █░▀█ ░█░ %blank cnt
--            if state = st_start then
--                stay_start_cnt <= stay_start_cnt + '1';
--            elsif state = st_line then
--                waitnum <= stay_start_cnt;
--            else
--                stay_start_cnt <= (others=> '0');
--            end if;

--            if state = st_line_wait then
--                waitcnt <= waitcnt + '1';
--            else
--                waitcnt <= (others=>'0');
--            end if;
--        --
--        end if;
--    end process;
--    -- █▀ █▀▄▀█
--    -- ▄█ █░▀░█ %sm
--    NEXT_STATE_DECODE: process (state, i_vcnt, i_hsyn,
--                                hsyn0, hsyn1, hcnt, width, heigh,
--                                waitcnt, waitnum)
--    begin
--       next_state <= state;
--       if i_vcnt=1 and hsyn0='0' and i_hsyn='1' then
--            next_state <= st_start;
--       else
--           case (state) is
--              when st_idle =>
--                  next_state <= st_idle; --stay
--              when st_start =>
--                 if hsyn1='0' and hsyn0='1' then
--                    next_state <= st_line;
--                 end if;
--              when st_line =>
--                 if hcnt+1 >= width then
--                    next_state <= st_line_end;
--                 end if;
--              when st_line_end =>
--                 if vcnt+2 = heigh then
--                     next_state <= st_line_wait;
--                 elsif vcnt+2 > heigh then
--                     next_state <= st_frame_end;
--                 else
--                     next_state <= st_start;
--                 end if;
--              --### st_line_wait : wait blank and make 1 more line - hync.
--              when st_line_wait =>
--                 if waitcnt >= waitnum-1 then
--                    next_state <= st_line;
--                end if;
--              when st_frame_end =>
--                     next_state <= st_idle; --stay
--              when others =>
--                 next_state <= st_idle;
--           end case;
--        end if;
--    end process;

    --# Shift registers for pipeline delay and 3x3 mask data mapping
    process(clk)
    begin
        if (clk'event and clk = '1') then
        --
            shf_reg_width <= shf_reg_width(shf_reg_width'left - 1 downto 0) & i_reg_width;
            shf_reg_heigh <= shf_reg_heigh(shf_reg_heigh'left - 1 downto 0) & i_reg_height;

                             --### divide width by para4 ###
            width         <= "00" & shf_reg_width(shf_reg_width'left)(12 - 1 downto 2);
            heigh         <= shf_reg_heigh(shf_reg_heigh'left);

            shf_vsyn <= shf_vsyn(shf_vsyn'left - 1 downto 0) & i_vsyn;
            shf_hsyn <= shf_hsyn(shf_hsyn'left - 1 downto 0) & i_hsyn;
            shf_vcnt <= shf_vcnt(shf_vcnt'left - 1 downto 0) & i_vcnt;
            shf_hcnt <= shf_hcnt(shf_hcnt'left - 1 downto 0) & i_hcnt;
            shf_data <= shf_data(shf_data'left - 1 downto 0) & i_data;

            shf_rdd0 <= shf_rdd0(shf_rdd0'left - 1 downto 0) & rdline00;
            shf_rdd1 <= shf_rdd1(shf_rdd1'left - 1 downto 0) & rdline01;

            shf_gvsyn <= shf_gvsyn(shf_gvsyn'left - 1 downto 0) & gen_vsyn;
            shf_ghsyn <= shf_ghsyn(shf_ghsyn'left - 1 downto 0) & gen_hsyn;
            shf_gvcnt <= shf_gvcnt(shf_gvcnt'left - 1 downto 0) & gen_vcnt;
            shf_ghcnt <= shf_ghcnt(shf_ghcnt'left - 1 downto 0) & gen_hcnt;

            vsyn_2x2 <= shf_gvsyn(1);
            hsyn_2x2 <= shf_ghsyn(1);
            vcnt_2x2 <= shf_gvcnt(1);
            hcnt_2x2 <= shf_ghcnt(1);

            -- ▀▀█ ▀▄▀ ▀▀█  █▀▄▀█ ▄▀█ █▀█
            -- ▄▄█ █░█ ▄▄█  █░▀░█ █▀█ █▀▀ %33map
            data_1x1 <= shf_rdd0(3)(48 - 1 downto 32) & shf_rdd0(3)(32 - 1 downto 16) & shf_rdd0(3)(16 - 1 downto 00) & shf_rdd0(4)(64 - 1 downto 48);
            data_1x2 <= shf_rdd0(3)(64 - 1 downto 48) & shf_rdd0(3)(48 - 1 downto 32) & shf_rdd0(3)(32 - 1 downto 16) & shf_rdd0(3)(16 - 1 downto 00);
            data_1x3 <= shf_rdd0(2)(16 - 1 downto 00) & shf_rdd0(3)(64 - 1 downto 48) & shf_rdd0(3)(48 - 1 downto 32) & shf_rdd0(3)(32 - 1 downto 16);
            data_2x1 <= shf_rdd1(3)(48 - 1 downto 32) & shf_rdd1(3)(32 - 1 downto 16) & shf_rdd1(3)(16 - 1 downto 00) & shf_rdd1(4)(64 - 1 downto 48);
            data_2x2 <= shf_rdd1(3)(64 - 1 downto 48) & shf_rdd1(3)(48 - 1 downto 32) & shf_rdd1(3)(32 - 1 downto 16) & shf_rdd1(3)(16 - 1 downto 00);
            data_2x3 <= shf_rdd1(2)(16 - 1 downto 00) & shf_rdd1(3)(64 - 1 downto 48) & shf_rdd1(3)(48 - 1 downto 32) & shf_rdd1(3)(32 - 1 downto 16);
            data_3x1 <= shf_data(4)(48 - 1 downto 32) & shf_data(4)(32 - 1 downto 16) & shf_data(4)(16 - 1 downto 00) & shf_data(5)(64 - 1 downto 48);
            data_3x2 <= shf_data(4)(64 - 1 downto 48) & shf_data(4)(48 - 1 downto 32) & shf_data(4)(32 - 1 downto 16) & shf_data(4)(16 - 1 downto 00);
            data_3x3 <= shf_data(3)(16 - 1 downto 00) & shf_data(4)(64 - 1 downto 48) & shf_data(4)(48 - 1 downto 32) & shf_data(4)(32 - 1 downto 16);

        --
        end if;
    end process;

    o_vsyn_2x2 <= vsyn_2x2;
    o_hsyn_2x2 <= hsyn_2x2;
    o_vcnt_2x2 <= vcnt_2x2;
    o_hcnt_2x2 <= hcnt_2x2;

    o_data_1x1 <= data_1x1;
    o_data_1x2 <= data_1x2;
    o_data_1x3 <= data_1x3;
    o_data_2x1 <= data_2x1;
    o_data_2x2 <= data_2x2;
    o_data_2x3 <= data_2x3;
    o_data_3x1 <= data_3x1;
    o_data_3x2 <= data_3x2;
    o_data_3x3 <= data_3x3;

end Behavioral;

--# Unused signals (removed from declaration, used only in commented-out code):
--# signal rhcnt          : std_logic_vector(10 - 1 downto 0) := (others => '0');
--# signal next_state     : type_sm_gensync;
--# signal waitnum        : std_logic_vector(16 - 1 downto 0) := (others => '0');
--# signal stay_start_cnt : std_logic_vector(16 - 1 downto 0) := (others => '0');
