library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

use std.env.finish;

entity ObscuroTb is
end entity ObscuroTb;

architecture test of ObscuroTb is
    signal and_in : std_logic_vector(1 downto 0) := (others => '0');
    alias in_a is and_in(0);
    alias in_b is and_in(1);
    signal out_q  : std_logic;
begin
    -- Instantiate DUT
    dut: entity work.Obscuro
    port map (
        a => in_a,
        b => in_b,
        q => out_q
    );

    -- Generate the test stimulus
    test: process begin
        -- Generate each of in turn, waiting 2 clock periods between

        -- each iteration to allow for propagation times
        and_in <= "00";
        wait for 2 ns;
        and_in <= "01";
        wait for 2 ns;
        and_in <= "10";
        wait for 2 ns;
        and_in <= "11";

        -- Testing complete
        report "##### TESTBENCH COMPLETE #####";
        finish;
    end process test;

end architecture;