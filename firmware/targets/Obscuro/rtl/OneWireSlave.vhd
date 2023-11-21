library IEEE;
    use IEEE.STD_LOGIC_1164.all;
    use IEEE.NUMERIC_STD.all;
    use IEEE.NUMERIC_STD.all;

entity OneWireSlave is
    generic (
        F_CLK_KHZ : natural := 100
    );
    port (
        -- 100KHz/10us clock
        clk  : in    STD_LOGIC;
        data : inout STD_LOGIC
    );
end entity;

architecture Behavioural of OneWireSlave is
    type state_type is (WAIT_FOR_RESET, WAIT_FOR_RESET_RELEASE, WAIT_FOR_PRESENCE, PRESENCE, WAIT_FOR_COMMAND);
    signal pr_state : state_type := WAIT_FOR_RESET;
    signal nx_state : state_type;

    signal timer     : natural := 0;
    signal timer_max : natural := 0;

    -- family is 0x28
    --constant ID : std_logic_vector := x"E800000B1FCD1028";
begin
    -- Register for state
    process (clk)
    begin
        if rising_edge(clk) then
            pr_state <= nx_state;
        end if;
    end process;

    -- Logic for state transitions
    process (all)
    begin
        case pr_state is
            when WAIT_FOR_RESET =>
                if not data then
                    -- Detected start of a reset pulse
                    nx_state <= WAIT_FOR_RESET_RELEASE;
                else
                    nx_state <= WAIT_FOR_RESET;
                end if;
            when WAIT_FOR_RESET_RELEASE =>
                if data then
                    -- Detected end of a reset pulse
                    nx_state <= WAIT_FOR_PRESENCE;
                else
                    nx_state <= WAIT_FOR_RESET_RELEASE;
                end if;
            when WAIT_FOR_PRESENCE =>
                if timer = timer_max then
                    nx_state <= PRESENCE;
                end if;
            when PRESENCE =>
                nx_state <= WAIT_FOR_COMMAND;
                -- TODO: set a timeout?
            when WAIT_FOR_COMMAND =>
        end case;
    end process;

    -- Logic for output
    process (all)
    begin
        if pr_state = PRESENCE then
            data <= '0';
        else
            data <= 'Z';
        end if;
    end process;

    -- Timer
    process (all)
    begin
        case pr_state is
            when WAIT_FOR_PRESENCE =>
                -- wait for tPDH (15us-60us)
                timer_max <= 3;
            when PRESENCE =>
                timer_max <= 10;
                -- wait for tPDL (60us-240us)
            when others =>
                -- TODO: Minimum reset pulse duration check?
                -- TODO: set a timeout for waiting for command?
                timer_max <= 0;
        end case;

        if rising_edge(clk) then
            if pr_state /= nx_state then
                -- state transition, reset timer
                timer <= 0;
            elsif timer /= timer_max then
                timer <= timer + 1;
            end if;
        end if;
    end process;

end architecture;
