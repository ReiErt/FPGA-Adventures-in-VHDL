library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use STD.textio.all;
use ieee.std_logic_textio.all;
use ieee.math_real.all;

library work;
--use work.file_io_pckg.all;
use work.type_definitions_pckg.all;
use work.function_pckg.all;

entity tb_uart_phy is
  generic(
    gi_baud_rate        : integer range 9600 to 1500000   := 115200;
    gi_num_data_bits    : integer range 5 to 9            := 8;
    gi_num_parity_bits  : integer range 0 to 1            := 0;
    -- options are "none, even, odd, mark, space
    gi_parity_type      : string                          := "none";
    gi_clk_freq         : integer range 10 to 500000000   := 100000000;
    gi_num_stop_bits    : integer range 1 to 2            := 1
  );
end tb_uart_phy;

architecture behave of tb_uart_phy is

  constant clk_period_ns              : time := 10 ns;
  --
  signal sl_clk_in                    : std_logic := '0';
  signal sl_rst_in                    : std_logic := '1';
  --
  signal sl_tb_vld_in                 : std_logic;
  signal sl_tb_rdy_out                : std_logic;
  signal sv_tb_data_in                : std_logic_vector(gi_num_data_bits-1 downto 0);
  --
  signal sl_tb_vld_out                : std_logic;
  signal sl_tb_data_out               : std_logic_vector(gi_num_data_bits-1 downto 0);
  signal sl_tb_err_out                : std_logic;
  --
  signal sl_tb_uart_tx_out            : std_logic;
  signal sl_tb_uart_rx_in             : std_logic;
  --
  signal su_start_cnt                 : unsigned(32-1 downto 0);
  signal sl_start_flag                : std_logic;
  signal su_cnt                       : unsigned(gi_num_data_bits-1 downto 0);

begin

  -- Wiring Area
  sv_tb_data_in      <= std_logic_vector(su_cnt);
  sl_tb_uart_rx_in   <= sl_tb_uart_tx_out;

  -- Clock Process
  process
  begin
    sl_clk_in <= not(sl_clk_in);
    wait for clk_period_ns/2;
  end process;

  process
  begin
    sl_rst_in       <= '0';
    wait until (rising_edge(sl_clk_in));
    sl_rst_in       <= '1';
    sl_tb_vld_in    <= '0';
    su_cnt          <= (others => '0');
    -- reset everything
    wait until (rising_edge(sl_clk_in));
    sl_rst_in       <= '0';
    wait until (rising_edge(sl_clk_in));
    -- put in first value
    sl_tb_vld_in    <= '1';
    su_cnt          <= x"41";
    wait until (rising_edge(sl_clk_in));
    sl_tb_vld_in    <= '0';
    wait until (sl_tb_rdy_out <= '1');
    -- loop through 256 values
    for m in 0 to 255 loop
      sl_tb_vld_in    <= '1';
      su_cnt          <= to_unsigned(m, su_cnt'length);
      wait until (rising_edge(sl_clk_in));
      sl_tb_vld_in    <= '0';
      wait until (rising_edge(sl_clk_in));
      wait until (sl_tb_rdy_out <= '1');
    end loop;

    wait;
  end process;


-- Instance Area
  uart_phy_inst : entity work.uart_phy
  generic map(
    gi_baud_rate          => gi_baud_rate,
    gi_num_data_bits      => gi_num_data_bits,
    gi_num_parity_bits    => gi_num_parity_bits,
    gi_parity_type        => gi_parity_type,
    gi_clk_freq           => gi_clk_freq,
    gi_num_stop_bits      => gi_num_stop_bits
   )
   port map (
    clk_in                => sl_clk_in,
    rst_in                => sl_rst_in,
    -- TX Interface begin
    vld_in                => sl_tb_vld_in,
    rdy_out               => sl_tb_rdy_out,
    data_in               => sv_tb_data_in,
    --
    uart_tx_out           => sl_tb_uart_tx_out,
    -- RX
    vld_out               => sl_tb_vld_out,
    data_out              => sl_tb_data_out,
    err_out               => sl_tb_err_out,
    --
    uart_rx_in            => sl_tb_uart_rx_in
  );

end architecture behave;
