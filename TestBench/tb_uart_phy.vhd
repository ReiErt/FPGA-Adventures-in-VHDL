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

  --  signal sl_fifo_vld_in               : std_logic;
  --  signal sl_fifo_rdy_out              : std_logic;
  --  signal sv_fifo_data_in              : std_logic_vector(gi_num_data_bits-1 downto 0);
  --  signal sv_fifo_data_out             : std_logic_vector(gi_num_data_bits-1 downto 0);
  --  signal sl_fifo_vld_out              : std_logic;
  --  signal sl_fifo_rdy_in               : std_logic;
  --  signal sl_fifo_prog_full_out        : std_logic;
begin

--  -- rx -> fifo
--  sl_fifo_vld_in      <= sl_tb_vld_out when (sl_fifo_rdy_out = '1') else '0';
--  sv_fifo_data_in     <= sl_tb_data_out;
--
--  -- fifo -> tx
--  sl_tb_vld_in        <= sl_fifo_vld_out when (sl_tb_rdy_out = '1') else '0';
--  sl_fifo_rdy_in      <= sl_tb_rdy_out;
--  sv_tb_data_in       <= sv_fifo_data_out;

 -- --------------------------------- originally - made iwth mathias
 --  -- rx -> fifo
 -- sl_fifo_vld_in      <= sl_phy_rx_vld_out when (sl_fifo_rdy_out = '1') else '0';
 -- sv_fifo_data_in     <= sv_phy_rx_data_out;
 --
 -- -- fifo -> tx
 -- sl_phy_tx_vld_in    <= sl_fifo_vld_out when (sl_phy_tx_rdy_out = '1') else '0';
 -- sl_fifo_rdy_in      <= sl_phy_tx_rdy_out;
 -- sv_phy_tx_data_in   <= sv_fifo_data_out;
 --  --------------------------------- originally - made iwth mathias

  -- Wiring Area
  --sl_tb_vld_in       <= sl_tb_vld_out;
  sv_tb_data_in      <= std_logic_vector(su_cnt);
  sl_tb_uart_rx_in   <= sl_tb_uart_tx_out;

  -- Clock Process
  process
  begin
    sl_clk_in <= not(sl_clk_in);
    wait for clk_period_ns/2;
  end process;

--  process
--  begin
--    sl_rst_in <= '1';
--    wait until (rising_edge(sl_clk_in));
--    sl_rst_in <= '0';
--    wait until (rising_edge(sl_clk_in));
--    sl_tb_vld_in <= '1';
--    wait;
--  end process;

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



 --     -- a begin to count at 32 and end at 127
 --     --su_cnt            <= x"21";
 --     su_cnt            <= x"61";
 --     su_start_cnt      <= (others => '0');
 --     sl_start_flag     <= '0';
 --   elsif (rising_edge(sl_clk_in)) then
 --     --if (su_start_cnt < 50000000) then
 --     if (su_start_cnt < 10000) then
 --       su_start_cnt    <= su_start_cnt + 1;
 --       sl_start_flag   <= '0';
 --       --su_cnt          <= x"21";
 --       su_cnt          <= x"61";
 --     else
 --       sl_start_flag   <= '1';
 --       if (su_cnt = x"7E") then
 --         su_start_cnt  <= (others => '0');
 --       else
 --         if (sl_tb_rdy_out = '1') then
 --           su_cnt        <= su_cnt + 1;
 --         end if;
 --       end if;
 --     end if;
 --   end if;
 -- end process;


--  -- Instance Area
--  insert_counter :
--  process (sl_clk_in, sl_rst_in)
--  begin
--    if (sl_rst_in = '1') then
--      -- a begin to count at 32 and end at 127
--      --su_cnt            <= x"21";
--      su_cnt            <= x"61";
--      su_start_cnt      <= (others => '0');
--      sl_start_flag     <= '0';
--    elsif (rising_edge(sl_clk_in)) then
--      --if (su_start_cnt < 50000000) then
--      if (su_start_cnt < 10000) then
--        su_start_cnt    <= su_start_cnt + 1;
--        sl_start_flag   <= '0';
--        --su_cnt          <= x"21";
--        su_cnt          <= x"61";
--      else
--        sl_start_flag   <= '1';
--        if (su_cnt = x"7E") then
--          su_start_cnt  <= (others => '0');
--        else
--          if (sl_tb_rdy_out = '1') then
--            su_cnt        <= su_cnt + 1;
--          end if;
--        end if;
--      end if;
--    end if;
--  end process;

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

--  fifo_inst: entity work.fifo
--  generic map(
--    gn_ram_width          =>   gi_num_data_bits,
--    gn_ram_depth          =>   10,
--    gn_prog_full          =>    2
--  )
--  port map(
--    clk_in                => sl_clk_in,
--    rst_in                => sl_rst_in,
--    -- Write port
--    vld_in                => sl_fifo_vld_in,
--    rdy_out               => sl_fifo_rdy_out,
--    data_in               => sv_fifo_data_in,
--    -- Read port
--    vld_out               => sl_fifo_vld_out,
--    rdy_in                => sl_fifo_rdy_in,
--    data_out              => sv_fifo_data_out,
--    -- status
--    prog_full_out         => sl_fifo_prog_full_out
--  );

end architecture behave;