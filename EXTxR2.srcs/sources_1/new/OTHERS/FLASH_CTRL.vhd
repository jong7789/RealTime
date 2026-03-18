----------------------------------------------------------------------------------
-- Company: drt
-- Engineer: mbh
--
-- Create Date: 2021/03/04 19:03:01
-- Design Name:
-- Module Name: FLASH_CTRL - Behavioral
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

library UNISIM;
	use UNISIM.VComponents.all;
use WORK.TOP_HEADER.ALL;

entity FLASH_CTRL is
	port (
		irst		  : in	  std_logic;
		isysclk		  : in	  std_logic;
        iepc_cs_n : in    std_logic; -- it's for auto-increment

		ireg_fla_ctrl : in	  std_logic_vector(32 - 1 downto 0);
		ireg_fla_addr : in	  std_logic_vector(32 - 1 downto 0);
		oreg_fla_data : out   std_logic_vector(32 - 1 downto 0);

        ireg_flaw_ctrl  : in    std_logic_vector(32 - 1 downto 0);
        ireg_flaw_cmd   : in    std_logic_vector(32 - 1 downto 0);
        ireg_flaw_addr  : in    std_logic_vector(32 - 1 downto 0);
        ireg_flaw_wdata : in    std_logic_vector(32 - 1 downto 0);
        oreg_flaw_rdata : out   std_logic_vector(32 - 1 downto 0);

		ispi_io0_i : in    std_logic;
		ospi_io0_o : out   std_logic;
		ospi_io0_t : out   std_logic;
		ispi_io1_i : in    std_logic;
		ospi_io1_o : out   std_logic;
		ospi_io1_t : out   std_logic;
		ispi_io2_i : in    std_logic;
		ospi_io2_o : out   std_logic;
		ospi_io2_t : out   std_logic;
		ispi_io3_i : in    std_logic;
		ospi_io3_o : out   std_logic;
		ospi_io3_t : out   std_logic;
		ispi_sck_i : in    std_logic;
		ospi_sck_o : out   std_logic;
		ospi_sck_t : out   std_logic;
		ispi_css_i : in    std_logic;
		ospi_css_o : out   std_logic;
		ospi_css_t : out   std_logic
	);
end entity flash_ctrl;

