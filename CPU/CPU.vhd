-- Copyright (C) 1991-2013 Altera Corporation
-- Your use of Altera Corporation's design tools, logic functions 
-- and other software and tools, and its AMPP partner logic 
-- functions, and any output files from any of the foregoing 
-- (including device programming or simulation files), and any 
-- associated documentation or information are expressly subject 
-- to the terms and conditions of the Altera Program License 
-- Subscription Agreement, Altera MegaCore Function License 
-- Agreement, or other applicable license agreement, including, 
-- without limitation, that your use is for the sole purpose of 
-- programming logic devices manufactured by Altera and sold by 
-- Altera or its authorized distributors.  Please refer to the 
-- applicable agreement for further details.

-- PROGRAM		"Quartus II 64-Bit"
-- VERSION		"Version 13.1.0 Build 162 10/23/2013 SJ Web Edition"
-- CREATED		"Tue Aug 02 12:21:27 2022"

LIBRARY ieee;
USE ieee.std_logic_1164.all; 

LIBRARY work;

ENTITY CPU IS 
	PORT
	(
		clk :  IN  STD_LOGIC;
		reset :  IN  STD_LOGIC;
		bus_busy :  IN  STD_LOGIC;
		bus_din :  IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
		instr_reg :  IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
		bus_write :  OUT  STD_LOGIC;
		bus_enable :  OUT  STD_LOGIC;
		bus_addr :  OUT  STD_LOGIC_VECTOR(31 DOWNTO 0);
		bus_dout :  OUT  STD_LOGIC_VECTOR(31 DOWNTO 0);
		bus_width :  OUT  STD_LOGIC_VECTOR(1 DOWNTO 0);
		pc_next :  OUT  STD_LOGIC_VECTOR(31 DOWNTO 0)
	);
END CPU;

ARCHITECTURE bdf_type OF CPU IS 

COMPONENT control_unit
	PORT(reset : IN STD_LOGIC;
		 instr : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
		 out_sel_a : OUT STD_LOGIC;
		 out_zero_a : OUT STD_LOGIC;
		 out_sel_b : OUT STD_LOGIC;
		 out_zero_b : OUT STD_LOGIC;
		 out_bus_write : OUT STD_LOGIC;
		 out_bus_enable : OUT STD_LOGIC;
		 out_alu_neg_b : OUT STD_LOGIC;
		 out_alu_arithm : OUT STD_LOGIC;
		 out_branch_test_en : OUT STD_LOGIC;
		 out_sign_ex_mode : OUT STD_LOGIC;
		 out_result_src : OUT STD_LOGIC;
		 out_result_src_int : OUT STD_LOGIC;
		 out_alu_func : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
		 out_branch_offset : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
		 out_branch_test_func : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
		 out_bus_width : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
		 out_imm : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
		 out_jump_offset : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
		 out_pc_func : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
		 out_rdst : OUT STD_LOGIC_VECTOR(4 DOWNTO 0);
		 out_reg_a : OUT STD_LOGIC_VECTOR(4 DOWNTO 0);
		 out_reg_b : OUT STD_LOGIC_VECTOR(4 DOWNTO 0);
		 out_sign_ex_width : OUT STD_LOGIC_VECTOR(1 DOWNTO 0)
	);
END COMPONENT;

COMPONENT mux2_32b
	PORT(sel : IN STD_LOGIC;
		 zero : IN STD_LOGIC;
		 d_in_1 : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
		 d_in_2 : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
		 d_out : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
	);
END COMPONENT;

COMPONENT sign_extender
	PORT(ex_mode : IN STD_LOGIC;
		 a : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
		 ex_width : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
		 b : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
	);
END COMPONENT;

COMPONENT branch_test
	PORT(enable : IN STD_LOGIC;
		 a : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
		 b : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
		 func : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
		 branch : OUT STD_LOGIC
	);
END COMPONENT;

