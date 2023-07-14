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

-- RX Interface: receives serial bits from sender and outputs bit vector. Also outputs vld_out = '1' when finished receiving

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


entity uart_rx is
  generic(
    gi_baud_rate            : integer range 9600 to 1500000   := 115200;
    gi_num_data_bits        : integer range 5 to 9            := 8;
    gi_num_parity_bits      : integer range 0 to 1            := 1;
    -- options are "none, even, odd, mark, space
    gi_parity_type          : string                          := "even";
    -- will be need for calculate sinus frequency
    gi_clk_freq             : integer range 10 to 500000000   := 100000000;
    gi_num_stop_bits        : integer range 1 to 2            := 1;
    -- debouncer
    gi_dbnc_width           : integer range 1 to 8            := 3;
    gi_dbnc_smpl_time_in_ns : integer                         := 100
  );
  port(
    -- Common Interface
    clk_in                  : in  std_logic;
    rst_in                  : in  std_logic;
    --
    vld_out                 : out std_logic;
    data_out                : out std_logic_vector(gi_num_data_bits-1 downto 0);
    err_out                 : out std_logic;
    --
    uart_rx_in              : in std_logic
  );
end entity uart_rx;

architecture rtl of uart_rx is

    constant ci_clk_period_in_ns  : integer     := integer((real(1) / real(gi_clk_freq)) * real(10**9));
    constant ci_num_start_bits    : integer     := 1;
    constant ci_total_num_of_bits : integer     := ci_num_start_bits + gi_num_data_bits + gi_num_parity_bits + gi_num_stop_bits;
    constant ci_clks_per_bit      : integer     := gi_clk_freq / gi_baud_rate / ci_total_num_of_bits;
    constant ci_clk_half          : integer     := ci_clks_per_bit / 2;
    constant ci_counter           : integer     := 16;

  ------------------------------------------------------------------------------------------------
  -- Type Area
  ------------------------------------------------------------------------------------------------

  type uart_rx_fsm is (idle, start, data, parity, stop);

  ------------------------------------------------------------------------------------------------
  -- Signal Area
  ------------------------------------------------------------------------------------------------

  -- RX signals begin
  signal rx_current_state           : uart_rx_fsm;
  signal rx_next_state              : uart_rx_fsm;
  --
  signal sv_baud_sampler            : std_logic_vector(ci_total_num_of_bits-1 downto 0);
  signal sv_rx_final_output_buffer  : std_logic_vector(gi_num_data_bits-1 downto 0);
  signal sv_baud_tick_counter       : std_logic_vector(ci_counter-1 downto 0);
  signal sv_baud_bit_cnt            : std_logic_vector(3 downto 0);
  signal sv_stop_bit_cnt            : std_logic_vector(1 downto 0);
  signal sv_rx_parity_vector        : std_logic_vector(gi_num_data_bits-1 downto 0);
  --
  signal sl_uart_rx_in              : std_logic;
  signal sl_rx_vld_out              : std_logic;
  signal sv_rx_data_out             : std_logic_vector(gi_num_data_bits-1 downto 0);
  -- parity
  signal sl_frame_error_out         : std_logic;
  signal sl_rx_parity_error_out     : std_logic;
  signal sl_rx_received_parity_bit  : std_logic;
  -- debouncer
  signal sl_rx_dbnc_data_in         : std_logic;
  signal sl_rx_dbnc_data_out        : std_logic;
  -- RX signals end

  signal sv_buffer_out              : std_logic_vector(gi_num_data_bits-1 downto 0);

