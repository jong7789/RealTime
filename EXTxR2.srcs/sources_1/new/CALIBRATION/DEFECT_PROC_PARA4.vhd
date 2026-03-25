library IEEE;
    use IEEE.STD_LOGIC_1164.ALL;
    use IEEE.STD_LOGIC_UNSIGNED.ALL;
    use IEEE.STD_LOGIC_ARITH.ALL;

    use WORK.TOP_HEADER.ALL;

entity DEFECT_PROC_PARA4 is
port (
    clk                : in  std_logic;
    rstn               : in  std_logic;

    i_reg_debug_mode   : in  std_logic;
    i_reg_defect_map   : in  std_logic;

    i_reg_defect_mode  : in  std_logic;
    i_reg_defect_wen   : in  std_logic;
    i_reg_defect_addr  : in  std_logic_vector(16 - 1 downto 0);
    i_reg_defect_wdata : in  std_logic_vector(32 - 1 downto 0);
    o_reg_defect_rdata : out std_logic_vector(32 - 1 downto 0);

    i_reg_linedefect_mode  : in  std_logic;
    i_reg_row_defect_wen   : in  std_logic;
    i_reg_row_defect_addr  : in  std_logic_vector( 3 downto 0);
    i_reg_row_defect_wdata : in  std_logic_vector(15 downto 0);
    o_reg_row_defect_rdata : out std_logic_vector(15 downto 0);
    i_reg_col_defect_wen   : in  std_logic;
    i_reg_col_defect_addr  : in  std_logic_vector( 3 downto 0);
    i_reg_col_defect_wdata : in  std_logic_vector(15 downto 0);
    o_reg_col_defect_rdata : out std_logic_vector(15 downto 0);

    i_reg_width  : in  std_logic_vector(12 - 1 downto 0);
    i_reg_height : in  std_logic_vector(12 - 1 downto 0);

    i_hsyn : in  std_logic;
    i_vsyn : in  std_logic;
    i_hcnt : in  std_logic_vector(12 - 1 downto 0);
    i_vcnt : in  std_logic_vector(12 - 1 downto 0);
    i_data : in  std_logic_vector(64 - 1 downto 0);

    o_hsyn : out std_logic;
    o_vsyn : out std_logic;
    o_hcnt : out std_logic_vector(12 - 1 downto 0);
    o_vcnt : out std_logic_vector(12 - 1 downto 0);
    o_data : out std_logic_vector(64 - 1 downto 0)
);
end DEFECT_PROC_PARA4;

