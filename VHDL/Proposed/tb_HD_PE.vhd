library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library work;
use work.HD_Package.ALL;

entity tb_HD_PE is
end tb_HD_PE;

architecture Behavioral of tb_HD_PE is

    component HD_PE
        generic(
            VECTOR_WIDTH : natural;
            SLICE_WIDTH  : natural -- Doit être une puissance de 2
        );
        port(
            clk                 : in  std_logic;
            rstn                : in  std_logic;
            PE_acc_clear_input  : in  std_logic;
            PE_acc_enable_input : in  std_logic;
            PE_slice_input_BHV  : in  std_logic_vector(SLICE_WIDTH - 1 downto 0);
            PE_slice_input_QHV  : in  std_logic_vector(SLICE_WIDTH - 1 downto 0);
    
            PE_HamDist_output   : out std_logic_vector(log2c(VECTOR_WIDTH) - 1 downto 0)
        );
    end component;

    -- Constantes
    constant CLK_PERIOD   : time := 2 ns;
    constant NBR_TEST     : natural := 2;
    constant VECTOR_WIDTH : natural := 128;
    constant SLICE_WIDTH  : natural := 32;
    constant NBR_ACC      : natural := VECTOR_WIDTH / SLICE_WIDTH;
    
    
    -- Signaux internes
    signal clk        : std_logic := '0';
    signal rstn       : std_logic := '0';
    signal acc_clear  : std_logic := '0';
    signal acc_enable : std_logic := '0';
    signal slice_BHV  : std_logic_vector(SLICE_WIDTH - 1 downto 0) := (others => '0');
    signal slice_QHV  : std_logic_vector(SLICE_WIDTH - 1 downto 0) := (others => '0');
    signal HamDist    : std_logic_vector(log2c(VECTOR_WIDTH) - 1 downto 0) := (others => '0');

    -- Vecteurs de test
    type vector_array is array(0 to NBR_TEST * NBR_ACC - 1) of std_logic_vector(SLICE_WIDTH - 1 downto 0);
    signal vector_input_1 : vector_array := (others => (others => '0'));
    signal vector_input_2 : vector_array := (others => (others => '0'));

begin

    U0 : HD_PE
        generic map(
            VECTOR_WIDTH => VECTOR_WIDTH, -- Doit être une puissance de 2
            SLICE_WIDTH  => SLICE_WIDTH
        )
        port map(
            clk                  => clk,
            rstn                 => rstn,
            PE_acc_clear_input   => acc_clear,
            PE_acc_enable_input  => acc_enable,
            PE_slice_input_BHV   => slice_BHV,
            PE_slice_input_QHV   => slice_QHV,

            PE_HamDist_output    => HamDist
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
    
        -- 1ER HYPERVECTEUR : HamDist_total = 69 = 19 + 15 + 18 + 17
        vector_input_1(0) <= x"E537A563";
        vector_input_1(1) <= x"51C90EF0";
        vector_input_1(2) <= x"91f470d6";
        vector_input_1(3) <= x"4c354d6b";
        --vector_input_1(0) <= x"E537A56351C90EF091f470d64c354d6b";
        
        vector_input_2(0) <= x"016A50A9";
        vector_input_2(1) <= x"9e5d21d0";
        vector_input_2(2) <= x"dd03bec5";
        vector_input_2(3) <= x"221f64d5";
        --vector_input_2(0) <= x"016A50A99e5d21d0dd03bec5221f64d5";
 
        -- 2EME HYPERVECTEUR : HamDist_total = 67 = 16 + 14 + 19 + 18
        vector_input_1(4) <= x"7e121e1a";
        vector_input_1(5) <= x"96602ae1";
        vector_input_1(6) <= x"73ce2e5f";
        vector_input_1(7) <= x"041bc31c";
        --vector_input_1(1) <= x"7e121e1a96602ae173ce2e5f041bc31c";

        vector_input_2(4) <= x"1a0b7077";
        vector_input_2(5) <= x"25c46340";
        vector_input_2(6) <= x"17d4c5a8";
        vector_input_2(7) <= x"e094adc4";
        --vector_input_2(1) <= x"1a0b707725c4634017d4c5a8e094adc4";
        
        -- Reset
        rstn <= '0';
        wait for 1 ns;
        rstn <= '1';
        wait for 3 ns;

        slice_BHV <= vector_input_1(0);
        slice_QHV <= vector_input_2(0);

        wait until rising_edge(clk);

        acc_enable <= '1';

        wait for 1.3 ns;
        slice_BHV <= vector_input_1(1);
        slice_QHV <= vector_input_2(1);

        wait until rising_edge(clk);

        -- Test des vecteurs de test
        for i in 0 to NBR_TEST - 1 loop

            acc_enable <= '1';

            for j in 0 to NBR_ACC - 1 loop
                slice_BHV <= vector_input_1(i * NBR_ACC + j);
                slice_QHV <= vector_input_2(i * NBR_ACC + j);
                wait until rising_edge(clk);

            end loop;

            acc_enable <= '0';

            wait until rising_edge(clk);
            wait until rising_edge(clk);
            acc_clear <= '1';
            wait until rising_edge(clk);
            acc_clear <= '0';
            --wait until rising_edge(clk);
                
        end loop;

    end process;
    
end architecture;