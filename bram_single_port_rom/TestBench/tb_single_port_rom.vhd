-- TB requests output of all values from ROM from 0 to MAX

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use STD.textio.all;
use ieee.std_logic_textio.all;
USE ieee.math_real.all;

Library xpm;
use xpm.vcomponents.all;

Library UNISIM;
use UNISIM.vcomponents.all;

Library UNIMACRO;
use UNIMACRO.vcomponents.all;

library work;
use work.function_pckg.all;

entity tb_single_port_rom is
end tb_single_port_rom;


architecture sim of tb_single_port_rom is

  type t_result is array (12 downto 0) of integer;
  signal r_result : t_result := (others => 0);

  constant clk_period_ns          : time      := 10 ns;
  constant ci_tb_addr_width       : integer   := 20;
  constant ci_tb_data_width       : integer   := 16;

  signal sl_clk_in                : std_logic := '0';
  signal sl_rst_in                : std_logic := '1';

  signal sv_tb_addra_in           : std_logic_vector(ci_tb_addr_width-1 downto 0) := (others => '0');
  signal sv_tb_data_read_out      : std_logic_vector(ci_tb_data_width-1 downto 0) := (others => '0');

  signal sl_tb_dut_vld_in         : std_logic := '0';
  signal sl_tb_dut_vld_out        : std_logic := '0';

begin

  -- Clock Process
  process
  begin
    sl_clk_in  <= not(sl_clk_in);
    wait for clk_period_ns/2;
  end process;

  -- main test process
  process
    variable vi_result    : integer := 0;
  begin

    sl_tb_dut_vld_in    <= '0';
    sv_tb_addra_in      <= (others => '0');
    sl_rst_in <= '1';
    wait for 120 ns;
    sl_rst_in <= '0';

    for m in 0 to 2000 loop

      wait until (rising_edge(sl_clk_in));
      sl_tb_dut_vld_in        <= '1';
      sv_tb_addra_in <= sv_tu(m, sv_tb_addra_in'length);  -- input

      wait until (rising_edge(sl_clk_in));
      sl_tb_dut_vld_in <= '0';

      wait until (rising_edge(sl_clk_in));
      vi_result := ti_u(sv_tb_data_read_out);
    end loop;
    wait;
  end process;

  ------------------------------------------------------------------------------------------------
  -- Instance Area
  ------------------------------------------------------------------------------------------------
  xpm_memory_sprom_inst_tb : entity work.single_port_rom
  generic map (
    gi_addr_width       => ci_tb_addr_width,
    gi_width            => ci_tb_data_width
  )
  port map (
    clk_in                => sl_clk_in,
    rst_in                => sl_rst_in,

    addr_in               => sv_tb_addra_in,
    vld_in                => sl_tb_dut_vld_in,

    vld_out               => sl_tb_dut_vld_out,
    data_out              => sv_tb_data_read_out
  );

end architecture sim;





