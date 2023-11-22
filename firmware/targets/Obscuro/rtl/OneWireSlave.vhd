library IEEE;
    use IEEE.STD_LOGIC_1164.all;
    use IEEE.NUMERIC_STD.all;
    use IEEE.NUMERIC_STD.all;

entity OneWireSlave is
    generic (
        F_CLK_MHZ : positive := 1
    );
    port (
        clk  : in    STD_LOGIC;
        data : inout STD_LOGIC
    );
end entity;

architecture Behavioural of OneWireSlave is
    type state_type is (
            WAIT_FOR_RESET, WAIT_FOR_RESET_RELEASE,
            WAIT_FOR_PRESENCE, PRESENCE,
            DATA_WAIT_FOR_FALL, DATA_WAIT_FOR_SAMPLE_TIME,
            SAMPLE, DATA_WAIT_FOR_REMAINING_WINDOW,
        );
    signal pr_state : state_type := WAIT_FOR_RESET;
    signal nx_state : state_type;

    signal timer     : natural := 0;
    signal timer_max : natural := 0;

    signal bits_read : natural range 0 to 7         := 0;
    signal rx_byte   : std_logic_vector(7 downto 0) := "00000000";

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
                else
                    nx_state <= WAIT_FOR_PRESENCE;
                end if;
            when PRESENCE =>
                if timer = timer_max then
                    nx_state <= DATA_WAIT_FOR_FALL;
                else
                    nx_state <= PRESENCE;
                end if;
            when DATA_WAIT_FOR_FALL =>
                if not data then
                    nx_state <= DATA_WAIT_FOR_SAMPLE_TIME;
                else
                    nx_state <= DATA_WAIT_FOR_FALL;
                end if;
            when DATA_WAIT_FOR_SAMPLE_TIME =>
                if timer = timer_max then
                    nx_state <= SAMPLE;
                else
                    nx_state <= DATA_WAIT_FOR_SAMPLE_TIME;
                end if;
            when SAMPLE =>
                nx_state <= DATA_WAIT_FOR_REMAINING_WINDOW;
            when DATA_WAIT_FOR_REMAINING_WINDOW =>
                if data then
                    nx_state <= DATA_WAIT_FOR_FALL;
                else
                    nx_state <= DATA_WAIT_FOR_REMAINING_WINDOW;
                end if;
        end case;
    end process;

    -- Logic for output
    process (all)
    begin
        case pr_state is
            when PRESENCE =>
            data <= '0';
            when DATA_WAIT_FOR_SAMPLE_TIME | DATA_WAIT_FOR_REMAINING_WINDOW =>
                -- data <= bit that should be written; 
                data <= 'Z';
            when others =>
            data <= 'Z';
        end case;
    end process;

    -- Timer
    process (all)
    begin
        case pr_state is
            when WAIT_FOR_PRESENCE =>
                -- wait for tPDH (15us-60us)
                timer_max <= 30 * F_CLK_MHZ;
            when PRESENCE =>
                -- wait for tPDL (60us-240us)
                timer_max <= 100 * F_CLK_MHZ;
            when DATA_WAIT_FOR_SAMPLE_TIME =>
                -- wait for between tW0Lmin and tW1Lmax (15us-60us)
                timer_max <= 30 * F_CLK_MHZ;
            when others =>
                -- TODO: Minimum reset pulse duration check?
                -- TODO: set a timeout for waiting for command?
                timer_max <= 0 * F_CLK_MHZ;
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
