library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;


entity ERROR_CHECK  is
    generic (
        constant N  : integer := 8
    );
    port(
        CLK_I     :   in    std_logic;
        RESET_I   :   in    std_logic;
        VALID_I   :   in    std_logic;
        DATA_I    :   in    std_logic_vector(n-1 downto 0);
        ERROR_O   :   out   std_logic_vector(  3 downto 0);
        READY_O   :   out   std_logic
    );
end ERROR_CHECK;

architecture BEHAVIORAL of ERROR_CHECK is

    type   state is (idle , wait_for_valid_rise , zero_ready);
    signal present_state , next_state : state ;

    signal data     : std_logic_vector(n-1 downto 0);
    signal data_0   : std_logic_vector(n-1 downto 0);
    signal error    : std_logic_vector(  3 downto 0) := (others => '0');
    
begin


    present_state_chenge : process (CLK_I)     --chenge present state
    begin

        if(CLK_I'event and CLK_I = '1')then
            if(RESET_I = '1')then 
                present_state  <= idle       ;
            else
                present_state  <= next_state ;
            end if;
        end if;

    end process present_state_chenge;

    next_state_chenge : process (present_state , VALID_I)     --chenge next state
    begin

        case present_state is

            when idle =>
                next_state  <= wait_for_valid_rise  ;
                READY_O     <=  '0' ;
                ERROR_O       <= "0000" ;
            -------------------------------------------------------        
            when wait_for_valid_rise =>
                if(VALID_I = '1')then
                    data        <= DATA_I ;
                    data_0      <= data + 1 ;
                    READY_O     <= '1' ;
                    next_state  <= zero_ready ;
                else
                    next_state  <= wait_for_valid_rise ;
                    READY_O     <= '0' ;
                end if;
            -------------------------------------------------------        
            when zero_ready =>
                READY_O     <= '0' ;
                next_state  <= wait_for_valid_rise ;

                --Error_Check(start)
                if(data /= (x"00"))then         --if DATA_I /= 0x00
                    if(data_0 /= data)then
                        error <= error + 1 ;
                    end if;
                end if;
                --Error_Check(End)

                ERROR_O   <= error ;
        end case;

    end process next_state_chenge;
                
end architecture BEHAVIORAL;
