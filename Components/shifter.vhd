library IEEE;
use IEEE.std_logic_1164.all;

entity shifter is
	port (
		func : in std_logic_vector(1 downto 0) := "00";
		a : in std_logic_vector(31 downto 0);
		b : in std_logic_vector(4 downto 0);
		c : out std_logic_vector(31 downto 0) := (others => '0')
	);
end entity;

architecture beh of shifter is
	constant SHIFT_LEFT_LOG : std_logic_vector(1 downto 0) := "00";
	constant SHIFT_LEFT_ARI : std_logic_vector(1 downto 0) := "01";
	constant SHIFT_RIGHT_LOG : std_Logic_vector(1 downto 0) := "10";
	constant SHIFT_RIGHT_ARI : std_Logic_vector(1 downto 0) := "11";
	
	signal pad : std_logic_vector(15 downto 0);
begin

process(func, a)
	begin
		-- Generate padding for arithmetic shift right
		if func = SHIFT_RIGHT_ARI AND a(a'high) = '1' then
			pad <= (others => '1');
		else
			pad <= (others => '0');
		end if;
	end process;

process(func, a, b, pad)
	variable t : std_logic_vector(31 downto 0);
	begin
		-- Swap bit order if shiting to the right
		if func = SHIFT_RIGHT_LOG OR func = SHIFT_RIGHT_ARI then
			t := a;
		else
			t := a( 0) & a( 1) & a( 2) & a( 3) & a( 4) & a( 5) & a( 6) & a( 7)
            & a( 8) & a( 9) & a(10) & a(11) & a(12) & a(13) & a(14) & a(15)
            & a(16) & a(17) & a(18) & a(19) & a(20) & a(21) & a(22) & a(23)
            & a(24) & a(25) & a(26) & a(27) & a(28) & a(29) & a(30) & a(31);
		end if;
		
		if b(4) = '1' then
			t := pad(15 downto 0) & t(31 downto 16);
		end if;
		
		if b(3) = '1' then
			t := pad(7 downto 0) & t(31 downto 8);
		end if;
		
		if b(2) = '1' then
			t := pad(3 downto 0) & t(31 downto 4);
		end if;
		
		if b(1) = '1' then
			t := pad(1 downto 0) & t(31 downto 2);
		end if;
		
		if b(0) = '1' then
			t := pad(0 downto 0) & t(31 downto 1);
		end if;
		
		if func = SHIFT_RIGHT_LOG OR func = SHIFT_RIGHT_ARI then
			c <= t;
		else 
			c <= t( 0) & t( 1) & t( 2) & t( 3) & t( 4) & t( 5) & t( 6) & t( 7)
            & t( 8) & t( 9) & t(10) & t(11) & t(12) & t(13) & t(14) & t(15)
            & t(16) & t(17) & t(18) & t(19) & t(20) & t(21) & t(22) & t(23)
            & t(24) & t(25) & t(26) & t(27) & t(28) & t(29) & t(30) & t(31);
		end if;
	end process;
end beh;
		
			