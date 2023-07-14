library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
USE ieee.math_real.all;

Library xpm;
use xpm.vcomponents.all;

Library UNISIM;
use UNISIM.vcomponents.all;

Library UNIMACRO;
use UNIMACRO.vcomponents.all;

library work;
use work.function_pckg.all;

entity tb_sine_bram_lut is
  generic(
    gi_latency                        : integer   := 2;
    gi_width                          : integer   := 16;
    gi_addr_width                     : integer   := 20;
    gi_clk_freq                       : integer   := 100000000;
    gi_saw_freq                       : integer   := 200;
    gi_triangle_freq                  : integer   := 500;
    gi_amount_of_addresses            : integer   := 4096;
    gi_memory_size                    : integer   := gi_amount_of_addresses * gi_width;
    gi_clk_period_ns                  : time      := 10 ns;
    gi_data_in_signed                 : std_logic := '0'
  );
end tb_sine_bram_lut;

architecture behave of tb_sine_bram_lut is

  -- this module
  signal sl_clk_in                    : std_logic := '0';
  signal sl_rst_in                    : std_logic := '0';
  --
  signal sl_tb_dut_vld_in             : std_logic := '0';
  signal sl_tb_dut_vld_out            : std_logic := '0';
  --
  signal sv_tb_data_out               : std_logic;
  signal sv_tb_data_out2              : std_logic;

  -- sawtooth
  signal sl_sclr_in                   : std_logic;
  signal sl_saw_reg_mem_vld_in        : std_logic;
  signal sl_saw_reg_mem_trig_in       : std_logic;
  signal sl_saw_reg_mem_rdy_out       : std_logic;
  signal sv_saw_reg_mem_addr_in       : std_logic_vector(8-1 downto 0);
  signal sv_saw_reg_mem_data_in       : std_logic_vector(32-1 downto 0);
  signal sv_saw_reg_mem_data_out      : std_logic_vector(32-1 downto 0);
  signal sv_saw_data_out              : std_logic_vector(gi_width-1 downto 0);

  -- sine bram
  signal sl_sine_vld_in               : std_logic;
  signal sl_sine_rdy_out              : std_logic;
  signal sl_sine_vld_out              : std_logic;
  signal sv_sine_data_in              : std_logic_vector(gi_width-1 downto 0);
  signal sv_sine_data_out             : std_logic_vector(gi_width-1 downto 0);

  -- PWM for BRAM signals
  signal sl_bram_pwm_reg_mem_vld_in   : std_logic;
  signal sl_bram_pwm_reg_mem_trig_in  : std_logic;
  signal sl_bram_pwm_reg_mem_rdy_out  : std_logic;
  signal sv_bram_pwm_reg_mem_addr_in  : std_logic_vector(8-1 downto 0);
  signal sv_bram_pwm_reg_mem_data_in  : std_logic_vector(32-1 downto 0);
  signal sv_bram_pwm_reg_mem_data_out : std_logic_vector(32-1 downto 0);
  -- Forward Input Interface
  signal sl_bram_pwm_vld_in           : std_logic;
  signal sl_bram_pwm_rdy_out          : std_logic;
  signal sv_bram_pwm_data_in          : std_logic_vector(gi_width-1 downto 0);
  -- Backward Output Interface
  signal sl_bram_pwm_vld_out          : std_logic;
  signal sl_bram_pwm_data_g01_out     : std_logic;


begin
---------------- Wiring area begin --------------------------

  sl_sclr_in                <= '0';

  -- saw tooth to sine
  sl_sine_vld_in            <= '1';
  sv_sine_data_in           <= sv_saw_data_out;

  -- bram_sine to bram_pwm
  sl_bram_pwm_vld_in        <= sl_sine_vld_out;
  sv_bram_pwm_data_in       <= sv_sine_data_out;

  -- bram_pwm to master output
  sv_tb_data_out            <= sl_bram_pwm_data_g01_out;


  -- Clock Process
  process
  begin
    sl_clk_in  <= not(sl_clk_in);
    wait for gi_clk_period_ns/2;
  end process;

  -- main process
  process
  begin
    sl_tb_dut_vld_in <= '0';
    sl_rst_in <= '1';
    wait for 120 ns;
    sl_rst_in <= '0';
    wait;
  end process;

----------------- instance area begin --------------------------

  tb_saw_tooth_gen_inst: entity work.saw_tooth_gen
  generic map(
    G_LATENCY   => gi_latency,
    G_WIDTH     => gi_width,
    G_SIGNED    => gi_data_in_signed,
    G_CLK_FREQ  => gi_clk_freq,
    G_FREQ      => gi_saw_freq,
    G_PHASE     => 1.0
  )
  port map(
    -- Common Interface
    clk_in                => sl_clk_in,
    rst_in                => sl_rst_in,
    sclr_in               => sl_sclr_in,
    -- parameter input
    reg_mem_vld_in        => sl_saw_reg_mem_vld_in,
    reg_mem_trig_in       => sl_saw_reg_mem_trig_in,
    reg_mem_rdy_out       => sl_saw_reg_mem_rdy_out,
    reg_mem_addr_in       => sv_saw_reg_mem_addr_in,
    reg_mem_data_in       => sv_saw_reg_mem_data_in,
    reg_mem_data_out      => sv_saw_reg_mem_data_out,
    -- Backward Output Interface
    data_out              => sv_saw_data_out
  );


  tb_sine_bram_inst: entity work.sine_bram_lut
  generic map (
    gi_latency            => gi_latency,
    gi_addr_width         => gi_addr_width,
    gi_width              => gi_width
  )
  port map (
    clk_in                => sl_clk_in,
    rst_in                => sl_rst_in,
    vld_in                => sl_sine_vld_in,
    rdy_out               => sl_sine_rdy_out,
    vld_out               => sl_sine_vld_out,
    data_in               => sv_sine_data_in,
    data_out              => sv_sine_data_out
  );

  tb_pwm_gen_full_bridge_for_bram_inst: entity work.pwm_gen_full_bridge
  generic map(
    G_LATENCY             => gi_latency,
    G_WIDTH               => gi_width,
    G_CLK_FREQ            => gi_clk_freq,
    G_TRIANGLE_FREQ       => gi_triangle_freq,
    G_TRIANGLE_PHASE      => 1.0
  )
  port map(
    -- Common Interface
    clk_in                => sl_clk_in,
    rst_in                => sl_rst_in,
    -- parameter input
    reg_mem_vld_in        => sl_bram_pwm_reg_mem_vld_in,
    reg_mem_trig_in       => sl_bram_pwm_reg_mem_trig_in,
    reg_mem_rdy_out       => sl_bram_pwm_reg_mem_rdy_out,
    reg_mem_addr_in       => sv_bram_pwm_reg_mem_addr_in,
    reg_mem_data_in       => sv_bram_pwm_reg_mem_data_in,
    reg_mem_data_out      => sv_bram_pwm_reg_mem_data_out,
    -- Forward Input Interface
    vld_in                => sl_bram_pwm_vld_in,
    rdy_out               => sl_bram_pwm_rdy_out,
    data_in               => sv_bram_pwm_data_in,
    -- Backward Output Interface
    vld_out               => sl_bram_pwm_vld_out,
    data_g02_out          => open,
    data_g01_out          => sl_bram_pwm_data_g01_out,
    data_g03_out          => open,
    data_g04_out          => open
  );

end architecture behave;