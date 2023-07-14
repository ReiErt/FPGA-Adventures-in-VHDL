 -- -----------------------------------------------------------------------------------------------
--  Title      : sine_bram_lut
--  Project    : Library
--  File       : sine_bram_lut.vhd
-- -----------------------------------------------------------------------------------------------

-- -----------------------------------------------------------------------------------------------
-- Description: Module takes value A from range X and maps to value B in range Y.
-- In other words, this module takes an incoming 1Q15 value and maps that value to an address in block memory.
-- The mapping formula is the constant ci_affine_transformation:
-- input range in module is fix at 1Q15 or [-32768 to 32767]. Output range is [0 to 2048] or [0 to 4096], etc. Depends on how many block rams being used.
-- input amount of block ram to be used in gi_amount_of_32Kb_rams

-- -----------------------------------------------------------------------------------------------

  -- sine wave:
--     Q1 | Q2 | Q3 | Q4
--    "10"|"11"|"00"|"01"
--        |    |  ----
--        |    | -  | -
--        |    |-   |  -
--  ------|---------|------
--    -   |  - |    |
--     -  | -  |    |
--      ----   |    |
--        |    |    |
-- Our block memory stores values for sine wave from 0 to pi/2.
-- For x values outside of 0 to pi/2, combinational logic calculates the value.
-- Output is the amplitude of a sine wave.


library ieee;
use ieee.std_logic_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use ieee.numeric_std.all;


Library UNISIM;
use UNISIM.vcomponents.all;

Library UNIMACRO;
use UNIMACRO.vcomponents.all;

Library xpm;
use xpm.vcomponents.all;

library work;
use work.function_pckg.all;

entity sine_bram_lut is
  generic(
    gi_width                  : integer range 1 to 32 := 16;
    gi_addr_width             : integer range 1 to 20 := 20;
    gi_latency                : integer               := 2;

      -- input how many address of size gi_width to store in RAM
    gi_amount_of_addresses    : integer := 4096;
      -- creates exactly 2 block rams when gi_width = 16
    gi_memory_size            : integer := gi_amount_of_addresses * gi_width;
      -- "none" for no memory initilization. For more information, see single_port_rom.vhd
    gs_memory_init_file       : string  := "my_init_sinewave_modelsim.mem";
      -- "0" for no memory initialization via this parameter. "AB,CD,EF,1,2,34,56,78" for memory initialization.
    gs_memory_init_param      : string  := "0";
      -- "ASYNC" for asynchronous reset. "SYNC" for synchronous reset
    gs_rst_mode_a             : string  := "ASYNC"
  );
  port (
    clk_in            : in   std_logic;
    rst_in            : in   std_logic;
    vld_in            : in   std_logic;
    rdy_out           : out  std_logic;
    data_in           : in   std_logic_vector (gi_width-1 downto 0);

    vld_out           : out  std_logic;
    data_out          : out  std_logic_vector (gi_width-1 downto 0)
  );
end sine_bram_lut;

architecture rtl of sine_bram_lut is

  ------------------------------------------------------------------------------------------------
  -- Constant Area
  ------------------------------------------------------------------------------------------------

  constant ci_32_bit_bus            : integer := 32;

  -- vector of 0s
  constant cv_empty_vector          : std_logic_vector(gi_width-1 downto 0) := (others => '0');

  -- cache value until it leaves module. Data takes roughly 12 clock cycles from input to output
  constant ci_cycles_to_calculate   : integer := 12;

  -- the amount of bits a RAMB36E1 block ram
  constant ci_bits_in_RAMB36E1_ram  : integer := 32768;

