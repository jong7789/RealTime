----------------------------------------------------------------------------------
-- Company: DRTech
-- Engineer: bhmoon
--
-- Create Date: 2021/03/29 11:51:27
-- Design Name:
-- Module Name: IMG_AVG - Behavioral
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

entity IMG_AVG is
    generic (
        para : integer := 4 -- 4 or 1
    );
    port (
        iclk   : in    std_logic;
        ivsync : in    std_logic;
        ihsync : in    std_logic;
        idata  : in    std_logic_vector((para*16)-1 downto 0);

        oreg_img_avg : out   std_logic_vector(32 - 1 downto 0)
    );
end entity img_avg;

architecture behavioral of img_avg is

    component div_24_8
        port (
            aclk                   : in    std_logic;
            s_axis_divisor_tvalid  : in    std_logic;
            s_axis_divisor_tdata   : in    std_logic_vector(7 downto 0);
            s_axis_dividend_tvalid : in    std_logic;
            s_axis_dividend_tdata  : in    std_logic_vector(23 downto 0);
            m_axis_dout_tvalid     : out   std_logic;
            m_axis_dout_tdata      : out   std_logic_vector(31 downto 0)
        );
    end component;

    component div_24_28_lutmult
        port (
            aclk                   : in    std_logic;
            s_axis_divisor_tvalid  : in    std_logic;
            s_axis_divisor_tdata   : in    std_logic_vector(7 downto 0);
            s_axis_dividend_tvalid : in    std_logic;
            s_axis_dividend_tdata  : in    std_logic_vector(15 downto 0);
            m_axis_dout_tvalid     : out   std_logic;
            m_axis_dout_tdata      : out   std_logic_vector(23 downto 0)
        );
    end component;

    signal clk : std_logic;
    signal vSh : std_logic_vector(8 - 1 downto 0) := (others=>'0');
    signal hSh : std_logic_vector(8 - 1 downto 0) := (others=>'0');

    type   type_dsh is array ( 8 - 1 downto 0) of std_logic_vector( (para * 16) - 1 downto 0);
    signal dsh : type_dsh := (others=> (others=> '0'));

    signal divEn  : std_logic := '0';
    signal sum    : std_logic_vector(64 - 1 downto 0) := (others=> '0');
    signal cnt    : std_logic_vector(32 - 1 downto 0) := (others=> '0');
    signal sumLat : std_logic_vector(64 - 1 downto 0) := (others=> '0');
    signal cntLat : std_logic_vector(32 - 1 downto 0) := (others=> '0');

    signal s_axis_divisor_tvalid  : std_logic;
    signal s_axis_divisor_tdata   : std_logic_vector(31 downto 0);
    signal s_axis_dividend_tvalid : std_logic;
    signal s_axis_dividend_tdata  : std_logic_vector(63 downto 0);
    signal m_axis_dout_tvalid     : std_logic;
    signal m_axis_dout_tdata      : std_logic_vector(32 - 1 downto 0);
    signal s_axis_divisor_tready  : std_logic;
    signal s_axis_dividend_tready : std_logic;

    signal resultEn  : std_logic := '0';
    signal result    : std_logic_vector(32 - 1 downto 0) := (others=> '0');
    signal resultcnt : std_logic_vector(16 - 1 downto 0) := (others=> '0');

