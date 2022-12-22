library ieee;
use ieee.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;

entity TOP is
    generic (
        constant    DATA_IN_LENGTH   : natural   := 8 ;            -- data is N bit
        constant    CPOL             : std_logic := '0' ;          -- polarity in st_idle state
        constant    CPHA             : std_logic := '0' ;          -- edge of clock in sampled data
        constant    buad_rate_spi    : integer   := 10 ;           -- buad rate= bit rate= buad_rate_spi (Mbit/s) ===> buad_rate_spi (default) = 10MHz
        constant    clk_input        : integer   := 100            -- Clock manufacturer SCLK (it is assumed) = 100 MHz 
    );    
    port (
        RESET_TOP   :   in      std_logic   ;
        CLK_TOP     :   in      std_logic   ;
        ENABLE_TOP  :   in      std_logic   ;   
        ERROR_TOP   :   out     std_logic_vector(3 downto 0)          
    );
end TOP;

architecture STRUCTRUAL of TOP is

    component  COUNTER is
        generic( 
            number_of_bit : integer := DATA_IN_LENGTH        -- Counter is n bit
        );     
        port (
            enable      : in     std_logic   ;
            reset       : in     std_logic   ;
            clk         : in     std_logic   ;
            ready_in    : in     std_logic   ;
            valid_out   : out    std_logic   ;
            data_out    : out    std_logic_vector(number_of_bit-1 downto 0)
        );
    end component;

    component SPI_MASTER_TOP is
        generic (
            constant    DATA_IN_LENGTH  : natural       :=  DATA_IN_LENGTH ;     
            constant    buad_rate_spi   : integer       :=  buad_rate_spi ;      
            constant    clk_input       : integer       :=  clk_input ;           
            constant    CPOL            : std_logic     :=  CPOL ;       
            constant    CPHA            : std_logic     :=  CPHA        
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
    end component;

    component SPI_SLAVE is
        generic (
            constant data_in_length     : natural   := DATA_IN_LENGTH ;   
            constant CPOL               : std_logic := CPOL ;             
            constant CPHA               : std_logic := CPHA               
        );     
        port (
            reset      : in    std_logic ;
            clk        : in    std_logic ;    
            SDO        : out   std_logic ;   
            SDI        : in    std_logic ;    
            sclk       : in    std_logic ; 
            ss         : in    std_logic ;
            data_out   : out   std_logic_vector(data_in_length-1 downto 0) ;
            valid_out  : out   std_logic ;
            ready_in   : in    std_logic 
        );
    end component;

    component ERROR_CHECK is
        generic (
            constant N  : integer := DATA_IN_LENGTH
        );
        port (
            CLK_I     :   in    std_logic ;
            RESET_I   :   in    std_logic ;
            VALID_I   :   in    std_logic ;
            DATA_I    :   in    std_logic_vector(n-1 downto 0) ;
            ERROR_O   :   out   std_logic_vector(  3 downto 0) ;
            READY_O   :   out   std_logic
        );
    end component;

    signal valid_counter_im     : std_logic :='0'   ; 
    signal ready_counter_im     : std_logic :='0'   ;
    signal data_counter_im      : std_logic_vector(DATA_IN_LENGTH-1 downto 0) := (others => '0');

    signal SDI_master_im    : std_logic :='0' ;
    signal SDO_master_im    : std_logic :='0' ;
    signal ss_im            : std_logic :='0' ;
    signal sclk_im          : std_logic :='0' ;

    signal valid_error_check_im : std_logic :='0'   ; 
    signal ready_error_check_im : std_logic :='0'   ;
    signal data_error_check_im  : std_logic_vector(DATA_IN_LENGTH-1 downto 0) := (others => '0');

begin

    COUNTER_I0 : COUNTER 
        port map (
            enable     => enable_top,
            reset      => reset_top, 
            clk        => clk_top,   
            ready_in   => ready_counter_im, 
            valid_out  => valid_counter_im, 
            data_out   => data_counter_im       
        );  

    SPI_MASTER_TOP_I0 : SPI_MASTER_TOP 
        port map(
            RESET_I     => reset_top,
            CLK_I       => clk_top,
            DATA_I      => data_counter_im,
            VALID_I     => valid_counter_im,
            READY_O     => ready_counter_im,
            SDO         => SDO_master_im,
            SDI         => SDI_master_im,
            SS          => ss_im,
            SCLK        => sclk_im
        ); 

    SPI_SLAVE_I0 : SPI_SLAVE 
        port map(
            reset        => reset_top,
            clk          => clk_top,
            SDO          => SDI_master_im,
            SDI          => SDO_master_im,
            sclk         => sclk_im,
            ss           => ss_im,
            data_out     => data_error_check_im,
            valid_out    => valid_error_check_im,
            ready_in     => ready_error_check_im
        );                            
                               
 
        
    ERROR_CHECK_I0 : ERROR_CHECK 
        port map (
            CLK_I     =>  clk_top,  
            RESET_I   =>  reset_top,
            VALID_I   =>  valid_error_check_im,  
            DATA_I    =>  data_error_check_im,   
            ERROR_O   =>  ERROR_TOP,  
            READY_O   =>  ready_error_check_im     
        ); 

end architecture STRUCTRUAL;