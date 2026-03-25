library IEEE;
    use IEEE.STD_LOGIC_1164.ALL;
    use IEEE.STD_LOGIC_ARITH.ALL;
    use IEEE.STD_LOGIC_UNSIGNED.ALL;

    use WORK.TOP_HEADER.ALL;

entity GEV_DATA_MAPPING is
    port (
        igev_clk   : in  std_logic;
        igev_rstn  : in  std_logic;

        ireg_out_en : in  std_logic;

        ihsync : in  std_logic;
        ivsync : in  std_logic;
        ihcnt  : in  std_logic_vector(9 downto 0);
        ivcnt  : in  std_logic_vector(11 downto 0);
        idata  : in  std_logic_vector(63 downto 0);

        ofb_frame : out std_logic;
        ofb_dv    : out std_logic;
        ofb_data  : out std_logic_vector(63 downto 0);
        ofb_width : out std_logic_vector( 2 downto 0)
    );
end GEV_DATA_MAPPING;

architecture Behavioral of GEV_DATA_MAPPING is

    signal sreg_out_en : std_logic;

begin

    --# Latch output enable on vsync inactive
    process(igev_clk)
    begin
        if(igev_clk'event and igev_clk = '1') then
            if(igev_rstn = '0') then
                sreg_out_en <= '0';
            else
                if(ivsync = '0') then
                    sreg_out_en <= ireg_out_en;
                end if;
            end if;
        end if;
    end process;

    --# Map GEV data output with byte-swap
    process(igev_clk)
    begin
        if(igev_clk'event and igev_clk = '1') then
            if(igev_rstn = '0') then
                ofb_frame <= '0';
                ofb_dv    <= '0';
                ofb_data  <= (others => '0');
                ofb_width <= (others => '0');
            else
                if(sreg_out_en = '1') then
                    ofb_frame <= ivsync;
                    ofb_dv    <= ihsync;
                    ofb_data  <= idata(15 downto 0) & idata(31 downto 16) & idata(47 downto 32) & idata(63 downto 48);
                    ofb_width <= "111";
                else
                    ofb_frame <= '0';
                    ofb_dv    <= '0';
                    ofb_data  <= (others => '0');
                    ofb_width <= (others => '0');
                end if;
            end if;
        end if;
    end process;

end Behavioral;
