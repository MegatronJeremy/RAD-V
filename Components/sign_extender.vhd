library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity sign_extender is
	port (
		ex_mode : in std_logic;
		ex_width : in std_logic_vector(1 downto 0);
		a : in std_logic_vector(31 downto 0);
		b : out std_logic_vector(31 downto 0)
	);
end entity;

architecture beh of sign_extender is
	constant WIDTH_B : std_logic_vector(1 downto 0) := "00";
	constant WIDTH_H : std_logic_vector(1 downto 0) := "01";
	constant WIDTH_W : std_logic_vector(1 downto 0) := "10";
	constant WIDTH_X : std_logic_vector(1 downto 0) := "11";
	constant EX_SIGNED : std_logic := '0';
	constant EX_UNSIGNED : std_logic := '1';
	signal pad : std_logic_vector(31 downto 0);
begin

process(ex_mode, ex_width, a)
	begin
		pad <= (others => '0');
		if ex_mode = EX_SIGNED then
			case ex_width is
				when WIDTH_B =>
					if a(7) = '1' then
						pad <= (others => '1');
					end if;
				when others =>
					if a(15) = '1' then
						pad <= (others => '1');
					end if;
			end case;
		end if;
	end process;

process(ex_width, pad, a)
	begin
		case ex_width is
			when WIDTH_B =>
				b <= pad(31 downto 8) & a(7 downto 0);
			when WIDTH_H =>
				b <= pad(31 downto 16) & a(15 downto 0);
			when others =>
				b <= a;
		end case;
	end process;
end beh;