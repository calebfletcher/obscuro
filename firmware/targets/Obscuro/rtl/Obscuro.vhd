library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


library xpm;
use xpm.vcomponents.all;

entity Obscuro is
    port (
        a : in STD_LOGIC;
        b : in STD_LOGIC;
        q : out STD_LOGIC
    );
end Obscuro;


architecture Behavioural of Obscuro is
begin
    q <= a and b;
end Behavioural;
