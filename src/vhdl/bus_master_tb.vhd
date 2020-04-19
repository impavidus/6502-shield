library ieee;
use ieee.std_logic_1164.all;

library machxo2;
use machxo2.all;

entity bus_master_tb is
end bus_master_tb;

architecture tb of bus_master_tb is

    constant C_EXT_PERIOD : time := 1 us; -- period of ext oscillator for simulation (1 MHz)

    type test_v is record
        clk_sel_in : std_logic;
        reset_in   : std_logic;
    end record;
    type test_va is array (natural range <>) of test_v;

    constant tests : test_va := (
		-- Test 1 - toggle global reset
	    (clk_sel_in => '0', reset_in => '0'),
        (clk_sel_in => '0', reset_in => '1'),
		
		-- Test 2 - verify clk select pin switches correctly between int and ext clock sources
        (clk_sel_in => '1', reset_in => '1'),
        (clk_sel_in => '0', reset_in => '1')
		
		-- Test 3
		-- ...
    );

    signal s_a           : std_logic_vector(15 downto 0);
    signal s_clk         : std_logic;
    signal s_clk_runhalt : std_logic;
    signal s_clk_sel     : std_logic;
    signal s_clk_step    : std_logic;
    signal s_dma         : std_logic;
    signal s_eeprom_pgm  : std_logic;
    signal s_ext_clk     : std_logic;
    signal s_reset       : std_logic;

begin

    uut : entity bus_master
        port map
        (
            a_in           => s_a,
            be_out         => open,
            clk_out        => s_clk,
            clk_runhalt_in => s_clk_runhalt,
            clk_sel_in     => s_clk_sel,
            clk_step_in    => s_clk_step,
            d_io           => open,
            dma_in         => s_dma,
            eeprom_pgm_in  => s_eeprom_pgm,
            ext_clk_in     => s_ext_clk,
            io_en_out      => open,
            irqn_io        => open,
            led_clk_out    => open,
            led_fpga_out   => open,
            led_irq_out    => open,
            led_pio_out    => open,
            led_ram_out    => open,
            led_rom_out    => open,
            led_rw_out     => open,
            oe_out         => open,
            ram_en_out     => open,
            reset_in       => s_reset,
            resetn_out     => open,
            rw_out         => open,
            rom_en_out     => open,
            we_out         => open
        );

    ext_clk : process
    begin
        s_ext_clk <= '0';
        wait for C_EXT_PERIOD / 2;
        s_ext_clk <= '1';
        wait for C_EXT_PERIOD / 2;
    end process ext_clk;

    test_harness : process
    begin
        for i in tests'range loop
            s_clk_sel <= tests(i).clk_sel_in;
            s_reset   <= tests(i).reset_in;
            wait for 10 us;
        end loop;
        wait;
    end process test_harness;

end tb;