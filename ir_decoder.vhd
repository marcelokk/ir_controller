libraRY ieee;
use ieee.std_LOGIC_1164.all;
use ieee.std_LOGIC_ARITH.all;
use ieee.std_LOGIC_unsigned.all;
use ieee.numeric_std.all;

entity ir_decoder is
	port( clk			: in std_logic;
			reset			: in std_logic;
			ir_signal	: in std_logic;
			
			led0			: out std_logic;
			led1			: out std_logic;
			led2			: out std_logic;
			led3			: out std_logic;
			led4			: out std_logic;			
			
			output		: out std_logic_vector(15 downto 0)
		);
end ir_decoder;

ARCHITECTURE main of ir_decoder is
		
	type states is (waiting, header, receiving);	
		
	constant	nbits	: integer := 3;
	
begin

-- Maquina de Controle
process(clk, reset)
	variable contador		: integer;
	variable received_bits : integer;
	variable output_buffer : std_logic_vector(15 downto 0);
	variable state : states;
	variable next_state : states;
			
begin

	if(reset = '1') then
		contador := 0;
		received_bits := 0;
		output_buffer := x"0000";
		state := waiting;
		next_state := header;
		
		led0 <= '0';
		led1 <= '0';	
		led2 <= '0';
		led3 <= '0';
		led4 <= '0';
		
	elsif(clk'event and clk = '1') then
		
		case state is
			when waiting =>	
				led0 <= '1';	
				led1 <= '0';	
				led2 <= '0';					
				contador := 0;		-- reseta contador		

				if(ir_signal = '1') then
					state := next_state;
				end if;
		
			when header =>			
				led0 <= '0';	
				led1 <= '1';	
				led2 <= '0';				
				led3 <= '0';
						
				if(ir_signal = '0') then							 -- parou de receber sinal						
					if(0 <= contador and contador < 2300) then -- nao recebeu o header
						state := waiting;
						next_state := header;
					else 													 -- recebeu o header		
						contador := 0;									 -- reseta contador	
						state := waiting;	
						next_state := receiving;
					end if;
				end if;
			
			when receiving =>	
				led0 <= '0';	
				led1 <= '0';	
				led2 <= '1';	
				
				--output <= CONV_STD_LOGIC_VECTOR(CONV_INTEGER(received_bits), 16);				
				
				if(received_bits = nbits) then			
					state := waiting;
					next_state := header;
					
					received_bits := 0;	
					output <= output_buffer;
					led4 <= '1';
				end if;
			
				if(ir_signal = '0') then									-- parou de receber sinal
					if(400 < contador and contador < 800) then		-- bit 0 = 600		
						output_buffer(nbits - received_bits - 1) := '0';
						received_bits := received_bits + 1;
						state := waiting;
						next_state := receiving;	
		
					elsif(1000 < contador and contador < 1400) then	-- bit 1	= 1200		
						output_buffer(nbits - received_bits - 1) := '1';	
						received_bits := received_bits + 1;
						state := waiting;
						next_state := receiving;
						
					else
						state := waiting;
						next_state := header;
						received_bits := 0;
						led3 <= '1';		
						--output <= CONV_STD_LOGIC_VECTOR(CONV_INTEGER(received_bits), 16);							
					end if;
				end if;	
								
		end case;
				
		-- sempre conta
		if(ir_signal = '1') then
			contador := contador + 1;
		end if;					
				
	end if;
end process;

end main;
