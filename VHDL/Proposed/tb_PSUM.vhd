library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library work;
use work.HD_Package.ALL;

entity tb_PSUM is
end tb_PSUM;

architecture Behavioral of tb_PSUM is

    component PSUM is
        generic(
            SLICE_WIDTH : natural -- Doit être une puissance de 2
        );
        port(
            PSUM_slice_input : in  std_logic_vector(SLICE_WIDTH - 1 downto 0);
            
            PSUM_sum_output  : out std_logic_vector(log2c(SLICE_WIDTH) - 1 downto 0)
        );
    end component;

    -- Constantes
    constant SLICE_WIDTH : natural := 32;

    -- Entrée / sortie
    signal tb_input  : std_logic_vector(SLICE_WIDTH - 1 downto 0) := (others => '0');
    signal tb_output : std_logic_vector(log2c(SLICE_WIDTH) - 1 downto 0);

begin

    -- Instanciation composant PSUM
    U1: component PSUM
        generic map (
            SLICE_WIDTH => SLICE_WIDTH
        )
        port map (
            PSUM_slice_input  => tb_input,

            PSUM_sum_output   => tb_output
        );

    -- Stimulis
    stim_proc: process
    begin
    
        tb_input <= (others => '0');
        wait for 10 ns;

        tb_input <= (others => '1');
        wait for 10 ns;

        tb_input <= "10101010101010101010101010101010";  -- 16 x '1'
        wait for 10 ns;

        tb_input <= "11010000011010001001001011001100";  -- 13 x '1'
        wait for 10 ns;

        tb_input <= "10101000111100001111000011110000";  -- 15 x '1'
        wait for 10 ns;

    end process;

end Behavioral;

