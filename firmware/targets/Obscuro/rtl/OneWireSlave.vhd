library IEEE;
    use IEEE.STD_LOGIC_1164.all;
    use IEEE.NUMERIC_STD.all;
    use IEEE.NUMERIC_STD.all;

entity OneWireSlave is
    port (
        -- 100KHz/10us clock
        clk  : in    STD_LOGIC;
        data : inout STD_LOGIC
    );
end entity;

architecture Behavioural of OneWireSlave is
begin
    data <= 'Z';

    process (clk)
    begin
        if rising_edge(clk) then
            if data = '0' or data = 'L' then
                report "detected low";

                -- wait for tPDH (15us-60us)
                -- pull low for presence signal
                -- wait for tPDL (60us-240us)
                -- 
            end if;
        end if;
    end process;
end architecture;
