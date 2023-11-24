library IEEE;
    use IEEE.STD_LOGIC_1164.all;
    use IEEE.NUMERIC_STD.all;
    use IEEE.NUMERIC_STD.all;

entity OneWireSlave is
    generic (
        F_CLK_MHZ : positive := 1
    );
    port (
        clk      : in  STD_LOGIC;
        data_in  : in  STD_LOGIC;
        data_out : out STD_LOGIC;

        -- data read from the slave to the master
        rd_data  : in  bit_vector(7 downto 0); -- must not change while rd_valid is held high
        rd_valid : in  boolean;                -- when the user has supplied the data in rx_data
        rd_ready : out boolean;                -- when the slave module is ready for new data

        -- data written to the slave from the master
        wr_data  : out bit_vector(7 downto 0) := b"00000000";
        wr_valid : out boolean                 -- when the data in wr_data is valid, for at least one clock cycle
    );
end entity;

architecture Behavioural of OneWireSlave is
    type state_type is (
            WAIT_FOR_RESET, WAIT_FOR_RESET_RELEASE,
            WAIT_FOR_PRESENCE, PRESENCE,
            DATA_WAIT_FOR_SAMPLE_TIME, SAMPLE, DATA_WAIT_FOR_REMAINING_WINDOW,
            IDLE
        );
    signal pr_state : state_type := WAIT_FOR_RESET;
    signal nx_state : state_type;

    signal timer     : natural              := 0;
    signal timer_max : natural              := 0;
    signal bit_idx   : natural range 0 to 7 := 0;

    -- high for one clock cycle at the end of each slot
    signal slot_end : boolean;

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
                if not data_in then
                    -- Detected start of a reset pulse
                    nx_state <= WAIT_FOR_RESET_RELEASE;
                else
                    nx_state <= WAIT_FOR_RESET;
                end if;
            when WAIT_FOR_RESET_RELEASE =>
                if data_in then
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
                    nx_state <= IDLE;
                else
                    nx_state <= PRESENCE;
                end if;
            when IDLE =>
                if not data_in then
                    nx_state <= DATA_WAIT_FOR_SAMPLE_TIME;
                else
                    nx_state <= IDLE;
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
                if data_in then
                    nx_state <= IDLE;
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
                data_out <= '0';
            when DATA_WAIT_FOR_SAMPLE_TIME | DATA_WAIT_FOR_REMAINING_WINDOW =>
                -- data <= bit that should be written; 
                data_out <= 'Z';
            when others =>
                data_out <= 'Z';
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

    -- slot ends when the state changes to idle
    slot_end <= pr_state = DATA_WAIT_FOR_REMAINING_WINDOW and nx_state = IDLE;

    rd_ready <= slot_end and bit_idx = 7;

    -- Bit counter and reads
    process (clk)
    begin
        if rising_edge(clk) then
            -- Read the written bit every sample time
            if pr_state = SAMPLE then
                wr_data(bit_idx) <= to_bit(data_in);
                wr_valid <= false;
            end if;

            -- Increment bit index every slot
            if slot_end then
                if bit_idx = 7 then
                    bit_idx <= 0;
                    wr_valid <= true;
                else
                    bit_idx <= bit_idx + 1;
                end if;
            end if;
        end if;
    end process;
end architecture;
