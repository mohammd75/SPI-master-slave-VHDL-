library IEEE;
use IEEE.std_logic_1164.all;

entity CLK_GENERATOR is
    generic (
        constant   CPOL         : std_logic := '0' ;    -- Polarity Clock in start SPI communication
        constant   clk_output   : integer   := 10 ;     -- clk_output  specifies the division coefficient to make the output clock
        constant   clk_input    : integer   := 100      -- Clock manufacturer SCLK (it is assumed) = 100 MHz
    );       
    port(
        ------------ input--------------------
        RESET_I       :   in    std_logic ;
        CLK_I         :   in    std_logic ;
        CLK_OUT_EN_I  :   in    std_logic ;
        ------------ output-------------------
        CLK_O         :   out   std_logic 
    );
end CLK_GENERATOR;

architecture BEHAVIORAL of CLK_GENERATOR is

    constant    clock_factor    : Natural := (clk_input / clk_output) ;
    signal      clk_div         : std_logic := CPOL ;       
    signal      count_clk       : Positive range 1 to clock_factor := 1 ;
 
    
begin

    CLK_DIV_label : process(CLK_I)    --generate clk SPI (in next Project of use clock_Wizard[MMCM])
    begin

        if(CLK_OUT_EN_I = '1')then
            if(CLK_I = '1' and CLK_I'event)then
                if(count_clk = (clock_factor/2) )then
                    count_clk   <= 1 ;
                    clk_div     <= not clk_div ;
                else
                    count_clk   <= count_clk + 1 ;
                end if;
            end if;
        else
            count_clk   <= 1 ;
            clk_div     <= CPOL ;       
        end if;

    end process CLK_DIV_label;    

    CLK_O   <= clk_div when CLK_OUT_EN_I = '1' else (not CPOL) ;

end architecture BEHAVIORAL;    