begin
  ------------------------------------------------------------------------------------------------
  -- Wiring Area
  ------------------------------------------------------------------------------------------------



  -- data going in and out of debouncer
  sl_rx_dbnc_data_in      <= uart_rx_in;
  sl_uart_rx_in           <= sl_rx_dbnc_data_out;
  data_out                <= sv_rx_data_out;
  vld_out                 <= sl_rx_vld_out;
  err_out                 <= '1' when sl_frame_error_out = '1' or sl_rx_parity_error_out = '1' else '0';

  -- extract payload bits from total bit vector to check parity
  sv_rx_parity_vector     <= sv_baud_sampler(ci_total_num_of_bits-gi_num_stop_bits-gi_num_parity_bits-1 downto ci_num_start_bits);

  ------------------------------------------------------------------------------------------------
  -- Generate Area RX
  ------------------------------------------------------------------------------------------------

  -- flip order of bits
  rx_flip_order_bits_generate :
  for i in sv_rx_parity_vector'range generate
    sv_rx_final_output_buffer(i) <= sv_rx_parity_vector(gi_num_data_bits-1-i);
  end generate;

  rx_even_parity_generate  : if (gi_parity_type = "even"   and gi_num_parity_bits = 1) generate
    -- calculate parity of payload. if parity is not same as received parity bit, raise parity error.
    sl_rx_parity_error_out <= '1' when ((rx_current_state = stop) and
    ((xor(sv_baud_sampler(ci_total_num_of_bits-1-gi_num_stop_bits-gi_num_parity_bits downto 1))) /= sl_rx_received_parity_bit)) else '0';

  end generate;

  rx_odd_parity_generate   : if (gi_parity_type = "odd"     and gi_num_parity_bits = 1) generate
    -- calculate parity of own bit. if parity bit is not same as received parity bit, we have a parity error
    sl_rx_parity_error_out <= '1' when ((rx_current_state = stop) and
    ((not(xor(sv_baud_sampler(ci_total_num_of_bits-1-gi_num_stop_bits-gi_num_parity_bits downto 1)))) /= sl_rx_received_parity_bit)) else '0';
  end generate;

  rx_mark_parity_generate  : if (gi_parity_type = "mark"   and gi_num_parity_bits = 1) generate
    sl_rx_parity_error_out <= '1' when (rx_current_state = stop) and (sv_baud_sampler(1) /= '1') else '0';
  end generate;

  rx_space_parity_generate : if (gi_parity_type = "space" and gi_num_parity_bits = 1) generate
    sl_rx_parity_error_out <= '1' when (rx_current_state = stop) and (sv_baud_sampler(1) /= '0') else '0';
  end generate;

  ------------------------------------------------------------------------------------------------
  -- Process Area RX
  ------------------------------------------------------------------------------------------------

  rx_state_chage_fsm :
  process (all)
  begin

    case rx_current_state is

      when idle =>
        if (uart_rx_in = '0') then
          rx_next_state             <= start;
        else
          rx_next_state             <= idle;
        end if;

      when start =>
        if (ti_u(sv_baud_tick_counter) = ci_clks_per_bit-1) then
          rx_next_state             <= data;
        else
          rx_next_state             <= start;
        end if;

        when data =>
          if (ti_u(sv_baud_tick_counter) = ci_clks_per_bit-1) then
            if (to_integer(unsigned(sv_baud_bit_cnt)) = gi_num_data_bits) then
              if (gi_num_parity_bits = 1) then
                rx_next_state       <= parity;
              else
                rx_next_state       <= stop;
              end if;
            else
              rx_next_state         <= data;
            end if;
          else
            rx_next_state           <= data;
          end if;

        when parity =>
          if (ti_u(sv_baud_tick_counter) = ci_clks_per_bit-1) then
            rx_next_state           <= stop;
          else
            rx_next_state           <= parity;
          end if;

        when stop =>
          if (ti_u(sv_baud_tick_counter) = ci_clks_per_bit-1) then
            if (ti_u(sv_stop_bit_cnt) = gi_num_stop_bits-1) then
              rx_next_state          <= idle;
            else
              rx_next_state          <= stop;
            end if;
          else
            rx_next_state            <= stop;
          end if;

        when others =>
          rx_next_state <= idle;

    end case;
  end process;

  rx_within_state:
  process(clk_in, rst_in)
  begin
    if (rst_in = '1') then
      -- reset stuff
      sl_rx_vld_out                   <= '0';
      sl_frame_error_out              <= '0';
      sl_rx_received_parity_bit       <= '0';
      sv_stop_bit_cnt                 <= (others => '0');
      sv_baud_tick_counter            <= (others => '0');
      sv_baud_bit_cnt                 <= (others => '0');
      sv_baud_sampler                 <= (others => '0');
      sv_rx_data_out                  <= (others => '0');

    elsif (rising_edge(clk_in)) then

      case rx_current_state is

        when idle =>
          sl_rx_vld_out                   <= '0';
          sl_frame_error_out              <= '0';
          sv_stop_bit_cnt                 <= (others => '0');
          sv_baud_tick_counter            <= (others => '0');
          sv_baud_bit_cnt                 <= (others => '0');
          sv_baud_sampler                 <= (others => '0');
          if (rx_next_state = start) then
          -- stuff for 1 tick here
          else
          -- else stuff
          end if;


        when start =>
          if (ti_u(sv_baud_tick_counter) = ci_clk_half-1) then
          -- sample the middle of input bit
            sv_baud_sampler(ti_u(sv_baud_bit_cnt))    <= sl_uart_rx_in;
          end if;

          if (rx_next_state = data) then
          -- stuff for 1 tick here
            sv_baud_tick_counter          <= (others => '0');
            sv_baud_bit_cnt               <= std_logic_vector(unsigned(sv_baud_bit_cnt + '1'));
            if (sv_baud_sampler(0) /= '0') then
              sl_frame_error_out          <= '1';
            end if;

          else
            sv_baud_tick_counter          <= std_logic_vector(unsigned(sv_baud_tick_counter + '1'));
          end if;


        when data =>
          sv_baud_tick_counter            <= std_logic_vector(unsigned(sv_baud_tick_counter + '1'));
          if (rx_next_state = parity) then
          -- stuff for 1 tick here
            sv_baud_tick_counter          <= (others => '0');
            sv_baud_bit_cnt               <= std_logic_vector(unsigned(sv_baud_bit_cnt + '1'));

          elsif (rx_next_state = stop) then
            sv_baud_tick_counter          <= (others => '0');
            sv_baud_bit_cnt               <= std_logic_vector(unsigned(sv_baud_bit_cnt + '1'));

          else
            if (ti_u(sv_baud_tick_counter) = ci_clk_half-1) then
              -- sample the middle of input bit
              sv_baud_sampler(ti_u(sv_baud_bit_cnt))    <= sl_uart_rx_in;
            elsif (ti_u(sv_baud_tick_counter) = ci_clks_per_bit-1) then
              sv_baud_bit_cnt             <= std_logic_vector(unsigned(sv_baud_bit_cnt + '1'));
              sv_baud_tick_counter        <= (others => '0');
            end if;

          end if;


        when parity =>
          if (ti_u(sv_baud_tick_counter) = ci_clk_half-1) then
          -- sample the middle of input bit
            sv_baud_sampler(ti_u(sv_baud_bit_cnt))    <= sl_uart_rx_in;
            sl_rx_received_parity_bit                 <= sl_uart_rx_in;
          end if;

          if (rx_next_state = stop) then
          -- stuff for 1 tick here
            sv_baud_tick_counter          <= (others => '0');
            sv_baud_bit_cnt               <= std_logic_vector(unsigned(sv_baud_bit_cnt + '1'));

          else
            sv_baud_tick_counter          <= std_logic_vector(unsigned(sv_baud_tick_counter + '1'));
          end if;


        when stop =>
          sv_rx_data_out <= sv_rx_final_output_buffer;
          if (ti_u(sv_baud_tick_counter) = ci_clk_half-1) then
          -- sample the middle of input bit
            sv_baud_sampler(ti_u(sv_baud_bit_cnt))    <= sl_uart_rx_in;
          end if;

          if (rx_next_state = idle) then
            sv_baud_tick_counter          <= (others => '0');
            sv_baud_bit_cnt               <= (others => '0');
            sl_rx_vld_out                 <= '1';

            -- if stop bit is not '1', we have a problem
            if (sv_baud_sampler(ci_total_num_of_bits-1) /= '1') then
              sl_frame_error_out          <= '1';
            end if;

          else
            sv_baud_tick_counter          <= std_logic_vector(unsigned(sv_baud_tick_counter + '1'));
          end if;
      end case;
    end if;
  end process;

  rx_next_state_logic :
  process (clk_in, rst_in)
  begin
    if (rst_in = '1') then
      rx_current_state                  <= idle;
    elsif (rising_edge(clk_in)) then
      rx_current_state                  <= rx_next_state;
    end if;
  end process;

  ------------------------------------------------------------------------------------------------
  -- Instance Area
  ------------------------------------------------------------------------------------------------

  dbnc_inst : entity work.dbnc
  generic map(
    gi_clk_period_in_ns     => ci_clk_period_in_ns,
    gi_dbnc_width           => gi_dbnc_width,
    gi_dbnc_smpl_time_in_ns => gi_dbnc_smpl_time_in_ns
  )
  port map (
    clk_in                  => clk_in,
    rst_in                  => rst_in,
    data_in                 => sl_rx_dbnc_data_in,
    data_out                => sl_rx_dbnc_data_out
  );

end architecture rtl;