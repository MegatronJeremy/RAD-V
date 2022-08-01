library IEEE;
use IEEE.std_logic_1164.all;

entity control_unit is
  port (
    reset : in std_logic;
    instr : in std_logic_vector(31 downto 0);
    out_imm : out std_logic_vector(31 downto 0) := (others => '0');

    out_reg_a : out std_logic_vector(4 downto 0) := (others => '0');
    out_sel_a : out std_logic := '0';
    out_zero_a : out std_logic := '0';

    out_reg_b : out std_logic_vector(4 downto 0) := (others => '0');
    out_sel_b : out std_logic := '0';
    out_zero_b : out std_logic := '0';

    out_pc_func : out std_logic_vector(1 downto 0) := "00";
    out_jump_offset : out std_logic_vector(31 downto 0) := (others => '0');
    out_branch_offset : out std_logic_vector(31 downto 0) := (others => '0');

    out_bus_write : out std_logic;
    out_bus_enable : out std_logic;
    out_bus_width : out std_logic_vector(1 downto 0);

    out_alu_func : out std_logic_vector(2 downto 0) := "000";
    out_alu_neg_b : out std_logic := '0';
    out_alu_arithm : out std_logic := '0';
    out_branch_test_en : out std_logic := '0';
    out_branch_test_func : out std_logic_vector(2 downto 0) := "000";

    out_sign_ex_mode : out std_logic := '0';
    out_sign_ex_width : out std_logic_vector(1 downto 0) := "00";
	 
    out_result_src : out std_logic := '0';
	 out_result_src_int : out std_logic := '0'; 
    out_rdst : out std_logic_vector(4 downto 0) := (others => '0')
  );
end entity;

architecture beh of control_unit is
  -- Decoding the instruction
  signal opcode : std_logic_vector(6 downto 0);
  signal rd : std_logic_vector(4 downto 0);
  signal rs1 : std_logic_vector(4 downto 0);
  signal rs2 : std_logic_vector(4 downto 0);
  signal func3 : std_logic_vector(2 downto 0);
  signal func7 : std_logic_vector(6 downto 0);
  signal imm_I : std_logic_vector(31 downto 0);
  signal imm_S : std_logic_vector(31 downto 0);
  signal imm_B : std_logic_vector(31 downto 0);
  signal imm_U : std_logic_vector(31 downto 0);
  signal imm_J : std_logic_vector(31 downto 0);
  signal instr31 : std_logic_vector(31 downto 0);

  -- MUXing A and B data
  constant A_BUS_REG : std_logic := '0';
  constant A_BUS_PC : std_logic := '1';

  constant B_BUS_REG : std_logic := '0';
  constant B_BUS_IMM : std_logic := '1';

  -- Program counter update mode
  constant PC_JMP_REL : std_logic_vector(1 downto 0) := "00";
  constant PC_JMP_REG_REL : std_logic_vector(1 downto 0) := "01";
  constant PC_JMP_REL_CND : std_logic_vector(1 downto 0) := "10";
  constant PC_RESET : std_logic_vector(1 downto 0) := "11";

  -- Conditional branch test
  constant BRANCH_TEST_EQ : std_logic_vector(2 downto 0) := "000";
  constant BRANCH_TEST_NE : std_logic_vector(2 downto 0) := "001";
  constant BRANCH_TEST_TRUE : std_logic_vector(2 downto 0) := "010";
  constant BRANCH_TEST_FALSE : std_logic_vector(2 downto 0) := "011";
  constant BRANCH_TEST_LT : std_logic_vector(2 downto 0) := "100";
  constant BRANCH_TEST_GE : std_logic_vector(2 downto 0) := "101";
  constant BRANCH_TEST_LTU : std_logic_vector(2 downto 0) := "110";
  constant BRANCH_TEST_GEU : std_logic_vector(2 downto 0) := "111";

  -- ALU functions
  constant ALU_ADD : std_logic_vector(2 downto 0) := "000";
  constant ALU_SHL : std_logic_vector(2 downto 0) := "001";
  constant ALU_SLT : std_logic_vector(2 downto 0) := "010";
  constant ALU_SLTU : std_logic_vector(2 downto 0) := "011";
  constant ALU_XOR : std_logic_vector(2 downto 0) := "100";
  constant ALU_SHR : std_logic_vector(2 downto 0) := "101";
  constant ALU_OR : std_logic_vector(2 downto 0) := "110";
  constant ALU_AND : std_logic_vector(2 downto 0) := "111";

  -- Register file input mux signals
  constant RES_MEM : std_logic := '0';
  constant RES_INTERNAL : std_logic := '1';
  constant RES_ALU : std_logic := '0';
  constant RES_PC_PLUS_4 : std_logic := '1';

  -- Sign extender modes
  constant SIGN_EX_WIDTH_B : std_logic_vector(1 downto 0) := "00";
  constant SIGN_EX_WIDTH_H : std_logic_vector(1 downto 0) := "01";
  constant SIGN_EX_WIDTH_W : std_logic_vector(1 downto 0) := "10";
  constant SIGN_EX_WIDTH_X : std_logic_vector(1 downto 0) := "11";
  constant SIGN_EX_SIGNED : std_logic := '0';
  constant SIGN_EX_UNSIGNED : std_logic := '1';

