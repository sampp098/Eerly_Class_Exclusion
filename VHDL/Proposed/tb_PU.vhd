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
            NBR_CLASS     : natural; -- Nombre de class
            VECTOR_WIDTH  : natural; -- Taille total des vecteurs
            SLICE_WIDTH   : natural; -- Taille des tranches
            SEGMENT_WIDTH : natural  -- Taille des segments
        );
        port (
            clk  : in std_logic;
            rstn : in std_logic;

            -- État du PU
            PU_start_input  : in  std_logic;
            PU_ready_output : out std_logic;

            -- Prédiction
            PU_predicted_class_idx_output : out std_logic_vector(log2c(NBR_CLASS - 1) - 1 downto 0);

            -- Index du vecteur de requête pour simulation
            simu_PU_query_idx_input : in std_logic_vector(log2c(12 - 1) - 1 downto 0)
        );
    end component;

    -- Constantes
    constant CLK_PERIOD    : time := 2 ns;
    constant NBR_QUERY     : natural := 12;
    constant NBR_CLASS     : natural := 22;
    constant VECTOR_WIDTH  : natural := 8192;
    constant SLICE_WIDTH   : natural := 32;
    constant SEGMENT_WIDTH : natural := 256;
    -- constant NBR_QUERY       : natural := 5;
    -- constant NBR_CLASS       : natural := 4;
    -- constant VECTOR_WIDTH    : natural := 192;
    -- constant SLICE_WIDTH     : natural := 16;
    -- constant SEGMENT_WIDTH   : natural := 48;
    
    -- Signaux internes
    signal clk            : std_logic;
    signal rstn           : std_logic;
    signal start          : std_logic;
    signal ready          : std_logic;
    signal prediction     : std_logic_vector(log2c(NBR_CLASS - 1) - 1 downto 0);
    signal simu_query_idx : std_logic_vector(log2c(12 - 1) - 1 downto 0);

begin

    U0 : PU
        generic map(
            NBR_CLASS     => NBR_CLASS,
            VECTOR_WIDTH  => VECTOR_WIDTH,
            SLICE_WIDTH   => SLICE_WIDTH,
            SEGMENT_WIDTH => SEGMENT_WIDTH
        )
        port map(
            clk  => clk,
            rstn => rstn,

            PU_start_input  => start,
            PU_ready_output => ready,

            PU_predicted_class_idx_output => prediction,

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
        simu_query_idx <= (others => '0');
        wait for 0.5 ns;
        rstn   <= '1';
        --wait for 1 ns;

        for i in 0 to NBR_QUERY - 1 loop

            wait for CLK_PERIOD;
            start <= '1';
            wait for CLK_PERIOD;
            start <= '0';

            simu_query_idx <= std_logic_vector(to_unsigned(i, simu_query_idx'length));

            wait until ready = '1';

        end loop;

        wait;

    end process;

end architecture;