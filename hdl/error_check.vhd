library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;


entity ERROR_CHECK  is
    generic (
        constant N  : integer := 8  --data is N bit
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

    type   state is (idle , wait_for_valid_rise , ready_rise , error_check_disable);
    signal present_state , next_state : state ;

    signal data      : std_logic_vector(n-1 downto 0) := (others => '0') ;
    signal data_R    : std_logic_vector(n-1 downto 0) := (others => '0') ;

    signal error_check_en   : std_logic := '0' ;
    signal error            : std_logic_vector(  3 downto 0) := (others => '0') ;
    
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
                next_state  <= ready_rise  ;
                READY_O     <=  '0' ;
                data        <= (others => '0') ;
                data_R      <= (others => '0') ;
            ------------------------------------------------------- 
            when ready_rise =>
                READY_O         <= '1' ;
                error_check_en  <= '0' ;
                next_state      <= wait_for_valid_rise ;
            -------------------------------------------------------
            when wait_for_valid_rise =>
                if(VALID_I = '1')then
                    data            <= DATA_I ;
                    data_R          <= data + 1 ;
                    error_check_en  <= '1' ;    
                    next_state      <= error_check_disable ;
                end if ;
            -------------------------------------------------------
            when error_check_disable =>
                error_check_en  <= '0' ;
                next_state      <= wait_for_valid_rise ;

        end case;

    end process next_state_chenge;
                
    error_check : process(CLK_I)     --chenge present state
    begin

        if(CLK_I'event and CLK_I = '1')then
            if(RESET_I = '1')then 
                error  <= (others => '0') ;
            elsif(error_check_en = '1' and VALID_I = '1')then
                --Error_Check(start)
                    if(data /= (x"00"))then         --if DATA_I /= 0x00
                        if(data_R /= data)then
                            error <= error + 1 ;
                        end if;
                    end if;
                --Error_Check(End)
            end if;
        end if;

    end process error_check;

    error_drive_out_port : process(CLK_I)     --chenge present state
    begin

        if(CLK_I'event and CLK_I = '1')then
            if(RESET_I = '1')then 
                ERROR_O <= "0000" ;
            else
                ERROR_O <= error ;  
            end if;
        end if;
    end process error_drive_out_port;



end architecture BEHAVIORAL;
