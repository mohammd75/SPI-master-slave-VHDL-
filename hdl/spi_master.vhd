library IEEE;
use IEEE.std_logic_1164.all;

entity SPI_MASTER is
    generic (
        constant   data_in_length  : natural   :=  8 ;     --data is n bit
        constant   CPOL            : std_logic := '0';     --polarity in st_idle state
        constant   CPHA            : std_logic := '0';     --edge of clock in sampled data
        constant   k               : integer   :=  5       --buad rate= bit rate= 10Mbit/s (assune clk=100MHz) ===> clk/2k=clk_spi
    );     
    port(
        RESET_I     :   in      std_logic   ;
        CLK_I       :   in      std_logic   ;
        ----------------------input--------------------------------------------
        DATA_I      :   in      std_logic_vector(data_in_length-1 downto 0) ;
        VALID_I     :   in      std_logic ;
        READY_O     :   out     std_logic ;
        ----------------------output-------------------------------------------
        SDO         :   out     std_logic   ;     --ss:slave select active low
        SDI         :   in      std_logic   ;
        SS          :   out     std_logic   ;
        SCLK        :   out     std_logic   
    );
end SPI_MASTER;

architecture BEHAVIORAL of SPI_MASTER is

signal clk_spi       : std_logic := '0';
signal count_clk_spi : Positive range 1 to k := 1;


type   fsm_spi_state is (idle_fsm_spi , data_received_state , st_tx_rx_spi);
signal present_state_spi  , next_state_spi : fsm_spi_state := idle_fsm_spi ;

type   fsm_axi_state is (idle_fsm_axi , ready_rise , wait_for_valid_rise , wait_for_spi_tx_finish_rise , wait_for_spi_tx_finish_fall);
signal present_state_axi , next_state_axi : fsm_axi_state := idle_fsm_axi ;

signal count          : Natural range 0 to data_in_length := 0 ;
signal count_state    : std_logic := '0' ;

signal spi_tx_finish_flag   : std_logic := '0' ;



signal data_in                 : std_logic_vector (data_in_length-1 downto 0) ;
signal data_in_R               : std_logic_vector (data_in_length-1 downto 0) ;
signal data_received_axi       : std_logic := '0' ;
signal data_received_axi_R     : std_logic := '0' ;
signal data_received_axi_RR    : std_logic := '0' ;


begin

    CLK_div: process(CLK_I)    --generate clk SPI (in next Project of use clock_Wizard[MMCM])
    begin
        if(CLK_I='1' and CLK_I'event)then
            if (count_clk_spi = k)then
                count_clk_spi <= 1;
                clk_spi <= not clk_spi;
            else
            count_clk_spi <= count_clk_spi +1;
            end if;
        end if;            
    end process CLK_div;    

    present_state_chenge_fsm_SPI : process(clk_spi)     --chenge present state
    begin   
        if(CPHA = '0' and clk_spi'event and clk_spi = '0')then
            if(RESET_I ='1')then
                present_state_spi <= idle_fsm_spi ;
            else
                present_state_spi <= next_state_spi;
                if(count_state = '1')then
                    count <= count + 1 ;
                else 
                    count <= 0 ;
                end if;

    --multi_flop sanyhronizer data received
                data_received_axi_R     <=  data_received_axi ;  
                data_received_axi_RR    <=  data_received_axi_R ;   
 
            end if;
        ------------------------------------------------------------
        elsif(CPHA = '1' and clk_spi'event and clk_spi = '1')then
            if(RESET_I ='1')then
                present_state_spi <= idle_fsm_spi ;
            else
                present_state_spi <= next_state_spi;
                if(count_state = '1')then
                    count <= count + 1 ;
                else 
                    count <= 0 ;
                end if;

    --multi_flop sanyhronizer data received
                data_received_axi_R     <=  data_received_axi ;  
                data_received_axi_RR    <=  data_received_axi_R ;   
     
            end if;
        end if;
    end process present_state_chenge_fsm_SPI;

    next_state_chenge_fsm_SPI : process(present_state_spi , data_received_axi_RR , count)     
    begin   
        case present_state_spi is 
            -------------------------------------------------------        
            when idle_fsm_spi =>
                SS                  <= '1' ;
                spi_tx_finish_flag  <= '0' ;
                next_state_spi      <= data_received_state ;
            ------------------------------------------------------- 
            when data_received_state =>
                if(data_received_axi_RR = '1')then
                    data_in_R       <= data_in ;
                    next_state_spi  <= st_tx_rx_spi ;
                -- else
                --     data_in_R   <= data_in_R ;
                else
                    next_state_spi  <= data_received_state ;
                end if;
            ------------------------------------------------------- 
            when st_tx_rx_spi =>
                if (count < 8)then 
                    SDO         <= data_in_R(7-count) ;   
                    SS          <=  '0' ; 
                    count_state <=  '1' ;
                    next_state_spi  <= st_tx_rx_spi ;
                    if(count = 7)then
                        spi_tx_finish_flag  <= '1' ;

                    end if;
                else    
                    SS                  <= '1' ;
                    count_state         <= '0' ;
                    spi_tx_finish_flag  <= '0' ;
                    next_state_spi      <=  data_received_state ; 
                end if; 
        end case;                
    end process next_state_chenge_fsm_SPI;  

    SCLK <= CPOL when present_state_spi = idle_fsm_spi else clk_spi;

--==================================================================================--
    present_state_chenge_fsm_AXI : process(RESET_I , CLK_I)
    begin     
        if(CLK_I'event and CLK_I ='1')then
            if(RESET_I ='1')then
                present_state_axi <= idle_fsm_axi   ;
            else
                present_state_axi <= next_state_axi ;
            end if;
        end if;
    end process present_state_chenge_fsm_AXI ;

    next_state_chenge_fsm_AXI : process(present_state_axi , VALID_I , spi_tx_finish_flag)     
    begin   
        case present_state_axi is 
            when idle_fsm_axi =>
                READY_O             <= '0' ;
                data_in             <= (others => '0') ;
                data_received_axi   <= '0' ;
                next_state_axi      <= ready_rise ;
            ------------------------------------------------------- 
            when ready_rise =>
                READY_O         <= '1' ;
                next_state_axi  <= wait_for_valid_rise ;
            ------------------------------------------------------- 
            when wait_for_valid_rise =>
                if(VALID_I = '1')then
                    data_in             <= DATA_I ;
                    data_received_axi   <= '1' ;
                    READY_O             <= '0' ;
                    next_state_axi      <=  wait_for_spi_tx_finish_rise ;
                else
                    next_state_axi  <= wait_for_valid_rise ;
                end if;
            ------------------------------------------------------- 
            when wait_for_spi_tx_finish_rise =>
                if(spi_tx_finish_flag = '1')then
                    next_state_axi  <= wait_for_spi_tx_finish_fall ;
                    data_received_axi   <= '0' ;
                else
                    next_state_axi  <= wait_for_spi_tx_finish_rise ;
                end if;
            ------------------------------------------------------- 
            when wait_for_spi_tx_finish_fall =>
                if(spi_tx_finish_flag = '0')then
                    next_state_axi  <= ready_rise ;
                else
                    next_state_axi  <= wait_for_spi_tx_finish_fall ;
                end if;

        end case;                
    end process next_state_chenge_fsm_AXI;
    

end architecture BEHAVIORAL;    