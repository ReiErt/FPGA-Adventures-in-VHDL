-- -----------------------------------------------------------------------------------------------
--  Title      : block ram as single port rom
--  Project    : Library
--  File       : single_port_rom.vhd
-- -----------------------------------------------------------------------------------------------

-- -----------------------------------------------------------------------------------------------
-- Description: Module is an XPM wrapper to instantiate block ram as single port rom on bare metal.
-- Enter following generics to use:
-- (1) amount of addressable bits for memory
-- (2) size of data stored in each address
-- (3) total bits of memory used
-- (4) name of .mem file
-- Save data in my_init.mem. See doc folder in module for more information how to create and use .mem file for modelsim or vivado.

  -- Note: a block ram (RAMB36E1) can store 32768 bit (32 Kb).
  -- Examples, how memory size creates block ram:
      --MEMORY_SIZE         => 32768,              -- one block ram is created.
      --MEMORY_SIZE         => 32769,              -- two block rams are created.
      --MEMORY_SIZE         => 65536,              -- two block rams are created.
      --MEMORY_SIZE         => 65537,              -- three block rams are created.
      --MEMORY_SIZE         => 131072,             -- four block rams are created.
      --MEMORY_SIZE         => 262144,             -- eight block rams are created.
------------------------------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use ieee.numeric_std.all;
use std.textio.all;


Library UNISIM;
use UNISIM.vcomponents.all;

Library UNIMACRO;
use UNIMACRO.vcomponents.all;

Library xpm;
use xpm.vcomponents.all;


entity single_port_rom is
  generic(

    gi_addr_width           : integer range 1 to 20   := 20;
    gi_width                : integer range 1 to 4608 := 16;

    -- Specify "none" (including quotes) for no memory initialization, or specify the name of a memory initialization file
    -- Enter only the name of the file with .mem extension, including quotes but without path (e.g. "my_file.mem").
    -- File format must be ASCII and consist of only hexadecimal values organized into the specified depth by
    -- narrowest data width generic value of the memory. See the Memory File (MEM) section for more
    -- information on the syntax. Initialization of memory happens through the file name specified only when parameter
    -- MEMORY_INIT_PARAM value is equal to "".
    -- When using XPM_MEMORY in a project, add the specified file to the Vivado project as a design source.
    gs_memory_init_file     : string := "my_init.mem";

    -- Specify "" or "0" (including quotes) for no memory initialization through parameter, or specify the string
    -- containing the hex characters. Enter only hex characters with each location separated by delimiter (,).
    -- Parameter format must be ASCII and consist of only hexadecimal values organized into the specified depth by
    -- narrowest data width generic value of the memory.For example, if the narrowest data width is 8, and the depth of
    -- memory is 8 locations, then the parameter value should be passed as shown below.
    -- parameter MEMORY_INIT_PARAM = "AB,CD,EF,1,2,34,56,78"
    -- Where "AB" is the 0th location and "78" is the 7th location.
    gs_memory_init_param    : string := "0";

    -- Specify the total memory array size, in bits.
    -- gi_memory_size = size of each data in bits * how many data entries
    gi_memory_size          : integer range 2 to 150994944 := 65536;

    -- Specify the number of register stages in the port A read data pipeline. Read data output to port douta takes this
    -- number of clka cycles.
    -- To target block memory, a value of 1 or larger is required- 1 causes use of memory latch only; 2 causes use of
    -- output register. To target distributed memory, a value of 0 or larger is required- 0 indicates combinatorial output.
    -- Values larger than 2 synthesize additional flip-flops that are not retimed into memory primitives.
    -- Default value = 2.
    gi_latency              : integer range 0 to 100 := 2;

    -- "SYNC" - when reset is applied, synchronously resets output port douta to the value specified by parameter READ_RESET_VALUE_A
    -- "ASYNC" - when reset is applied, asynchronously resets output port douta to zero
    -- Allowed values: SYNC, ASYNC. Default value = SYNC.
    gs_rst_mode_a           : string := "ASYNC"
  );

  port (
    clk_in                  : in std_logic;
    rst_in                  : in std_logic;

    vld_in                  : in std_logic;
    rdy_out                 : out std_logic;
    addr_in                 : in std_logic_vector(gi_addr_width-1 downto 0);

    vld_out                 : out std_logic;
    data_out                : out std_logic_vector(gi_width-1 downto 0)
  );
