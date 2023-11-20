library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    use ieee.math_real.all;

    use std.env.finish;

entity OneWireSlaveTb is
end entity;

architecture test of OneWireSlaveTb is
    -- 100KHz/10us clock
    signal clk                 : STD_LOGIC := '1';
    signal data                : STD_LOGIC;
    signal master_release_time : delay_length;
    signal rx_value            : std_logic;

    procedure write_bit(signal data : out std_logic; constant value : in boolean) is
        variable slot_start : delay_length;
    begin
        slot_start := now;
        -- pull low
        data <= '0';
        if value then
            -- wait t1l
            wait for 10 us;
        else
            -- wait t0l
            wait for 60 us;
        end if;
        -- release
        data <= 'Z';
        -- wait for remaining tslot
        wait for (80 us + slot_start) - now;
    end procedure;

    procedure read_bit(signal data : inout std_logic; signal value : out std_logic) is
        variable slot_start : delay_length;
    begin
        slot_start := now;
        -- pull low
        data <= '0';
        -- wait tRL
        wait for 5 us;
        -- release
        data <= 'Z';
        -- wait for tMSR after slot start
        wait for 10 us;
        value <= data;
        -- wait for remaining tslot
        wait for (80 us + slot_start) - now;
    end procedure;
begin
    -- Instantiate DUT
    dut: entity work.OneWireSlave
        port map (
            clk  => clk,
            data => data
        );

    clk  <= not clk after 5 us;
    data <= 'H'; -- weak pullup

    -- Generate the test stimulus

    test: process
    begin
        wait for 20 us;
        -- reset pulse  tRSTL (480us to 640us)
        data <= '0';
        wait for 480 us;
        data <= 'Z';
        master_release_time <= now;

        -- wait for tMSP (min 68us max 75us)
        wait for 70 us;
        -- check for presence
        if data = '1' or data = 'H' then
            -- slave not found
            report "slave not found" severity failure;
        end if;

        -- wait for tRSTH since we went high-impedance
        wait for (master_release_time + 480 us) - now;

        -- Can start data communications now
        read_bit(data, rx_value);
        report "got value " & to_string(rx_value);
        -- Testing complete
        report "##### TESTBENCH COMPLETE #####";
        finish;
    end process;

end architecture;