COMPONENT pc_control
	PORT(clk : IN STD_LOGIC;
		 busy : IN STD_LOGIC;
		 branch : IN STD_LOGIC;
		 a : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
		 branch_offset : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
		 func : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
		 jump_offset : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
		 jumpreg_offset : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
		 pc : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
		 pc_next : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
		 pc_plus_four : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
	);
END COMPONENT;

COMPONENT reg_file
	PORT(clk : IN STD_LOGIC;
		 busy : IN STD_LOGIC;
		 read_addr_1 : IN STD_LOGIC_VECTOR(4 DOWNTO 0);
		 read_addr_2 : IN STD_LOGIC_VECTOR(4 DOWNTO 0);
		 write_addr : IN STD_LOGIC_VECTOR(4 DOWNTO 0);
		 write_data : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
		 read_data_1 : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
		 read_data_2 : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
	);
END COMPONENT;

COMPONENT alu
	PORT(arithm : IN STD_LOGIC;
		 neg_b : IN STD_LOGIC;
		 a : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
		 b : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
		 func : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
		 c : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
	);
END COMPONENT;

SIGNAL	a :  STD_LOGIC_VECTOR(31 DOWNTO 0);
SIGNAL	alu :  STD_LOGIC_VECTOR(31 DOWNTO 0);
SIGNAL	alu_ar_shift :  STD_LOGIC;
SIGNAL	alu_func :  STD_LOGIC_VECTOR(2 DOWNTO 0);
SIGNAL	alu_neg_b :  STD_LOGIC;
SIGNAL	b :  STD_LOGIC_VECTOR(31 DOWNTO 0);
SIGNAL	br_offs :  STD_LOGIC_VECTOR(31 DOWNTO 0);
SIGNAL	br_test_func :  STD_LOGIC_VECTOR(2 DOWNTO 0);
SIGNAL	branch_test_en :  STD_LOGIC;
SIGNAL	bus_en :  STD_LOGIC;
SIGNAL	bus_wdt :  STD_LOGIC_VECTOR(1 DOWNTO 0);
SIGNAL	bus_wr :  STD_LOGIC;
SIGNAL	busy :  STD_LOGIC;
SIGNAL	gnd :  STD_LOGIC;
SIGNAL	imm :  STD_LOGIC_VECTOR(31 DOWNTO 0);
SIGNAL	instr :  STD_LOGIC_VECTOR(31 DOWNTO 0);
SIGNAL	jmp_offs :  STD_LOGIC_VECTOR(31 DOWNTO 0);
SIGNAL	pc :  STD_LOGIC_VECTOR(31 DOWNTO 0);
SIGNAL	pc_func :  STD_LOGIC_VECTOR(1 DOWNTO 0);
SIGNAL	pc_plus_four :  STD_LOGIC_VECTOR(31 DOWNTO 0);
SIGNAL	reg_a :  STD_LOGIC_VECTOR(4 DOWNTO 0);
SIGNAL	reg_b :  STD_LOGIC_VECTOR(4 DOWNTO 0);
SIGNAL	reg_dst :  STD_LOGIC_VECTOR(4 DOWNTO 0);
SIGNAL	res_mem :  STD_LOGIC_VECTOR(31 DOWNTO 0);
SIGNAL	res_src :  STD_LOGIC;
SIGNAL	res_src_internal :  STD_LOGIC;
SIGNAL	sel_a :  STD_LOGIC;
SIGNAL	sel_b :  STD_LOGIC;
SIGNAL	sign_ex_mode :  STD_LOGIC;
SIGNAL	sign_ex_wdt :  STD_LOGIC_VECTOR(1 DOWNTO 0);
SIGNAL	zero_a :  STD_LOGIC;
SIGNAL	zero_b :  STD_LOGIC;
SIGNAL	SYNTHESIZED_WIRE_0 :  STD_LOGIC_VECTOR(31 DOWNTO 0);
SIGNAL	SYNTHESIZED_WIRE_1 :  STD_LOGIC;
SIGNAL	SYNTHESIZED_WIRE_2 :  STD_LOGIC_VECTOR(31 DOWNTO 0);
SIGNAL	SYNTHESIZED_WIRE_3 :  STD_LOGIC_VECTOR(31 DOWNTO 0);
SIGNAL	SYNTHESIZED_WIRE_4 :  STD_LOGIC_VECTOR(31 DOWNTO 0);


