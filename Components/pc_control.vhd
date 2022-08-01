 library IEEE;
 use IEEE.std_logic_1164.all;
 use IEEE.numeric_std.all;
 
 entity pc_control is
	port (
		clk : in std_logic;
		busy : in std_logic;
		
		func : in std_logic_vector(1 downto 0);
		branch : in std_logic;
		jump_offset : in std_logic_vector(31 downto 0);
		branch_offset : in std_logic_vector(31 downto 0);
		jumpreg_offset : in std_logic_vector(31 downto 0);
		a : in std_logic_vector(31 downto 0);
		
		pc : out std_logic_vector(31 downto 0);
		pc_next : out std_logic_vector(31 downto 0);
		pc_plus_four : out std_logic_vector(31 downto 0)
	);
end entity;

architecture beh of pc_control is
	signal curr_pc : unsigned(31 downto 0) := x"FFFFFFF0";
	signal next_instr : unsigned(31 downto 0);
	signal is_true : std_logic;
	
	constant JMP_REL : std_logic_vector(1 downto 0) := "00";
	constant JMP_REG_REL : std_logic_vector(1 downto 0) := "01";
	constant JMP_REL_CND : std_logic_vector(1 downto 0) := "10";
	constant RESET : std_logic_vector(1 downto 0) := "11";
	
	constant RESET_VECTOR : std_logic_vector(31 downto 0) := x"F0000000";
	
begin

	pc <= std_logic_vector(curr_pc);
	pc_plus_four <= std_logic_vector(curr_pc + 4);

process(next_instr, busy, curr_pc)
	begin
		if busy = '1' then
			pc_next <= std_logic_vector(curr_pc);
		else
			pc_next <= std_logic_vector(next_instr);
		end if;
	end process;
	
process(func, curr_pc, a, branch_offset, jump_offset, jumpreg_offset, branch)
	variable LHS : unsigned(31 downto 0);
	variable RHS : unsigned(31 downto 0);
	begin
		-- Set LHS
		case func is
			when JMP_REL_CND => LHS := unsigned(curr_pc);
			when JMP_REL => LHS := unsigned(curr_pc);
			when JMP_REG_REL => LHS := unsigned(a);
			when others => LHS := unsigned(RESET_VECTOR);
		end case;
	
		-- Set RHS
		case func is
			when JMP_REL_CND =>
				if branch = '1' then
					RHS := unsigned(branch_offset);
				else
					RHS := to_unsigned(4, 32);
				end if;
			when JMP_REL => RHS := unsigned(jump_offset);
			when JMP_REG_REL => RHS := unsigned(jumpreg_offset);
			when others => RHS := x"00000000";
		end case;
		
		-- Calculate 4-byte aligned instruction
		next_instr <= (LHS + RHS) AND x"FFFFFFFC";
	end process;

process(clk)
	begin
		if rising_edge(clk) then
			if busy = '0' then
				curr_pc <= next_instr;
			end if;
		end if;
	end process;
end beh;