architecture behavioral of flash_ctrl is

	constant QUAD_FAST_READ : std_logic_vector(0 to 8 - 1) := x"6B";

	component fifo_fla_4x2048_32x256
		port (
			rst			  : in	  std_logic;
			wr_clk		  : in	  std_logic;
			rd_clk		  : in	  std_logic;
			din			  : in	  std_logic_vector(3 downto 0);
			wr_en		  : in	  std_logic;
			rd_en		  : in	  std_logic;
			dout		  : out   std_logic_vector(31 downto 0);
			full		  : out   std_logic;
			empty		  : out   std_logic;
			rd_data_count : out   std_logic_vector(7 downto 0);
			wr_data_count : out   std_logic_vector(10 downto 0)
		);
	end component;

	signal cfi_rst			 : std_logic;
	signal cfi_wr_clk		 : std_logic;
	signal cfi_rd_clk		 : std_logic;
	signal cfi_din			 : std_logic_vector(3 downto 0):=(others=>'0');
	signal cfi_wr_en		 : std_logic:='0';
	signal cfi_rd_en		 : std_logic:='0';
	signal cfi_dout			 : std_logic_vector(31 downto 0):=(others=>'0');
	signal cfi_full			 : std_logic:='0';
	signal cfi_empty		 : std_logic:='0';
	signal cfi_rd_data_count : std_logic_vector(7 downto 0):=(others=>'0');
	signal cfi_wr_data_count : std_logic_vector(10 downto 0):=(others=>'0');

    component fifo_flaw_32x256_4x2048
        port (
            rst           : in    std_logic;
            wr_clk        : in    std_logic;
            rd_clk        : in    std_logic;
            din           : in    std_logic_vector(31 downto 0);
            wr_en         : in    std_logic;
            rd_en         : in    std_logic;
            dout          : out   std_logic_vector(3 downto 0);
            full          : out   std_logic;
            empty         : out   std_logic;
            rd_data_count : out   std_logic_vector(10 downto 0);
            wr_data_count : out   std_logic_vector(7 downto 0);
            wr_rst_busy   : out   std_logic;
            rd_rst_busy   : out   std_logic
  );
    end component;

    signal wfi_rst           : std_logic;
    signal wfi_wr_clk        : std_logic;
    signal wfi_rd_clk        : std_logic;
    signal wfi_din           : std_logic_vector(31 downto 0);
    signal wfi_wr_en         : std_logic;
    signal wfi_rd_en         : std_logic;
    signal wfi_dout          : std_logic_vector(3 downto 0);
    signal wfi_full          : std_logic;
    signal wfi_empty         : std_logic;
    signal wfi_rd_data_count : std_logic_vector(10 downto 0);
    signal wfi_wr_data_count : std_logic_vector(7 downto 0);
    signal wfi_wr_rst_busy   : std_logic;
    signal wfi_rd_rst_busy   : std_logic;

    type   type_sm_read is ( ST_IDLE, ST_CMD, ST_ADDR, ST_DUMMY, ST_RD256, ST_RD128, ST_wait);
    signal SM_READ : type_sm_read;

	signal i0Csel		 : std_logic:='0';
	signal i0Incr		 : std_logic:='0';
	signal sCsel		 : std_logic:='0';
	signal sIncr		 : std_logic:='0';
	signal s0Incr		 : std_logic:='0';
	signal i0Addr		 : std_logic_vector(32 - 1 downto 0) := (others=> '0');
	signal sAddr		 : std_logic_vector(32 - 1 downto 0) := (others=> '0');
	signal sFlaAddr		 : std_logic_vector(32 - 1 downto 0) := (others=> '0');
	signal TurnOnCnt	 : std_logic_vector(8 - 1 downto 0) := (others=> '0');
	signal FlashReadAddr : std_logic_vector(0 to 32 - 1) := (others=> '0'); -- Up to
	signal CmdCnt		 : integer range 0 to 8 - 1 := 0;
	signal DummyCnt		 : integer range 0 to 8 - 1 := 0;
	signal WaitCnt		 : integer range 0 to 256 - 1 := 0;
	signal AddrCnt		 : integer range 0 to 32 - 1 := 0;
	signal cnt256		 : integer range 0 to 256 * 34 / 4 - 1 := 0;
	signal cnt128		 : integer range 0 to 128 * 34 / 4 - 1 := 0;
	signal Rd128_256	 : std_logic:='0';
	signal fla_din4b	 : std_logic_vector(4 - 1 downto 0) := (others=> '0');
	signal Zout			 : std_logic_vector(4 - 1 downto 0) := (others=> '0');
	signal Zout0		 : std_logic_vector(4 - 1 downto 0) := (others=> '0');
	signal fla_dout		 : std_logic_vector(4 - 1 downto 0) := (others=> '0');
	signal fla_dout0	 : std_logic_vector(4 - 1 downto 0) := (others=> '0');
	signal fla_din		 : std_logic_vector(4 - 1 downto 0) := (others=> '0');
	signal fla_wen		 : std_logic:='0';

	signal rCsel   : std_logic:='0';
	signal rIncr   : std_logic:='0';
	signal rIncr1d : std_logic:='0';
	signal rIncr2d : std_logic:='0';
	signal rd_en   : std_logic:='0';
	signal halfclk : std_logic:='0';
	signal Cs	   : std_logic:='0';
	signal sRst    : std_logic:='0';

	signal sepc_cs_n1d    : std_logic:='0';
	signal sepc_cs_n2d    : std_logic:='0';
	signal Mode_AutoIncr  : std_logic:='0';
    
  -- #########################
  -- ##### write declare #####
    constant BYTE1   : integer := 8 - 1;
    constant BYTE2   : integer := 8 * 2 - 1;
    constant BYTE4   : integer := 8 * 4 - 1;
    constant BYTE256 : integer := 8 * 256 / 4 - 1; -- 4bit transmitter

    type type_sm_write is (st_idle, st_w1B, st_wd1B, st_r1B, st_w4B, st_w256B);

    type   type_sm_cmd is (st_idle, st_wCmd, st_rCmd, st_wCmdData, st_wCmdAddr, st_wCmdAddrData);
    signal next_SM_WRITE : type_sm_write;
    signal SM_WRITE      : type_sm_write;
    signal next_SM_CMD   : type_sm_cmd;
    signal SM_CMD        : type_sm_cmd;

    signal ireg_flaw_ctrl_d0 : std_logic_vector(32 - 1 downto 0) := (others=>'0');
    signal ireg_flaw_ctrl_d1 : std_logic_vector(32 - 1 downto 0) := (others=>'0');
    signal ireg_flaw_cmd_d0  : std_logic_vector(32 - 1 downto 0) := (others=>'0');
    signal ireg_flaw_cmd_d1  : std_logic_vector(32 - 1 downto 0) := (others=>'0');
    signal ireg_flaw_addr_d0 : std_logic_vector(32 - 1 downto 0) := (others=>'0');
    signal ireg_flaw_addr_d1 : std_logic_vector(32 - 1 downto 0) := (others=>'0');
    signal ireg_flaw_data_d0 : std_logic_vector(32 - 1 downto 0) := (others=>'0');
    signal ireg_flaw_data_d1 : std_logic_vector(32 - 1 downto 0) := (others=>'0');
    signal reg_wCtrl         : std_logic_vector(32 - 1 downto 0) := (others=>'0');
    signal reg_wCmd          : std_logic_vector(32 - 1 downto 0) := (others=>'0');
    signal reg_wAddr         : std_logic_vector(32 - 1 downto 0) := (others=>'0');
    signal reg_wData         : std_logic_vector(32 - 1 downto 0) := (others=>'0');

    signal reg_wEn               : std_logic := '0';
    signal reg_wEn0              : std_logic := '0';
    signal reg_wCmdTrig          : std_logic := '0';
    signal reg_wCmdTrig0         : std_logic := '0';
    signal reg_rCmdTrig          : std_logic := '0';
    signal reg_rCmdTrig0         : std_logic := '0';
    signal reg_wCmdDataTrig      : std_logic := '0';
    signal reg_wCmdDataTrig0     : std_logic := '0';
    signal reg_wCmdAddrTrig      : std_logic := '0';
    signal reg_wCmdAddrTrig0     : std_logic := '0';
    signal reg_wCmdAddrDataTrig  : std_logic := '0';
    signal reg_wCmdAddrDataTrig0 : std_logic := '0';
    signal fla_r1B_data          : std_logic_vector(32 - 1 downto 0) := (others=>'0');

    signal smwCnt : std_logic_vector(16 - 1 downto 0) := (others=>'0');

    signal wfi_wrEn    : std_logic := '0';
    signal wfi_reg_wEn : std_logic := '0';
    signal reg_wr_en   : std_logic := '0';
    signal reg_wr_en0  : std_logic := '0';
    signal clkcnt      : std_logic_vector(4 - 1 downto 0) := (others=>'0');

