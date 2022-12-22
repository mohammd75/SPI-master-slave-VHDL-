library  IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;

entity  COUNTER is
    generic( 
        constant number_of_bit : integer := 8                -- Counter is n bit
    );    
    port(
        enable          : in     std_logic   ;
        reset           : in     std_logic   ;
        clk             : in     std_logic   ;
        ready_in        : in     std_logic   ;
        valid_out       : out    std_logic   ;
        data_out        : out    std_logic_vector(number_of_bit-1 downto 0)
    );
end COUNTER;

architecture BEHAVIORAL  of  COUNTER is
    
    signal data : std_logic_vector(number_of_bit-1 downto 0) := (others => '0') ;     

    type  state is ( idle , wait_for_enable_high , data_valid , create_data , wait_for_ready_rise);
    signal present_state , next_state   : state := idle ;

    begin
        present_state_chenge:process(clk)     --chenge present state
        begin   
            if(clk'event and clk = '1')then
                if(reset ='1')then 
                    present_state  <= idle          ;
                else
                    present_state  <= next_state    ;
                end if;
            end if;
        end process present_state_chenge;

        next_state_chenge:process(present_state , enable , ready_in)     --chenge next state
        constant high_count     : std_logic_vector(number_of_bit-1 downto 0) := (others => '1');
        begin   
            case present_state is 
                -------------------------------------------------------        
                when idle =>
                    next_state  <=  wait_for_enable_high ;
                    valid_out   <=  '0' ;
                    data        <=  (others => '0') ;
                -------------------------------------------------------
                when wait_for_enable_high =>
                    if(enable = '1')then
                        next_state  <=  data_valid ;
                    else
                        next_state  <=  wait_for_enable_high ;
                    end if;
                -------------------------------------------------------
                when data_valid =>
                    if(enable = '1')then 
                        valid_out   <= '1' ;
                        data_out    <= data ;
                        next_state  <= wait_for_ready_rise  ;
                    else
                        next_state  <= wait_for_enable_high ;
                        valid_out   <= '0' ;
                    end if;
                -------------------------------------------------------
                when create_data =>
                    if(data = high_count)then    
                        data        <= (others => '0') ;
                        next_state  <= data_valid ;
                    else
                        data        <= data + 1 ;
                        next_state  <= data_valid ;
                    end if;
                -------------------------------------------------------        
                when wait_for_ready_rise =>
                    if(ready_in = '1')then
                        valid_out   <=  '0' ;
                        next_state  <= create_data ;
                    else
                        next_state  <= wait_for_ready_rise  ;
                    end if;  

            end case;                
        end process next_state_chenge;
end architecture BEHAVIORAL;

