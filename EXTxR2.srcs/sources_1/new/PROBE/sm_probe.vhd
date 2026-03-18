----------------------------------------------------------------------------------
-- Company: drtech
-- Engineer: bhmoon
--
-- Create Date: 2021/04/05 11:56:38
-- Design Name:
-- Module Name: sm_probe - Behavioral
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

entity sm_probe is
    generic (
        sysclkhz : integer := 100_000_000;
        sm_bit   : integer := 4;
        sm_num   : integer := 9
    );
    port (
        ISYSCLK : in    std_logic;

        ireg_sm_ctrl : in    std_logic_vector(32 - 1 downto 0);
        ireg_sm_data : out   std_logic_vector(32 - 1 downto 0);

        iclk : in    std_logic;
        sm   : in    std_logic_vector(sm_bit - 1 downto 0)
    );
end entity sm_probe;

architecture behavioral of sm_probe is

    constant ms500  : integer := sysclkhz / 2;
    constant ms100  : integer := sysclkhz / 10;
    constant fifonum : integer := 9;
    constant zero : std_logic_vector(12 - 1 downto 0) := (others=> '0');
    signal   sysclk : std_logic;
    signal   clk    : std_logic;

    component fifo_sm_reg
        port (
            wr_clk        : in    std_logic;
            rd_clk        : in    std_logic;
            din           : in    std_logic_vector(36 - 1 downto 0);
            wr_en         : in    std_logic;
            rd_en         : in    std_logic;
            dout          : out   std_logic_vector(36 - 1 downto 0);
            full          : out   std_logic;
            empty         : out   std_logic;
            wr_data_count : out   std_logic_vector(fifonum - 1 downto 0);
            rd_data_count : out   std_logic_vector(fifonum - 1 downto 0)
        );
    end component;

    signal fi_wr_clk        : std_logic;
    signal fi_rd_clk        : std_logic;
    signal fi_din           : std_logic_vector(36 - 1 downto 0);
    signal fi_wr_en         : std_logic;
    signal fi_rd_en         : std_logic;
    signal fi_dout          : std_logic_vector(36 - 1 downto 0);
    signal fi_full          : std_logic;
    signal fi_empty         : std_logic;
    signal fi_wr_data_count : std_logic_vector(fifonum - 1 downto 0);
    signal fi_rd_data_count : std_logic_vector(fifonum - 1 downto 0);

    type   type_smsh is array (8 - 1 downto 0) of std_logic_vector(sm_bit - 1 downto 0);
    signal smSysSh : type_smsh := (others=> (others=>'0'));
    signal smSh    : type_smsh := (others=> (others=>'0'));

    signal smSysCnt : std_logic_vector(32 - 1 downto 0) := (others=> '0');
    signal smLat    : std_logic_vector(4 - 1 downto 0) := (others=> '0');

    -- signal wcntLat : integer range 0 to 8 - 1 := 0;
    signal cnt    : std_logic_vector(32 - 1 downto 0) := (others=> '0');
    signal cntLat : std_logic_vector(32 - 1 downto 0) := (others=> '0');

    signal ms100cnt    : std_logic_vector(32 - 1 downto 0) := (others=> '0');
    signal ms100togg   : std_logic := '0';
    signal ms100toggd1 : std_logic := '0';
    signal ms100toggd2 : std_logic := '0';
    signal ms100toggd3 : std_logic := '0';

  -- 211214 mbh counter 16b->32b

    -- type   type_smcnt is array (sm_num - 1 downto 0) of std_logic_vector(32 - 1 downto 0);
    -- signal smCnt    : type_smcnt := (others=> (others=>'0'));
    -- signal smCntLat : type_smcnt := (others=> (others=>'0'));

    signal reg_stopped : std_logic := '0';
    signal smEn        : std_logic := '0';

    signal sreg_sm_ctrl_s0 : std_logic_vector(32 - 1 downto 0);
    signal sreg_sm_ctrl_s1 : std_logic_vector(32 - 1 downto 0);
    signal sreg_sm_ctrl_d0 : std_logic_vector(32 - 1 downto 0);
    signal sreg_sm_ctrl_d1 : std_logic_vector(32 - 1 downto 0);
    signal sreg_probe_en   : std_logic;
    signal sreg_read_trig0 : std_logic;
    signal sreg_read_trig1 : std_logic;
    signal sreg_read_page  : std_logic;
    signal smWriteEnTime   : std_logic_vector(16 - 1 downto 0);
    signal smWriteEnTime0  : std_logic_vector(16 - 1 downto 0);
    signal smWriteEn       : std_logic;
    signal smWriteEn_d0    : std_logic;
    signal smTimeCnt       : std_logic_vector(16 - 1 downto 0);
    signal r0_smTimeCnt    : std_logic_vector(16 - 1 downto 0);
    signal r1_smTimeCnt    : std_logic_vector(16 - 1 downto 0);
    signal r2_smTimeCnt    : std_logic_vector(16 - 1 downto 0);
    signal smWriteTime     : std_logic_vector(16 - 1 downto 0);
    signal smWriteTime0    : std_logic_vector(16 - 1 downto 0);
    signal smTimeCnt_s0    : std_logic_vector(16 - 1 downto 0);
    signal smTimeCnt_s1    : std_logic_vector(16 - 1 downto 0);
    signal smTimeCnt_s2    : std_logic_vector(16 - 1 downto 0);
    signal sm100mCnt       : std_logic_vector(32 - 1 downto 0);

    signal smw         : std_logic_vector(4 - 1 downto 0) := x"0";
    signal s0_smw      : std_logic_vector(4 - 1 downto 0) := x"0";
    signal s1_smw      : std_logic_vector(4 - 1 downto 0) := x"0";
    signal s2_smw      : std_logic_vector(4 - 1 downto 0) := x"0";
    signal next_smw    : std_logic_vector(4 - 1 downto 0) := x"0";
    signal sreg_ready  : std_logic;
    signal sreg_sm_sel : std_logic_vector(4 - 1 downto 0) := x"0";
    signal high32      : std_logic_vector(32 - 1 downto 0) := (others=> '1');

    signal oreg_sm_data : std_logic_vector(32 - 1 downto 0);

    component ila_probe
        port (
            clk    : in    std_logic;
            probe0 : in    std_logic_vector(0 downto 0);
            probe1 : in    std_logic_vector(3 downto 0);
            probe2 : in    std_logic_vector(31 downto 0);
            probe3 : in    std_logic_vector(0 downto 0);
            probe4 : in    std_logic_vector(35 downto 0);
            probe5 : in    std_logic_vector(0 downto 0);
            probe6 : in    std_logic_vector(35 downto 0);
            probe7 : in    std_logic_vector(9 downto 0);
            probe8 : in    std_logic_vector(31 downto 0)
        );
    end component;

