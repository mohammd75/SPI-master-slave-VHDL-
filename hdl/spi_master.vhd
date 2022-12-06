library IEEE;
use IEEE.std_logic_1164.all;

entity spi_master is
    generic (
        constant   data_in_length  : natural   :=  8 ;     --data is n bit
        constant   CPOL            : std_logic := '0';     --polarity in st_idle state
        constant   CPHA            : std_logic := '0';     --edge of clock in sampled data
        constant   k               : integer   :=  5       --buad rate= bit rate= 10Mbit/s (assune clk=100MHz) ===> clk/2k=clk_spi
    );     
    port(
        reset          :   in      std_logic   ;
        clk            :   in      std_logic   ;
        ----------------------input--------------------------------------------
        data_in        :   in      std_logic_vector(data_in_length-1 downto 0);
        valid_in       :   in      std_logic   ;
        ready_out      :   out     std_logic   ;
        ----------------------output-------------------------------------------
        SDO            :   out     std_logic   ;     --ss:slave select active low
        SDI            :   in      std_logic   ;
        ss             :   out     std_logic   ;
        sclk           :   out     std_logic   
    );
end spi_master;

architecture behavioral of spi_master is

signal clk_spi          : std_logic := '0';
signal count_clk_spi    : Positive range 1 to k := 1;

type   state is (idle , wait_for_start , wait_for_valid_rise , st_tx_rx_spi);
signal present_state , next_state : state ;

signal Count            : Natural       range 0 to data_in_length   := 0 ;
signal Count_state      : std_logic     := '0' ;
signal data_in_0        : std_logic_vector (data_in_length-1 downto 0)   ;
signal data_in_00        : std_logic_vector (data_in_length-1 downto 0)   ;


begin

    CLK_div: process(clk)    --generate clk SPI (in next Project of use clock_Wizard[MMCM])
    begin
        if(clk='1' and clk'event)then
            if (count_clk_spi = k)then
                count_clk_spi <= 1;
                clk_spi <= not clk_spi;
            else
            count_clk_spi <= count_clk_spi +1;
            end if;
        end if;            
    end process CLK_div;    

    present_state_chenge:process(clk_spi)     --chenge present state
    begin   
        if(CPHA = '0' and clk_spi'event and clk_spi = '0')then
            if(reset ='1')then
                present_state <= idle ;
            else
                present_state <= next_state;
                if(Count_state = '1')then
                    Count <= Count + 1 ;
                else 
                    Count <= 0        ;
                end if;
            end if;
        ------------------------------------------------------------
        elsif(CPHA = '1' and clk_spi'event and clk_spi = '1')then
            if(reset ='1')then
                present_state <= idle ;
            else
                present_state <= next_state;
                if(Count_state = '1')then
                    Count <= Count + 1 ;
                else 
                    Count <= 0        ;
                end if;
            end if;
        end if;
    end process present_state_chenge;

    next_state_chenge:process(present_state ,valid_in , Count)     --chenge next state
    variable    start   : Integer   := 0;
    begin   
        case present_state is 
            -------------------------------------------------------        
            when idle =>
                ready_out   <=  '0'     ;       
                SDO         <=  'Z'     ;
                ss          <=  '1'     ;
                ---------------------------------
                next_state  <= wait_for_start  ;
                start       := 1               ;
            ------------------------------------------------------- 
            when wait_for_start =>
                if(start = 1)then
                    next_state  <= wait_for_valid_rise  ;
                    ready_out   <=  '1'                 ;
                else
                    next_state  <= wait_for_start       ;
                end if;            
            ------------------------------------------------------- 
            -- when wait_for_ready_rise =>
            --     if(ready_out = '1')then
            --         next_state  <= wait_for_valid_rise  ;
            --     else
            --         next_state  <= wait_for_ready_rise  ;
            --     end if;
            -- ------------------------------------------------------- 
            when wait_for_valid_rise =>
                if(valid_in = '1')then
                    data_in_0   <=  data_in     ;
                    data_in_00  <=  data_in_0   ;
                    ready_out   <=  '0'         ;
                    next_state  <= st_tx_rx_spi ;
                else
                    next_state  <= wait_for_valid_rise ;
                end if;
            ------------------------------------------------------- 
            when st_tx_rx_spi =>
                if (Count < 8)then 
                    SDO         <= data_in_00(7-Count)  ;   
                    ss          <=  '0'                 ; 
                    Count_state <=  '1'                 ;
                    --------------------------------------
                    next_state  <= st_tx_rx_spi         ;
                else    
                    ready_out   <=  '1'         ;
                    SDO         <=  'Z'         ;
                    ss          <=  '1'         ;
                    Count_state <=  '0'         ;
                    --------------------------------------
                    next_state  <=  wait_for_valid_rise ; 
                end if; 
        end case;                
    end process next_state_chenge;   

sclk <= CPOL when present_state = idle else clk_spi;

end behavioral;    