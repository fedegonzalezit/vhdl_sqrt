library	ieee;
use		ieee.std_logic_1164.all;
use		ieee.numeric_std.all;
use 		ieee.std_logic_textio.all;

entity tb_sqrt is
end entity tb_sqrt;

architecture testbench of tb_sqrt is
	signal tb_reset : std_logic := '0';
	signal tb_clk : std_logic := '0';
	signal tb_rdcn : std_logic_vector(15 downto 0) := (others => '0');
	signal tb_start : std_logic := '0';
	signal tb_root : std_logic_vector(7 downto 0);
	signal tb_rmd : std_logic_vector(8 downto 0);
	signal tb_op_done : std_logic;
	signal tb_root_ok : std_logic_vector(7 downto 0);
	signal tb_rmd_ok : std_logic_vector(8 downto 0);
	
  constant CLK_PERIOD : time := 20 ns;
	constant SYN_DELAY : time := 1 ns;
	
	function tb_sqrt_sim(value : integer) return integer is
		variable a : unsigned(31 downto 0):= to_unsigned(value, 32);  --original input.
		variable q : unsigned(15 downto 0):=(others => '0');  --result.
		variable left,right,r : unsigned(17 downto 0):=(others => '0');  --input to adder/sub.r-remainder.
		variable i : integer:=0;
	begin
		for i in 0 to 15 loop
		right(0):='1';
		right(1):=r(17);
		right(17 downto 2):=q;
		left(1 downto 0):=a(31 downto 30);
		left(17 downto 2):=r(15 downto 0);
		a(31 downto 2):=a(29 downto 0);  --shifting by 2 bit.
		if ( r(17) = '1') then
		r := left + right;
		else
		r := left - right;
		end if;
		q(15 downto 1) := q(14 downto 0);
		q(0) := not r(17);
		end loop; 
		return to_integer(q);
	end function tb_sqrt_sim;
	
	function tb_rmd_sim(rd, r : integer) return integer is
	begin
		return rd - r * r;
	end function tb_rmd_sim;
begin
	uut : entity work.sqrt
		port map
			(
					reset => tb_reset,
					clk => tb_clk,
					rdcn => tb_rdcn,
					start => tb_start,
					root => tb_root,
					rmd => tb_rmd,
					op_done => tb_op_done
			);

	clk_process : process
	begin
		wait for CLK_PERIOD / 2;
		tb_clk <= '1';
		wait for CLK_PERIOD / 2;
		tb_clk <= '0';
	end process;
	
	rst_process : process
	begin
		tb_reset <= '0';
		wait for CLK_PERIOD * 2 + SYN_DELAY;
		tb_reset <= '1';
		wait for CLK_PERIOD;
		tb_reset <= '0';
		wait;
	end process;
	
	process
		variable errorCount: integer := 0;
	begin
		wait for CLK_PERIOD * 10 + SYN_DELAY;
		
		for r in 0 to 65535 loop
			tb_rdcn <= std_logic_vector(to_unsigned(r, 16));
			wait for CLK_PERIOD;
			tb_start <= '1';
			wait for CLK_PERIOD;
			tb_start <= '0';
			wait until tb_op_done = '1';
				tb_root_ok <= std_logic_vector(to_unsigned(tb_sqrt_sim(r), 8));
				tb_rmd_ok <= std_logic_vector(to_unsigned(tb_rmd_sim(r, tb_sqrt_sim(r)), 9));
			wait for SYN_DELAY;
				if (tb_root /= tb_root_ok or tb_rmd /= tb_rmd_ok) then
					report "[ERROR] ";
					report "[ESPERADO] Raiz cuadrada de " & INTEGER'IMAGE(r) & " es " & INTEGER'IMAGE(to_integer(unsigned(tb_root_ok)));
					report "[ESPERADO] Resto de la raiz cuadrada de " & INTEGER'IMAGE(r) & " es " & INTEGER'IMAGE(to_integer(unsigned(tb_rmd_ok)));
					report "[OBTENIDO] Raiz cuadrada de " & INTEGER'IMAGE(r) & " segun el circuito es " & INTEGER'IMAGE(to_integer(unsigned(tb_root)));
					report "[OBTENIDO] Resto de la raiz cuadrada de " & INTEGER'IMAGE(r) & " segun el circuito es " & INTEGER'IMAGE(to_integer(unsigned(tb_rmd)));
					errorCount := errorCount + 1;					
				end if;
			wait for CLK_PERIOD * 1 - SYN_DELAY;
		end loop;
		
		if (errorCount = 0) then
			report "LA SIMULACION HA SIDO EXITOSA";
		else
			report "La simulación tuvo " & INTEGER'IMAGE(errorCount) & " errores.";
		end if;			
		
		assert false			
			report "Simulacion finalizada"
		severity failure;
	end process;
end architecture testbench;
