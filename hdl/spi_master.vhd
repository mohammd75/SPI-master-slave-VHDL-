library IEEE;
use IEEE.std_logic_1164.all;

entity SPI_MASTER is
    generic (
        constant   data_in_length   : natural   :=  8  ;     -- data is n bit
        constant   CPOL             : std_logic := '0' ;     -- Polarity Clock in start SPI communication
        constant   CPHA             : std_logic := '0' ;     -- determinative (first or second) edge clcok in data sampling by receiver 
        constant   buad_rate_spi    : integer   :=  10 ;     -- buad rate= bit rate= buad_rate_spi (Mbit/s)  ===> buad_rate_spi (default) = 10 MHz
        constant   clk_input        : integer   :=  100      -- Clock manufacturer SCLK (it is assumed) = 100 MHz 
    );     
    port(
        RESET_I     :   in      std_logic ;
        CLK_I       :   in      std_logic ;
        DATA_I      :   in      std_logic_vector(data_in_length-1 downto 0) ;
        VALID_I     :   in      std_logic ;
        READY_O     :   out     std_logic ;
        ----------------------spi-------------------------------------------
        SDO         :   out     std_logic ;     --ss:slave select active low
        SDI         :   in      std_logic ;
        SS          :   out     std_logic := '1' ;
        SCLK_EN_O   :   out     std_logic := '0'    
    );
end SPI_MASTER;

architecture BEHAVIORAL of SPI_MASTER is

    constant clock_factor       : Natural := (clk_input / buad_rate_spi) ;
    signal count_buad_rate_spi  : Natural range 0 to clock_factor ;

    type   fsm_state is (idle , ready_rise , wait_for_valid_rise , data_in_register , st_tx_rx_spi);
    signal present_state  , next_state : fsm_state := idle ;

    signal spi_active : std_logic := '0' ;

    signal count          : Natural range 0 to data_in_length := 0 ;
    signal count_state    : std_logic := '0' ;

    signal data_in                 : std_logic_vector (data_in_length-1 downto 0) ;
    signal data_in_R               : std_logic_vector (data_in_length-1 downto 0) ;

begin

    ss_and_sclk_gen : process(CLK_I)
    
    begin
        --ss & sclk generate 
        if(CLK_I'event and CLK_I = '1')then
            if(spi_active = '1')then
                if(CPHA = '0')then
                    -- if CPHA = 0
                    if(next_state = st_tx_rx_spi and count < data_in_length)then
                        SCLK_EN_O   <= '1' ;
                        SS          <= '0' ;
                    elsif(count_buad_rate_spi = (clock_factor/2) )then
                        SCLK_EN_O   <= '0' ;
                        SS          <= '1' ;
                    end if;
                else
                    -- if CPHA = 1
                    if(next_state = st_tx_rx_spi and count < (data_in_length - 1) )then
                        SCLK_EN_O   <= '1' ;
                        SS          <= '0' ;
                    elsif(count_buad_rate_spi = clock_factor)then
                        SCLK_EN_O   <= '0' ;
                        SS          <= '1' ;
                    end if;
                end if;
            end if;
        end if;                                                                

    end process ss_and_sclk_gen;
            
    present_state_chenge : process(CLK_I)     

    begin
        if(CLK_I'event and CLK_I = '1')then
            if(RESET_I ='1')then
                present_state <= idle ;
            else
                if(spi_active = '0')then
                    present_state <= next_state ;
                    if(CPHA = '0')then
                        -- if CPHA = 0
                        count_buad_rate_spi <= clock_factor ;
                    else
                        -- if CPHA = 1
                        count_buad_rate_spi <= (clock_factor/2) ;
                    end if;
                else
                    --spi 
                    if(count_buad_rate_spi = clock_factor)then
                        present_state       <= next_state ;
                        count_buad_rate_spi <= 1 ;
                        if(count_state = '1')then
                            count <= count + 1 ;
                        else 
                            count <= 0 ;
                        end if;
                    else
                        count_buad_rate_spi   <= count_buad_rate_spi + 1 ;
                    end if;
                end if;
            end if;
        end if;

    end process present_state_chenge;

    next_state_chenge : process(present_state , VALID_I , count) 

    begin   
        case present_state is 
            -------------------------------------------------------        
            when idle =>
                READY_O     <= '0' ;
                next_state  <= ready_rise ;
                spi_active  <= '0' ;
            ------------------------------------------------------- 
            when ready_rise =>
                spi_active  <= '0' ;
                READY_O     <= '1' ;
                next_state  <= wait_for_valid_rise ;
            ------------------------------------------------------- 
            when wait_for_valid_rise =>
                if(VALID_I = '1')then
                    data_in     <= DATA_I ;
                    READY_O     <= '0' ;
                    next_state  <=  data_in_register ;
                else
                    next_state  <= wait_for_valid_rise ;
                end if;
            ------------------------------------------------------- 
            when data_in_register =>
                    data_in_R   <= data_in ;
                    next_state  <= st_tx_rx_spi ;
                    spi_active  <= '1' ;
            ------------------------------------------------------- 
            when st_tx_rx_spi =>
                if (count < data_in_length)then 
                    SDO         <= data_in_R( (data_in_length - 1) -count) ;   
                    count_state <=  '1' ;
                    next_state  <= st_tx_rx_spi ;
                else    
                    count_state <= '0' ;
                    next_state  <=  ready_rise ; 
                end if; 
        end case;

    end process next_state_chenge;  


end architecture BEHAVIORAL;    