
filepath = r"//192.168.2.53/fpga1/work/EXTxR2/EXTxR2_bu/EXTxR2_bu_260304/EXTxR2.srcs/sources_1/new/TFT_CTRL/TI/TI_DATA_ALIGN.vhd"
with open(filepath, "r") as f:
    lines = f.readlines()
result = []
i = 0
while i < len(lines):
    line = lines[i]
    if "constant ADC_REV" in line and "FUNC_ADC_REV" in line:
        result.append(line)
        result.append("
")
        result.append("    --$ BRAM optimization: use Block RAM for AFE3256 (EXT4343RD) to save LUT
")
        result.append("    constant C_USE_BRAM : boolean := (ROIC_BY_MODEL(GNR_MODEL) = "AFE3256");
")
        i += 1
        continue
    if line.strip() == "end component;" and i > 50 and i < 80:
        result.append(line)
        result.append("
")
        cl = [
            "    component DPRAM_BANK4_BRAM is",
            "        port (",
            "            clka   : in  std_logic;",
            "            ena0   : in  std_logic;",
            "            addra0 : in  std_logic_vector(5 downto 0);",
            "            dina0  : in  std_logic_vector(15 downto 0);",
            "            ena1   : in  std_logic;",
            "            addra1 : in  std_logic_vector(5 downto 0);",
            "            dina1  : in  std_logic_vector(15 downto 0);",
            "            ena2   : in  std_logic;",
            "            addra2 : in  std_logic_vector(5 downto 0);",
            "            dina2  : in  std_logic_vector(15 downto 0);",
            "            ena3   : in  std_logic;",
            "            addra3 : in  std_logic_vector(5 downto 0);",
            "            dina3  : in  std_logic_vector(15 downto 0);",
            "            toggle : in  std_logic;",
            "            clkb   : in  std_logic;",
            "            addrb  : in  std_logic_vector(5 downto 0);",
            "            doutb  : out std_logic_vector(63 downto 0)",
            "        );",
            "    end component;",
        ]
        for c in cl:
            result.append(c + "
")
        i += 1
        continue
    if "    dpram_gen : for i in 0 to ROIC_NUM(GNR_MODEL)-1 generate" in line:
        while i < len(lines):
            if "    end generate dpram_gen;" in lines[i]:
                i += 1
                break
            i += 1
        result.append("PLACEHOLDER_DPRAM_GEN
")
        continue
    result.append(line)
    i += 1
with open(filepath, "w") as f:
    f.writelines(result)
print("Phase 1 done - placeholders inserted")