-- !begin

begin

    ila_debug_spi_ctrl : if(GEN_ILA_SPI = "ON") generate

	component ila_flash_ctrl
		port (
			clk		: in	std_logic;
            probe0  : in    type_sm_READ; -- std_logic_vector(2 downto 0);
			probe1	: in	std_logic_vector(15 downto 0);
            probe2  : in    std_logic_vector(0 downto 0);
            probe3  : in    std_logic_vector(0 downto 0);
            probe4  : in    std_logic_vector(0 downto 0);
			probe5	: in	std_logic_vector(3 downto 0);
			probe6	: in	std_logic_vector(10 downto 0);
            probe7  : in    std_logic_vector(0 downto 0);
			probe8	: in	std_logic_vector(31 downto 0);
			probe9	: in	std_logic_vector(7 downto 0);
            probe10 : in    std_logic_vector(0 downto 0) 
        );
    end component;

    component ila_flawrite
        port (
            clk     : in    std_logic;
            probe0  : in    std_logic_vector(0 downto 0);
            probe1  : in    std_logic_vector(31 downto 0);
            probe2  : in    std_logic_vector(31 downto 0);
            probe3  : in    std_logic_vector(31 downto 0);
            probe4  : in    std_logic_vector(31 downto 0);
            probe5  : in    std_logic_vector(31 downto 0);
            probe6  : in    std_logic_vector(3 downto 0);
            probe7  : in    type_sm_write; -- std_logic_vector(2 downto 0);
            probe8  : in    type_sm_cmd;   -- std_logic_vector(2 downto 0);
            probe9  : in    std_logic_vector(0 downto 0);
            probe10 : in    std_logic_vector(31 downto 0);
            probe11 : in    std_logic_vector(7 downto 0);
            probe12 : in    std_logic_vector(0 downto 0);
            probe13 : in    std_logic_vector(3 downto 0);
            probe14 : in    std_logic_vector(10 downto 0);
            probe15 : in    std_logic_vector(15 downto 0);
            probe16 : in    std_logic_vector(3 downto 0);
            probe17 : in    std_logic_vector(3 downto 0);
            probe18 : in    std_logic_vector(0 downto 0);
            probe19 : in    std_logic_vector(0 downto 0);
            probe20 : in    type_sm_READ   -- std_logic_vector(2 downto 0)
		);
	end component;

