library IEEE;
use IEEE.STD_LOGIC_1164.ALL;			----------thu vien logic
use ieee.std_logic_unsigned.all;		
use ieee.numeric_std.all;
entity ngoc is

port (  	
			clk 	    : in std_logic;
			eoc 		 : in std_logic;
			datain	 : in std_logic_vector(7 downto 0);
			adc_clk	 : out std_logic;
			start_adc : out std_logic;
			tx			 : out std_logic;
			led7seg	 : out std_logic_vector(6 downto 0);
			D: out std_logic_vector(2 downto 1)
);
end entity ngoc;

architecture behavioral of ngoc is

signal bcd: std_logic_vector(3 downto 0) := "0101";

---------------signal for adc_control-----------------------

signal count_adc: std_logic_vector(24 downto 0) := "0000000000000000000000000";


---------------signal for catching rising_edge of eoc ----------
signal reg: std_logic_vector(1 downto 0):= "00";
signal reg_xor: std_logic := '0';
signal en : std_logic;
----------------signal for uart_transsmit ----------------------
signal data: std_logic_vector(7 downto 0) := "01001101";
type state is (idle,start_bit,data_bit,stop_bit);
signal pre_state: state := idle;
signal count : integer range 0 to 5300;
signal index : integer range 0 to 8; 


-------------signal for 7seg-------------
signal int_val: integer range 0 to 200;
signal a,b: integer range 0 to 9;
signal a_binary,b_binary: std_logic_vector(3 downto 0);
type step is (waiting, cal0, caldone);
signal step_n: step := waiting;
begin


---------------------adc control----------------------
start_adc <= '1' when count_adc < 6 else '0';
adc_clk <= count_adc(11);
adc_control: process (clk)
begin
	if rising_edge(clk) then
		count_adc <= count_adc + 1;
	end if;
end process adc_control;

---------------------//-------------------//-----------


-----------------catching rising_edge of eoc----------
en <= reg_xor and eoc;
reg_xor <= reg(1) xor reg (0);
ngoc_di_len: process(clk,eoc,reg_xor)
begin
	if rising_edge(clk) then 
		reg <= reg(0) & eoc;

	end if;
end process ngoc_di_len; 
------------------//-------------------//-----------------


--------------------uart_transsmit------------------------
uart_transsmit: process(clk,en)
begin
	if rising_edge(clk) then
		case pre_state is
		
			when idle => 
				tx <= '1';
				if en = '1' then 
					count <= 0;
					pre_state <= start_bit;
					data <= datain;
				end if;
			
			when start_bit => 
				tx <= '0';
				if count = 5208 then
					pre_state <= data_bit;
					count <= 0;
					index <= 0;
				else 
					count <= count + 1;
				end if;
			when data_bit => 
					tx <= data(index);
					count <= count + 1;
				if index > 7 then
					pre_state <= stop_bit;
					count <= 0;
					index <= 0;
				elsif count = 5208 then
					count <= 0;
					index <= index + 1; 
				end if;
			when stop_bit =>
				tx <= '1';
				count <= count + 1;
				if count = 5208 then 
					count <= 0;
					pre_state <= idle;
				end if;
		end case;
	end if;

end process uart_transsmit;

--------------------bcd covert------------------
process(bcd)
begin
	case bcd is 
		when "0000" => led7seg <= "0000001";
		when "0001" => led7seg <= "1001111";
		when "0010" => led7seg <= "0010010";
		when "0011" => led7seg <= "0000110";
		when "0100" => led7seg <= "1001100";
		when "0101" => led7seg <= "0100100";
		when "0110" => led7seg <= "0100000";
		when "0111" => led7seg <= "0001111";
		when "1000" => led7seg <= "0000000";
		when "1001" => led7seg <= "0000100";

		when others => led7seg <= "1111111";

	end case;	
end process;
----------------------------//-------------------


D <= "01" 			when count_adc(12) = '0' else "10";
bcd <= a_binary 	when count_adc(12) = '0' else b_binary;

process(clk,en)
begin
	if rising_edge(clk) then
		case step_n is
			when waiting => 
			if en = '1' then
				int_val <= to_integer(unsigned(datain));
				step_n <= cal0;
			end if;
			when cal0 => 
				a <= int_val /10;							----- chia lay thuong
				b <= int_val mod 10;						----- chia lay du
				step_n <= caldone;
			when caldone => 
				a_binary <= std_logic_vector(to_unsigned(a, 4));
				b_binary <= std_logic_vector(to_unsigned(b, 4));
				step_n <= waiting;
		end case;
	end if;
end process;
end behavioral;
 