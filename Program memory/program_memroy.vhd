library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_Std.all;

entity program_memory is
	port (
		clk : in std_logic;
		-- Instruction interface
		pc_next : in std_logic_vector(31 downto 0);
		instr_reg : out std_logic_vector(31 downto 0)
	);
end entity;

architecture beh of program_memory is
	type a_prog_memory is array (0 to 1023) of std_logic_vector(31 downto 0);
	signal prog_memory : a_prog_memory := (
         -- Test XOR, ADDI and ADD.
         0      => "0000000" & "00001" & "00001" & "100" & "00001" & "0110011",  -- XOR  r01 <= r01 ^ r01  ;  Clear out r01
         1      => "0000000" & "00010" & "00010" & "100" & "00010" & "0110011",  -- XOR  r02 <= r02 ^ r02  ;  Clear out r02
         2      => "000000000001"      & "00001" & "000" & "00001" & "0010011",  -- ADDI r01 <= r01 + 1
         3      => "0000000" & "00001" & "00001" & "000" & "00010" & "0110011",  -- ADD  r02 <= r01 + r01
         4      => "0000000" & "00001" & "00010" & "000" & "00010" & "0110011",  -- ADD  r02 <= r02 + r01
         5      => "0000000" & "00010" & "00001" & "000" & "00010" & "0110011",  -- ADD  r02 <= r01 + r02
                                                                                 -- r01 should be 1, r02 should be 5
                
         -- Test LUI and SRAI and SRLI
         6      =>                "11111111111111111111" & "00010" & "0110111",  -- LUI  r02 <= 0xFFFFF000
         7      => "0100000" & "00010" & "00010" & "101" & "00010" & "0010011",  -- SRAI r02 <= (int)(r02)>>2;
         8      => "0000000" & "00100" & "00010" & "101" & "00010" & "0010011",  -- SRLI r02 <= (unsigned)(r02)>>4;
         9      => "0000000" & "00010" & "00010" & "001" & "00010" & "0010011",  -- SRLI r02 <= (unsigned)(r02)<<2;
                                                                                 -- r02 should be 0x3FFFFFF00
         -- Test AUIPC
         10     =>                "00010010001101000101" & "00010" & "0010111",  -- AUIPC r02 <= 0x023450030
         -- Load RAM address into r07
         11     =>                "00010000000000000000" & "00111" & "0110111",  -- LUI  r07 <= 0xFFFFF000
         --  Test STB
         12     => "0000000" & "00010" & "00111" & "000" & "00000" & "0100011",  -- STB ram(0) <= r02 (byte)
         13     => "0000000" & "00010" & "00111" & "000" & "00001" & "0100011",  -- STB ram(1) <= r02 (byte)
         14     => "0000000" & "00010" & "00111" & "000" & "00010" & "0100011",  -- STB ram(2) <= r02 (byte)
         15     => "0000000" & "00010" & "00111" & "000" & "00011" & "0100011",  -- STB ram(3) <= r02 (byte)
         16     => "000000000000"      & "00111" & "010" & "00011" & "0000011",  -- LW r03 <= ram(0);
         --  Test STH
         17     => "0000000" & "00010" & "00111" & "001" & "00000" & "0100011",  -- STH ram(0) <= r02 (halfword)
         18     => "0000000" & "00010" & "00111" & "001" & "00010" & "0100011",  -- STH ram(2) <= r02 (halfword)
         19     => "000000000000"      & "00111" & "010" & "00011" & "0000011",  -- LW r03 <= ram(0);
         --  Test STW
         20     =>                "10001001101010111101" & "00010" & "0110111",  -- LUI  r02 <= 0x89ABD000
         21     => "110111101111"      & "00010" & "000" & "00010" & "0010011",  -- ADDI r02 <= r02 + x"FFFFFDEF"
         22     => "0000000" & "00010" & "00111" & "010" & "00000" & "0100011",  -- SW ram(0) <= r02 (word)
         23     => "000000000000"      & "00111" & "010" & "00011" & "0000011",  -- LW r03 <= ram(0);
         -- Test LH
         24     => "000000000000"      & "00111" & "001" & "00010" & "0000011",  -- LH r02 <= half0(ram(0));
         25     => "000000000010"      & "00111" & "001" & "00010" & "0000011",  -- LH r02 <= half1(ram(0));
         -- Test LB
         26     => "000000000000"      & "00111" & "000" & "00010" & "0000011",  -- LB r02 <= byte0(ram(0));
         27     => "000000000001"      & "00111" & "000" & "00010" & "0000011",  -- LB r02 <= byte1(ram(0));
         28     => "000000000010"      & "00111" & "000" & "00010" & "0000011",  -- LB r02 <= byte2(ram(0));
         29     => "000000000011"      & "00111" & "000" & "00010" & "0000011",  -- LB r02 <= byte3(ram(0));
         -- Test LHU
         30     => "000000000000"      & "00111" & "101" & "00010" & "0000011",  -- LHU r02 <= unsigned half0(ram(0));
         31     => "000000000010"      & "00111" & "101" & "00010" & "0000011",  -- LHU r02 <= unsigned half1(ram(0));
         -- Test LBU
         32     => "000000000000"      & "00111" & "100" & "00010" & "0000011",  -- LBU r02 <= unsigned byte0(ram(0));
         33     => "000000000001"      & "00111" & "100" & "00010" & "0000011",  -- LBU r02 <= unsigned byte1(ram(0));
         34     => "000000000010"      & "00111" & "100" & "00010" & "0000011",  -- LBU r02 <= unsigned byte2(ram(0));
         35     => "000000000011"      & "00111" & "100" & "00010" & "0000011",  -- LBU r02 <= unsigned byte3(ram(0));
         ---- Load values for Testing all the reg-to-reg ALU operations 
         36     =>                "01100110011001100110" & "00010" & "0110111",  -- LUI  r02 <= 0x66666000
         37     => "011001100110"      & "00010" & "000" & "00010" & "0010011",  -- ADDI r02 <= r02 + x"00000666"
         38     =>                "11001100110011001101" & "00011" & "0110111",  -- LUI  r03 <= 0xCCCCCD00
         39     => "110011001100"      & "00011" & "000" & "00011" & "0010011",  -- ADDI r03 <= r03 + x"FFFFFCCC"
         ---- Testing all the reg-to-reg ALU operations 
         40     => "0000000" & "00011" & "00010" & "000" & "00100" & "0110011",  -- ADD  r04 <= r02 + r03
         41     => "0000000" & "00010" & "00011" & "000" & "00100" & "0110011",  -- ADD  r04 <= r03 + r02
         42     => "0100000" & "00011" & "00010" & "000" & "00100" & "0110011",  -- SUB  r04 <= r02 - r03
         43     => "0100000" & "00010" & "00011" & "000" & "00100" & "0110011",  -- SUB  r04 <= r03 - r02
         44     => "0000000" & "00011" & "00010" & "001" & "00100" & "0110011",  -- SLL  r04 <= r02 << (r03 & 0x1F)
         45     => "0000000" & "00010" & "00011" & "001" & "00100" & "0110011",  -- SLL  r04 <= r03 << (r02 & 0x1F)
         46     => "0000000" & "00011" & "00010" & "010" & "00100" & "0110011",  -- SLT  r04 <= ((int)r02 < (int)r03 ? 1 : 0)
         47     => "0000000" & "00010" & "00011" & "010" & "00100" & "0110011",  -- SLT  r04 <= ((int)r03 < (int)r02 ? 1 : 0)
         48     => "0000000" & "00011" & "00010" & "011" & "00100" & "0110011",  -- SLTU r04 <= ((unsigned)r02 < (unsigned)r03 ? 1 : 0)
         49     => "0000000" & "00010" & "00011" & "011" & "00100" & "0110011",  -- SLTU r04 <= ((unsigned)r03 < (unsigned)r02 ? 1 : 0)
         50     => "0000000" & "00011" & "00010" & "100" & "00100" & "0110011",  -- XOR  r04 <= r02 ^ r03
         51     => "0000000" & "00010" & "00011" & "100" & "00100" & "0110011",  -- XOR  r04 <= r03 ^ r02
         52     => "0000000" & "00011" & "00010" & "101" & "00100" & "0110011",  -- SRL  r04 <= (unsigned)r02 >> (r03 & 0x1f)
         53     => "0000000" & "00010" & "00011" & "101" & "00100" & "0110011",  -- SRL  r04 <= (unsigned)r03 >> (r02 & 0x1f)
         54     => "0100000" & "00011" & "00010" & "101" & "00100" & "0110011",  -- SRA  r04 <= r02 >> (r03 & 0x1f)
         55     => "0100000" & "00010" & "00011" & "101" & "00100" & "0110011",  -- SRA  r04 <= r03 >> (r02 & 0x1f)
         56     => "0000000" & "00011" & "00010" & "110" & "00100" & "0110011",  -- OR   r04 <= r02 | r03
         57     => "0000000" & "00010" & "00011" & "110" & "00100" & "0110011",  -- OR   r04 <= r03 | r02
         58     => "0000000" & "00011" & "00010" & "111" & "00100" & "0110011",  -- AND  r04 <= r02 & r03
         59     => "0000000" & "00010" & "00011" & "111" & "00100" & "0110011",  -- AND  r04 <= r03 & r02
         ---- Testing all the reg, immediate ALU operations 
         60     =>      "011001100110" & "00011" & "000" & "00100" & "0010011",  -- ADDI  r04 <= r03 + 0x666
         61     =>      "011001100110" & "00011" & "010" & "00100" & "0010011",  -- SLTI  r04 <= ((int)r03 < 0x666 ? 1 : 0)
         62     =>      "011001100110" & "00011" & "011" & "00100" & "0010011",  -- SLTUI r04 <= ((unsigned)r03 < 0x666 ? 1 : 0)
         63     =>      "011001100110" & "00011" & "100" & "00100" & "0010011",  -- XORI  r04 <= r03 ^ 0x666
         64     =>      "011001100110" & "00011" & "110" & "00100" & "0010011",  -- ORI   r04 <= r03 | 0x666
         65     =>      "011001100110" & "00011" & "111" & "00100" & "0010011",  -- ANDI  r04 <= r03 & 0x666
         66     =>      "000000000110" & "00011" & "001" & "00100" & "0010011",  -- SLLI  r04 <= r03 << 6
         67     =>      "000000000110" & "00011" & "101" & "00100" & "0010011",  -- SRLI  r04 <= (unsigned)r03 >> 6
         68     =>      "010000000110" & "00011" & "101" & "00100" & "0010011",  -- SRAI  r04 <= r03 >> 6
         ---- JAL, JAR
         69     =>      "000000000000" & "00000" & "000" & "00011" & "0010011",  -- ADDI  r03 <= r00 + 0x000
         70     =>                "00000000100000000000" & "00100" & "1101111",  -- JAL   +8, r04
         71     =>      "000000000001" & "00011" & "110" & "00011" & "0010011",  -- ORI   r03 <= r03 | 0x001  <<< Skipped
         72     =>      "000000000010" & "00011" & "110" & "00011" & "0010011",  -- ORI   r03 <= r03 | 0x002
         73     =>      "000000000100" & "00011" & "110" & "00011" & "0010011",  -- ORI   r03 <= r03 | 0x004 << Should be 0x6
       
         -- BEQ, BNE, BLT, BGE, BLTU, BGEU with regsters equal, (r03 = 8, r04 = 8)
         74     => "0000000" & "00010" & "00010" & "100" & "00010" & "0110011",  -- XOR  r02 <= r02 ^ r02
         75     =>      "000000001000" & "00010" & "000" & "00011" & "0010011",  -- ADDI r03 <= r02 + 0x008
         76     =>      "000000001000" & "00010" & "000" & "00100" & "0010011",  -- ADDI r04 <= r02 + 0x008
         77     => "0000000" & "00100" & "00011" & "000" & "01000" & "1100011",  -- BEQ  r03, r04, +8
         78     =>      "000000000001" & "00010" & "110" & "00010" & "0010011",  -- ORI  r02 <= r02 | 0x001
         79     => "0000000" & "00100" & "00011" & "001" & "01000" & "1100011",  -- BNE  r03, r04, +8
         80     =>      "000000000010" & "00010" & "110" & "00010" & "0010011",  -- ORI  r02 <= r02 | 0x002
         81     => "0000000" & "00100" & "00011" & "100" & "01000" & "1100011",  -- BLT  r03, r04, +8
         82     =>      "000000000100" & "00010" & "110" & "00010" & "0010011",  -- ORI  r02 <= r02 | 0x004
         83     => "0000000" & "00100" & "00011" & "101" & "01000" & "1100011",  -- BGE  r03, r04, +8
         84     =>      "000000001000" & "00010" & "110" & "00010" & "0010011",  -- ORI  r02 <= r02 | 0x008
         85     => "0000000" & "00100" & "00011" & "110" & "01000" & "1100011",  -- BLTU r03, r04, +8
         86     =>      "000000010000" & "00010" & "110" & "00010" & "0010011",  -- ORI  r02 <= r02 | 0x010
         87     => "0000000" & "00100" & "00011" & "111" & "01000" & "1100011",  -- BGEU r03, r04, +8
         88     =>      "000000100000" & "00010" & "110" & "00010" & "0010011",  -- ORI  r02 <= r02 | 0x020

         -- BEQ, BNE, BLT, BGE, BLTU, BGEU with r04 > r03 (both signed and unsigned (r03 = 8, r04 = 16)
         89     => "0000000" & "00010" & "00010" & "100" & "00010" & "0110011",  -- XOR  r02 <= r02 ^ r02
         90     =>      "000000001000" & "00011" & "000" & "00100" & "0010011",  -- ADDI r04 <= r03 + 0x008
         91     => "0000000" & "00100" & "00011" & "000" & "01000" & "1100011",  -- BEQ  r03, r04, +8
         92     =>      "000000000001" & "00010" & "110" & "00010" & "0010011",  -- ORI  r02 <= r02 | 0x001
         93     => "0000000" & "00100" & "00011" & "001" & "01000" & "1100011",  -- BNE  r03, r04, +8
         94     =>      "000000000010" & "00010" & "110" & "00010" & "0010011",  -- ORI  r02 <= r02 | 0x002
         95     => "0000000" & "00100" & "00011" & "100" & "01000" & "1100011",  -- BLT  r03, r04, +8
         96     =>      "000000000100" & "00010" & "110" & "00010" & "0010011",  -- ORI  r02 <= r02 | 0x004
         97     => "0000000" & "00100" & "00011" & "101" & "01000" & "1100011",  -- BGE  r03, r04, +8
         98     =>      "000000001000" & "00010" & "110" & "00010" & "0010011",  -- ORI  r02 <= r02 | 0x008
         99     => "0000000" & "00100" & "00011" & "110" & "01000" & "1100011",  -- BLTU r03, r04, +8
         100    =>      "000000010000" & "00010" & "110" & "00010" & "0010011",  -- ORI  r02 <= r02 | 0x010
         101    => "0000000" & "00100" & "00011" & "111" & "01000" & "1100011",  -- BGEU r03, r04, +8
         102    =>      "000000100000" & "00010" & "110" & "00010" & "0010011",  -- ORI  r02 <= r02 | 0x020
       
         -- BEQ, BNE, BLT, BGE, BLTU, BGEU with r04 > r03 (both signed and unsigned (r03 = 8, r04 = -16)
         103    => "0000000" & "00010" & "00010" & "100" & "00010" & "0110011",  -- XOR  r02 <= r02 ^ r02
         104    =>      "111111100000" & "00010" & "000" & "00100" & "0010011",  -- ADDI r04 <= r02 + 0xFFFFFFE0  (-32)
         105    => "0000000" & "00100" & "00011" & "000" & "01000" & "1100011",  -- BEQ  r03, r04, +8
         106    =>      "000000000001" & "00010" & "110" & "00010" & "0010011",  -- ORI  r02 <= r02 | 0x001
         107    => "0000000" & "00100" & "00011" & "001" & "01000" & "1100011",  -- BNE  r03, r04, +8
         108    =>      "000000000010" & "00010" & "110" & "00010" & "0010011",  -- ORI  r02 <= r02 | 0x002
         109    => "0000000" & "00100" & "00011" & "100" & "01000" & "1100011",  -- BLT  r03, r04, +8
         110    =>      "000000000100" & "00010" & "110" & "00010" & "0010011",  -- ORI  r02 <= r02 | 0x004
         111    => "0000000" & "00100" & "00011" & "101" & "01000" & "1100011",  -- BGE  r03, r04, +8
         112    =>      "000000001000" & "00010" & "110" & "00010" & "0010011",  -- ORI  r02 <= r02 | 0x008
         113    => "0000000" & "00100" & "00011" & "110" & "01000" & "1100011",  -- BLTU r03, r04, +8
         114    =>      "000000010000" & "00010" & "110" & "00010" & "0010011",  -- ORI  r02 <= r02 | 0x010
         115    => "0000000" & "00100" & "00011" & "111" & "01000" & "1100011",  -- BGEU r03, r04, +8
         116    =>      "000000100000" & "00010" & "110" & "00010" & "0010011",  -- ORI  r02 <= r02 | 0x020
       
         1023   => "1111111" & "11101" & "11110" & "111" & "11101" & "1001100",  -- Just to make sure all bits are toggled
         others => "000000000001"      & "00001" & "000" & "00001" & "0010011"   -- r01 <= r01 + 1
    );
	 attribute keep : string;
	 attribute ram_style : string;
	 
begin
	 -- PROGRAM ROM INTERFACE 
	 process(clk)
		begin
			if rising_edge(clk) then
				if pc_next(31 downto 12) = x"F0000" then
					instr_reg <= prog_memory(to_integer(unsigned(pc_next(11 downto 2))));
				else
					instr_reg <= (others => '0');
				end if;
			end if;
		end process;
		
end beh;