signal map1b_0 : std_logic;
signal map1b_1 : std_logic;

	begin
--	u_ila_flash_ctrl : ila_flash_ctrl
--		port map (
--			clk		=> isysclk,
--            probe0    => SM_READ,           -- 3
--			probe1	=> b"0000_0000_0000_000" & iepc_cs_n,
--            probe2(0) => fla_dout(0),       -- 1
--            probe3(0) => Zout(0),           -- 1
--            probe4(0) => cfi_wr_en,         -- 1
--			probe5	=> cfi_din,			  -- 4
--			probe6	=> cfi_wr_data_count, -- 11
--            probe7(0) => cfi_rd_en,         -- 1
--			probe8	=> cfi_dout,		  -- 32
--			probe9	=> cfi_rd_data_count, -- 8
--            probe10(0)=> not cfi_wr_clk     -- 1
--        );

map1b_0 <= not cfi_wr_clk;
map1b_1 <= not Cs;
    u_ila_flaw : ila_flawrite
        port map (
            clk       => isysclk,
            probe0(0) => iepc_cs_n,         -- 1
            probe1    => ireg_flaw_ctrl,    -- 32
            probe2    => ireg_flaw_cmd,     -- 32
            probe3    => ireg_flaw_addr,    -- 32
            probe4    => ireg_flaw_wdata,   -- 32
            probe5    => fla_r1B_data,      -- 32 -- read status
            probe6    => fla_din4b,         -- 4
            probe7    => SM_WRITE,          -- 3
            probe8    => SM_CMD,            -- 3
            probe9(0) => wfi_wr_en,         -- 1
            probe10   => wfi_din,           -- 32
            probe11   => wfi_wr_data_count, -- 8
            probe12(0)=> wfi_rd_en,         -- 1
            probe13   => wfi_dout,          -- 4
            probe14   => wfi_rd_data_count, -- 11
            probe15   => smwCnt,            -- 16
            probe16   => fla_dout0,         -- 4 -- wierd
            probe17   => Zout0,             -- 4
            probe18(0)=> map1b_0,           -- 1
            probe19(0)=> map1b_1,           -- 1
            probe20   => SM_READ            -- 3
		);

end generate ila_debug_spi_ctrl;  

  -- ### clk divide by 2
process (isysclk)
begin
    if isysclk'event and isysclk='1' then
--        halfclk <= not halfclk;
          clkcnt <= clkcnt + '1';
          halfclk <= clkcnt(1);
    end if;
end process;

-- .%%...%%..%%%%%...........%%%%%%..%%%%%%..%%%%%%...%%%%..
-- .%%...%%..%%..%%..........%%........%%....%%......%%..%%.
-- .%%.%.%%..%%%%%...........%%%%......%%....%%%%....%%..%%.
-- .%%%%%%%..%%..%%..........%%........%%....%%......%%..%%.
-- ..%%.%%...%%..%%..........%%......%%%%%%..%%.......%%%%..
-- .........................................................

fla_dout0 <= fla_dout;
Zout0     <= Zout;
process (wfi_wr_clk)
begin
    if wfi_wr_clk'event and wfi_wr_clk='1' then
      --
        wfi_reg_wEn <= ireg_flaw_ctrl(0);
        reg_wr_en   <= ireg_flaw_ctrl(16);
        reg_wr_en0  <= reg_wr_en;

        if wfi_reg_wEn = '0' then
            wfi_wrEn <= '0';
        elsif reg_wr_en0 = '0' and reg_wr_en = '1' then
            wfi_wrEn <= '1';
        else
            wfi_wrEn <= '0';
        end if;
        
    --
    end if;
end process;

wfi_rst    <= '0';
wfi_wr_clk <= isysclk;
wfi_wr_en  <= wfi_wrEn;
wfi_din    <= ireg_flaw_wdata;

