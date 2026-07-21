library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library work;
use work.HD_Package.ALL;

entity tb_ACC is
end tb_ACC;

architecture Behavioral of tb_ACC is

    component ACC
        generic(
            VECTOR_WIDTH : natural;
            SLICE_WIDTH  : natural
        );
        port(
            clk                : in  std_logic;
            rstn               : in  std_logic;
            ACC_clear_input    : in  std_logic;
            ACC_enable_input   : in  std_logic;
            ACC_sum_input      : in  std_logic_vector(log2C(SLICE_WIDTH) - 1 downto 0);
    
            ACC_HamDist_output : out std_logic_vector(log2c(VECTOR_WIDTH) - 1 downto 0)
        );
    end component;

    constant CLK_PERIOD   : time := 2 ns;
    constant VECTOR_WIDTH : natural := 128;
    constant SLICE_WIDTH  : natural := 32;

    signal clk     : std_logic := '0';
    signal rstn    : std_logic := '0';
    signal clear   : std_logic := '0';
    signal enable  : std_logic := '0';
    signal sum     : std_logic_vector(log2C(SLICE_WIDTH) - 1 downto 0) := (others => '0');
    signal HamDist : std_logic_vector(log2c(VECTOR_WIDTH) - 1 downto 0);

begin

    -- Instanciation composant ACC
    U0: ACC
        generic map (
            VECTOR_WIDTH => VECTOR_WIDTH,
            SLICE_WIDTH  => SLICE_WIDTH
        )
        port map (
            clk                => clk,
            rstn               => rstn,
            ACC_clear_input    => clear,
            ACC_enable_input   => enable,
            ACC_sum_input      => sum,

            ACC_HamDist_output => HamDist
        );

    -- Génération d'horloge
    clk_proc : process
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

        -- Reset
        rstn <= '0';
        wait for 1 ns;
        rstn <= '1';
        wait for 3 ns;
        wait until rising_edge(clk);
        
        -- Clear
        wait until rising_edge(clk);
        clear <= '1';
        wait until rising_edge(clk);
        clear <= '0';
        wait until rising_edge(clk);

        -- Test 1
        enable <= '1';
        sum <= "011001"; -- sum = 25
        wait until rising_edge(clk);
        sum <= "001001"; -- sum = 9
        wait until rising_edge(clk);
        sum <= "010110"; -- sum = 22
        wait until rising_edge(clk);
        sum <= "000100"; -- sum = 4
        wait until rising_edge(clk);
        enable <= '0';
        -- acc = 60

        -- Clear
        wait until rising_edge(clk);
        clear <= '1';
        wait until rising_edge(clk);
        clear <= '0';
        wait until rising_edge(clk);

        -- Test 2
        enable <= '1';
        sum <= "100000"; -- sum = 32
        wait until rising_edge(clk);
        sum <= "100000"; -- sum = 32
        wait until rising_edge(clk);
        sum <= "100000"; -- sum = 32
        wait until rising_edge(clk);
        sum <= "100000"; -- sum = 32
        wait until rising_edge(clk);
        enable <= '0';
        -- acc = 128

        -- Clear
        wait until rising_edge(clk);
        clear <= '1';
        wait until rising_edge(clk);
        clear <= '0';
        wait until rising_edge(clk);

        -- Test 3
        enable <= '1';
        sum <= "000000"; -- sum = 0
        wait until rising_edge(clk);
        sum <= "000000"; -- sum = 0
        wait until rising_edge(clk);
        sum <= "000000"; -- sum = 0
        wait until rising_edge(clk);
        sum <= "000000"; -- sum = 0
        wait until rising_edge(clk);
        enable <= '0';
        -- acc = 0

    end process;

end architecture;
