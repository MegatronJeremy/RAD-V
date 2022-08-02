library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity alu is
  port (
    func : in std_logic_vector(2 downto 0);
    a : in std_logic_vector(31 downto 0);
    b : in std_logic_vector(31 downto 0);
    arithm : in std_logic;
    neg_b : in std_logic;
    c : out std_logic_vector(31 downto 0) := (others => '0')
  );
end alu;

architecture beh of alu is
  constant ALU_ADD : std_logic_vector(2 downto 0) := "000";
  constant ALU_SHL : std_logic_vector(2 downto 0) := "001";
  constant ALU_SLT : std_logic_vector(2 downto 0) := "010";
  constant ALU_SLTU : std_logic_vector(2 downto 0) := "011";
  constant ALU_XOR : std_logic_vector(2 downto 0) := "100";
  constant ALU_SHR : std_logic_vector(2 downto 0) := "101";
  constant ALU_OR : std_logic_vector(2 downto 0) := "110";
  constant ALU_AND : std_logic_vector(2 downto 0) := "111";

  signal padding : std_logic_vector(15 downto 0);
begin

  process (a, arithm)
  begin
    if arithm = '1' and a(a'high) = '1' then
      padding <= (others => '1');
    else
      padding <= (others => '0');
    end if;
  end process;

  process (func, a, b, neg_b, padding)
    variable t : std_logic_vector(31 downto 0);
  begin
    case func is
      when ALU_ADD =>
			  if neg_b = '0' then
				  c <= std_logic_vector(unsigned(a) + unsigned(b));
			  else
				  c <= std_logic_vector(unsigned(a) - unsigned(b));
			  end if;
      when ALU_SLT =>
        c <= (others => '0');
        if signed(a) < signed(b) then
          c(0) <= '1';
        end if;
      when ALU_SLTU =>
        c <= (others => '0');
        if unsigned(a) < unsigned(b) then
          c(0) <= '1';
        end if;
      when ALU_XOR =>
        c <= a xor b;
      when ALU_OR =>
        c <= a or b;
      when ALU_AND =>
        c <= a and b;
      when ALU_SHL | ALU_SHR =>
        -- Swap bit order if shifting to the right --
        if func = ALU_SHR then
          t := a;
        else
          t := a(0) & a(1) & a(2) & a(3) & a(4) & a(5) & a(6) & a(7)
            & a(8) & a(9) & a(10) & a(11) & a(12) & a(13) & a(14) & a(15)
            & a(16) & a(17) & a(18) & a(19) & a(20) & a(21) & a(22) & a(23)
            & a(24) & a(25) & a(26) & a(27) & a(28) & a(29) & a(30) & a(31);
        end if;

        if b(4) = '1' then
          t := padding(15 downto 0) & t(31 downto 16);
        end if;

        if b(3) = '1' then
          t := padding(7 downto 0) & t(31 downto 8);
        end if;

        if b(2) = '1' then
          t := padding(3 downto 0) & t(31 downto 4);
        end if;

        if b(1) = '1' then
          t := padding(1 downto 0) & t(31 downto 2);
        end if;

        if b(0) = '1' then
          t := padding(0 downto 0) & t(31 downto 1);
        end if;

        if func = ALU_SHR then
          c <= t;
        else
          c <= t(0) & t(1) & t(2) & t(3) & t(4) & t(5) & t(6) & t(7)
            & t(8) & t(9) & t(10) & t(11) & t(12) & t(13) & t(14) & t(15)
            & t(16) & t(17) & t(18) & t(19) & t(20) & t(21) & t(22) & t(23)
            & t(24) & t(25) & t(26) & t(27) & t(28) & t(29) & t(30) & t(31);
        end if;

      when others =>
    end case;
  end process;
end beh;