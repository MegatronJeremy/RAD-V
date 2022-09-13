library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity ram_memory is
	port (
		clk : in std_logic;
		bus_busy : out std_logic;
		bus_addr : in std_logic_vector(11 downto 2);
		bus_enable : in std_logic;
		bus_write_mask : in std_logic_vector(3 downto 0);
		bus_write_data : in std_logic_vector(31 downto 0);
		bus_read_data : out std_logic_vector(31 downto 0) := (others => '0')
	);
end entity;

architecture beh of ram_memory is
	type a_memory is array (0 to 1023) of std_logic_vector(31 downto 0);
	signal memory : a_memory := (
		others => (others =>'0')
	);
	signal data_valid : std_logic := '1';
begin

	process(bus_enable, bus_write_mask, data_valid)
	begin
		bus_busy <= '0';
		if bus_enable = '1' and bus_write_mask = "0000" then
			if data_valid = '0' then
				bus_busy <= '1';
			end if;
		end if;
	end process;
	
	process(clk)
	begin
		if rising_edge(clk) then
			data_valid <= '0';
			if bus_enable = '1' then
				if bus_write_mask(0) = '1' then
					memory(to_integer(unsigned(bus_addr)))(7 downto 0) <= bus_write_data(7 downto 0);
				end if;
				if bus_write_mask(1) = '1' then
					memory(to_integer(unsigned(bus_addr)))(15 downto 8) <= bus_write_data(15 downto 8);
				end if;
				if bus_write_mask(2) = '1' then
					memory(to_integer(unsigned(bus_addr)))(23 downto 16) <= bus_write_data(23 downto 16);
				end if;
				if bus_write_mask(3) = '1' then
					memory(to_integer(unsigned(bus_addr)))(31 downto 24) <= bus_write_data(31 downto 24);
				end if;
				if bus_write_mask = "0000" and data_valid = '0' then
					data_valid <= '1';
				end if;
				bus_read_data <= memory(to_integer(unsigned(bus_addr)));
			end if;
		end if;
	end process;

end beh;