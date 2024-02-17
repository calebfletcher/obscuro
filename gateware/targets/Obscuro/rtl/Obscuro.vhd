library IEEE;
    use IEEE.STD_LOGIC_1164.all;
    use IEEE.NUMERIC_STD.all;
    use IEEE.NUMERIC_STD.all;

entity Obscuro is
    port (
        CLK100MHZ : in  STD_LOGIC;
        ck_rst    : in  STD_LOGIC;
        btn       : in  STD_LOGIC_VECTOR(0 downto 0);
        led       : out STD_LOGIC_VECTOR(0 downto 0)
    );
end entity;

architecture Behavioural of Obscuro is
    signal counter : STD_LOGIC_VECTOR(3 downto 0);
begin
    led(0) <= CLK100MHZ;

    process (CLK100MHZ)
    begin
        if rising_edge(CLK100MHZ) then
            if ck_rst = '0' then
                -- Reset
                counter <= "0";
            else
                -- Normal operation
                --counter <= counter + std_logic_vector(1);
            end if;
        end if;
    end process;
end architecture;