-- ci_affine_transformation   :=  (x - input_range_mini) * (output_range_maximum) / (input_range_maximum - input_range_minimum) + output_range_minimum
    -- the above line simplifies to x * 0b0.0010000000000000001 => x * 0b0010000000000000001 * 2^-19
    -- => x * 0b0010000000000 * 2^-12 => 1024(10er System) * 2^-12(2er System) (assuming the use of 2 block rams)

  -- this constant maps an input within the range -32768 to 32767 to another value in the range 0 to gi_amount_of_addresses
  constant ci_affine_transformation : integer := 512;

  ------------------------------------------------------------------------------------------------
  -- function area
  ------------------------------------------------------------------------------------------------
  -- Calculates the needed amount of block rams depending on how many address
  function ram_block_size (
    amount_save_addresses   : integer;
    size                    : integer)
    return integer is
    variable vi_result      : integer;
    constant ci_total_bits  : integer := amount_save_addresses * size;
  begin
    if (ci_total_bits mod ci_bits_in_RAMB36E1_ram /= 0) then
      vi_result := ((ci_total_bits / ci_bits_in_RAMB36E1_ram) + 1) * ci_affine_transformation;
    elsif (ci_total_bits mod ci_bits_in_RAMB36E1_ram = 0) then
      vi_result := (ci_total_bits / ci_bits_in_RAMB36E1_ram) * ci_affine_transformation;
    else
      vi_result := 0;
    end if;
    return vi_result;
  end function;

  -----------------------------------------------------------------------------------------------
  -- signals & constants
  -----------------------------------------------------------------------------------------------

  -- calculated mapping constant for given number of block rams
  constant ci_final_size            : integer := ram_block_size(gi_amount_of_addresses, gi_width);

  -- this module
  signal sl_sine_vld_in             : std_logic;
  signal sv_sine_data_in            : std_logic_vector(gi_width-1 downto 0);
  signal sl_sine_vld_out            : std_logic;
  signal sl_sine_rdy_out            : std_logic;
  signal sv_sine_data_out           : std_logic_vector(gi_width-1 downto 0);
  signal sv_shift_reg               : std_logic_vector(ci_cycles_to_calculate-1 downto 0);
  signal sl_negate_flag             : std_logic;

  -- block ram
  signal sl_rom_vld_in              : std_logic;
  signal sl_rom_rdy_out             : std_logic;
  signal sv_rom_addr_in             : std_logic_vector(gi_addr_width-1 downto 0);
  signal sl_rom_vld_out             : std_logic;
  signal sv_rom_data_out            : std_logic_vector(gi_width-1 downto 0);
  signal sl_ena                     : std_logic;

  -- add/sub
  signal sl_addsub_vld_in           : std_logic;
  signal sv_addsub_data_A_in        : std_logic_vector(gi_width-1 downto 0);
  signal sv_addsub_data_B_in        : std_logic_vector(gi_width-1 downto 0);
  signal sl_addsub_vld_out          : std_logic;
  signal sv_addsub_data_out         : std_logic_vector(gi_width downto 0);
  signal sl_addsub_add_sub          : std_logic;

  -- round for addsub
  signal sl_trunc_addsub_vld_in     : std_logic;
  signal sl_trunc_addsub_rdy_out    : std_logic;
  signal sv_trunc_addsub_data_in    : std_logic_vector(gi_width downto 0);
  signal sl_trunc_addsub_vld_out    : std_logic;
  signal sv_trunc_addsub_data_out   : std_logic_vector(gi_width-1 downto 0);

  -- multiply
  signal sl_mult_vld_in             : std_logic;
  signal sl_mult_rdy_out            : std_logic;
  signal sv_mult_data_A_in          : std_logic_vector(gi_width-1 downto 0);
  signal sv_mult_data_B_in          : std_logic_vector(gi_width-1 downto 0);
  signal sl_mult_vld_out            : std_logic;
  signal sv_mult_data_out           : std_logic_vector(ci_32_bit_bus-1 downto 0);

  -- round for multi
  signal sl_trunc_mult_vld_in       : std_logic;
  signal sl_trunc_mult_rdy_out      : std_logic;
  signal sv_trunc_mult_data_in      : std_logic_vector(ci_32_bit_bus-1 downto 0);
  signal sl_trunc_mult_vld_out      : std_logic;
  signal sv_trunc_mult_data_out     : std_logic_vector(gi_addr_width-1 downto 0);