architecture Behavioral of DEFECT_PROC_PARA4 is

    component MASK_PARA4
    port (
        clk          : in  std_logic;
        rstn         : in  std_logic;

        i_reg_width  : in  std_logic_vector(12 - 1 downto 0);
        i_reg_height : in  std_logic_vector(12 - 1 downto 0);

        i_hsyn       : in  std_logic;
        i_vsyn       : in  std_logic;
        i_hcnt       : in  std_logic_vector(12 - 1 downto 0);
        i_vcnt       : in  std_logic_vector(12 - 1 downto 0);
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
    end component;

    COMPONENT mem_32_1024
    PORT (
        clka  : IN  STD_LOGIC;
        wea   : IN  STD_LOGIC_VECTOR(0 DOWNTO 0);
        addra : IN  STD_LOGIC_VECTOR(9 DOWNTO 0);
        dina  : IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
        douta : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        clkb  : IN  STD_LOGIC;
        web   : IN  STD_LOGIC_VECTOR(0 DOWNTO 0);
        addrb : IN  STD_LOGIC_VECTOR(9 DOWNTO 0);
        dinb  : IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
        doutb : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
    );
    END COMPONENT;

--#    COMPONENT blk_mem_32x4096
--#      PORT (
--#        clka : IN STD_LOGIC;
--#        wea : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
--#        addra : IN STD_LOGIC_VECTOR(11 DOWNTO 0);
--#        dina : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
--#        douta : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
--#        clkb : IN STD_LOGIC;
--#        web : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
--#        addrb : IN STD_LOGIC_VECTOR(11 DOWNTO 0);
--#        dinb : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
--#        doutb : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
--#      );
--#    END COMPONENT;
--#
    component DEFECT_DECODER
    port (
        idata_clk    : in  std_logic;
        idata_rstn   : in  std_logic;

        idefect_data : in  std_logic_vector(7 downto 0);
        ihsync       : in  std_logic;
        ivsync       : in  std_logic;
        ihcnt        : in  std_logic_vector(11 downto 0);
        ivcnt        : in  std_logic_vector(11 downto 0);

        idata_1x1    : in  std_logic_vector(15 downto 0);
        idata_1x2    : in  std_logic_vector(15 downto 0);
        idata_1x3    : in  std_logic_vector(15 downto 0);
        idata_2x1    : in  std_logic_vector(15 downto 0);
        idata_2x2    : in  std_logic_vector(15 downto 0);
        idata_2x3    : in  std_logic_vector(15 downto 0);
        idata_3x1    : in  std_logic_vector(15 downto 0);
        idata_3x2    : in  std_logic_vector(15 downto 0);
        idata_3x3    : in  std_logic_vector(15 downto 0);

        ohsync       : out std_logic;
        ovsync       : out std_logic;
        ohcnt        : out std_logic_vector(11 downto 0);
        ovcnt        : out std_logic_vector(11 downto 0);
        odata        : out std_logic_vector(15 downto 0);

        odata_sum    : out std_logic_vector(18 downto 0);
        odata_mul    : out std_logic_vector(17 downto 0)
    );
    end component;

    component MULTI_19x17
    port (
        clk : in  std_logic;
        ce  : in  std_logic;
        a   : in  std_logic_vector(18 downto 0);
        b   : in  std_logic_vector(16 downto 0);
        p   : out std_logic_vector(35 downto 0)
    );
    end component;

    COMPONENT ila_col_def
    PORT (
        clk     : IN STD_LOGIC;
        probe0  : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
        probe1  : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
        probe2  : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
        probe3  : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
        probe4  : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
        probe5  : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
        probe6  : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
        probe7  : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
        probe8  : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
        probe9  : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
        probe10 : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
        probe11 : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
        probe12 : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
        probe13 : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
        probe14 : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
        probe15 : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
        probe16 : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
        probe17 : IN STD_LOGIC_VECTOR(15 DOWNTO 0)
    );
    END COMPONENT;

    constant SHF_REG_NUM : integer := 3;

    type ty_reg_shf32b is array (SHF_REG_NUM - 1 downto 0) of std_logic_vector(32 - 1 downto 0);
    type ty_reg_shf16b is array (SHF_REG_NUM - 1 downto 0) of std_logic_vector(16 - 1 downto 0);
    type ty_reg_shf4b  is array (SHF_REG_NUM - 1 downto 0) of std_logic_vector( 4 - 1 downto 0);
    signal shf_reg_defect_addr  : ty_reg_shf16b;
    signal shf_reg_defect_wdata : ty_reg_shf32b;
    signal shf_reg_defect_map   : std_logic_vector(SHF_REG_NUM - 1 downto 0);
    signal shf_reg_defect_mode  : std_logic_vector(SHF_REG_NUM - 1 downto 0);
    signal shf_reg_defect_wen   : std_logic_vector(SHF_REG_NUM - 1 downto 0);

    signal shf_reg_linedefect_mode  : std_logic_vector(SHF_REG_NUM - 1 downto 0);
    signal shf_reg_row_defect_wen   : std_logic_vector(SHF_REG_NUM - 1 downto 0);
    signal shf_reg_row_defect_addr  : ty_reg_shf4b;
    signal shf_reg_row_defect_wdata : ty_reg_shf16b;
    signal shf_reg_col_defect_wen   : std_logic_vector(SHF_REG_NUM - 1 downto 0);
    signal shf_reg_col_defect_addr  : ty_reg_shf4b;
    signal shf_reg_col_defect_wdata : ty_reg_shf16b;

    constant PARA4 : integer := 4;
    type ty_para4_shf4b  is array (PARA4 - 1 downto 0) of std_logic_vector(4 - 1 downto 0);
    type ty_para4_shf8b  is array (PARA4 - 1 downto 0) of std_logic_vector(8 - 1 downto 0);
    type ty_para4_shf10b is array (PARA4 - 1 downto 0) of std_logic_vector(10 - 1 downto 0);
    type ty_para4_shf12b is array (PARA4 - 1 downto 0) of std_logic_vector(12 - 1 downto 0);
    type ty_para4_shf16b is array (PARA4 - 1 downto 0) of std_logic_vector(16 - 1 downto 0);
    type ty_para4_shf18b is array (PARA4 - 1 downto 0) of std_logic_vector(18 - 1 downto 0);
    type ty_para4_shf19b is array (PARA4 - 1 downto 0) of std_logic_vector(19 - 1 downto 0);
    type ty_para4_shf32b is array (PARA4 - 1 downto 0) of std_logic_vector(32 - 1 downto 0);
    type ty_para4_shf36b is array (PARA4 - 1 downto 0) of std_logic_vector(36 - 1 downto 0);
    signal reg_defect_addr_inc : ty_para4_shf10b;
    signal defect_addr_inc     : ty_para4_shf10b;
    signal defect_rdata        : ty_para4_shf32b;
    signal defect_rdata0       : ty_para4_shf32b;
    signal addrbadd            : ty_para4_shf10b;
    signal addrb               : ty_para4_shf10b;
    signal list_dot            : ty_para4_shf32b;
    signal def_use_dot         : ty_para4_shf8b;
    signal col_news            : ty_para4_shf4b;

    signal defect_wen : std_logic_vector(PARA4 - 1 downto 0);

    signal decd_hsyn   : std_logic_vector(PARA4 - 1 downto 0);
    signal decd_vsyn   : std_logic_vector(PARA4 - 1 downto 0);
    signal decd_hcnt   : ty_para4_shf12b;
    signal decd_vcnt   : ty_para4_shf12b;
    signal decd_data   : ty_para4_shf16b;
    signal decd_data64 : std_logic_vector(64 - 1 downto 0);

    signal sdata_sum_decoder : ty_para4_shf19b;
    signal sdata_mul_decoder : ty_para4_shf18b;
    signal sdata_p           : ty_para4_shf36b;
    signal sdata_p_cut       : ty_para4_shf16b;

    signal col_def : std_logic_vector(PARA4 - 1 downto 0);
    signal row_def : std_logic;

    constant SHF_VID_NUM : integer := 8;
    type ty_vid_shf4b  is array (SHF_VID_NUM - 1 downto 0) of std_logic_vector( 4 - 1 downto 0);
    type ty_vid_shf12b is array (SHF_VID_NUM - 1 downto 0) of std_logic_vector(12 - 1 downto 0);
    type ty_vid_shf64b is array (SHF_VID_NUM - 1 downto 0) of std_logic_vector(64 - 1 downto 0);
    type ty_vid_shf96b is array (SHF_VID_NUM - 1 downto 0) of std_logic_vector(96 - 1 downto 0);

    signal shf_decd_vsyn : std_logic_vector(SHF_VID_NUM - 1 downto 0);
    signal shf_decd_hsyn : std_logic_vector(SHF_VID_NUM - 1 downto 0);
    signal shf_decd_vcnt : ty_vid_shf12b;
    signal shf_decd_hcnt : ty_vid_shf12b;
    signal shf_decd_data : ty_vid_shf64b;
    signal shf_defpoint  : ty_vid_shf96b;

    signal shf_col_def : ty_vid_shf4b;
    signal shf_row_def : std_logic_vector(8 - 1 downto 0);

    constant LIST_LINE_NUM : integer := 16;
    type ty_vid_shf16b is array (LIST_LINE_NUM - 1 downto 0) of std_logic_vector(16 - 1 downto 0);
    type ty_para4_vid_shf16b is array (PARA4 - 1 downto 0) of ty_vid_shf16b;
    signal list_row : ty_vid_shf16b         := (others => (others => '1'));
    signal list_col : ty_para4_vid_shf16b   := (others => (others => (others => '1')));

    signal al_hsyn : std_logic;
    signal al_vsyn : std_logic;
    signal al_hcnt : std_logic_vector(12 - 1 downto 0);
    signal al_vcnt : std_logic_vector(12 - 1 downto 0);
    signal al_data : std_logic_vector(64 - 1 downto 0);
    signal defpoint : std_logic_vector(96 - 1 downto 0);

    signal reg_defect_map   : std_logic;
    signal reg_defect_mode  : std_logic;
    signal reg_defect_wen   : std_logic;
    signal reg_defect_addr  : std_logic_vector(16 - 1 downto 0);
    signal reg_defect_wdata : std_logic_vector(32 - 1 downto 0);
    signal defect_wdata     : std_logic_vector(32 - 1 downto 0);
    signal reg_defect_rdata : std_logic_vector(32 - 1 downto 0);

    signal reg_linedefect_mode : std_logic;

    signal reg_row_defect_wen   : std_logic;
    signal reg_row_defect_addr  : std_logic_vector(4 - 1 downto 0);
    signal reg_row_defect_wdata : std_logic_vector(16 - 1 downto 0);

    signal reg_row_defect_wen0   : std_logic;
    signal reg_row_defect_wen1   : std_logic;
    signal reg_row_defect_addr0  : std_logic_vector(4 - 1 downto 0);
    signal reg_row_defect_wdata0 : std_logic_vector(16 - 1 downto 0);

    signal reg_col_defect_wen   : std_logic;
    signal reg_col_defect_addr  : std_logic_vector(4 - 1 downto 0);
    signal reg_col_defect_wdata : std_logic_vector(16 - 1 downto 0);

    signal col_defect_wen   : std_logic_vector(4 - 1 downto 0);
    signal col_defect_addr  : std_logic_vector(4 - 1 downto 0);
    signal col_defect_wdata : std_logic_vector(16 - 1 downto 0);

    signal col_defect_wen0   : std_logic_vector(4 - 1 downto 0);
    signal col_defect_wen1   : std_logic_vector(4 - 1 downto 0);
    signal col_defect_wdata0 : std_logic_vector(16 - 1 downto 0);

    signal col_defect_waddr_inc : ty_para4_shf4b := (others => (others => '0'));

    signal mask_hsyn_2x2 : std_logic;
    signal mask_vsyn_2x2 : std_logic;
    signal mask_hcnt_2x2 : std_logic_vector(12 - 1 downto 0);
    signal mask_vcnt_2x2 : std_logic_vector(12 - 1 downto 0);
    signal mask_data_1x1 : std_logic_vector(64 - 1 downto 0);
    signal mask_data_1x2 : std_logic_vector(64 - 1 downto 0);
    signal mask_data_1x3 : std_logic_vector(64 - 1 downto 0);
    signal mask_data_2x1 : std_logic_vector(64 - 1 downto 0);
    signal mask_data_2x2 : std_logic_vector(64 - 1 downto 0);
    signal mask_data_2x3 : std_logic_vector(64 - 1 downto 0);
    signal mask_data_3x1 : std_logic_vector(64 - 1 downto 0);
    signal mask_data_3x2 : std_logic_vector(64 - 1 downto 0);
    signal mask_data_3x3 : std_logic_vector(64 - 1 downto 0);

    signal row_inc  : std_logic_vector(4 - 1 downto 0);
    signal col_inc  : ty_para4_shf4b;
    signal row_news : std_logic_vector(4 - 1 downto 0);
    signal dot_def  : std_logic_vector(4 - 1 downto 0);

-- █▄▄ █▀▀ █▀▀ █ █▄░█
-- █▄█ ██▄ █▄█ █ █░▀█ %begin
begin

    U_MASK_PARA4 : MASK_PARA4
    port map (
        clk          => clk,
        rstn         => rstn,

        i_reg_width  => i_reg_width,
        i_reg_height => i_reg_height,

        i_hsyn       => i_hsyn,
        i_vsyn       => i_vsyn,
        i_hcnt       => i_hcnt,
        i_vcnt       => i_vcnt,
        i_data       => i_data,

        o_hsyn_2x2   => mask_hsyn_2x2,
        o_vsyn_2x2   => mask_vsyn_2x2,
        o_hcnt_2x2   => mask_hcnt_2x2,
        o_vcnt_2x2   => mask_vcnt_2x2,

        o_data_1x1   => mask_data_1x1,
        o_data_1x2   => mask_data_1x2,
        o_data_1x3   => mask_data_1x3,
        o_data_2x1   => mask_data_2x1,
        o_data_2x2   => mask_data_2x2,
        o_data_2x3   => mask_data_2x3,
        o_data_3x1   => mask_data_3x1,
        o_data_3x2   => mask_data_3x2,
        o_data_3x3   => mask_data_3x3
    );

    -- ### reg shift

--█▀ █░█ █ █▀▀ ▀█▀
--▄█ █▀█ █ █▀░ ░█░%shift
    --# register input shift pipeline
    process(clk)
    begin
        if (clk'event and clk = '1') then
        --
            shf_reg_defect_map   <= shf_reg_defect_map  (shf_reg_defect_map  'left - 1 downto 0) & i_reg_defect_map;
            shf_reg_defect_mode  <= shf_reg_defect_mode (shf_reg_defect_mode 'left - 1 downto 0) & i_reg_defect_mode;
            shf_reg_defect_wen   <= shf_reg_defect_wen  (shf_reg_defect_wen  'left - 1 downto 0) & i_reg_defect_wen;
            shf_reg_defect_addr  <= shf_reg_defect_addr (shf_reg_defect_addr 'left - 1 downto 0) & i_reg_defect_addr;
            shf_reg_defect_wdata <= shf_reg_defect_wdata(shf_reg_defect_wdata'left - 1 downto 0) & i_reg_defect_wdata;
                reg_defect_map   <= shf_reg_defect_map  (shf_reg_defect_map  'left);
                reg_defect_mode  <= shf_reg_defect_mode (shf_reg_defect_mode 'left);
                reg_defect_addr  <= shf_reg_defect_addr (shf_reg_defect_addr 'left);
                reg_defect_wdata <= shf_reg_defect_wdata(shf_reg_defect_wdata'left);

--              reg_defect_wen   <= shf_reg_defect_wen  (shf_reg_defect_wen  'left);
                -- rising edge
                reg_defect_wen   <= (not (shf_reg_defect_wen(shf_reg_defect_wen'left - 1))) and
                                         (shf_reg_defect_wen(shf_reg_defect_wen'left));
            --### row column ###
--#no use#  shf_reg_linedefect_mode  <= shf_reg_linedefect_mode (shf_reg_linedefect_mode 'left-1 downto 0) & i_reg_linedefect_mode ;
            shf_reg_row_defect_wen   <= shf_reg_row_defect_wen  (shf_reg_row_defect_wen  'left - 1 downto 0) & i_reg_row_defect_wen;
            shf_reg_row_defect_addr  <= shf_reg_row_defect_addr (shf_reg_row_defect_addr 'left - 1 downto 0) & i_reg_row_defect_addr;
            shf_reg_row_defect_wdata <= shf_reg_row_defect_wdata(shf_reg_row_defect_wdata'left - 1 downto 0) & i_reg_row_defect_wdata;
            shf_reg_col_defect_wen   <= shf_reg_col_defect_wen  (shf_reg_col_defect_wen  'left - 1 downto 0) & i_reg_col_defect_wen;
            shf_reg_col_defect_addr  <= shf_reg_col_defect_addr (shf_reg_col_defect_addr 'left - 1 downto 0) & i_reg_col_defect_addr;
            shf_reg_col_defect_wdata <= shf_reg_col_defect_wdata(shf_reg_col_defect_wdata'left - 1 downto 0) & i_reg_col_defect_wdata;
--#no use#      reg_linedefect_mode  <= shf_reg_row_defect_mode (shf_reg_row_defect_mode 'left);
                reg_row_defect_wen   <= shf_reg_row_defect_wen  (shf_reg_row_defect_wen  'left);
                reg_row_defect_addr  <= shf_reg_row_defect_addr (shf_reg_row_defect_addr 'left);
                reg_row_defect_wdata <= shf_reg_row_defect_wdata(shf_reg_row_defect_wdata'left);
                reg_col_defect_wen   <= shf_reg_col_defect_wen  (shf_reg_col_defect_wen  'left);
                reg_col_defect_addr  <= shf_reg_col_defect_addr (shf_reg_col_defect_addr 'left);
                reg_col_defect_wdata <= shf_reg_col_defect_wdata(shf_reg_col_defect_wdata'left);
        --
        end if;
    end process;

-- clear <= '1' when shf_reg_defect_wen(shf_reg_defect_wen'left)='1' and
--                   shf_reg_defect_addr(shf_reg_defect_addr'left)=0 else
--                   '0';

    --### point write
    defect_wen(0) <= '1' when reg_defect_wen = '1' and (reg_defect_wdata(2 - 1 downto 0) = "00" or reg_defect_wdata = x"00ffffff") else '0';
    defect_wen(1) <= '1' when reg_defect_wen = '1' and (reg_defect_wdata(2 - 1 downto 0) = "01" or reg_defect_wdata = x"00ffffff") else '0';
    defect_wen(2) <= '1' when reg_defect_wen = '1' and (reg_defect_wdata(2 - 1 downto 0) = "10" or reg_defect_wdata = x"00ffffff") else '0';
    defect_wen(3) <= '1' when reg_defect_wen = '1' and (reg_defect_wdata(2 - 1 downto 0) = "11" or reg_defect_wdata = x"00ffffff") else '0';
    defect_addr_inc <= reg_defect_addr_inc;
    defect_wdata    <= reg_defect_wdata(32 - 1 downto 24) & reg_defect_wdata(24 - 1 downto 12) & "00" & reg_defect_wdata(12 - 1 downto 2);

    --### column write
    col_defect_wen(0) <= '1' when reg_col_defect_wen = '1' and reg_col_defect_wdata(2 - 1 downto 0) = "00" else '0';
    col_defect_wen(1) <= '1' when reg_col_defect_wen = '1' and reg_col_defect_wdata(2 - 1 downto 0) = "01" else '0';
    col_defect_wen(2) <= '1' when reg_col_defect_wen = '1' and reg_col_defect_wdata(2 - 1 downto 0) = "10" else '0';
    col_defect_wen(3) <= '1' when reg_col_defect_wen = '1' and reg_col_defect_wdata(2 - 1 downto 0) = "11" else '0';
    col_defect_addr   <= reg_col_defect_addr;
    col_defect_wdata  <= reg_col_defect_wdata(16 - 1 downto 12) & "00" & reg_col_defect_wdata(12 - 1 downto 2);

-- █▀█ █▀█ █░█░█   █▀▄▀█ █▀▀ █▀▄▀█
-- █▀▄ █▄█ ▀▄▀▄▀   █░▀░█ ██▄ █░▀░█
    --# row addressing and memory
    process(clk)
    begin
        if (clk'event and clk = '1') then
        --
            reg_row_defect_wen0   <= reg_row_defect_wen;
            reg_row_defect_wen1   <= reg_row_defect_wen0;
            reg_row_defect_addr0  <= reg_row_defect_addr;
            reg_row_defect_wdata0 <= reg_row_defect_wdata;
            --### rising clear
            if reg_row_defect_wen0 = '0' and reg_row_defect_wen = '1' and reg_row_defect_addr = 0 then
                list_row <= (others => (others => '1'));
            elsif reg_row_defect_wen1 = '0' and reg_row_defect_wen0 = '1' then
                list_row(conv_integer(reg_row_defect_addr0)) <= reg_row_defect_wdata0;
            end if;
        --
        end if;
    end process;

    --# row read address and row line match
    process(clk)
    begin
        if (clk'event and clk = '1') then
        --
            --### row read
            if mask_vsyn_2x2 = '0' then
                row_inc <= (others => '0');
            else
                if list_row(conv_integer(row_inc))(12 - 1 downto 0) < mask_vcnt_2x2 then
                    row_inc <= row_inc + '1';
                end if;
            end if;

            --## row line match
            --# upper bit used by double line detect.
            if list_row(conv_integer(row_inc))(12 - 1 downto 0) = mask_vcnt_2x2 then
                row_def  <= '1';
                row_news <= list_row(conv_integer(row_inc))(16 - 1 downto 12); --double line check NEWS
            else
                row_def  <= '0';
                row_news <= (others => '0');
            end if;
        --
        end if;
    end process;

-- █░█ █▀█ ▄▀█ █▀█ ▄▀█   █▀▀ █▀█ █▀█
-- ▀▀█ █▀▀ █▀█ █▀▄ █▀█   █▀░ █▄█ █▀▄
gen_mem_point : for i in 0 to 4 - 1 generate
begin

    -- █▀▀ █▀█ █░░   █▀▄▀█ █▀▀ █▀▄▀█
    -- █▄▄ █▄█ █▄▄   █░▀░█ ██▄ █░▀░█
    --# column write and read address
    process(clk)
    begin
        if (clk'event and clk = '1') then
        --
            --# write
            col_defect_wen0   <= col_defect_wen;
            col_defect_wen1   <= col_defect_wen0;
            col_defect_wdata0 <= col_defect_wdata;
            --### write address init by addr 0
            if col_defect_wen0(i) = '0' and reg_col_defect_wen = '1' and col_defect_addr = 0 then
                col_defect_waddr_inc(i) <= (others => '0');
                list_col(i) <= (others => (others => '1'));
            --## write address increment by rising edge
            elsif col_defect_wen1(i) = '0' and col_defect_wen0(i) = '1' then
                col_defect_waddr_inc(i) <= col_defect_waddr_inc(i) + '1';
                list_col(i)(conv_integer(col_defect_waddr_inc(i))) <= col_defect_wdata0;
            end if;

            --# column read address
            if mask_hsyn_2x2 = '0' then
                col_inc(i) <= (others => '0');
            else
                if list_col(i)(conv_integer(col_inc(i)))(12 - 1 downto 0) <= mask_hcnt_2x2 then
                    col_inc(i) <= col_inc(i) + '1';
                end if;
            end if;

--          if list_col(i)(conv_integer(col_inc(i))) = mask_hcnt_2x2                then
--             col_def(i) <= '1';
--          else
--             col_def(i) <= '0';
--          end if;
        --
        end if;
    end process;

    --### column line match
    col_def(i)   <= '1' when list_col(i)(conv_integer(col_inc(i)))(12 - 1 downto 0) = mask_hcnt_2x2 else
                    '0';
    col_news(i)  <= list_col(i)(conv_integer(col_inc(i)))(16 - 1 downto 12) when col_def(i) = '1' else
                    (others => '0');

-- █▀▄ █▀█ ▀█▀   █▀▄▀█ █▀▀ █▀▄▀█
-- █▄▀ █▄█ ░█░   █░▀░█ ██▄ █░▀░█
    --# point write address for 4 memory
    process(clk)
    begin
        if (clk'event and clk = '1') then
        --
            if shf_reg_defect_wen(shf_reg_defect_wen'left) = '1' and
               shf_reg_defect_addr(shf_reg_defect_addr'left) = 0 then --# addr 0 clear
                reg_defect_addr_inc(i) <= (others => '0');
            elsif defect_wen(i) = '1' then
                reg_defect_addr_inc(i) <= reg_defect_addr_inc(i) + '1';
            end if;
        --
        end if;
    end process;

    -- ### point memory 1024*4
    u_mem_32_1024 : mem_32_1024
    PORT MAP (
        clka   => clk,
        wea(0) => defect_wen(i),
        addra  => defect_addr_inc(i)(10 - 1 downto 0),
        dina   => defect_wdata,
        douta  => defect_rdata(i),
        clkb   => clk,
        web(0) => '0',
        addrb  => addrbadd(i),
        dinb   => (others => '0'), -- dinb,
        doutb  => list_dot(i)
    );

    --# latch defect read data on write
    process(clk)
    begin
        if (clk'event and clk = '1') then
        --
            if defect_wen(i) = '1' then
                defect_rdata0(i) <= defect_rdata(i);
            end if;
        --
        end if;
    end process;

    o_reg_defect_rdata <=
        defect_rdata0(0) when reg_defect_wdata(2 - 1 downto 0) = "00" else
        defect_rdata0(1) when reg_defect_wdata(2 - 1 downto 0) = "01" else
        defect_rdata0(2) when reg_defect_wdata(2 - 1 downto 0) = "10" else
        defect_rdata0(3) when reg_defect_wdata(2 - 1 downto 0) = "11" else
        (others => '0');

    --# point memory read address increment
    process(clk)
    begin
        if (clk'event and clk = '1') then
        --
            if mask_vsyn_2x2 = '0' then
                addrb(i) <= (others => '0');
            elsif mask_vsyn_2x2 = '1' and
                  mask_hsyn_2x2 = '1' and
                  mask_vcnt_2x2 = list_dot(i)(24 - 1 downto 12) and
                  mask_hcnt_2x2 = list_dot(i)(12 - 1 downto 0) then
                addrb(i) <= addrb(i) + '1';
            end if;
        --
        end if;
    end process;

    dot_def(i)  <= '1' when mask_vsyn_2x2 = '1' and
                            mask_hsyn_2x2 = '1' and
                            mask_vcnt_2x2 = list_dot(i)(24 - 1 downto 12) and
                            mask_hcnt_2x2 = list_dot(i)(12 - 1 downto 0) else
                   '0';
    addrbadd(i) <= addrb(i) + '1' when mask_vsyn_2x2 = '1' and
                                        mask_hsyn_2x2 = '1' and
                                        mask_vcnt_2x2 = list_dot(i)(24 - 1 downto 12) and
                                        mask_hcnt_2x2 = list_dot(i)(12 - 1 downto 0) else
                   addrb(i);

-- █▀█ █▀▀ █▀▀ ░ █▀▄ █▀█ ▀█▀ ▄▄ █▀ █▀▀ █░░
-- █▀▄ ██▄ █▀░ ▄ █▄▀ █▄█ ░█░ ░░ ▄█ ██▄ █▄▄
-- ### 1 pixel ref
--  def_use_dot(i) <= b"010_00_000" when row_def='1'    and row_news="0001" else  --# double line south
--                    b"000_00_010" when row_def='1'    and row_news="1000" else  --# north
--                    b"010_00_010" when row_def='1'    and row_news="0000" else
--                    b"000_10_000" when col_def(i)='1' and col_news(i)="0100" else --# east
--                    b"000_01_000" when col_def(i)='1' and col_news(i)="0010" else --# west
--                    b"000_11_000" when col_def(i)='1' and col_news(i)="0000" else
--                    list_dot(i)(32-1 downto 24);
-- ### 3 pixel ref
    def_use_dot(i) <= list_dot(i)(32 - 1 downto 24) when dot_def(i) = '1'                        else
                      b"111_00_000"                  when row_def = '1'    and row_news = "0001"   else --# double line south
                      b"000_00_111"                  when row_def = '1'    and row_news = "1000"   else --# north
                      b"111_00_111"                  when row_def = '1'    and row_news = "0000"   else
                      b"100_10_100"                  when col_def(i) = '1' and col_news(i) = "0100" else --# east
                      b"001_01_001"                  when col_def(i) = '1' and col_news(i) = "0010" else --# west
                      b"101_11_101"                  when col_def(i) = '1' and col_news(i) = "0000" else
                      b"000_00_000";

    U0_DEFECT_DECODER : DEFECT_DECODER -- 1 Delay
    port map (
        idata_clk    => clk,
        idata_rstn   => rstn,

        idefect_data => def_use_dot(i),

        ihsync       => mask_hsyn_2x2,
        ivsync       => mask_vsyn_2x2,
        ihcnt        => mask_hcnt_2x2,
        ivcnt        => mask_vcnt_2x2,
        idata_1x1    => mask_data_1x1(16 * (i + 1) - 1 downto 16 * i),
        idata_1x2    => mask_data_1x2(16 * (i + 1) - 1 downto 16 * i),
        idata_1x3    => mask_data_1x3(16 * (i + 1) - 1 downto 16 * i),
        idata_2x1    => mask_data_2x1(16 * (i + 1) - 1 downto 16 * i),
        idata_2x2    => mask_data_2x2(16 * (i + 1) - 1 downto 16 * i),
        idata_2x3    => mask_data_2x3(16 * (i + 1) - 1 downto 16 * i),
        idata_3x1    => mask_data_3x1(16 * (i + 1) - 1 downto 16 * i),
        idata_3x2    => mask_data_3x2(16 * (i + 1) - 1 downto 16 * i),
        idata_3x3    => mask_data_3x3(16 * (i + 1) - 1 downto 16 * i),

        ohsync       => decd_hsyn(i),
        ovsync       => decd_vsyn(i),
        ovcnt        => decd_vcnt(i),
        ohcnt        => decd_hcnt(i),
        odata        => decd_data(i),

        odata_sum    => sdata_sum_decoder(i),
        odata_mul    => sdata_mul_decoder(i)
    );

    u_MULTI_19x17 : MULTI_19x17 -- 3 delay
    port map (
        clk => clk,
        ce  => rstn,
        a   => sdata_sum_decoder(i),
        b   => sdata_mul_decoder(i)(16 downto 0),
        p   => sdata_p(i)
    );

    --### calc data
    sdata_p_cut(i) <= (others => '1') when sdata_p(i)(36 - 1 downto 32) > 0 else --# over
                      sdata_p(i)(32 - 1 downto 16);

end generate gen_mem_point;
--### for gen END ###

    decd_data64 <= decd_data(3) &
                   decd_data(2) &
                   decd_data(1) &
                   decd_data(0);
    --# dot mem out
    defpoint    <= list_dot(3)(24 - 1 downto 0) &
                   list_dot(2)(24 - 1 downto 0) &
                   list_dot(1)(24 - 1 downto 0) &
                   list_dot(0)(24 - 1 downto 0);

-- █▀▄ ▄▀█ ▀█▀ ▄▀█ ░ █▀ █▀▀ █░░
-- █▄▀ █▀█ ░█░ █▀█ ▄ ▄█ ██▄ █▄▄
    --# data output select with defect map / defect correction / bypass
    process(clk)
    begin
        if (clk'event and clk = '1') then
        --
            shf_decd_hsyn <= shf_decd_hsyn(shf_decd_hsyn'left - 1 downto 0) & decd_hsyn(0);
            shf_decd_vsyn <= shf_decd_vsyn(shf_decd_vsyn'left - 1 downto 0) & decd_vsyn(0);
            shf_decd_vcnt <= shf_decd_vcnt(shf_decd_vcnt'left - 1 downto 0) & decd_vcnt(0);
            shf_decd_hcnt <= shf_decd_hcnt(shf_decd_hcnt'left - 1 downto 0) & decd_hcnt(0);
            shf_decd_data <= shf_decd_data(shf_decd_data'left - 1 downto 0) & decd_data64;
            shf_defpoint  <= shf_defpoint (shf_defpoint 'left - 1 downto 0) & defpoint;

            shf_row_def <= shf_row_def(shf_row_def'left - 1 downto 0) & row_def;
            shf_col_def <= shf_col_def(shf_col_def'left - 1 downto 0) & col_def;

            al_hsyn <= shf_decd_hsyn(2);
            al_vsyn <= shf_decd_vsyn(2);
            al_vcnt <= shf_decd_vcnt(2);
            al_hcnt <= shf_decd_hcnt(2);
            --### black white Defect map
            if reg_defect_map = '1' then
                if shf_row_def(4) = '1' or shf_col_def(4)(0) = '1' or
                  (shf_defpoint(4)(24 - 1 downto 12) = shf_decd_vcnt(2) and
                   shf_defpoint(4)(12 - 1 downto  0) = shf_decd_hcnt(2)) then
                    al_data(16 - 1 downto 0) <= (others => '1');
                else
                    al_data(16 - 1 downto 0) <= (others => '0');
                end if;
                if shf_row_def(4) = '1' or shf_col_def(4)(1) = '1' or
                  (shf_defpoint(4)(48 - 1 downto 36) = shf_decd_vcnt(2) and
                   shf_defpoint(4)(36 - 1 downto 24) = shf_decd_hcnt(2)) then
                    al_data(32 - 1 downto 16) <= (others => '1');
                else
                    al_data(32 - 1 downto 16) <= (others => '0');
                end if;
                if shf_row_def(4) = '1' or shf_col_def(4)(2) = '1' or
                  (shf_defpoint(4)(72 - 1 downto 60) = shf_decd_vcnt(2) and
                   shf_defpoint(4)(60 - 1 downto 48) = shf_decd_hcnt(2)) then
                    al_data(48 - 1 downto 32) <= (others => '1');
                else
                    al_data(48 - 1 downto 32) <= (others => '0');
                end if;
                if shf_row_def(4) = '1' or shf_col_def(4)(3) = '1' or
                  (shf_defpoint(4)(96 - 1 downto 84) = shf_decd_vcnt(2) and
                   shf_defpoint(4)(84 - 1 downto 72) = shf_decd_hcnt(2)) then
                    al_data(64 - 1 downto 48) <= (others => '1');
                else
                    al_data(64 - 1 downto 48) <= (others => '0');
                end if;
            --### defect enable
            elsif reg_defect_mode = '1' then
                if shf_row_def(4) = '1' or shf_col_def(4)(0) = '1' or
                  (shf_defpoint(4)(24 - 1 downto 12) = shf_decd_vcnt(2) and
                   shf_defpoint(4)(12 - 1 downto  0) = shf_decd_hcnt(2)) then
                    al_data(16 - 1 downto 0) <= sdata_p_cut(0);
                else
                    al_data(16 - 1 downto 0) <= shf_decd_data(2)(16 - 1 downto 0);
                end if;
                if shf_row_def(4) = '1' or shf_col_def(4)(1) = '1' or
                  (shf_defpoint(4)(48 - 1 downto 36) = shf_decd_vcnt(2) and
                   shf_defpoint(4)(36 - 1 downto 24) = shf_decd_hcnt(2)) then
                    al_data(32 - 1 downto 16) <= sdata_p_cut(1);
                else
                    al_data(32 - 1 downto 16) <= shf_decd_data(2)(32 - 1 downto 16);
                end if;
                if shf_row_def(4) = '1' or shf_col_def(4)(2) = '1' or
                  (shf_defpoint(4)(72 - 1 downto 60) = shf_decd_vcnt(2) and
                   shf_defpoint(4)(60 - 1 downto 48) = shf_decd_hcnt(2)) then
                    al_data(48 - 1 downto 32) <= sdata_p_cut(2);
                else
                    al_data(48 - 1 downto 32) <= shf_decd_data(2)(48 - 1 downto 32);
                end if;
                if shf_row_def(4) = '1' or shf_col_def(4)(3) = '1' or
                  (shf_defpoint(4)(96 - 1 downto 84) = shf_decd_vcnt(2) and
                   shf_defpoint(4)(84 - 1 downto 72) = shf_decd_hcnt(2)) then
                    al_data(64 - 1 downto 48) <= sdata_p_cut(3);
                else
                    al_data(64 - 1 downto 48) <= shf_decd_data(2)(64 - 1 downto 48);
                end if;
            else --### bypass
                al_data <= shf_decd_data(2);
            end if;
        --
        end if;
    end process;

    o_hsyn <= al_hsyn;
    o_vsyn <= al_vsyn;
    o_hcnt <= al_hcnt;
    o_vcnt <= al_vcnt; --# h v swap error 230216
    o_data <= al_data when al_hsyn = '1' and al_vsyn = '1' else
              (others => '0');

--  u_ila_col_def : ila_col_def
--  PORT MAP (
--      clk      => clk                    ,
--      probe0(0)=> reg_col_defect_wen     , --  1
--      probe1   => reg_col_defect_addr    , --  4
--      probe2   => reg_col_defect_wdata   , -- 16
--      probe3   => col_defect_wen         , --  4
--      probe4   => col_def                , --  4
--      probe5   => col_defect_wdata       , -- 16
--      probe6   => list_col(0)(0)         , -- 16
--      probe7   => list_col(0)(1)         , -- 16
--      probe8   => list_col(0)(2)         , -- 16
--      probe9   => list_col(1)(0)         , -- 16
--      probe10  => list_col(1)(1)         , -- 16
--      probe11  => list_col(1)(2)         , -- 16
--      probe12  => list_col(2)(0)         , -- 16
--      probe13  => list_col(2)(1)         , -- 16
--      probe14  => list_col(2)(2)         , -- 16
--      probe15  => list_col(3)(0)         , -- 16
--      probe16  => "0000" & mask_hcnt_2x2 , -- 16
--      probe17  => "0000" & mask_vcnt_2x2   -- 16
--  );
--
--  u_ila_row_def : ila_col_def
--  PORT MAP (
--      clk      => clk                    ,
--      probe0(0)=> reg_row_defect_wen     , --  1
--      probe1   => reg_row_defect_addr    , --  4
--      probe2   => reg_row_defect_wdata   , -- 16
--      probe3   => "000" & row_def        , --  4
--      probe4   => reg_row_defect_addr0   , --  4
--      probe5   => reg_row_defect_wdata0  , -- 16
--      probe6   => list_row(0)            , -- 16
--      probe7   => list_row(1)            , -- 16
--      probe8   => list_row(2)            , -- 16
--      probe9   => list_row(3)            , -- 16
--      probe10  => list_row(4)            , -- 16
--      probe11  => list_row(5)            , -- 16
--      probe12  => list_row(6)            , -- 16
--      probe13  => list_row(7)            , -- 16
--      probe14  => list_row(8)            , -- 16
--      probe15  => list_row(9)            , -- 16
--      probe16  => "0000" & mask_hcnt_2x2 , -- 16
--      probe17  => "0000" & mask_vcnt_2x2   -- 16
--  );

end Behavioral;
