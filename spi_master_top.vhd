library ieee;
use ieee.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;

entity SPI_MASTER_TOP is
    generic (
        constant    DATA_IN_LENGTH  : natural   := 8 ;         -- data is n bit
        constant    buad_rate_spi   : integer   := 10 ;        -- buad rate= bit rate= buad_rate_spi (Mbit/s) ===> buad_rate_spi (default) = 10MHz
        constant    clk_input       : integer   := 100 ;       -- Clock manufacturer SCLK (it is assumed) = 100 MHz 
        constant    CPOL            : std_logic := '0' ;       -- polarity in st_idle state
        constant    CPHA            : std_logic := '0'         -- edge of clock in sampled data
    );    
    port (
        RESET_I     :   in      std_logic ;
        CLK_I       :   in      std_logic ;
        DATA_I      :   in      std_logic_vector(data_in_length-1 downto 0) ;
        VALID_I     :   in      std_logic ;
        READY_O     :   out     std_logic ;
    ----------------------spi----------------------
        SDO         :   out     std_logic ;    
        SDI         :   in      std_logic ;
        SS          :   out     std_logic ;
        SCLK        :   out     std_logic   
    );
end SPI_MASTER_TOP;

architecture STRUCTRUAL of SPI_MASTER_TOP is

    component SPI_MASTER is
        generic (
            constant   data_in_length  : natural   :=  DATA_IN_LENGTH ;         
            constant   CPOL            : std_logic :=  CPOL ;                    
            constant   CPHA            : std_logic :=  CPHA ;                    
            constant   buad_rate_spi   : integer   :=  buad_rate_spi ;          
            constant   clk_input       : integer   :=  clk_input                
        );     
        port (
            RESET_I        :   in      std_logic   ;
            CLK_I          :   in      std_logic   ;
            DATA_I         :   in      std_logic_vector(data_in_length-1 downto 0);
            VALID_I        :   in      std_logic   ;
            READY_O        :   out     std_logic   ;
            ----------------------spi-------------------------------------------
            SDO            :   out     std_logic   ;                            --ss:slave select active low
            SDI            :   in      std_logic   ;
            SS             :   out     std_logic   ; 
            SCLK_EN_O      :   out     std_logic    

        );
    end component;

    component CLK_GENERATOR is
        generic (
            constant   CPOL         : std_logic := '0' ;                
            constant   clk_output   : integer   :=  buad_rate_spi  ;    -- clk_output  specifies the division coefficient to make the output clock
            constant   clk_input    : integer   :=  clk_input           -- Clock manufacturer SCLK (it is assumed) = 100 MHz
        ); 
        port(
            RESET_I       :   in    std_logic ;
            CLK_I         :   in    std_logic ;
            CLK_OUT_EN_I  :   in    std_logic ;
            CLK_O         :   out   std_logic 
        );
    end component;

    signal sclk_en_im  : std_logic ; 
  
begin

    SPI_MASTER_I0 : SPI_MASTER 
        port map(
            RESET_I     => RESET_I,
            CLK_I       => CLK_I,
            DATA_I      => DATA_I,
            VALID_I     => VALID_I,
            READY_O     => READY_O,
            SDO         => SDO,
            SDI         => SDI,
            SS          => SS,
            SCLK_EN_O   => sclk_en_im
        ); 

    CLK_GENERATOR_I0 : CLK_GENERATOR 
        port map (
            RESET_I         =>  RESET_I,           
            CLK_I           =>  CLK_I,      
            CLK_OUT_EN_I    =>  sclk_en_im,
            CLK_O           =>  SCLK      
        ); 

end architecture STRUCTRUAL;