BEGIN 



b2v_inst : control_unit
PORT MAP(reset => reset,
		 instr => instr,
		 out_sel_a => sel_a,
		 out_zero_a => zero_a,
		 out_sel_b => sel_b,
		 out_zero_b => zero_b,
		 out_bus_write => bus_wr,
		 out_bus_enable => bus_en,
		 out_alu_neg_b => alu_neg_b,
		 out_alu_arithm => alu_ar_shift,
		 out_branch_test_en => branch_test_en,
		 out_sign_ex_mode => sign_ex_mode,
		 out_result_src => res_src,
		 out_result_src_int => res_src_internal,
		 out_alu_func => alu_func,
		 out_branch_offset => br_offs,
		 out_branch_test_func => br_test_func,
		 out_bus_width => bus_wdt,
		 out_imm => imm,
		 out_jump_offset => jmp_offs,
		 out_pc_func => pc_func,
		 out_rdst => reg_dst,
		 out_reg_a => reg_a,
		 out_reg_b => reg_b,
		 out_sign_ex_width => sign_ex_wdt);


b2v_inst1 : mux2_32b
PORT MAP(sel => res_src,
		 zero => gnd,
		 d_in_1 => res_mem,
		 d_in_2 => SYNTHESIZED_WIRE_0,
		 d_out => SYNTHESIZED_WIRE_2);


b2v_inst11 : sign_extender
PORT MAP(ex_mode => sign_ex_mode,
		 a => bus_din,
		 ex_width => sign_ex_wdt,
		 b => res_mem);


b2v_inst14 : branch_test
PORT MAP(enable => branch_test_en,
		 a => a,
		 b => b,
		 func => br_test_func,
		 branch => SYNTHESIZED_WIRE_1);


b2v_inst2 : mux2_32b
PORT MAP(sel => res_src_internal,
		 zero => gnd,
		 d_in_1 => alu,
		 d_in_2 => pc_plus_four,
		 d_out => SYNTHESIZED_WIRE_0);



b2v_inst5 : pc_control
PORT MAP(clk => clk,
		 busy => busy,
		 branch => SYNTHESIZED_WIRE_1,
		 a => a,
		 branch_offset => br_offs,
		 func => pc_func,
		 jump_offset => jmp_offs,
		 jumpreg_offset => imm,
		 pc => pc,
		 pc_next => pc_next,
		 pc_plus_four => pc_plus_four);


b2v_inst6 : reg_file
PORT MAP(clk => clk,
		 busy => busy,
		 read_addr_1 => reg_a,
		 read_addr_2 => reg_b,
		 write_addr => reg_dst,
		 write_data => SYNTHESIZED_WIRE_2,
		 read_data_1 => a,
		 read_data_2 => b);


b2v_inst7 : mux2_32b
PORT MAP(sel => sel_a,
		 zero => zero_a,
		 d_in_1 => a,
		 d_in_2 => pc,
		 d_out => SYNTHESIZED_WIRE_3);


b2v_inst8 : mux2_32b
PORT MAP(sel => sel_b,
		 zero => zero_b,
		 d_in_1 => b,
		 d_in_2 => imm,
		 d_out => SYNTHESIZED_WIRE_4);


b2v_inst9 : alu
PORT MAP(arithm => alu_ar_shift,
		 neg_b => alu_neg_b,
		 a => SYNTHESIZED_WIRE_3,
		 b => SYNTHESIZED_WIRE_4,
		 func => alu_func,
		 c => alu);

bus_write <= bus_wr;
instr <= instr_reg;
bus_enable <= bus_en;
bus_addr <= alu;
busy <= bus_busy;
bus_dout <= b;
bus_width <= bus_wdt;

gnd <= '0';
END bdf_type;