begin
  -- Immediate value sign extending (sign is always bit 31)
  with instr(31) select instr31 <= x"FFFFFFFF" when '1', x"00000000" when others;

  -- Breakdown of the R, I, S, B, U and J instruction types
  opcode <= instr(6 downto 0);
  rd <= instr(11 downto 7);
  func3 <= instr(14 downto 12);
  func7 <= instr(31 downto 25);
  rs1 <= instr(19 downto 15);
  rs2 <= instr(24 downto 20);
  imm_I <= instr31(31 downto 12) & instr(31 downto 20);
  imm_S <= instr31(31 downto 12) & instr(31 downto 25) & instr(11 downto 7);
  imm_B <= instr31(31 downto 12) & instr(7) & instr(30 downto 25) & instr(11 downto 8) & "0";
  imm_U <= instr(31 downto 12) & x"000";
  imm_J <= instr31(31 downto 20) & instr(19 downto 12) & instr(20) & instr(30 downto 21) & "0";

  instr_decode : process (instr, opcode, rd, func3, func7, imm_I, imm_S, imm_B, imm_U, imm_J, rs1, rs2, reset)
  begin

    if 1 = 1 then -- reserve structure for resets or int requests
      -- Set default output signals
      out_imm <= imm_I;

      out_reg_a <= rs1;
      out_sel_a <= A_BUS_REG;
      out_zero_a <= '0';

      out_reg_b <= rs2;
      out_sel_b <= B_BUS_REG;
      out_zero_b <= '0';

      out_pc_func <= PC_JMP_REL_CND;
      out_branch_test_func <= func3;
      out_branch_test_en <= '0';

      out_jump_offset <= imm_J;
      out_branch_offset <= imm_B;

      out_alu_func <= func3;
      out_alu_neg_b <= '0';
      out_alu_arithm <= func7(5);
      out_result_src <= RES_INTERNAL;
      out_result_src_int <= RES_ALU;
      out_rdst <= "00000"; -- Write to reg zero (no effect)
      out_bus_width <= func3(1 downto 0);
      out_bus_write <= '0';
      out_bus_enable <= '0';
      out_sign_ex_width <= func3(1 downto 0);
      out_sign_ex_mode <= func3(2);

      case opcode is

        when "0110111" =>
          --- LUI : Load upper immediate value to rd ---
          out_imm <= imm_U;
          out_zero_a <= '1';
          out_sel_b <= B_BUS_IMM;
          out_alu_func <= ALU_OR;
          out_rdst <= rd;

        when "0010111" =>
          --- AUIPC : Add upper immediate value to pc and save to rd ---
          out_imm <= imm_U;
          out_sel_a <= A_BUS_PC;
          out_sel_b <= B_BUS_IMM;
          out_alu_func <= ALU_ADD;
          out_rdst <= rd;

        when "1101111" =>
          --- JAL : Jump and link (jump directly and save ra) ---
          -- offsets set as defaults
          out_result_src_int <= RES_PC_PLUS_4;
          out_pc_func <= PC_JMP_REL;
          out_rdst <= rd;

        when "1100111" =>
          --- JALR : Jump and link register (jump relative to register and save ra) ---
          if func3 = "000" then
            -- offsets set as defaults
            out_result_src <= RES_PC_PLUS_4;
            out_rdst <= rd;
            out_pc_func <= PC_JMP_REG_REL;
          end if;

        when "1100011" =>
          --- BEQ, BNE, BLT, BGE, BLTU, BGEU : Conditional branch instructions ---
          case func3 is

            when "000" | "001" | "100" | "101" | "110" | "111" =>
              out_branch_test_en <= '1';
              out_pc_func <= PC_JMP_REL_CND;

            when others => null;
              -- Undecoded for opcode 1100011

          end case;

        when "0000011" =>
          --- LB, LH, LW, LBU, LHU : Memory load instructions ---
          case func3 is

            when "000" | "001" | "010" | "100" | "101" =>
              out_bus_enable <= '1';
              out_sel_b <= B_BUS_IMM;
              out_alu_func <= ALU_ADD;
              out_rdst <= rd;
              out_result_src <= RES_MEM;

            when others => null;
              -- Undecoded for opcode 0000011

          end case;

        when "0100011" =>
          --- SB, SH, SW : Memory store instructions ---
          case func3 is

            when "000" | "001" | "010" =>
              out_bus_enable <= '1';
              out_bus_write <= '1';
              out_sel_b <= B_BUS_IMM;
              out_alu_func <= ALU_ADD;
              out_imm <= imm_S;

            when others => null;
              -- Undecoded for opcode 0100011
          end case;

        when "0010011" =>
          case func3 is
            when "000" | "010" | "011" | "100" | "110" | "111" =>
              --- ADDI, SLTI, SLTIU, XORI, ORI, ANDI ---
              out_sel_b <= B_BUS_IMM;
              out_rdst <= rd;

            when "001" =>
              --- SLLI ---
              case func7 is 
                when "0000000" =>
                  out_sel_b <= B_BUS_IMM;
                  out_rdst <= rd;

                when others => 
                  -- Undecoded for opcode 0010011
              
              end case;

            when "101" =>
              --- SRLI, SRAI ---
              case func7 is 
                when "0000000" | "0010000" =>
                  out_sel_b <= B_BUS_IMM;
                  out_rdst <= rd;
                
                when others =>
                  -- Undecoded for opcode 0010011
              end case;

            when others => null;
              -- Undecoded for opcode 0010011

          end case;

        when "0110011" =>
          case func3 is 
            when "000" =>
              --- ADD, SUB ---
              case func7 is
                when "0000000" =>
                  out_rdst <= rd;
                
                when "0100000" =>
                  out_rdst <= rd;
                  out_alu_neg_b <= '1';

                when others =>
                  -- Undecoded for opcode 0110011
              end case;

            when "001" | "010" | "011" | "100" | "110" | "111" =>
              --- SLL, SLT, SLTU, XOR, OR, AND ---
              case func7 is 
                when "0000000" =>
                  out_rdst <= rd;

                when others =>
                  -- Undecoded for opcode 0110011
              end case;

            when "101" =>
              --- SRA, SRL ---
              case func7 is 
                when "0000000" | "0100000" =>
                  out_rdst <= rd;
              
                when others =>
                  -- Undecoded for opcode 0110011
              end case;

            when others => null;
              -- Undecoded for opcode 0110011
          end case;

        when "0001111" =>
          case func3 is
            when "000" =>
              --- FENCE ---
              -- TODO
            when others => null;
              -- Undecoded for opcode 0001111

          end case;

        when "1110011" =>
          case instr(31 downto 20) is
            when x"000" =>
              if rs1 = "00000" and func3 = "000" and rd = "00000" then
                --- ECALL ---
                -- TODO
              end if;
            when x"001" =>
              if rs1 = "00000" and func3 = "000" and rd = "00000" then
                --- EBREAK ---
                -- TODO
              end if;

            when others => null;
              -- Undecoded for opcode 1110011
          end case;
        when others => null;
          -- Undecoded opcode

      end case;

      if reset = '1' then
        out_pc_func <= PC_RESET;
        out_branch_test_func <= BRANCH_TEST_TRUE;
      end if;

    end if;
  end process;
end beh;