begin

--    gen_ila : if (sm_num=2 or sm_num=3 or sm_num=4) generate
--        u_ila_probe : ila_probe
--            port map (
--                clk       => sysclk,
--                probe0(0) => smWriteEn,        -- 1
--                probe1    => smSh(0),          -- 4
--                probe2    => cnt,              -- 32
--                probe3(0) => fi_wr_en,         -- 1
--                probe4    => fi_din,           -- 36
--                probe5(0) => fi_rd_en,         -- 1
--                probe6    => fi_dout,          -- 36
--                probe7    => fi_rd_data_count, -- 10
--                probe8    => oreg_sm_data      -- 32
--            );
--    end generate gen_ila;

    sysclk <= ISYSCLK;

    process (sysclk)
    begin
        if sysclk'event and sysclk='1' then
    --
            smSysSh <= smSysSh(8 - 2 downto 0) & sm;

            if smSysSh(3) /= smSysSh(2) then
                smSysCnt <= (others=> '0');
            elsif smSysCnt < ms500 then
                smSysCnt <= smSysCnt + '1';
            end if;

            if ms500 <= smSysCnt then
                reg_stopped <= '1';
            else
                reg_stopped <= '0';
            end if;

            -- if ms100cnt < ms100 then -- 0.1sec toggle
            --     ms100cnt <= ms100cnt + '1';
            -- else
            --     ms100cnt  <= (others=> '0');
            --     ms100togg <= not ms100togg;
            -- end if;

            -- # time count
            s2_smw <= s1_smw; s1_smw <= s0_smw; s0_smw <= smw;
            if s2_smw = x"01" then
                if sm100mCnt < ms100 then
                    sm100mCnt <= sm100mCnt + '1';
                else
                    sm100mCnt <= (others=> '0');
                    smTimeCnt <= smTimeCnt + '1';
                end if;
            else
                sm100mCnt <= (others=> '0');
                smTimeCnt <= (others=> '0');
            end if;
    --
        end if;
    end process;

    clk <= iclk;

    SYNC_PROC : process (clk)
    begin
        if (clk'event and clk= '1') then
      -- ### reg shift
            sreg_sm_ctrl_s0 <= ireg_sm_ctrl;
            sreg_sm_ctrl_s1 <= sreg_sm_ctrl_s0;
            smWriteTime     <= sreg_sm_ctrl_s1(32 - 1 downto 16);
            smWriteTime0    <= smWriteTime;

            smw          <= next_smw;
            r2_smTimeCnt <= r1_smTimeCnt; r1_smTimeCnt <= r0_smTimeCnt; r0_smTimeCnt <= smTimeCnt;

      -- # output
            if next_smw = x"1" then
                smWriteEn <= '1';
            else
                smWriteEn <= '0';
            end if;
        end if;
    end process;

    NEXT_STATE_DECODE : process (smw, smWriteTime, smWriteTime0,  r2_smTimeCnt)
    begin
        next_smw <= smw;
        if smWriteTime = 0 then
            next_smw <= x"0";
        else

            case (smw) is
                when x"0" => -- # idle
                    if smWriteTime0=0 and smWriteTime /= 0 then
                        next_smw <= x"1";
                    end if;
                when x"1" => -- # count wait time
                    if r2_smTimeCnt > smWriteTime then
                        next_smw <= x"2";
                    end if;
                when others =>
                    next_smw <= x"0";
            end case;

        end if;
    end process;

    process (clk)
    begin
        if clk'event and clk='1' then
    --
            smWriteEn_d0 <= smWriteEn;
            smSh         <= smSh(8 - 2 downto 0) & sm;

            if smWriteEn = '1' then
                if smSh(1) /= smSh(0) or
                   smWriteEn_d0 = '0' then -- least 1 write enable
                    smEn <= '1';
                    --wcntLat <= wcntLat + 1;
                    smLat  <= x"0" + smSh(1);
                    cntLat <= cnt;
                    cnt    <= (others=> '0');
                else
                    smEn <= '0';
                    if cnt < high32 then -- x"FFFF_FFFF" then -- 2 ** 32 - 2 then
                        cnt <= cnt + '1';
                    end if;
                end if;
            else
                --wcntLat <= 0;
                cnt  <= (others=> '0');
                smEn <= '0';
            end if;

            -- ms100toggd1 <= ms100togg;
            -- ms100toggd2 <= ms100toggd1;
            -- ms100toggd3 <= ms100toggd2;
            -- if ms100toggd3 /= ms100toggd2 then -- 0.1s
            --     smCnt    <= (others=> (others=>'0'));
            --     smCntLat <= smCnt;
            -- else
            --     if smSh(1) /= smSh(0) then
            --         for i in 0 to sm_num - 1 loop
            --             if smSh(1) = i then
            --                 if smCnt(i) < 2 ** 32 - 1 then
            --                     smCnt(i) <= smCnt(i) + '1';
            --                 end if;
            --             end if;
            --         end loop;
            --     end if;
            -- end if;

    --
        end if;
    end process;

    fi_wr_clk <= clk;
    fi_wr_en  <= smEn when fi_full ='0' else '0';
    fi_din    <= smLat & cntLat;
--    36b     <=      4b &  32b ;

    u_fifo_sm_reg : fifo_sm_reg
        port map (
            wr_clk        => fi_wr_clk,
            wr_en         => fi_wr_en,
            din           => fi_din,
            full          => fi_full,
            wr_data_count => fi_wr_data_count,

            rd_clk        => fi_rd_clk,
            rd_en         => fi_rd_en,
            dout          => fi_dout,
            empty         => fi_empty,
            rd_data_count => fi_rd_data_count
        );
    fi_rd_clk <= sysclk;

    process (sysclk)
    begin
        if sysclk'event and sysclk='1' then
    --
      -- ##### Write reg #####
      -- ### (0)     : Read Enable
      -- ### (1)     : Read Trigger
      -- ### (2)     : Read data "Page" 32bit selection
    -- ### (7:4)   : sm selection
      -- ### (31:16) : write time
      -- ##### Read reg #####
      -- ### "Page 0"
        -- ### (0)     : sm stop flag
        -- ### (4:1)   : sm name
        -- ### (14:5)  : sm fifo count
        -- ### (31:16) : write time counter
      -- ### "Page 1"
        -- ### (31:0 ) : sm time counted value
            sreg_sm_ctrl_d0 <= ireg_sm_ctrl;
            sreg_sm_ctrl_d1 <= sreg_sm_ctrl_d0;
            sreg_ready      <= sreg_sm_ctrl_d1(0);
            sreg_read_trig0 <= sreg_sm_ctrl_d1(1);
            sreg_read_trig1 <= sreg_read_trig0;
            sreg_read_page  <= sreg_sm_ctrl_d1(2);
            sreg_sm_sel     <= sreg_sm_ctrl_d1(7 downto 4);
            if sreg_ready = '0' then
                fi_rd_en <= not fi_empty; -- make empty
             -- fi_rd_en <= '1';          -- make empty --# 230515 misunderstand  
            elsif sreg_read_trig1='0' and sreg_read_trig0='1' and -- rising
                 sreg_sm_sel = sm_num then                        -- compare sm_selection
                fi_rd_en <= '1';
            else
                fi_rd_en <= '0';
            end if;

            smTimeCnt_s2 <= smTimeCnt_s1; smTimeCnt_s1 <= smTimeCnt_s0; smTimeCnt_s0 <= smTimeCnt;
            if sreg_read_page = '0' then
        -- 32b       <= 16b + '0' + 10b(total) + 4b(sm) + 1b(stop)
                oreg_sm_data <= smTimeCnt_s2 &
                                zero(10-fifonum downto 0) & fi_rd_data_count(fifonum - 1 downto 0) &
                                fi_dout(32 + 4 - 1 downto 32) &
                                reg_stopped;
            else
                oreg_sm_data <= fi_dout(32 - 1 downto 0);
            end if;
    --
        end if;
    end process;

    ireg_sm_data <= oreg_sm_data;

end architecture behavioral;
