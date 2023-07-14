-- -----------------------------------------------------------------------------------------------
--  Title      : UART Receiver and Transmitter
--  Project    : Library
--  File       : uart_phy.vhd
-- -----------------------------------------------------------------------------------------------

-- -----------------------------------------------------------------------------------------------
-- Description:
-- -----------------------------------------------------------------------------------------------
-- This file contains both UART Receiver and Transmitter.
-- Change baud rate, number of data bits, parity on/off, type of parity, clock speed and number of stop bits via generics.

-- TX Interface: receives bit vector from sender and outputs serial bits. Will only trasmit when (rdy_out and vld_in) = '1'

library ieee;
use ieee.std_logic_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use ieee.numeric_std.all;
use ieee.math_real.all;

library work;
use work.type_definitions_pckg.all;
use work.function_pckg.all;

Library UNISIM;
use UNISIM.vcomponents.all;

Library UNIMACRO;
use UNIMACRO.vcomponents.all;


entity uart_tx is
  generic(
    gi_baud_rate            : integer range 9600 to 1500000   := 115200;
    gi_num_data_bits        : integer range 5 to 9            := 8;
    gi_num_parity_bits      : integer range 0 to 1            := 1;
    -- options are "none, even, odd, mark, space
    gi_parity_type          : string                          := "even";
    --
    gi_clk_freq             : integer range 10 to 500000000   := 100000000;
    gi_num_stop_bits        : integer range 1 to 2            := 1
  );
  port(
    -- Common Interface
    clk_in                  : in  std_logic;
    rst_in                  : in  std_logic;
    --
    vld_in                  : in std_logic;
    rdy_out                 : out std_logic;
    data_in                 : in std_logic_vector(gi_num_data_bits-1 downto 0);
    --
    uart_tx_out             : out std_logic
  );
end entity uart_tx;

architecture rtl of uart_tx is

    constant ci_total_num_bits    : integer     := gi_num_data_bits + gi_num_parity_bits + gi_num_stop_bits + 1;
    constant ci_clks_per_bit      : integer     := gi_clk_freq / gi_baud_rate / ci_total_num_bits; -- 100000000 / 9600 / 10
    constant baud_rate            : integer     := gi_clk_freq / gi_baud_rate;

  ------------------------------------------------------------------------------------------------
  -- Type Area
  ------------------------------------------------------------------------------------------------

  type uart_tx_fsm is (idle, start, data, parity, stop);

  ------------------------------------------------------------------------------------------------
  -- Signal Area
  ------------------------------------------------------------------------------------------------

  signal tx_current_state           : uart_tx_fsm;
  signal tx_next_state              : uart_tx_fsm;
  --
  signal su_data_bit_cnt            : unsigned(3 downto 0);
  signal su_baud_counter            : unsigned(15 downto 0);
  --
  signal sl_tx_rdy_out              : std_logic;
  signal sv_tx_data_in              : std_logic_vector(gi_num_data_bits-1 downto 0);
  signal sl_uart_tx_out             : std_logic;
  --
  signal sl_parity_out              : std_logic;
  signal sv_data_in_reg             : std_logic_vector(gi_num_data_bits-1 downto 0);


