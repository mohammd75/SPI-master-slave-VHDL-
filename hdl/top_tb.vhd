library ieee;
use ieee.std_logic_1164.all;

entity TOP_TB is
end;

architecture TESTBENCH of TOP_TB is
    component TOP
        generic (
            constant DATA_IN_LENGTH   : natural  := 8     -- data is n bit
        );     
        port(
            RESET_TOP   :   in      std_logic   ;
            CLK_TOP     :   in      std_logic   ;
            ENABLE_TOP  :   in      std_logic   ;   
            ERROR_TOP   :   out     std_logic_vector(3 downto 0)                  
        );
    end component;

signal reset_tb     : std_logic :='0' ; 
signal clk_tb       : std_logic :='0' ;
signal enable_tb    : std_logic :='0' ;
signal error_tb     : std_logic_vector(3 downto 0)   := (others => '0') ;

constant T_10      : time    := 10  ns ;
constant T_250     : time    := 250  ns;

signal  count : Positive range 1 to 5 := 1;

begin

    TOP_I0 : TOP
        port map (
            RESET_TOP   => reset_tb,
            CLK_TOP     => clk_tb,
            ENABLE_TOP  => enable_tb,
            ERROR_TOP   => error_tb
        );

process
begin
    clk_tb  <= '0' ;
    wait for T_10/2;
    clk_tb  <= '1' ;
    wait for T_10/2;
end process;



reset_tb  <= '1'  , '0' after (T_10)/2   ;
enable_tb <=  '0' , '1' after (3*T_10)/2 ; 
  
end architecture TESTBENCH;