u_fifo_flaw_32x256_4x2048 : fifo_flaw_32x256_4x2048
    port map (
        rst           => wfi_rst,
        wr_clk        => wfi_wr_clk,
        wr_en         => wfi_wr_en,
        din           => wfi_din,
        full          => wfi_full,
        wr_data_count => wfi_wr_data_count,
        rd_clk        => wfi_rd_clk,
        rd_en         => wfi_rd_en,
        dout          => wfi_dout,
        empty         => wfi_empty,
        rd_data_count => wfi_rd_data_count,
        wr_rst_busy   => OPEN,
        rd_rst_busy   => OPEN
    );

wfi_rd_clk <= halfclk;
wfi_rd_en  <= '1' when reg_wEn = '0' else
              '1' when SM_WRITE=st_w256B else
              '0';

WRITE_REG : process (wfi_rd_clk) -- wfi_rd_clk is sysclk/2
begin
    if wfi_rd_clk'event and wfi_rd_clk='1' then
  --
        ireg_flaw_ctrl_d0 <= ireg_flaw_ctrl;
        ireg_flaw_ctrl_d1 <= ireg_flaw_ctrl_d0;
        ireg_flaw_cmd_d0  <= ireg_flaw_cmd;
        ireg_flaw_cmd_d1  <= ireg_flaw_cmd_d0;
        ireg_flaw_addr_d0 <= ireg_flaw_addr;
        ireg_flaw_addr_d1 <= ireg_flaw_addr_d0;
        ireg_flaw_data_d0 <= ireg_flaw_wdata;
        ireg_flaw_data_d1 <= ireg_flaw_data_d0;

        reg_wCtrl <= ireg_flaw_ctrl_d1;
        reg_wCmd  <= ireg_flaw_cmd_d1;
        reg_wAddr <= ireg_flaw_addr_d1;
        reg_wData <= ireg_flaw_data_d1;

        reg_wEn <= reg_wCtrl(0);

        reg_wCmdTrig          <= reg_wCtrl(4);
        reg_wCmdTrig0         <= reg_wCmdTrig;
        reg_rCmdTrig          <= reg_wCtrl(5);
        reg_rCmdTrig0         <= reg_rCmdTrig;
        reg_wCmdDataTrig      <= reg_wCtrl(6);
        reg_wCmdDataTrig0     <= reg_wCmdDataTrig;
        reg_wCmdAddrTrig      <= reg_wCtrl(7);
        reg_wCmdAddrTrig0     <= reg_wCmdAddrTrig;
        reg_wCmdAddrDataTrig  <= reg_wCtrl(8);
        reg_wCmdAddrDataTrig0 <= reg_wCmdAddrDataTrig;
    end if;
end process;

