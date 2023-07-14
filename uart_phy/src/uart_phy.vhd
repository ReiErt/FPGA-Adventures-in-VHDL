-- -----------------------------------------------------------------------------------------------
--  Title      : UART Receiver and Transmitter
--  Project    : Library
--  File       : uart_phy.vhd
-- -----------------------------------------------------------------------------------------------

-- -----------------------------------------------------------------------------------------------
-- Description:
-- -----------------------------------------------------------------------------------------------
-- This file contains an instanziation of UART Receier and UART Transmitter.
-- There are three interfaces: (1) FPGA tx phy, (2) FPGA rx phy and (3) UART interfance
-- Change baud rate, number of data bits, parity on/off, type of parity, clock speed and number of stop bits via generics.


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


entity uart_phy is
  generic(
    gi_baud_rate            : integer range 9600 to 1500000   := 9600;
    gi_num_data_bits        : integer range 5 to 9            := 8;
    gi_num_parity_bits      : integer range 0 to 1            := 1;
    -- options are "none, even, odd, mark, space
    gi_parity_type          : string                          := "even";
    gi_clk_freq             : integer range 10 to 500000000   := 100000000;
    gi_num_stop_bits        : integer range 1 to 2            := 1
  );
  port(
    -- Common Interface
    clk_in                  : in  std_logic;
    rst_in                  : in  std_logic;
    -- fpga interface
    vld_in                  : in std_logic;
    rdy_out                 : out std_logic;
    data_in                 : in std_logic_vector(gi_num_data_bits-1 downto 0);
--    -- uart rx phy
    vld_out                 : out std_logic;
    data_out                : out std_logic_vector(gi_num_data_bits-1 downto 0);
    err_out                 : out std_logic;
    -- UART interface
    uart_tx_out             : out std_logic;
    uart_rx_in              : in std_logic
  );
end entity uart_phy;

architecture rtl of uart_phy is

  ------------------------------------------------------------------------------------------------
  -- Signal Area
  ------------------------------------------------------------------------------------------------

  signal sl_phy_rx_vld_out              : std_logic;
  signal sv_phy_rx_data_out             : std_logic_vector(gi_num_data_bits-1 downto 0);
  signal sl_phy_rx_err_out              : std_logic;
  signal sl_phy_rx_data_in              : std_logic;
  --
  signal sl_phy_tx_vld_in               : std_logic;
  signal sl_phy_tx_rdy_out              : std_logic;
  signal sv_phy_tx_data_in              : std_logic_vector(gi_num_data_bits-1 downto 0);
  signal sl_phy_tx_data_out             : std_logic;

  signal sv_cnt                         : std_logic_vector(gi_num_data_bits-1 downto 0);

begin
  ------------------------------------------------------------------------------------------------
  -- Wiring Area
  ------------------------------------------------------------------------------------------------

--  -- RX - data comes in as single bit
  sl_phy_rx_data_in   <= uart_rx_in;
--  -- RX - data goes out as 8 bit
  data_out            <= sv_phy_rx_data_out;
  vld_out             <= sl_phy_rx_vld_out;
  err_out             <= sl_phy_rx_err_out;

  -- TX - data goes in as 8 bit
  sv_phy_tx_data_in   <= data_in;
  -- TX - data comes out as single bit
  uart_tx_out         <= sl_phy_tx_data_out;
  sl_phy_tx_vld_in    <= vld_in;
  rdy_out             <= sl_phy_tx_rdy_out;

  ------------------------------------------------------------------------------------------------
  -- Generate Area
  ------------------------------------------------------------------------------------------------


  -----------------------------------------------------------------------------------------------
  -- Process Area
  ------------------------------------------------------------------------------------------------



  ------------------------------------------------------------------------------------------------
  -- Instance Area
  ------------------------------------------------------------------------------------------------

  uart_tx_inst : entity work.uart_tx
  generic map(
    gi_baud_rate          => gi_baud_rate,
    gi_num_data_bits      => gi_num_data_bits,
    gi_num_parity_bits    => gi_num_parity_bits,
    gi_parity_type        => gi_parity_type,
    gi_clk_freq           => gi_clk_freq,
    gi_num_stop_bits      => gi_num_stop_bits
   )
   port map (
    clk_in                => clk_in,
    rst_in                => rst_in,
    --
    vld_in                => sl_phy_tx_vld_in,
    rdy_out               => sl_phy_tx_rdy_out,
    data_in               => sv_phy_tx_data_in,
    --
    uart_tx_out           => sl_phy_tx_data_out
  );

  uart_rx_inst : entity work.uart_rx
  generic map(
    gi_baud_rate              => gi_baud_rate,
    gi_num_data_bits          => gi_num_data_bits,
    gi_num_parity_bits        => gi_num_parity_bits,
    gi_parity_type            => gi_parity_type,
    gi_clk_freq               => gi_clk_freq,
    gi_num_stop_bits          => gi_num_stop_bits
   )
   port map (
    clk_in                => clk_in,
    rst_in                => rst_in,
    --
    vld_out               => sl_phy_rx_vld_out,
    data_out              => sv_phy_rx_data_out,
    err_out               => sl_phy_rx_err_out,
    --
    uart_rx_in            => sl_phy_rx_data_in
  );

end architecture rtl;