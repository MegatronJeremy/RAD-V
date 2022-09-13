library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity bus_bridge is
	port (
		cpu_bus_busy : out std_logic;
		cpu_bus_addr : in std_logic_vector(31 downto 0);
		cpu_bus_width : in std_logic_vector(1 downto 0);
		cpu_bus_dout : in std_logic_vector(31 downto 0);
		cpu_bus_write : in std_logic;
		cpu_bus_enable : in std_logic;
		cpu_bus_din : out std_logic_vector(31 downto 0);
		
		m0_window_base : in std_logic_vector(31 downto 0);
		m0_window_mask : in std_logic_vector(31 downto 0);
		m0_bus_busy : in std_logic;
		m0_bus_addr : out std_logic_vector(31 downto 2);
		m0_bus_enable : out std_logic;
		m0_bus_write_mask : out std_logic_vector(3 downto 0);
		m0_bus_write_data : out std_logic_vector(31 downto 0);
		m0_bus_read_data : in std_logic_vector(31 downto 0) := (others => '0');
		
		m1_window_base : in std_logic_vector(31 downto 0);
		m1_window_mask : in std_logic_vector(31 downto 0);
		m1_bus_busy : in std_logic;
		m1_bus_addr : out std_logic_vector(31 downto 2);
		m1_bus_enable : out std_logic;
		m1_bus_write_mask : out std_logic_vector(3 downto 0);
		m1_bus_write_data : out std_logic_vector(31 downto 0);
		m1_bus_read_data : in std_logic_vector(31 downto 0) := (others => '0');
		
		m2_window_base : in std_logic_vector(31 downto 0);
		m2_window_mask : in std_logic_vector(31 downto 0);
		m2_bus_busy : in std_logic;
		m2_bus_addr : out std_logic_vector(31 downto 2);
		m2_bus_enable : out std_logic;
		m2_bus_write_mask : out std_logic_vector(3 downto 0);
		m2_bus_write_data : out std_logic_vector(31 downto 0);
		m2_bus_read_data : in std_logic_vector(31 downto 0) := (others => '0')
	);
end entity;

architecture beh of bus_bridge is
	signal active : std_logic_vector(2 downto 0);
	signal addr : std_logic_vector(31 downto 0) := (others => '0');
	signal write : std_logic;
	signal width : std_logic_vector(1 downto 0);
	signal write_data : std_logic_vector(31 downto 0) := (others => '0');
	signal latched_addr : std_logic_vector(31 downto 0) := (others => '0');
	signal latched_write : std_logic;
	signal latched_width : std_logic_vector(1 downto 0);
	signal latched_write_data : std_logic_vector(31 downto 0) := (others => '0');
	signal write_mask : std_logic_vector(3 downto 0);
	signal write_data_aligned : std_logic_vector(31 downto 0);
	signal read_data : std_logic_vector(31 downto 0);
	
	signal busy : std_logic := '0';	
begin
	m0_bus_enable <= active(0);
	m0_bus_addr <= addr(31 downto 2) AND NOT m0_window_mask(31 downto 2);
	m0_bus_write_data <= write_data_aligned;
	m0_bus_write_mask <= write_mask;
	
	m1_bus_enable <= active(1);
	m1_bus_addr <= addr(31 downto 2) AND NOT m1_window_mask(31 downto 2);
	m1_bus_write_data <= write_data_aligned;
	m1_bus_write_mask <= write_mask;
	
	m2_bus_enable <= active(1);
	m2_bus_addr <= addr(31 downto 2) AND NOT m2_window_mask(31 downto 2);
	m2_bus_write_data <= write_data_aligned;
	m2_bus_write_mask <= write_mask;
	
	cpu_bus_busy <= busy;
	
	-- Tell the CPU interface when we are busy
	busy <= (m0_bus_busy and active(0))
		or (m1_bus_busy and active(1))
		or (m2_bus_busy and active(2));
		
	addr <= cpu_bus_addr;
	write <= cpu_bus_write;
	write_data <= cpu_bus_dout;
	width <= cpu_bus_width;
	
process(write_data, addr)
	begin
		case addr(1 downto 0) is
			when "00" => write_data_aligned <= write_data(31 downto 0);
			when "01" => write_data_aligned <= write_data(23 downto 0) & x"00";
			when "10" => write_data_aligned <= write_data(15 downto 0) & x"0000";
			when others => write_data_aligned <= write_data(7 downto 0) & x"000000";
		end case;
	end process;
	
process(write, width, addr)
	begin
		write_mask <= "0000";
		if write = '1' then
			case width & addr(1 downto 0) is
				-- Width is one byte
				when "0000" => write_mask <= "0001";
				when "0001" => write_mask <= "0010";
				when "0010" => write_mask <= "0100";
				when "0011" => write_mask <= "1000";

				-- Width is two bytes
				when "0100" => write_mask <= "0011";
				when "0101" => write_mask <= "0110";
				when "0110" => write_mask <= "1100";
				when "0111" => write_mask <= "1000";

				-- Width is four bytes
				when "1000" => write_mask <= "1111";
				when "1001" => write_mask <= "1110";
				when "1010" => write_mask <= "1100";
				when "1011" => write_mask <= "1000";

				-- Don't write, invalid width
				when others => write_mask <= "0000";
			end case;
		end if;
	end process;
	
process(addr, cpu_bus_enable,
	m0_window_base, m0_window_mask,
	m1_window_base, m1_window_mask,
	m2_window_base, m2_window_mask)
	begin
		active <= (others => '0');
		if cpu_bus_enable = '1' then
			if (addr and m0_window_mask) = m0_window_base then
				active(0) <= '1';
			end if;
		
			if (addr and m1_window_mask) = m1_window_base then
				active(1) <= '1';
			end if;
		
			if (addr and m2_window_mask) = m2_window_base then
				active(2) <= '1';
			end if;
		end if;
	end process;
	
-- Work out which data is being read
process(active, m0_bus_read_data, m1_bus_read_data, m2_bus_read_data)
	begin
		case active is
			when "001" => read_data <= m0_bus_read_data;
			when "010" => read_data <= m1_bus_read_data;
			when "100" => read_data <= m2_bus_read_data;
			when others => read_data <= m2_bus_read_data; -- Multiple active (most likely an error!)
		end case;
	end process;

-- Correct alignment and send it to the CPU
process(read_data, addr)
	begin
		case addr(1 downto 0) is
			when "00" => cpu_bus_din <= read_data(31 downto 0);
			when "01" => cpu_bus_din <= x"00" & read_data(31 downto 8);
			when "10" => cpu_bus_din <= x"0000" & read_data(31 downto 16);
			when "11" => cpu_bus_din <= x"000000" & read_data(31 downto 24);
			when others => cpu_bus_din <= read_data(31 downto 0);
		end case;
	end process;

end beh;
	