end entity single_port_rom;

architecture rtl of single_port_rom is
  -----------------------------------------------------------------------------------------------
  -- signals & constants
  -----------------------------------------------------------------------------------------------
  constant ci_shift_register_width  : integer := 2;

  -- backward facing
  signal sl_bram_vld_in           : std_logic;
  signal sl_bram_rdy_out          : std_logic;
  signal sv_addra_in_xpm          : std_logic_vector(gi_addr_width-1 downto 0);
  -- forward facing
  signal sl_bram_vld_out          : std_logic;
  signal sv_data_out_xpm          : std_logic_vector(gi_width-1 downto 0);
  --
  signal sv_shift_reg_data_out    : std_logic_vector(ci_shift_register_width-1 downto 0);
  signal sl_ena_in                : std_logic;
  signal sl_inject_dbiterra_in    : std_logic;
  signal sl_inject_sbiterra_in    : std_logic;
  signal sl_regcea_in             : std_logic;
  signal sl_sleep_in              : std_logic;

begin

  ----------------------------------------------------------------------------------------------
  -- wiring area
  ------------------------------------------------------------------------------------------------

  sl_bram_vld_in                <= vld_in;
  rdy_out                       <= sl_bram_rdy_out;
  sv_addra_in_xpm               <= addr_in;

  sl_bram_vld_out               <= sv_shift_reg_data_out(sv_shift_reg_data_out'high);
  vld_out                       <= sl_bram_vld_out;
  data_out                      <= sv_data_out_xpm;

  sl_inject_sbiterra_in         <= '0';
  sl_inject_dbiterra_in         <= '0';
  sl_regcea_in                  <= '1';
  sl_ena_in                     <= '1';
  sl_sleep_in                   <= '0';

  ------------------------------------------------------------------------------------------------
  -- process area
  ------------------------------------------------------------------------------------------------

  data_pipeline_process :
  process(clk_in, rst_in)
  begin
    if (rst_in = '1') then
      --reset stuff
      sv_shift_reg_data_out     <= (others => '0');
      sl_bram_rdy_out           <= '1';

    elsif (rising_edge(clk_in)) then
      sv_shift_reg_data_out <= sv_shift_reg_data_out(sv_shift_reg_data_out'high-1 downto 0) & vld_in;

      -- if doing no work
      if nor(sv_shift_reg_data_out) then
        sl_bram_rdy_out       <= '1';
      end if;

      -- if working
      if (vld_in = '1') then
        sl_bram_rdy_out       <= '0';
      end if;
    end if;
  end process;


  xpm_memory_sprom_inst_1 : xpm_memory_sprom
  generic map (
    ADDR_WIDTH_A 	      => gi_addr_width,
    AUTO_SLEEP_TIME 	  => 0,
    ECC_MODE 		        => "no_ecc",
    MEMORY_INIT_FILE 	  => gs_memory_init_file,
    MEMORY_INIT_PARAM   => gs_memory_init_param,
    MEMORY_OPTIMIZATION => "false",
    MEMORY_PRIMITIVE    => "block",
    MEMORY_SIZE         => gi_memory_size,
    MESSAGE_CONTROL     => 0,
    READ_DATA_WIDTH_A   => gi_width,
    READ_LATENCY_A      => gi_latency,
    READ_RESET_VALUE_A  => "0",
    RST_MODE_A          => gs_rst_mode_a,
    USE_MEM_INIT        => 1,
    WAKEUP_TIME         => "disable_sleep"
  )
  port map (
    clka            => clk_in,
    rsta            => rst_in,
    douta           => sv_data_out_xpm,
    addra           => sv_addra_in_xpm,
    ena             => sl_ena_in,
    injectdbiterra  => sl_inject_dbiterra_in,
    injectsbiterra  => sl_inject_sbiterra_in,
    regcea          => sl_regcea_in,
    sleep           => sl_sleep_in,
    -- Leave open
    dbiterra        => open,
    -- Leave open
    sbiterra        => open
  );

end rtl;