begin

    clk <= iclk;

    process (clk)
    begin
        if clk'event and clk='1' then
  --
            vSh <= vSh(vSh'left - 1 downto 0) & ivsync;
            hSh <= hSh(hSh'left - 1 downto 0) & ihsync;
            dsh <= dsh(dsh'left - 1 downto 0) & idata;

            if vSh(2)= '1' then     -- ### v
                if hSh(2)= '1' then -- ### h
  --
                    if para = 4 then
                        cnt <= cnt + x"4";
                        sum <= sum + dsh(3)(16 * 1 - 1 downto 16 * 0)+
                               dsh(3)(16 * 2 - 1 downto 16 * 1)+
                               dsh(3)(16 * 3 - 1 downto 16 * 2)+
                               dsh(3)(16 * 4 - 1 downto 16 * 3);
                    elsif para = 1 then
                        cnt <= cnt + x"1";
                        sum <= sum + dsh(3);
                    end if;
  --
                end if;
            else
                cnt <= (others=> '0');
                sum <= (others=> '0');
            end if;

            if vSh(3)= '1' and vSh(2)='0' then -- V fall edge
                if para = 4 then
                    cntLat <= cnt + x"4";
                else
                    cntLat <= cnt + x"1";
                end if;
                sumLat <= sum;
                divEn  <= '1';
            else
                divEn <= '0';
            end if;

  --
        end if;
    end process;

    s_axis_dividend_tvalid <= divEn;
    s_axis_dividend_tdata  <= sumLat;
    s_axis_divisor_tvalid  <= divEn;
    s_axis_divisor_tdata   <= cntLat;

--#    process (clk)
--#    begin
--#        if clk'event and clk='1' then
--#        --
--#            if divEn = '1' then  --# 231222
--#              --   if 2**16 < s_axis_divisor_tdata then m_axis_dout_tdata(16-1 downto 0) <= s_axis_dividend_tdata(16+16-1 downto 16);  
--#              --elsif 2**17 < s_axis_divisor_tdata then m_axis_dout_tdata(16-1 downto 0) <= s_axis_dividend_tdata(17+16-1 downto 17);  
--#              --elsif 2**18 < s_axis_divisor_tdata then m_axis_dout_tdata(16-1 downto 0) <= s_axis_dividend_tdata(18+16-1 downto 18);  
--#              --elsif 2**19 < s_axis_divisor_tdata then m_axis_dout_tdata(16-1 downto 0) <= s_axis_dividend_tdata(19+16-1 downto 19);  
--#              --elsif 2**20 < s_axis_divisor_tdata then m_axis_dout_tdata(16-1 downto 0) <= s_axis_dividend_tdata(20+16-1 downto 20);  
--#                   if 2**21 < s_axis_divisor_tdata then m_axis_dout_tdata(16-1 downto 0) <= s_axis_dividend_tdata(21+16-1 downto 21);  
--#                elsif 2**22 < s_axis_divisor_tdata then m_axis_dout_tdata(16-1 downto 0) <= s_axis_dividend_tdata(22+16-1 downto 22);  
--#                elsif 2**23 < s_axis_divisor_tdata then m_axis_dout_tdata(16-1 downto 0) <= s_axis_dividend_tdata(23+16-1 downto 23);  
--#                elsif 2**24 < s_axis_divisor_tdata then m_axis_dout_tdata(16-1 downto 0) <= s_axis_dividend_tdata(24+16-1 downto 24);  
--#                elsif 2**25 < s_axis_divisor_tdata then m_axis_dout_tdata(16-1 downto 0) <= s_axis_dividend_tdata(25+16-1 downto 25);  
--#                elsif 2**26 < s_axis_divisor_tdata then m_axis_dout_tdata(16-1 downto 0) <= s_axis_dividend_tdata(26+16-1 downto 26);  
--#                elsif 2**27 < s_axis_divisor_tdata then m_axis_dout_tdata(16-1 downto 0) <= s_axis_dividend_tdata(27+16-1 downto 27);  
--#                elsif 2**28 < s_axis_divisor_tdata then m_axis_dout_tdata(16-1 downto 0) <= s_axis_dividend_tdata(28+16-1 downto 28);  
--#                elsif 2**29 < s_axis_divisor_tdata then m_axis_dout_tdata(16-1 downto 0) <= s_axis_dividend_tdata(29+16-1 downto 29);  
--#                elsif 2**30 < s_axis_divisor_tdata then m_axis_dout_tdata(16-1 downto 0) <= s_axis_dividend_tdata(30+16-1 downto 30);  
--#                else                                    m_axis_dout_tdata(16-1 downto 0) <= s_axis_dividend_tdata(31+16-1 downto 31);  
--#                end if;
--#            end if;
--#
--#            m_axis_dout_tvalid <= divEn;
--#        --
--#        end if;
--#    end process;

--     c_div_24_8 : div_24_8
--         port map (
--             aclk                   => clk,
--             s_axis_divisor_tvalid  => s_axis_divisor_tvalid,
--             s_axis_divisor_tready  => s_axis_divisor_tready,
--             s_axis_divisor_tdata   => s_axis_divisor_tdata(24-1 downto 16),
--             s_axis_dividend_tvalid => s_axis_dividend_tvalid,
--             s_axis_dividend_tready => s_axis_dividend_tready,
--             s_axis_dividend_tdata  => s_axis_dividend_tdata(40-1 downto 16),
--             m_axis_dout_tvalid     => m_axis_dout_tvalid,
--             m_axis_dout_tdata(24-1 downto 16) => m_axis_dout_tdata(24-1 downto 16),
--             m_axis_dout_tdata(16-1 downto 0)  => m_axis_dout_tdata(16-1 downto 0)
--         );

--     u_div_24_8 : div_24_8
--         port map (
--             aclk                   => clk,
--             s_axis_divisor_tvalid  => s_axis_divisor_tvalid,
--             s_axis_divisor_tdata   => s_axis_divisor_tdata(24 - 1 downto 16),
--             s_axis_dividend_tvalid => s_axis_dividend_tvalid,
--             s_axis_dividend_tdata  => s_axis_dividend_tdata(40 - 1 downto 16),
--             m_axis_dout_tvalid     => m_axis_dout_tvalid,
--             m_axis_dout_tdata      => m_axis_dout_tdata
-- 
-- --          m_axis_dout_tdata(32 - 1 downto 24) => m_axis_dout_tdata(32 - 1 downto 24),
-- --          m_axis_dout_tdata(24 - 1 downto 8)  => m_axis_dout_tdata(24 - 1 downto 8)
-- --          m_axis_dout_tdata(8 - 1 downto 0)   => m_axis_dout_tdata(8 - 1 downto 0)
--         );
--      u_div_24_28_lutmult : div_24_28_lutmult -- use
--          port map (
--              aclk                   => clk,
--              s_axis_divisor_tvalid  => s_axis_divisor_tvalid,
--              s_axis_divisor_tdata   => s_axis_divisor_tdata(17+8 - 1 downto 17),   -- 7bit
--              s_axis_dividend_tvalid => s_axis_dividend_tvalid,
--              s_axis_dividend_tdata  => s_axis_dividend_tdata(17+16 - 1 downto 17), -- 16
--              m_axis_dout_tvalid     => m_axis_dout_tvalid,
--              m_axis_dout_tdata      => m_axis_dout_tdata(24 - 1 downto 0)
--          );

    process (clk) -- out data latch
    begin
        if clk'event and clk='1' then
  --
            if m_axis_dout_tvalid = '1' then
                resultcnt <= resultcnt + '1';
           --#  result    <= resultcnt & m_axis_dout_tdata(16 - 1 downto 0);
                result    <= resultcnt & m_axis_dout_tdata(24 - 1 downto 8);
            end if;
  --
        end if;
    end process;

    oreg_img_avg <= result;

end architecture behavioral;
