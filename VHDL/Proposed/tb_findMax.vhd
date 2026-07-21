library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library work;
use work.HD_Package.ALL;

entity tb_findMax is
end tb_findMax;

architecture Behavioral of tb_findMax is

    component findMax
        generic (
            NBR_CLASS_NEXT_POW2 : natural;
            VECTOR_WIDTH        : natural
        );
        port (
            findmax_active_input  : in  std_logic_vector(NBR_CLASS_NEXT_POW2 - 1 downto 0);
            findmax_data_input    : in  std_logic_vector(NBR_CLASS_NEXT_POW2 * log2c(VECTOR_WIDTH) - 1 downto 0);

            findmax_maxIdx_output : out std_logic_vector(log2c(NBR_CLASS_NEXT_POW2 - 1) - 1 downto 0)
            );
    end component;

    -- Constantes
    constant CLK_PERIOD          : time := 2 ns;
    constant NBR_CLASS_NEXT_POW2 : natural := 8;
    constant VECTOR_WIDTH        : natural := 255;
    constant NBR_TEST            : natural := 2;
    
    -- Signaux internes
    signal clk    : std_logic := '0';
    signal active : std_logic_vector(NBR_CLASS_NEXT_POW2 - 1 downto 0) := (others => '1');
    signal din    : std_logic_vector(NBR_CLASS_NEXT_POW2 * log2c(VECTOR_WIDTH) - 1 downto 0) := (others => '0');
    signal maxIdx : std_logic_vector(log2c(NBR_CLASS_NEXT_POW2 - 1) - 1 downto 0);

begin

    U0 : findMax
        generic map(
            NBR_CLASS_NEXT_POW2 => NBR_CLASS_NEXT_POW2,
            VECTOR_WIDTH        => VECTOR_WIDTH
        )
        port map(
            findmax_active_input  => active,
            findmax_data_input    => din,

            findmax_maxIdx_output => maxIdx
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
        wait;
    end process;

    -- Stimulis
    stim_proc : process
    begin

        -- État initial
        wait for 3 ns;
        wait until rising_edge(clk);
    
        -- Comparaison entre :  55 / 165 / 99 / 229 / 81 / 201 / 14 / 21
        -- Index le plus grand : 3
        active <= "00000000";
        din <= x"37A563E551C90E15";

        -- Attente
        wait for 6 ns;
        wait until rising_edge(clk);

        -- Comparaison entre :  158 / 93 / 33 / 208 / 221 / 3 / 190
        -- Index le plus grand : 4
        active <= "11110111";
        din <= x"9E5D21D0DD03BEA8";

        -- Attente
        wait for 6 ns;
        wait until rising_edge(clk);

        -- Comparaison entre :
        -- Index le plus grand : 0
        active <= "00100100";
        din <= x"fa2e97e8e2c17335";

        -- Attente
        wait for 6 ns;
        wait until rising_edge(clk);

        -- Comparaison entre :
        -- Index le plus grand : 6
        active <= "10000000";
        din <= x"d5688853522af598";

        -- Attente
        wait for 6 ns;
        wait until rising_edge(clk);

        -- Comparaison entre :
        -- Index le plus grand : 0
        active <= "11111111";
        din <= x"0100000000000000";

        -- Attente
        wait for 6 ns;
        wait until rising_edge(clk);

        -- Comparaison entre :
        -- Index le plus grand : 7
        din <= x"0000000000000001";
    end process;
        
end architecture;

