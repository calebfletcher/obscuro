library IEEE;
    use IEEE.STD_LOGIC_1164.all;
    use IEEE.NUMERIC_STD.all;
    use IEEE.NUMERIC_STD.all;

entity OneWireSlave is
    port (
        CLK100MHZ : in    STD_LOGIC;
        data      : inout STD_LOGIC
    );
end entity;

architecture Behavioural of OneWireSlave is
    --signal counter : STD_LOGIC_VECTOR(3 downto 0);
begin
    data <= 'Z';

    process (CLK100MHZ)
    begin
        if rising_edge(CLK100MHZ) then
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