SYNC_PROC : process (wfi_rd_clk)
begin
    if (wfi_rd_clk'event and wfi_rd_clk = '1') then
        if irst = '1' or sRst = '1' then
            SM_WRITE <= ST_idle;
        else
            SM_WRITE <= next_SM_WRITE;
            SM_CMD   <= next_SM_CMD;
        end if;

        if SM_WRITE /= next_SM_WRITE then
            smwCnt <= (others=>'0');
        else
            smwCnt <= smwCnt + '1';
        end if;
    end if;
end process;

OUTPUT_DECODE : process (SM_WRITE)
begin
    if SM_WRITE = st_idle then
    -- output_i <= '1';
    else
         -- output_i <= '0';
    end if;
end process;

-- ..%%%%...%%...%%..........%%...%%..%%%%%...%%%%%%..%%%%%%..%%%%%%.
-- .%%......%%%.%%%..........%%...%%..%%..%%....%%......%%....%%.....
-- ..%%%%...%%.%.%%..........%%.%.%%..%%%%%.....%%......%%....%%%%...
-- .....%%..%%...%%..........%%%%%%%..%%..%%....%%......%%....%%.....
-- ..%%%%...%%...%%..%%%%%%...%%.%%...%%..%%..%%%%%%....%%....%%%%%%.
-- ..................................................................
NEXT_STATE_DECODE : process (SM_WRITE,
                             reg_wEn,
                             reg_wEn0,
                             reg_wCmdTrig,
                             reg_wCmdTrig0,
                             reg_rCmdTrig,
                             reg_rCmdTrig0,
                             reg_wCmdDataTrig,
                             reg_wCmdDataTrig0,
                             reg_wCmdAddrTrig,
                             reg_wCmdAddrTrig0,
                             reg_wCmdAddrDataTrig,
                             reg_wCmdAddrDataTrig0,
                             smwCnt,
                             SM_CMD
                            )
begin
    next_SM_WRITE <= SM_WRITE;
    next_SM_CMD   <= SM_CMD;

    if reg_wEn = '0' then
        next_SM_CMD   <= st_idle;
        next_SM_WRITE <= st_idle;
    else

        case (SM_WRITE) is
            when st_idle =>
                next_SM_CMD <= st_idle;

        -- ##########################
        -- ### write 1Byte command
        -- ### st_w1B
                if reg_wCmdTrig0='0' and reg_wCmdTrig='1' then
                    next_SM_WRITE <= st_w1B;
                    next_SM_CMD   <= st_wCmd;

                -- ##########################
                -- ### Read Status
                -- ### st_w1B >> st_rByte
                elsif reg_rCmdTrig0='0' and reg_rCmdTrig='1' then
                    next_SM_WRITE <= st_w1B;
                    next_SM_CMD   <= st_rCmd;

                -- ##########################
                -- ### write cmd + data 1b
                -- ### st_w1B >> st_w1B
                elsif reg_wCmdDataTrig0='0' and reg_wCmdDataTrig='1' then
                    next_SM_WRITE <= st_w1B;
                    next_SM_CMD   <= st_wCmdData;

                -- ##########################
                -- ### Write CMD + ADDR
                -- ### st_w1B >> st_addr4B
                elsif reg_wCmdAddrTrig0='0' and reg_wCmdAddrTrig='1' then
                    next_SM_WRITE <= st_w1B;
                    next_SM_CMD   <= st_wCmdAddr;

                -- ##########################
                -- ### Write CMD + ADDR + 256 DATA
                -- ### st_w1B >> st_w4B >> st_w256B
                elsif reg_wCmdAddrDataTrig0='0' and reg_wCmdAddrDataTrig='1' then
                    next_SM_WRITE <= st_w1B;
                    next_SM_CMD   <= st_wCmdAddrData;
                end if;

            -- ### command 1Byte write
            when st_w1B =>
                if smwCnt=BYTE1 then

                    case (SM_CMD) is
                        when st_wCmd => next_SM_WRITE <= st_idle;
                        when st_rCmd => next_SM_WRITE <= st_r1B;
                        when st_wCmdData => next_SM_WRITE <= st_wd1B;
                        when st_wCmdAddr => next_SM_WRITE <= st_w4B;
                        when st_wCmdAddrData => next_SM_WRITE <= st_w4B;
                        when others =>  next_SM_WRITE <= st_idle;
                    end case;

                end if;

    -- ### data 1B read
       when st_wd1B =>
                if smwCnt=BYTE1 then
                    next_SM_WRITE <= st_idle;
                end if;

    -- ### command 1B read
       when st_r1B =>
                if smwCnt=BYTE1 then
                    next_SM_WRITE <= st_idle;
                end if;

    -- ### addr4B write
       when st_w4B =>
                if smwCnt=BYTE4 then

                    case (SM_CMD) is
                        when st_wCmdAddr => next_SM_WRITE <= st_idle;
                        when st_wCmdAddrData => next_SM_WRITE <= st_w256B;
                        when others =>  next_SM_WRITE <= st_idle;
                    end case;

                end if;

    -- ### data256B write
       when st_w256B =>
                if smwCnt=BYTE256 then -- 4 bit transmitter
                    next_SM_WRITE <= st_idle;
                end if;

       when others =>
                next_SM_WRITE <= st_idle;
        end case;

    end if;

end process;

-- ..%%%%...%%...%%..........%%%%%...%%%%%%...%%%%...%%%%%..
-- .%%......%%%.%%%..........%%..%%..%%......%%..%%..%%..%%.
-- ..%%%%...%%.%.%%..........%%%%%...%%%%....%%%%%%..%%..%%.
-- .....%%..%%...%%..........%%..%%..%%......%%..%%..%%..%%.
-- ..%%%%...%%...%%..%%%%%%..%%..%%..%%%%%%..%%..%%..%%%%%..
-- .........................................................
process (cfi_wr_clk) -- cfi_wr_clk is sysclk/2
	begin
		if cfi_wr_clk'event and cfi_wr_clk='1' then
  --
			if TurnOnCnt < 100 then
				TurnOnCnt <= TurnOnCnt + '1';
				sRst	  <= '1';
			else
				sRst <= '0';
			end if;

			sCsel  <= i0Csel; i0Csel <= ireg_fla_ctrl(0);
			sIncr  <= i0Incr; i0Incr <= ireg_fla_ctrl(1);
			sAddr  <= i0Addr; i0Addr <= ireg_fla_addr;
			s0Incr <= sIncr;

			if irst = '1' or sRst = '1' then
            SM_READ <= ST_IDLE;
			else

            case (SM_READ) is
					----------### IDLE
					when ST_IDLE =>
						if sCsel='0' and  i0Csel = '1' then  -- first read address
                        SM_READ       <= ST_CMD;
							Rd128_256	  <= '0';
							FlashReadAddr <= sAddr;
						elsif sCsel='1' and
				cfi_wr_data_count <= (128 - 2) * 32 / 4 then -- # first out half of memory
                        SM_READ   <= ST_CMD;
							Rd128_256 <= '0';
   -- ### 32b Bport * 128 / byte (by flash)
							FlashReadAddr <= FlashReadAddr + ( 32 / 8 * 128);
						end if;
					----------### CMD : 0x6B extend quad read
					when ST_CMD =>
						if CmdCnt < 8 - 1 then
							CmdCnt <= CmdCnt + 1;
						else
							CmdCnt	 <= 0;
                        SM_READ <= ST_ADDR;
						end if;
					----------### ADDR : 4 byte
					when ST_ADDR =>
						if AddrCnt < 32 - 1 then
							AddrCnt <= AddrCnt + 1;
						else
							AddrCnt  <= 0;
                        SM_READ <= ST_DUMMY;
						end if;
					----------### DUMMY : 8 clk
					when ST_DUMMY =>
						if DummyCnt < 8 - 1 then
							DummyCnt <= DummyCnt + 1;
						else
							DummyCnt <= 0;
                        SM_READ  <= ST_RD128;
						end if;
					----------### Data 128
					when ST_RD128 =>
						if cnt128 < 128*32/4 - 1 then
							cnt128 <= cnt128 + 1;
						else
							cnt128	 <= 0;
                        SM_READ <= ST_WAIT;
						end if;
					when ST_WAIT =>
					----------### wait : wait 128 clk
						if WaitCnt < 128 - 1 then
							WaitCnt <= WaitCnt + 1;
						else
							WaitCnt  <= 0;
                        SM_READ <= ST_IDLE;
						end if;
                when others => SM_READ <= ST_IDLE;
				end case;

			end if;
  --
		end if;
	end process;

-- ..%%%%...%%..%%..%%%%%%.
-- .%%..%%..%%..%%....%%...
-- .%%..%%..%%..%%....%%...
-- .%%..%%..%%..%%....%%...
-- ..%%%%....%%%%.....%%...
-- ........................
	fla_din4b <= ispi_io3_i & ispi_io2_i & ispi_io1_i & ispi_io0_i;

process (SM_WRITE, SM_READ, CmdCnt, AddrCnt, smwCnt, reg_wCmd)
	begin
  --
    if  SM_WRITE = st_IDLE and SM_READ = st_IDLE then
        Zout     <= (others =>'1');
				Cs		<= '0';
				fla_wen <= '0';
        fla_dout <= (others =>'0');
    elsif SM_WRITE /= st_IDLE then

        case (SM_WRITE) is
            when st_w1B =>
                Cs          <= '1';
                Zout        <= x"E";
                fla_dout(0) <= reg_wCmd(conv_integer(not smwCnt(3 - 1 downto 0)));
            when st_r1B =>
                Cs   <= '1';
                Zout <= x"E";
                --
                fla_r1B_data(conv_integer(not smwCnt(3 - 1 downto 0))) <= fla_din4b(1);
            when st_wd1B =>
                Cs          <= '1';
                Zout        <= x"E";
                fla_dout(0) <= reg_wData(conv_integer(not smwCnt(3 - 1 downto 0)));
            when st_w4B =>
                Cs          <= '1';
                Zout        <= x"E";
                fla_dout(0) <= reg_wAddr(conv_integer(not smwCnt(5 - 1 downto 0)));
            when st_w256B =>
                Cs       <= '1';
                Zout     <= x"0";
                fla_dout <= wfi_dout;
            when others =>
        end case;

    else

        case (SM_READ) is
			when ST_CMD =>
				Cs			<= '1';
				Zout		<= x"E";
				fla_dout(0) <= QUAD_FAST_READ(CmdCnt);
			when ST_ADDR =>
				Cs			<= '1';
				Zout		<= x"E";
				fla_dout(0) <= FlashReadAddr(AddrCnt);
			when ST_DUMMY =>
				Cs		 <= '1';
				Zout	 <= x"F"; -- All in
				fla_dout <= x"0";
			when ST_RD128 =>
				Cs		 <= '1';
				Zout	 <= x"F"; -- All in
				fla_wen  <= '1';
				fla_din  <= fla_din4b;
				fla_dout <= x"0";
			when ST_WAIT =>
				Zout	<= x"F";  -- only 0 port out
				Cs		<= '0';
				fla_wen <= '0';

			when others =>
				Zout	 <= x"F";
				fla_dout <= x"0";
		end case;

    end if;
  --
	end process;

oreg_flaw_rdata(0)               <= '1' when SM_WRITE = st_IDLE else '0';
oreg_flaw_rdata(1)               <= '1' when SM_READ  = st_IDLE else '0';
oreg_flaw_rdata(32 - 1 downto 16) <= fla_r1B_data(16 - 1 downto 0);

  -- ### flash spi out
	ospi_sck_o <= not cfi_wr_clk; -- halfclk
	ospi_sck_t <= '0';
	
	ospi_io0_o <= fla_dout(0);
	ospi_io1_o <= fla_dout(1);
	ospi_io2_o <= fla_dout(2);
	ospi_io3_o <= fla_dout(3);
	ospi_io0_t <= Zout(0);
	ospi_io1_t <= Zout(1);
	ospi_io2_t <= Zout(2);
	ospi_io3_t <= Zout(3);
	ospi_css_o <= not Cs;
	ospi_css_t <= '0';

-- .%%%%%...%%%%%...........%%%%%%..%%%%%%..%%%%%%...%%%%..
-- .%%..%%..%%..%%..........%%........%%....%%......%%..%%.
-- .%%%%%...%%..%%..........%%%%......%%....%%%%....%%..%%.
-- .%%..%%..%%..%%..........%%........%%....%%......%%..%%.
-- .%%..%%..%%%%%...........%%......%%%%%%..%%.......%%%%..
-- ........................................................
  --
	cfi_rst    <= not rCsel; -- makes empty for A fort. re_en cant make it
	cfi_wr_clk <= halfclk;
	cfi_wr_en  <= fla_wen;
	cfi_din    <= fla_din;
	u_fifo_fla_4x2048_32x256 : fifo_fla_4x2048_32x256
		port map (
			rst			  => cfi_rst,
			wr_clk		  => cfi_wr_clk,
			wr_en		  => cfi_wr_en,
			din			  => cfi_din,
			wr_data_count => cfi_wr_data_count,
			full		  => cfi_full,
			rd_clk		  => cfi_rd_clk,
			rd_en		  => cfi_rd_en,
			dout		  => cfi_dout,
			empty		  => cfi_empty,
			rd_data_count => cfi_rd_data_count
		);
	cfi_rd_clk <= isysclk;
	cfi_rd_en  <= rd_en;

	process (cfi_rd_clk)
	begin
		if cfi_rd_clk'event and cfi_rd_clk='1' then
  --
			rCsel <= ireg_fla_ctrl(0);
			rIncr <= ireg_fla_ctrl(1);
			Mode_AutoIncr <= ireg_fla_ctrl(2);

			rIncr1d <= rIncr;
			rIncr2d <= rIncr1d;

			sepc_cs_n1d <= iepc_cs_n;
			sepc_cs_n2d <= sepc_cs_n1d;

			if rCsel = '0' then					   -- make empty
				rd_en <= '1';
			elsif rIncr2d='0' and rIncr1d='1' then -- edge trig
				rd_en <= '1';
			elsif Mode_AutoIncr= '1' and  -- auto increment address
				sepc_cs_n2d='0' and sepc_cs_n1d='1' then
				rd_en <= '1';
			else
				rd_en <= '0';
			end if;

			oreg_fla_data <= cfi_dout;
  --
		end if;
	end process;

end architecture behavioral;
