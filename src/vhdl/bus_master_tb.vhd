library ieee;
use ieee.std_logic_1164.all;

library machxo2;
use machxo2.all;

entity bus_master_tb is
end bus_master_tb;

architecture tb of bus_master_tb is

    constant C_EXT_PERIOD : time := 480.77 ns; --1 us; -- period of ext oscillator for simulation (1 MHz)

    type test_v is record
		delay			: time;
		sw_clksel_in	: std_logic;
        sw_runhalt_in 	: std_logic;
		pb_reset_in		: std_logic;
		pb_step_in		: std_logic;
    end record;
    type test_va is array (natural range <>) of test_v;

    constant tests : test_va := (
		-- Test 1 - verify clk select pin switches correctly between int and ext clock sources
        --(delay => 10us, sw_clksel_in  => '0', sw_runhalt_in => '1', pb_reset_in => '1'),
        --(delay => 10us, sw_clksel_in  => '1', sw_runhalt_in => '1', pb_reset_in => '1'),
		
		-- Test 2 - check debounce using pb_reset
		(delay => 27us, sw_clksel_in  => '1', sw_runhalt_in  => '1', pb_reset_in  => '0', pb_step_in => '1'),
		(delay => 15us, sw_clksel_in  => '1', sw_runhalt_in  => '1', pb_reset_in  => '1', pb_step_in => '1'),
		(delay => 79ms, sw_clksel_in  => '1', sw_runhalt_in  => '1', pb_reset_in  => '0', pb_step_in => '1'),
		(delay => 11us, sw_clksel_in  => '1', sw_runhalt_in  => '1', pb_reset_in  => '1', pb_step_in => '1'),
		(delay => 39us, sw_clksel_in  => '1', sw_runhalt_in  => '1', pb_reset_in  => '0', pb_step_in => '1'),
		(delay => 42us, sw_clksel_in  => '1', sw_runhalt_in  => '1', pb_reset_in  => '1', pb_step_in => '1'),
		
		-- Test 3 - clock step
		(delay => 11us,  sw_clksel_in  => '1', sw_runhalt_in  => '1', pb_reset_in  => '1', pb_step_in => '1'),
		(delay => 85ms,  sw_clksel_in  => '1', sw_runhalt_in  => '1', pb_reset_in  => '1', pb_step_in => '0'),
		(delay => 234ms,  sw_clksel_in  => '1', sw_runhalt_in  => '1', pb_reset_in  => '1', pb_step_in => '1'),
		
		-- Test 4 - clock run
		(delay => 818ms,  sw_clksel_in  => '1', sw_runhalt_in  => '0', pb_reset_in  => '1', pb_step_in => '1'),
		(delay => 50ms,  sw_clksel_in  => '1', sw_runhalt_in  => '1', pb_reset_in  => '1', pb_step_in => '1')
    );

    signal s_a           : std_logic_vector(15 downto 0)	:= (others => '0');
	signal s_bclk		 : std_logic    := '0';
	signal s_bounce		 : std_logic    := '0';
    signal s_clk         : std_logic	:= '0';
    signal s_clk_sel     : std_logic    := '0';
    signal s_clk_step    : std_logic    := '0';
    signal s_dma         : std_logic    := '0';
    signal s_eeprom_pgm  : std_logic    := '0';
    signal s_ext_clk     : std_logic    := '0';
	signal s_pb_reset    : std_logic    := '0';
	signal s_pb_step     : std_logic    := '1';
    signal s_reset       : std_logic    := '0';
	signal s_sw_clksel   : std_logic    := '0';
	signal s_sw_runhalt  : std_logic    := '0';

begin

    uut : entity bus_master
        port map
        (
            a_in           => s_a,
            be_out         => open,
            clk_out        => s_bclk,
            d_io           => open,
            dma_in         => s_dma,
            eeprom_pgm_in  => s_eeprom_pgm,
            ext_clk_in     => s_ext_clk,
            io_en_out      => open,
            irqn_out       => open,
            led_clk_out    => open,
            led_fpga_out   => open,
            led_irq_out    => open,
            led_pio_out    => open,
            led_ram_out    => open,
            led_rom_out    => open,
            led_rw_out     => open,
            oe_out         => open,
			pb_reset_in	   => s_pb_reset,
			pb_step_in     => s_pb_step,
            ram_en_out     => open,
            reset_in       => s_reset,
            resetn_out     => open,
            rw_out         => open,
            rom_en_out     => open,
			sw_clksel_in   => s_sw_clksel,
			sw_runhalt_in  => s_sw_runhalt,
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
			s_sw_clksel		<= tests(i).sw_clksel_in;
            s_sw_runhalt 	<= tests(i).sw_runhalt_in;
			s_pb_step 		<= tests(i).pb_step_in;
			s_pb_reset		<= tests(i).pb_reset_in;
			s_a				<= (others => '0');
			s_reset			<= '0';		-- this is a duplicate of pb_reset_in and needs to be removed from bus_master entirely
            wait for 		tests(i).delay;
        end loop;
        wait;
    end process test_harness;
end tb;
