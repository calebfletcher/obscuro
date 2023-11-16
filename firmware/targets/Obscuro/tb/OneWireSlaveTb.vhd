library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use ieee.math_real.all;

    use std.env.finish;

entity OneWireSlaveTb is
end entity;

architecture test of OneWireSlaveTb is
    signal CLK100MHZ : STD_LOGIC := '1';
    signal data      : STD_LOGIC;
begin
    -- Instantiate DUT
    dut: entity work.OneWireSlave
        port map (
            CLK100MHZ => CLK100MHZ,
            data      => data
        );

    CLK100MHZ <= not CLK100MHZ after 5 us;
    data      <= 'H'; -- weak pullup

    -- Generate the test stimulus

    test: process
        variable master_release_time : delay_length;
    begin
        wait for 20 us;
        -- reset pulse  tRSTL (480us to 640us)
        data <= '0';
        wait for 480 us;
        data <= 'Z';
        master_release_time := now;

        -- wait for tMSP (min 68us max 75us)
        wait for 70 us;
        -- check for presence
        if data = '1' or data = 'H' then
            -- slave not found
            report "slave not found" severity failure;
        end if;

        -- wait for tRSTH since we went high-impedance
        wait for 480 us - master_release_time;

        -- Can start data communications now
        --data <= '0';
        -- Testing complete
        report "##### TESTBENCH COMPLETE #####";
        finish;
    end process;

end architecture;
