library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library machxo2;
use machxo2.all;

entity clock_manager is
	port (
		bus_clk_out		: out std_logic;
		clk_out			: out std_logic;
		clk_sel_in		: in  std_logic;
		ext_clk_in		: in  std_logic;
		reset_in		: in  std_logic;
		runhalt_in		: in  std_logic;
		step_in         : in  std_logic
	);
end clock_manager;

architecture rtl of clock_manager is

	constant C_FPGA_FREQ : string := "2.08"; -- 2.08 MHz to 133.00 MHz +/- 5%, see Lattice TN1199 for valid step values
	--constant C_BCLK_TICKS : natural range 0 to 2080000 := 2080000; -- ~1 Hz
	constant C_BCLK_TICKS : natural range 0 to 260000 := 260000; -- ~4 Hz
	
	signal s_bclk_en	: std_logic;
	signal s_bclk_ff    : std_logic_vector(1 downto 0);
	signal s_bus_clk	: std_logic := '0';
	signal s_clk		: std_logic;
	signal s_clk_sel	: std_logic;
	signal s_div_ctr	: natural range 0 to C_BCLK_TICKS;
	signal s_ext_clk	: std_logic;
	signal s_int_clk	: std_logic;
	signal s_reset		: std_logic;
	signal s_runhalt    : std_logic;
	signal s_step       : std_logic_vector(1 downto 0);
	
	type   t_state is ( HALT, ARMED, PULSE );
	signal s_state 		: t_state;
	
	-- Internal oscillator
    component osch
    -- synthesis translate_off
    generic (NOM_FREQ : string := C_FPGA_FREQ);
    -- synthesis translate_on
    port (
		sedstdby : out std_logic;
        stdby    : in std_logic;
        osc      : out std_logic
    );
    end component osch;
    attribute NOM_FREQ           : string;
    attribute NOM_FREQ of osch_i : label is C_FPGA_FREQ;

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
    generic map(NOM_FREQ => C_FPGA_FREQ)
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
	
	bclk_div_proc : process (s_clk)
	begin
		if rising_edge(s_clk) then
		  if s_reset = '1' then
				s_bus_clk	<= '0';
				s_div_ctr	<= 0;
				s_bclk_ff   <= (others => '0');
		  else
			s_bclk_ff	<= 	s_bclk_ff(0) & s_bus_clk;
			
			if s_div_ctr = C_BCLK_TICKS then
				s_bus_clk	<= not s_bus_clk;
				s_div_ctr	<= 0;
			else
				s_bus_clk	<= s_bus_clk;
				s_div_ctr	<= s_div_ctr + 1;
			end if;
		  end if;
		end if;
	end process bclk_div_proc;
	
	fsm_proc : process (s_clk)
	begin
		if rising_edge(s_clk) then
		  if s_reset = '1' then
			s_bclk_en	<= '0';
			s_runhalt	<= '1';
			s_state		<= HALT;
			s_step		<= (others => '0');
		  else
			s_step		<= s_step(0) & step_in;
			s_runhalt	<= runhalt_in;
			
			case s_state is
				when HALT =>
					s_bclk_en		<= '0';
					
					if s_runhalt = '1' and s_step = "01" then
						s_state		<= ARMED;
					elsif s_runhalt = '1' then
						s_state		<= HALT;
					else
						s_state		<= ARMED;
					end if;
				
				when ARMED =>
					s_bclk_en		<= '0';
					
					if s_bclk_ff = "00" then
						s_state		<= PULSE;
					else
						s_state		<= ARMED;
					end if;
				
				when PULSE =>
					s_bclk_en		<= '1';
					
					if s_bclk_ff = "10" then
						s_state		<= HALT;
					else
						s_state		<= PULSE;
					end if;
		    end case;
		  end if;
		end if;
	end process fsm_proc;

	bus_clk_out	<= s_bus_clk and s_bclk_en;
	
	clk_out		<= s_clk;
	
	s_clk_sel	<= not clk_sel_in;
	s_ext_clk	<= ext_clk_in;
	s_reset		<= not reset_in;
	
	
	
end rtl;
