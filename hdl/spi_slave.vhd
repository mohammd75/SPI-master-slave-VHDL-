library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;

entity spi_slave is
    generic (constant data_in_length   : natural  := 8 ;    -- data is n bit
             constant CPOL : std_logic := '0';              -- polarity in st_idle state
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
end spi_slave;

architecture behavioral of spi_slave is

    type  fsm_spi_state is (idle_fsm_spi , tx_rx_spi);
    signal present_state_spi , next_state_spi : fsm_spi_state := idle_fsm_spi ;

    type  fsm_AXI_state is (idle_fsm_AXI ,wait_for_buffer_full_rise ,wait_for_ready_rise ,wait_for_ready_fall);
    signal present_state_axi , next_state_axi : fsm_AXI_state := idle_fsm_AXI ;

    signal Count            : Natural       range 0 to data_in_length   := 0 ;
    signal Count_state      : std_logic     := '0'          ;
    signal buffer_full      : natural range 0 to 1 := 0     ;

    signal data_in_SDI      : std_logic_vector (data_in_length-1 downto 0)  := (others => '0')   ;   
    signal data_in_SDI_0     : std_logic_vector (data_in_length-1 downto 0)  := (others => '0')   ;   -- register 1 in source clock domain
    signal data_in_SDI_00    : std_logic_vector (data_in_length-1 downto 0)  := (others => '0')   ;   -- register 1 in destination clock domain
    signal data_in_SDI_000   : std_logic_vector (data_in_length-1 downto 0)  := (others => '0')   ;   -- register 2 in destination clock domain

begin
-------------------------------------SPI------------------------------------------------------------
    present_state_chenge_fsm_SPI:process(reset , sclk)     --chenge present state
    begin   
        if(CPHA = '0' and sclk'event and sclk = '1')then
            if(reset ='1')then
                present_state_spi <= idle_fsm_spi       ;
            else
                present_state_spi <= next_state_spi     ;
                if(Count_state = '1')then
                    Count <= Count + 1 ;
                else 
                    Count <= 0          ;
                end if;
            end if;
        elsif(CPHA = '1' and sclk'event and sclk = '0')then
            if(reset ='1')then
                present_state_spi <= idle_fsm_spi       ;
            else
                present_state_spi <= next_state_spi     ;
                if(Count_state = '1')then
                    Count <= Count + 1 ;
                else 
                    Count <= 0          ;
                end if;
            end if;
        end if;
    end process present_state_chenge_fsm_SPI;

    next_state_chenge_fsm_SPI:process(present_state_spi , ss , Count)     --chenge next state
    begin   
        case present_state_spi is 
            -------------------------------------------------------        
            when idle_fsm_spi =>
                buffer_full <= 0 ;
                if(ss = '1')then                 
                    next_state_spi  <=  idle_fsm_spi    ;
                    SDO         <=  'Z'                 ;
                else    
                    next_state_spi  <=  tx_rx_spi       ;
                end if;
            -------------------------------------------------------        
            when tx_rx_spi =>
                if (Count < 8)then    
                    data_in_SDI(7-Count)    <=  SDI             ;            -- SDI = Slave DATA input
                    data_in_SDI_0           <=  data_in_SDI     ;            -- synchronizers source clock domain  
                    if(Count = 7)then
                        buffer_full <= 1;
                    else
                        buffer_full <= 0;
                    end if;
                end if;    
                if (ss = '1') then
                    next_state_spi  <=  idle_fsm_spi    ;
                else
                    next_state_spi  <=  tx_rx_spi       ;
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
        elsif(CPHA = '1' and sclk'event and sclk = '0')then
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
                valid_out   <= '0'               ;
                data_out    <=  (others => 'Z' ) ;
                next_state_axi  <=  wait_for_buffer_full_rise   ;
            -------------------------------------------------------        
            when wait_for_buffer_full_rise =>
                if (buffer_full = 1)then    
                    valid_out           <= '1'              ;
                    data_in_SDI_00      <=  data_in_SDI_0   ;       -- synchronizers destination clock domain                  
                    data_in_SDI_000     <=  data_in_SDI_00  ;       -- synchronizers destination clock domain                   
                    next_state_axi  <=  wait_for_ready_rise ;
            else    
                valid_out       <= '0'                          ;
                next_state_axi  <=  wait_for_buffer_full_rise   ;
            end if; 
            -------------------------------------------------------        
            when wait_for_ready_rise =>
                if (ready_in = '1')then 
                    data_out        <=  data_in_SDI_000     ;
                    next_state_axi  <=  wait_for_ready_fall ;
                else                   
                    next_state_axi  <=  wait_for_ready_rise   ;
                end if;
            -------------------------------------------------------        
            when wait_for_ready_fall =>
                if (ready_in = '0')then 
                    valid_out   <= '0'                  ;
                    data_out    <=  (others => 'Z' )    ;
                    next_state_axi  <=  wait_for_buffer_full_rise   ;
                else                   
                    next_state_axi  <=  wait_for_ready_fall   ;
                end if;
        end case;                
    end process next_state_chenge_fsm_AXI;
end behavioral;    
 