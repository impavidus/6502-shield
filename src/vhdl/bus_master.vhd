library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library machxo2;
use machxo2.all;

entity bus_master is
    port (
        a_in           : in std_logic_vector(15 downto 0);
        be_out         : out std_logic;
        clk_out        : out std_logic;
        clk_runhalt_in : in std_logic;
        clk_sel_in     : in std_logic;
        clk_step_in    : in std_logic;
        d_io           : inout std_logic_vector(7 downto 0);
        dma_in         : in std_logic;
        eeprom_pgm_in  : in std_logic;
        ext_clk_in     : in std_logic;
        io_en_out      : out std_logic;
        irqn_io        : inout std_logic;
        led_clk_out    : out std_logic;
        led_fpga_out   : out std_logic;
        led_irq_out    : out std_logic;
        led_pio_out    : out std_logic;
        led_ram_out    : out std_logic;
        led_rom_out    : out std_logic;
        led_rw_out     : out std_logic;
        oe_out         : out std_logic;
        ram_en_out     : out std_logic;
        reset_in       : in std_logic;
        resetn_out     : out std_logic;
        rw_out         : out std_logic;
        rom_en_out     : out std_logic;
        we_out         : out std_logic
    );
end bus_master;

architecture rtl of bus_master is

    constant C_NOM_FREQ  : string := "2.08"; -- 2.08 MHz to 133.00 MHz +/- 5%, see Lattice TN1199 for valid step values

    signal s_a           : std_logic_vector(15 downto 0);
    signal s_be          : std_logic;
    signal s_clk         : std_logic;
    signal s_clk_runhalt : std_logic;
    signal s_clk_sel     : std_logic;
    signal s_clk_step    : std_logic;
    signal s_d           : std_logic_vector(7 downto 0);
    signal s_dma         : std_logic;
    signal s_eeprom_pgm  : std_logic;
    signal s_ext_clk     : std_logic;
    signal s_int_clk     : std_logic;
    signal s_io_en       : std_logic;
    signal s_irqn        : std_logic;
    signal s_led_clk     : std_logic;
    signal s_led_fpga    : std_logic;
    signal s_led_irq     : std_logic;
    signal s_led_pio     : std_logic;
    signal s_led_ram     : std_logic;
    signal s_led_rom     : std_logic;
    signal s_led_rw      : std_logic;
    signal s_oe          : std_logic;
    signal s_ram_en      : std_logic;
    signal s_reset       : std_logic;
    signal s_resetn      : std_logic;
    signal s_rw          : std_logic;
    signal s_rom_en      : std_logic;
    signal s_we          : std_logic;

    -- Internal oscillator
    component osch
        -- synthesis translate_off
        generic (NOM_FREQ : string := C_NOM_FREQ);
        -- synthesis translate_on
        port (
            sedstdby : out std_logic;
            stdby    : in std_logic;
            osc      : out std_logic
        );
    end component osch;
    attribute NOM_FREQ           : string;
    attribute NOM_FREQ of osch_i : label is C_NOM_FREQ;

    -- dynamic clock mux
    component dcma
        port (
            clk0   : in std_logic;
            clk1   : in std_logic;
            sel    : in std_logic;
            dcmout : out std_logic
        );
    end component dcma;

begin

    osch_i : osch
    -- synthesis translate_off
    generic map(NOM_FREQ => C_NOM_FREQ)
    -- synthesis translate_on
    port map
    (
        stdby    => '0', -- oscillator output is active
        osc      => s_int_clk,
        sedstdby => open
    );

    dcma_i : dcma
    port map
    (
        clk0   => s_int_clk,
        clk1   => s_ext_clk,
        sel    => s_clk_sel,
        dcmout => s_clk
    );

    clk_out   <= s_clk;

    s_ext_clk <= ext_clk_in;
    s_clk_sel <= clk_sel_in;

end rtl;