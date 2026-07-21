library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library work;
use work.HD_Package.ALL;

entity tb_PU is
end tb_PU;

architecture Behavioral of tb_PU is

    component PU
        generic (
            NBR_CLASS_NEXT_POW2 : natural;
            NBR_CLASS           : natural; -- Nombre de class
            VECTOR_WIDTH        : natural; -- Taille total des vecteurs
            SLICE_WIDTH         : natural  -- Taille des tranches
        );
        port (
            clk  : in std_logic;
            rstn : in std_logic;

            -- État du PU
            PU_start_input  : in  std_logic;

            -- Prédiction
            PU_predicted_class_idx_output : out std_logic_vector(log2c(NBR_CLASS - 1) - 1 downto 0);

            -- Index du vecteur de requête pour simulation
            MEM_addr_slice          : in std_logic_vector(log2c(VECTOR_WIDTH / SLICE_WIDTH - 1) - 1 downto 0);
            simu_PU_query_idx_input : in std_logic_vector(log2c(12 - 1) - 1 downto 0)
        );
    end component;

    -- Constantes
    constant CLK_PERIOD          : time := 2 ns;
    constant NBR_QUERY           : natural := 12;
    constant NBR_CLASS_NEXT_POW2 : natural := 32;
    constant NBR_CLASS           : natural := 22;
    constant VECTOR_WIDTH        : natural := 8192;
    constant SLICE_WIDTH         : natural := 32;
    -- constant NBR_QUERY           : natural := 5;
    -- constant NBR_CLASS_NEXT_POW2 : natural := 32;
    -- constant NBR_CLASS           : natural := 4;
    -- constant VECTOR_WIDTH        : natural := 192;
    -- constant SLICE_WIDTH         : natural := 16;
    
    -- Signaux internes
    signal clk            : std_logic;
    signal rstn           : std_logic;
    signal start          : std_logic;
    signal ready          : std_logic;
    signal prediction     : std_logic_vector(log2c(NBR_CLASS - 1) - 1 downto 0);
    signal simu_slice_idx : std_logic_vector(log2c(VECTOR_WIDTH / SLICE_WIDTH - 1) - 1 downto 0);
    signal simu_query_idx : std_logic_vector(log2c(12 - 1) - 1 downto 0);

begin

    U0 : PU
        generic map(
            NBR_CLASS_NEXT_POW2 => NBR_CLASS_NEXT_POW2,
            NBR_CLASS           => NBR_CLASS,
            VECTOR_WIDTH        => VECTOR_WIDTH,
            SLICE_WIDTH         => SLICE_WIDTH
        )
        port map(
            clk  => clk,
            rstn => rstn,

            PU_start_input  => start,

            PU_predicted_class_idx_output => prediction,

            MEM_addr_slice          => simu_slice_idx,
            simu_PU_query_idx_input => simu_query_idx
        );

    -- Génération d'horloge
    clk_process : process
    begin
        while true loop
            clk <= '0';
            wait for CLK_PERIOD / 2;
            clk <= '1';
            wait for CLK_PERIOD / 2;
        end loop;
    end process;

    -- Stimulis
    stim_proc : process
    begin
    
        -- Reset
        rstn   <= '0';
        simu_slice_idx <= (others => '0');
        simu_query_idx <= (others => '0');
        wait for 0.5 ns;
        rstn   <= '1';

        for i in 0 to NBR_QUERY - 1 loop

            wait for CLK_PERIOD;
            start <= '1';
            wait for CLK_PERIOD;
            start <= '0';

            simu_query_idx <= std_logic_vector(to_unsigned(i, simu_query_idx'length));

            for j in 0 to VECTOR_WIDTH / SLICE_WIDTH - 1 loop

                simu_slice_idx <= std_logic_vector(to_unsigned(j, simu_slice_idx'length));
                wait for CLK_PERIOD;

            end loop;

            wait for 5 ns;

        end loop;

        wait;

    end process;

end architecture;