begin
  ----------------------------------------------------------------------------------------------
  -- wiring area
  ------------------------------------------------------------------------------------------------
  sv_sine_data_in         <= data_in;
  data_out                <= sv_sine_data_out;
  rdy_out                 <= sl_sine_rdy_out;

  sl_sine_vld_in          <= vld_in;
  sl_addsub_vld_in        <= sl_sine_vld_in;
  sl_trunc_addsub_vld_in  <= sl_addsub_vld_out;
  sl_mult_vld_in          <= sl_trunc_addsub_vld_out;
  sl_trunc_mult_vld_in    <= sl_mult_vld_out;
  sl_rom_vld_in           <= sl_trunc_mult_vld_out;
  vld_out                 <= sl_sine_vld_out;

 --------------------------- Addition Start --------------------------------

  -- two 1Q15 numbers go in. One 2Q15 number comes out
  sv_addsub_data_A_in    <=   std_logic_vector(to_signed(((2**gi_width)-2), sv_addsub_data_B_in'length))  when (sv_sine_data_in(sv_sine_data_in'high downto sv_sine_data_in'high-1) = "10") else
                              (others => '0')                                                             when (sv_sine_data_in(sv_sine_data_in'high downto sv_sine_data_in'high-1) = "11") else
                              (others => '0')                                                             when (sv_sine_data_in(sv_sine_data_in'high downto sv_sine_data_in'high-1) = "00") else
                              std_logic_vector(to_signed(((2**gi_width)-2), sv_addsub_data_B_in'length))  when (sv_sine_data_in(sv_sine_data_in'high downto sv_sine_data_in'high-1) = "01");

  sv_addsub_data_B_in    <=  sv_sine_data_in;

  -- 1 = addition. 0 = subtraction
  sl_addsub_add_sub      <=  '1' when (sv_sine_data_in(sv_sine_data_in'high downto sv_sine_data_in'high-1) = "10") else
                             '1' when (sv_sine_data_in(sv_sine_data_in'high downto sv_sine_data_in'high-1) = "00") else
                             '1' when (sv_sine_data_in(sv_sine_data_in'high downto sv_sine_data_in'high-1) = "11") else
                             '0' when (sv_sine_data_in(sv_sine_data_in'high downto sv_sine_data_in'high-1) = "01");

   --------------------------- Addition End --------------------------------

  -- Truncate from 2Q15 to 1Q15
  sv_trunc_addsub_data_in <= sv_addsub_data_out;

  ----------------------- Multiplication Start ---------------------------


  -- Negate data when begins with "11"
  sv_mult_data_A_in     <=      sv_trunc_addsub_data_out       when sv_trunc_addsub_data_out(sv_trunc_addsub_data_out'high downto sv_trunc_addsub_data_out'high-1) = "10" else
                            -- sinewave special case to stop sudden spikes in sine wave
                            not(sv_trunc_addsub_data_out)      when sv_trunc_addsub_data_out(sv_trunc_addsub_data_out'high downto sv_trunc_addsub_data_out'low)    = "11" & cv_empty_vector(cv_empty_vector'high-2 downto cv_empty_vector'low) else
                            not(sv_trunc_addsub_data_out) + 1  when sv_trunc_addsub_data_out(sv_trunc_addsub_data_out'high downto sv_trunc_addsub_data_out'high-1) = "11" else
                                sv_trunc_addsub_data_out       when sv_trunc_addsub_data_out(sv_trunc_addsub_data_out'high downto sv_trunc_addsub_data_out'high-1) = "00" else
                                sv_trunc_addsub_data_out       when sv_trunc_addsub_data_out(sv_trunc_addsub_data_out'high downto sv_trunc_addsub_data_out'high-1) = "01";

  -- convert calculated constant to std_logic_vector
  sv_mult_data_B_in     <= sv_ts(ci_final_size, sv_mult_data_B_in'length);

  ----------------------- Multiplication End ---------------------------

  -- truncation 20 bit to 32 bit
  sv_trunc_mult_data_in <= sv_mult_data_out;

  -- data becomes address and leaves for single_port_rom
  sv_rom_addr_in        <=  sv_trunc_mult_data_out;

  ------------------------------------------------------------------------------------------------
  -- process area
  ------------------------------------------------------------------------------------------------

  -- negates certain data leaving physical block memory
  shift_latency_and_negate_process :
  process(clk_in, rst_in)
  begin
    if (rst_in = '1') then
      -- reset stuff
      sv_shift_reg          <= (others => '0');
      sv_sine_data_out      <= (others => '0');
      sl_negate_flag        <= '0';
      sl_sine_rdy_out       <= '1';
      sl_sine_vld_out       <= '0';

    elsif (rising_edge(clk_in)) then

      -- the moment when input goes into block memory
      if (sl_rom_vld_in = '1') then
        sl_sine_rdy_out     <= '0';

        if (sv_sine_data_in(sv_sine_data_in'high) = '1') then
          sl_negate_flag    <= '1';
        else
          sl_negate_flag    <= '0';
        end if;
      else
        sl_negate_flag      <= '0';
      end if;

      -- bit shift register used to remember to negate numbers from Q1 and Q2
      sv_shift_reg          <= sv_shift_reg(sv_shift_reg'high-1 downto 0) & sl_negate_flag;

      -- at the moment BRAM outputs the value
      if(sl_rom_vld_out = '1') then
        sl_sine_vld_out     <= '1';
        sl_sine_rdy_out     <= '1';

        -- if '1' at end of pipeline, negate output
        if (sv_shift_reg(sv_shift_reg'high) = '1') then
          sv_sine_data_out  <= not(sv_rom_data_out) + 1;
        else
          sv_sine_data_out  <= sv_rom_data_out;
        end if;
      else
        sl_sine_vld_out     <= '0';
      end if;
    end if;
  end process;

  --------------------------------------------------------------------------
  -- instance area
  -------------------------------------------------------------------------

  -- 1Q15 to 2Q15
  addsub_sign_inst_1 : entity work.addsub_sign
  generic map (
    G_LATENCY           => gi_latency,
    G_WIDTH             => gi_width
  )
  port map (
    clk_in              => clk_in,
    rst_in              => rst_in,
    add_sub_in          => sl_addsub_add_sub,
    carry_in            => '0',
    carry_out           => open,
    vld_in              => sl_addsub_vld_in,
    data_A_in           => sv_addsub_data_A_in,
    data_B_in           => sv_addsub_data_B_in,
    vld_out             => sl_addsub_vld_out,
    data_out            => sv_addsub_data_out
  );

  -- truncate 2Q15 to 1Q15
  round_addsub_inst : entity work.round
  generic map(
    G_RND_OPT           => "trunc",
    G_INT_WIDTH_IN      => 2,
    G_FRAC_WIDTH_IN     => gi_width-1,
    G_INT_WIDTH_OUT     => 1,
    G_FRAC_WIDTH_OUT    => gi_width-1
  )
  port map (
    clk_in              => clk_in,
    rst_in              => rst_in,
    vld_in              => sl_trunc_addsub_vld_in,
    rdy_out             => sl_trunc_addsub_rdy_out,
    data_in             => sv_trunc_addsub_data_in,
    vld_out             => sl_trunc_addsub_vld_out,
    data_out            => sv_trunc_addsub_data_out,
    err_out  => open
  );

  -- multiply 1Q15 to 2Q30
  mult_sign_v1_inst : entity work.mult_sign_v1
  generic map (
    G_LATENCY           => gi_latency,
    G_WIDTH_A           => gi_width,
    G_WIDTH_B           => gi_width
  )
  port map (
    clk_in              => clk_in,
    rst_in              => rst_in,
    vld_in              => sl_mult_vld_in,
    rdy_out             => sl_mult_rdy_out,
    data_A_in           => sv_mult_data_A_in,
    data_B_in           => sv_mult_data_B_in,
    vld_out             => sl_mult_vld_out,
    data_out            => sv_mult_data_out
  );

  -- truncate 32 to 20 bit
  round_mult_inst : entity work.round
  generic map(
    G_RND_OPT           => "trunc",
    G_INT_WIDTH_IN      => 2,
    G_FRAC_WIDTH_IN     => (gi_width-1)*2,
    G_INT_WIDTH_OUT     => 2,
    G_FRAC_WIDTH_OUT    => gi_addr_width-2
  )
  port map (
    clk_in              => clk_in,
    rst_in              => rst_in,
    vld_in              => sl_trunc_mult_vld_in,
    rdy_out             => sl_trunc_mult_rdy_out,
    data_in             => sv_trunc_mult_data_in,
    vld_out             => sl_trunc_mult_vld_out,
    data_out            => sv_trunc_mult_data_out,
    err_out             => open
  );

  sine_bram_lut_inst : entity work.single_port_rom
  generic map (
    gi_addr_width 	    => gi_addr_width,
    gi_latency          => gi_latency,
    gi_width            => gi_width,
    gi_memory_size      => gi_memory_size,
    gs_rst_mode_a       => gs_rst_mode_a,
    gs_memory_init_file => gs_memory_init_file
  )
  port map (
    clk_in              => clk_in,
    rst_in              => rst_in,
    vld_in              => sl_rom_vld_in,
    rdy_out             => sl_rom_rdy_out,
    addr_in             => sv_rom_addr_in,
    vld_out             => sl_rom_vld_out,
    data_out            => sv_rom_data_out
  );
end rtl;