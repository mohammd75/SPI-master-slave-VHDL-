library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;

entity SPI_SLAVE is
    generic (constant data_in_length   : natural  := 8 ;    -- data is n bit
             constant CPOL : std_logic := '0' ;              -- polarity in st_idle state
             constant CPHA : std_logic := '0'               -- edge of clock in sampled data
            );     
    port(reset      : in    std_logic ;
         clk        : in    std_logic ;    
         SDO        : out   std_logic ;   
         SDI        : in    std_logic ;    
         sclk       : in    std_logic ; 
         ss         : in    std_logic ;
         data_out   : out   std_logic_vector(data_in_length-1 downto 0) ;
         valid_out  : out   std_logic ;
         ready_in   : in    std_logic 
        );
end SPI_SLAVE;

architecture BEHAVIORAL of SPI_SLAVE is

    type  fsm_spi_state is (idle_fsm_spi , tx_rx_spi);
    signal present_state_spi , next_state_spi : fsm_spi_state := idle_fsm_spi ;

    type  fsm_AXI_state is (idle_fsm_AXI , wait_for_buffer_full_rise ,register_data_0 ,
                             register_data_1 , data_valid , wait_for_ready_rise , wait_for_buffer_full_fall);
    signal present_state_axi , next_state_axi : fsm_AXI_state := idle_fsm_AXI ;

    signal count            : Natural       range 0 to data_in_length   := 0 ;
    signal count_state      : std_logic     := '0'          ;
    signal buffer_full      : natural range 0 to 1 := 0     ;

    

    signal data_in_SDI      : std_logic_vector (data_in_length-1 downto 0)  := (others => '0')   ;   
    signal data_in_SDI_0     : std_logic_vector (data_in_length-1 downto 0)  := (others => '0')   ;   -- register 1 in source clock domain
    signal data_in_SDI_00    : std_logic_vector (data_in_length-1 downto 0)  := (others => '0')   ;   -- register 1 in destination clock domain
    signal data_in_SDI_000   : std_logic_vector (data_in_length-1 downto 0)  := (others => '0')   ;   -- register 2 in destination clock domain

begin
-------------------------------------SPI------------------------------------------------------------
    present_state_chenge_fsm_SPI:process(sclk)     --chenge present state
    begin   
        if(CPHA = '0' and sclk'event and sclk = (not CPOL))then
            if(reset ='1')then
                present_state_spi <= idle_fsm_spi       ;
            else
                present_state_spi <= next_state_spi     ;
                if(count_state = '1')then
                    count <= count + 1 ;
                else 
                    count <= 0 ;
                end if;
            end if;
        end if;
        if(CPHA = '1' and sclk'event and sclk = CPOL)then
            if(reset ='1')then
                present_state_spi <= idle_fsm_spi       ;
            else
                present_state_spi <= next_state_spi     ;
                if(count_state = '1')then
                    count <= count + 1 ;
                else 
                    count <= 0          ;
                end if;
            end if;
        end if;
    end process present_state_chenge_fsm_SPI;

    next_state_chenge_fsm_SPI:process(present_state_spi , ss , Count)     --chenge next state
    begin 

        case present_state_spi is 
            when idle_fsm_spi =>
                buffer_full <= 0 ;
                if(ss = '0')then    
                    next_state_spi  <=  tx_rx_spi ;
                else    
                    next_state_spi  <=  idle_fsm_spi ;
                end if;
            -------------------------------------------------------        
            when tx_rx_spi =>
                if (count < data_in_length)then    
                    data_in_SDI((data_in_length-1) - Count) <=  SDI ;           -- SDI = Slave DATA input
                    count_state          <= '1' ;
                    if(count = (data_in_length-1))then
                        buffer_full <= 1 ;
                        count_state <= '0' ;
                    else
                        buffer_full <= 0 ;
                    end if;   
                end if;

                if (ss = '0') then
                    next_state_spi  <=  tx_rx_spi ;
                else
                    next_state_spi  <=  idle_fsm_spi ;
                    count_state <= '0' ;
                end if; 
        end case;      

    end process next_state_chenge_fsm_SPI;

--------------------------------------AXI----------------------------------------------------------
    present_state_chenge_fsm_AXI:process(reset , clk)     --chenge present state
    begin   
        if(clk'event and clk ='1')then
            if(reset ='1')then
                present_state_axi <= idle_fsm_AXI   ;
            else
                present_state_axi <= next_state_axi ;
            end if;
        end if;
    end process present_state_chenge_fsm_AXI ;

    next_state_chenge_fsm_AXI:process(present_state_axi , buffer_full , ready_in)     --chenge next state
    begin   
        case present_state_axi is 
            -------------------------------------------------------        
            when idle_fsm_AXI =>
                valid_out   <= '0' ;
                next_state_axi  <=  wait_for_buffer_full_rise ;
            -------------------------------------------------------        
            when wait_for_buffer_full_rise =>
                if (buffer_full = 1)then    
                    valid_out  <= '0' ;
                    data_in_SDI_0   <=  data_in_SDI ;                      
                    next_state_axi  <=  register_data_0 ;
            else    
                valid_out       <= '0' ;
                next_state_axi  <=  wait_for_buffer_full_rise   ;
            end if; 
            -------------------------------------------------------
            -- synchronizers destination clock domain  
            when register_data_0 =>                     
                valid_out  <= '0' ;
                data_in_SDI_00  <=  data_in_SDI_0 ;                             
                next_state_axi  <=  register_data_1 ;
            -------------------------------------------------------
            -- synchronizers destination clock domain  
            when register_data_1 =>                                 
                valid_out  <= '0' ;
                data_in_SDI_000  <=  data_in_SDI_00 ;                             
                next_state_axi   <=  data_valid ;
            -------------------------------------------------------
            when data_valid =>
                valid_out        <= '1' ;
                data_out         <=  data_in_SDI_000 ;
                next_state_axi   <=  wait_for_ready_rise ;
            -------------------------------------------------------
            when wait_for_ready_rise =>
                if (ready_in = '1')then 
                    valid_out       <= '0' ;
                    next_state_axi  <=  wait_for_buffer_full_fall ;
                else                   
                    next_state_axi  <=  wait_for_ready_rise ;
                end if;
            -------------------------------------------------------
            when wait_for_buffer_full_fall =>
                if (buffer_full = 0)then 
                    next_state_axi  <=  wait_for_buffer_full_rise ;
                else                   
                    next_state_axi  <=  wait_for_buffer_full_fall ;
                end if;

        end case;                
    end process next_state_chenge_fsm_AXI;

end architecture BEHAVIORAL;    
 