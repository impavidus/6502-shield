library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity bus_master is
    port (
        a_in          : in std_logic_vector(15 downto 0);
        be_out        : out std_logic;
        clk_out       : out std_logic;
        d_io          : inout std_logic_vector(7 downto 0);
        dma_in        : in std_logic;
        eeprom_pgm_in : in std_logic;
        ext_clk_in    : in std_logic;
        io_en_out     : out std_logic;
        irqn_out      : out std_logic;
        led_clk_out   : out std_logic;
        led_fpga_out  : out std_logic;
        led_irq_out   : out std_logic;
        led_pio_out   : out std_logic;
        led_ram_out   : out std_logic;
        led_rom_out   : out std_logic;
        led_rw_out    : out std_logic;
        oe_out        : out std_logic;
        pb_reset_in   : in std_logic;
        pb_step_in    : in std_logic;
        ram_en_out    : out std_logic;
        reset_in      : in std_logic;
        resetn_out    : out std_logic;
        rom_en_out    : out std_logic;
        rw_out        : out std_logic;
        sw_clksel_in  : in std_logic;
        sw_runhalt_in : in std_logic;
        we_out        : out std_logic
    );
end bus_master;

architecture rtl of bus_master is

    signal s_a          : std_logic_vector(15 downto 0);
    signal s_be         : std_logic;
    signal s_bclk       : std_logic;
    signal s_button_reg : std_logic_vector(3 downto 0);
    signal s_clk        : std_logic;
    signal s_clk_sel    : std_logic;
    signal s_d          : std_logic_vector(7 downto 0);
    signal s_dma        : std_logic;
    signal s_eeprom_pgm : std_logic;
    signal s_ext_clk    : std_logic;
    signal s_io_en      : std_logic;
    signal s_irqn       : std_logic;
    signal s_led_clk    : std_logic;
    signal s_led_fpga   : std_logic;
    signal s_led_irq    : std_logic;
    signal s_led_pio    : std_logic;
    signal s_led_ram    : std_logic;
    signal s_led_reg    : std_logic_vector(6 downto 0);
    signal s_led_rom    : std_logic;
    signal s_led_rw     : std_logic;
    signal s_oe         : std_logic;
    signal s_pb_reset   : std_logic;
    signal s_pb_step    : std_logic;
    signal s_ram_en     : std_logic;
    signal s_reset      : std_logic;
    signal s_resetn     : std_logic;
    signal s_rw         : std_logic;
    signal s_rom_en     : std_logic;
    signal s_sw_clksel  : std_logic;
    signal s_sw_runhalt : std_logic;
    signal s_we         : std_logic;

    component bus_activity_monitor is
        port (
            button_reg_out : out std_logic_vector(3 downto 0);
            clk_in         : in std_logic;
            led_clk_out    : out std_logic;
            led_fpga_out   : out std_logic;
            led_irq_out    : out std_logic;
            led_pio_out    : out std_logic;
            led_ram_out    : out std_logic;
            led_reg_in     : in std_logic_vector(6 downto 0);
            led_rom_out    : out std_logic;
            led_rw_out     : out std_logic;

            pb_reset_in    : in std_logic;
            pb_step_in     : in std_logic;
            sw_clksel_in   : in std_logic;
            sw_runhalt_in  : in std_logic
        );
    end component bus_activity_monitor;

    component clock_manager is
        port (
            bus_clk_out : out std_logic;
            clk_out     : out std_logic;
            clk_sel_in  : in std_logic;
            ext_clk_in  : in std_logic;
            reset_in    : in std_logic;
            runhalt_in  : in std_logic;
            step_in     : in std_logic
        );
    end component clock_manager;

begin
    bus_activity_monitor_i : bus_activity_monitor
    port map
    (
        button_reg_out => s_button_reg,
        clk_in         => s_clk,
        led_clk_out    => s_led_clk,
        led_fpga_out   => s_led_fpga,
        led_irq_out    => s_led_irq,
        led_pio_out    => s_led_pio,
        led_ram_out    => s_led_ram,
        led_reg_in     => s_led_reg,
        led_rom_out    => s_led_rom,
        led_rw_out     => s_led_rw,
        pb_reset_in    => s_pb_reset,
        pb_step_in     => s_pb_step,
        sw_clksel_in   => s_sw_clksel,
        sw_runhalt_in  => s_sw_runhalt
    );

    clock_manager_i : clock_manager
    port map
    (
        bus_clk_out => s_bclk,
        clk_out     => s_clk,
        clk_sel_in  => s_clk_sel,
        ext_clk_in  => s_ext_clk,
        reset_in    => s_pb_reset, -- raw button press, no debounce
        runhalt_in  => s_button_reg(1),
        step_in     => s_button_reg(2)
    );

    clk_out               <= s_bclk;

    led_clk_out           <= s_led_clk;
    led_fpga_out          <= s_led_fpga;
    led_irq_out           <= s_led_irq;
    led_pio_out           <= s_led_pio;
    led_ram_out           <= s_led_ram;
    led_rom_out           <= s_led_rom;
    led_rw_out            <= s_led_rw;
    resetn_out            <= s_resetn;

    s_resetn              <= s_button_reg(3);
    s_pb_reset            <= pb_reset_in;
    s_pb_step             <= pb_step_in;
    s_sw_clksel           <= sw_clksel_in;
    s_sw_runhalt          <= sw_runhalt_in;

    s_ext_clk             <= ext_clk_in;
    s_clk_sel             <= s_button_reg(0);
    s_led_reg(0)          <= not s_bclk;
    s_led_reg(6 downto 1) <= s_button_reg & "11"; -- temporary

end rtl;