begin
  ------------------------------------------------------------------------------------------------
  -- Wiring Area
  ------------------------------------------------------------------------------------------------

  uart_tx_out             <= sl_uart_tx_out;
  rdy_out                 <= sl_tx_rdy_out;



  ------------------------------------------------------------------------------------------------
  -- Generate Area TX
  ------------------------------------------------------------------------------------------------

    -- flip order of bits
  rx_flip_order_bits_generate :
  for i in data_in'range generate
    sv_tx_data_in(i) <= data_in(gi_num_data_bits-1-i);
  end generate;

  tx_parity_on_generate :
  if (gi_parity_type /= "none") generate

    tx_even_parity_generate :
    if (gi_parity_type = "even"   and gi_num_parity_bits = 1) generate
      sl_parity_out <= xor(sv_data_in_reg);
    end generate;

    tx_odd_parity_generate :
    if (gi_parity_type = "odd"    and gi_num_parity_bits = 1) generate
      sl_parity_out <= not(xor(sv_data_in_reg));
    end generate;

    tx_mark_parity_generate :
    if (gi_parity_type = "mark"   and gi_num_parity_bits = 1) generate
      sl_parity_out <= '1';
    end generate;

    tx_space_parity_generate :
    if (gi_parity_type = "space" and gi_num_parity_bits = 1) generate
      sl_parity_out <= '0';
    end generate;

  end generate;

  ------------------------------------------------------------------------------------------------
  -- Process Area TX
  ------------------------------------------------------------------------------------------------

  tx_state_chage_fsm :
  process (all)
  begin

    case tx_current_state is

      when idle =>
        if (vld_in = '1') then
          tx_next_state <= start;
        else
          tx_next_state <= idle;
        end if;

      when start =>
        if (to_integer(su_baud_counter) = ci_clks_per_bit-1) then
          tx_next_state <= data;
        else
          tx_next_state <= start;
        end if;

      when data =>
        if (to_integer(su_baud_counter) = ci_clks_per_bit-1) then
          if (to_integer(su_data_bit_cnt) = gi_num_data_bits-1) then
            if (gi_num_parity_bits = 1) then
              tx_next_state      <= parity;
            else
              tx_next_state      <= stop;
            end if;
          else
            tx_next_state        <= data;
          end if;
        else
          tx_next_state          <= data;
        end if;

      when parity =>
        if (to_integer(su_baud_counter) = ci_clks_per_bit-1) then
          tx_next_state          <= stop;
        else
          tx_next_state          <= parity;
        end if;

      when stop =>
        if (to_integer(su_baud_counter) = ci_clks_per_bit-1) then
          tx_next_state          <= idle;
        else
          tx_next_state          <= stop;
        end if;

      when others =>
        tx_next_state <= idle;

    end case;
  end process;

  tx_within_state :
  process (clk_in, rst_in)
  begin
    if (rst_in = '1') then
      -- reset stuff
      sl_tx_rdy_out               <= '0';
      su_baud_counter             <= (others => '0');
      su_data_bit_cnt             <= (others => '0');
      sl_uart_tx_out              <= '1';

    elsif (rising_edge(clk_in)) then

      case tx_current_state is
        when idle =>
        -- default stuff
          sl_tx_rdy_out           <= '1';
          sl_uart_tx_out          <= '1';
          if (tx_next_state = start) then
            sv_data_in_reg        <= data_in;
            su_baud_counter       <= (others => '0');
            su_data_bit_cnt       <= (others => '0');
            sl_tx_rdy_out         <= '0';
          else
          end if;

        when start =>
          sl_uart_tx_out          <= '0';
          if (tx_next_state = data) then
            su_baud_counter       <= (others => '0');
            su_data_bit_cnt       <= (others => '0');
          else
            su_baud_counter       <= su_baud_counter + 1;
          end if;

        when data =>
          --sl_uart_tx_out <= sv_tx_data_in(to_integer(unsigned(su_data_bit_cnt)));
          sl_uart_tx_out <= sv_data_in_reg(to_integer(su_data_bit_cnt));
          if (tx_next_state = parity) then
            su_baud_counter       <= (others => '0');
          elsif (tx_next_state = stop) then
            su_baud_counter       <= (others => '0');
          else
            su_baud_counter       <= su_baud_counter + 1;
            if (su_baud_counter = ci_clks_per_bit-1) then
              su_data_bit_cnt     <= su_data_bit_cnt + 1;
              su_baud_counter     <= (others => '0');
            end if;
          end if;

        when parity =>
          sl_uart_tx_out          <= sl_parity_out;
          if (tx_next_state = stop) then
            su_baud_counter       <= (others => '0');
          else
            su_baud_counter       <= su_baud_counter + 1;
          end if;

        when stop =>
          sl_uart_tx_out          <= '1';
          if (tx_next_state = idle) then
            sl_tx_rdy_out         <= '1';
            su_baud_counter       <= (others => '0');
          else
            su_baud_counter       <= su_baud_counter + 1;
          end if;

        when others =>
          sl_tx_rdy_out           <= '0';
          su_baud_counter         <= (others => '0');

      end case;
    end if;
  end process;

  tx_next_state_logic :
  process (clk_in, rst_in)
  begin
    if (rst_in = '1') then
      tx_current_state   <= idle;
    elsif (rising_edge(clk_in)) then
      tx_current_state   <= tx_next_state;
    end if;
  end process;

  ------------------------------------------------------------------------------------------------
  -- Instance Area
  ------------------------------------------------------------------------------------------------

end architecture rtl;