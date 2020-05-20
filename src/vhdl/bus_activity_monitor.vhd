library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity bus_activity_monitor is
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
end bus_activity_monitor;

architecture rtl of bus_activity_monitor is
    constant C_DEBOUNCE_TICKS : natural range 0 to 131071    := 131071;
    constant C_PWM_RESOLUTION : natural range 0 to 255       := 255;
    constant C_PWM_TICKS      : natural range 0 to 16383     := 16383;
    constant C_PWM_DUTY       : natural range 0 to 255       := 102; -- ~40% brightness

    signal s_button_reg       : std_logic_vector(3 downto 0) := (others => '1');
    signal s_led_reg          : std_logic_vector(6 downto 0);

    signal s_bouncing         : std_logic;
    signal s_clk              : std_logic;
    signal s_debounce_ctr     : natural range 0 to C_DEBOUNCE_TICKS;
    signal s_led_clk          : std_logic;
    signal s_led_fpga         : std_logic;
    signal s_led_irq          : std_logic;
    signal s_led_pio          : std_logic;
    signal s_led_ram          : std_logic;
    signal s_led_rom          : std_logic;
    signal s_led_rw           : std_logic;
    signal s_pb_reset         : std_logic_vector(1 downto 0);
    signal s_pb_step          : std_logic_vector(1 downto 0);
    signal s_pwm              : std_logic;
    signal s_pwm_duty_ctr     : natural range 0 to C_PWM_RESOLUTION;
    signal s_pwm_en           : std_logic;
    signal s_pwm_en_ctr       : natural range 0 to C_PWM_TICKS;
    signal s_sw_clksel        : std_logic_vector(1 downto 0);
    signal s_sw_runhalt       : std_logic_vector(1 downto 0);

begin

    debounce_proc : process (s_clk)
    begin
        if rising_edge(s_clk) then
            s_pb_reset   <= s_pb_reset(0) & pb_reset_in;
            s_pb_step    <= s_pb_step(0) & pb_step_in;
            s_sw_clksel  <= s_sw_clksel(0) & sw_clksel_in;
            s_sw_runhalt <= s_sw_runhalt(0) & sw_runhalt_in;

            if s_bouncing = '1' then
                s_debounce_ctr <= 0;
                s_button_reg   <= s_button_reg;
            elsif s_debounce_ctr < C_DEBOUNCE_TICKS then
                s_debounce_ctr <= s_debounce_ctr + 1;
                s_button_reg   <= s_button_reg;
            else
                s_debounce_ctr <= s_debounce_ctr;
                s_button_reg   <= s_pb_reset(1) & s_pb_step(1) &
                    s_sw_runhalt(1) & s_sw_clksel(1);
            end if;
        end if;
    end process debounce_proc;

    pwm_en_proc : process (s_clk)
    begin
        if rising_edge(s_clk) then
            if s_pwm_en_ctr < C_PWM_TICKS then
                s_pwm_en     <= '1';
                s_pwm_en_ctr <= 0;
            else
                s_pwm_en     <= '0';
                s_pwm_en_ctr <= s_pwm_en_ctr + 1;
            end if;
        end if;
    end process pwm_en_proc;

    pwm_proc : process (s_clk)
    begin
        if rising_edge(s_clk) then
            if s_pwm_en = '1' then
                if s_pwm_duty_ctr < C_PWM_DUTY then
                    s_pwm_duty_ctr <= s_pwm_duty_ctr + 1;
                    s_pwm          <= '1';
                elsif s_pwm_duty_ctr < C_PWM_RESOLUTION then
                    s_pwm_duty_ctr <= s_pwm_duty_ctr + 1;
                    s_pwm          <= '0';
                else
                    s_pwm_duty_ctr <= 0;
                    s_pwm          <= '1';
                end if;
            end if;
        end if;
    end process pwm_proc;

    s_clk      <= clk_in;

    s_bouncing <= (s_pb_reset(1) xor s_pb_reset(0)) or
        (s_pb_step(1) xor s_pb_step(0)) or
        (s_sw_clksel(1) xor s_sw_clksel(0)) or
        (s_sw_runhalt(1) xor s_sw_runhalt(0));

    led_clk_out    <= (not s_led_reg(0)) and s_pwm;
    led_fpga_out   <= (not s_led_reg(1)) and s_pwm;
    led_irq_out    <= (not s_led_reg(2)) and s_pwm;
    led_pio_out    <= (not s_led_reg(3)) and s_pwm;
    led_ram_out    <= (not s_led_reg(4)) and s_pwm;
    led_rom_out    <= (not s_led_reg(5)) and s_pwm;
    led_rw_out     <= (not s_led_reg(6)) and s_pwm;

    button_reg_out <= s_button_reg;
    s_led_reg      <= led_reg_in;

end rtl;