library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use ieee.math_real.all;

    use std.env.finish;

entity ObscuroTb is
end entity;

architecture test of ObscuroTb is
    signal CLK100MHZ : STD_LOGIC                    := '0';
    signal ck_rst    : STD_LOGIC                    := '1';
    signal btn       : STD_LOGIC_VECTOR(0 downto 0) := (others => '0');
    signal led       : STD_LOGIC_VECTOR(0 downto 0) := (others => '0');
begin
    -- Instantiate DUT
    dut: entity work.Obscuro
        port map (
            CLK100MHZ => CLK100MHZ,
            ck_rst    => ck_rst,
            btn       => btn,
            led       => led
        );

    CLK100MHZ <= not CLK100MHZ after 10 ns;
    ck_rst    <= '1', '0' after 50 ns;

    -- Generate the test stimulus

    test: process
    begin
        -- Wait for the Reset to be released before
        wait until (ck_rst = '0');

        -- Generate each of in turn, waiting 2 clock periods between
        -- each iteration to allow for propagation times
        -- and_in <= "00";
        -- wait for 2 ns;
        -- and_in <= "01";
        -- wait for 2 ns;
        -- and_in <= "10";
        -- wait for 2 ns;
        -- and_in <= "11";
        -- Testing complete
        report "##### TESTBENCH COMPLETE #####";
        finish;
    end process;

end architecture;
