library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity branch_test is
	port (
		func : in std_logic_vector(2 downto 0);
		enable : in std_logic;
		a : in std_logic_vector(31 downto 0);
		b : in std_logic_vector(31 downto 0);
		branch : out std_logic
	);
end entity;

architecture beh of branch_test is

	constant EQ : std_logic_vector(2 downto 0) := "000";
	constant NE : std_logic_vector(2 downto 0) := "001";	
	constant TRUE : std_logic_vector(2 downto 0) := "010";
	constant FALSE : std_logic_vector(2 downto 0) := "011";
	constant LT : std_logic_vector(2 downto 0) := "100";
	constant GE : std_logic_vector(2 downto 0) := "101";
	constant LTU : std_logic_vector(2 downto 0) := "110";
	constant GEU : std_logic_vector(2 downto 0) := "111";
	
	signal is_true : std_logic;
	
begin
	branch <= is_true and enable;
	
process(func, a, b)
	variable a_dash : std_logic_vector(31 downto 0);
	variable b_dash : std_logic_vector(31 downto 0);
	
	begin
		a_dash := a;
		b_dash := b;
		-- Map signed values to unsigned values for comparison
		if func = GE or func = LT then
			a_dash(a_dash'high) := NOT a_dash(a_dash'high);
			b_dash(b_dash'high) := NOT b_dash(b_dash'high);
		end if;
		
		case func(2 downto 1) is
			when "00" => -- EQ and NE
				if a_dash = b_dash then
					is_true <= NOT func(0);
				else
					is_true <= func(0);
				end if;
				
			when "01" => -- TRUE and FALSE
				is_true <= NOT func(0);
				
			when "10" => -- SIGNED LT and GE
				if unsigned(a_dash) < unsigned(b_dash) then
					is_true <= NOT func(0);
				else
					is_true <= func(0);
				end if;
				
			when "11" => -- UNSIGNED LT and GE
				if unsigned(a_dash) < unsigned(b_dash) then
					is_true <= NOT func(0);
				else
					is_true <= func(0);
				end if;
				
			when others =>
		end case;
	end process;
	
end beh;
		