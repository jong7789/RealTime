library IEEE;
    use IEEE.STD_LOGIC_1164.ALL;
    use IEEE.STD_LOGIC_UNSIGNED.ALL;
    use IEEE.STD_LOGIC_ARITH.ALL;
    use WORK.TOP_HEADER.ALL;

entity EDGE is
port (
    clk               : in  std_logic;

    i_reg_width       : in  std_logic_vector(11 downto 0);
    i_reg_height      : in  std_logic_vector(11 downto 0);

    i_reg_edge_ctrl   : in  std_logic_vector(16-1 downto 0);
    i_reg_edge_value  : in  std_logic_vector(16-1 downto 0);
    i_reg_edge_top    : in  std_logic_vector(16-1 downto 0);
    i_reg_edge_left   : in  std_logic_vector(16-1 downto 0);
    i_reg_edge_right  : in  std_logic_vector(16-1 downto 0);
    i_reg_edge_bottom : in  std_logic_vector(16-1 downto 0);

    i_hsyn            : in  std_logic;
    i_vsyn            : in  std_logic;
    i_hcnt            : in  std_logic_vector(12-1 downto 0);
    i_vcnt            : in  std_logic_vector(12-1 downto 0);
    i_data            : in  std_logic_vector(16-1 downto 0);

    o_hsyn            : out std_logic;
    o_vsyn            : out std_logic;
    o_hcnt            : out std_logic_vector(12-1 downto 0);
    o_vcnt            : out std_logic_vector(12-1 downto 0);
    o_data            : out std_logic_vector(16-1 downto 0)
);
end EDGE;

architecture Behavioral of EDGE is

    constant CDSH : integer := 2; --+1

    type ty_sh_12b is array (CDSH downto 0) of std_logic_vector(12-1 downto 0);
    signal sh_reg_width  : ty_sh_12b;
    signal sh_reg_height : ty_sh_12b;

    type ty_sh_16b is array (CDSH downto 0) of std_logic_vector(16-1 downto 0);
    signal sh_reg_edge_ctrl   : ty_sh_16b;
    signal sh_reg_edge_value  : ty_sh_16b;
    signal sh_reg_edge_top    : ty_sh_16b;
    signal sh_reg_edge_left   : ty_sh_16b;
    signal sh_reg_edge_right  : ty_sh_16b;
    signal sh_reg_edge_bottom : ty_sh_16b;

    signal reg_width       : std_logic_vector(12-1 downto 0);
    signal reg_height      : std_logic_vector(12-1 downto 0);
    signal reg_edge_ctrl   : std_logic_vector(16-1 downto 0);
    signal reg_edge_value  : std_logic_vector(16-1 downto 0);
    signal reg_edge_top    : std_logic_vector(16-1 downto 0);
    signal reg_edge_left   : std_logic_vector(16-1 downto 0);
    signal reg_edge_right  : std_logic_vector(16-1 downto 0);
    signal reg_edge_bottom : std_logic_vector(16-1 downto 0);

    signal reg_edge_en : std_logic;

    signal hsyn : std_logic;
    signal vsyn : std_logic;
    signal hcnt : std_logic_vector(12-1 downto 0);
    signal vcnt : std_logic_vector(12-1 downto 0);
    signal data : std_logic_vector(16-1 downto 0);

begin

    --# register cdc
    process(clk)
    begin
        if(clk'event and clk = '1') then
        --
            sh_reg_width       <= sh_reg_width      (CDSH-1 downto 0) & i_reg_width      ;
            sh_reg_height      <= sh_reg_height     (CDSH-1 downto 0) & i_reg_height     ;
            sh_reg_edge_ctrl   <= sh_reg_edge_ctrl  (CDSH-1 downto 0) & i_reg_edge_ctrl  ;
            sh_reg_edge_value  <= sh_reg_edge_value (CDSH-1 downto 0) & i_reg_edge_value ;
            sh_reg_edge_top    <= sh_reg_edge_top   (CDSH-1 downto 0) & i_reg_edge_top   ;
            sh_reg_edge_left   <= sh_reg_edge_left  (CDSH-1 downto 0) & i_reg_edge_left  ;
            sh_reg_edge_right  <= sh_reg_edge_right (CDSH-1 downto 0) & i_reg_edge_right ;
            sh_reg_edge_bottom <= sh_reg_edge_bottom(CDSH-1 downto 0) & i_reg_edge_bottom;

            reg_width       <= sh_reg_width      (CDSH);
            reg_height      <= sh_reg_height     (CDSH);
            reg_edge_ctrl   <= sh_reg_edge_ctrl  (CDSH);
            reg_edge_value  <= sh_reg_edge_value (CDSH);
            reg_edge_top    <= sh_reg_edge_top   (CDSH);
            reg_edge_left   <= sh_reg_edge_left  (CDSH);
            reg_edge_right  <= sh_reg_edge_right (CDSH);
            reg_edge_bottom <= sh_reg_edge_bottom(CDSH);

            reg_edge_en <= reg_edge_ctrl(0);
        --
        end if;
    end process;

    --# edge mask process
    process(clk)
    begin
        if(clk'event and clk = '1') then
        --
            if reg_edge_en = '0' then --# disable
                data <= i_data;
            elsif reg_edge_top <= i_vcnt and i_vcnt < reg_edge_bottom and
                  reg_edge_left <= i_hcnt and i_hcnt < reg_edge_right then
                data <= i_data;
            else
                data <= reg_edge_value;
            end if;

            hsyn <= i_hsyn;
            vsyn <= i_vsyn;
            hcnt <= i_hcnt;
            vcnt <= i_vcnt;
        --
        end if;
    end process;

    o_hsyn <= hsyn;
    o_vsyn <= vsyn;
    o_hcnt <= hcnt;
    o_vcnt <= vcnt;
    o_data <= data;

end Behavioral;
